"""
=========================================================
FILE: engine.py
SCOPO: Orchestratore Centrale del Sistema.
=========================================================
"""
import hashlib
import json
from fastapi import HTTPException
from geopy.geocoders import Nominatim
import redis

from external_apis import get_location, fetch_osrm_route, fetch_elevations
from trip_simulator import run_simulation as run_car_simulation
from trip_simulator_human import run_human_simulation

# Configurazione Cache
try:
    cache = redis.Redis(host='localhost', port=6379, db=0, decode_responses=True)
    cache.ping()
    USE_CACHE = True
except:
    USE_CACHE = False

def generate_telemetry(req, car_data):
    # 1. CONTROLLO CACHE (CHIAVE AGGIORNATA!)
    # Ora distingue perfettamente un pedone da un'auto sullo stesso percorso
    if USE_CACHE:
        raw_key = f"v3_{req.partenza}_{req.tappa}_{req.arrivo}_{req.categoria_trasporto}_{req.car_model}_{req.pedestrian_mode}_{req.is_training}"
        cache_key = hashlib.md5(raw_key.encode('utf-8')).hexdigest()
        cached = cache.get(cache_key)

        if cached:
            print("🚀 Hit in Cache! Calcolo saltato.")
            return json.loads(cached)

    # 2. GEOLOCALIZZAZIONE
    geolocator = Nominatim(user_agent="eco_fleet_pro")
    loc_partenza = get_location(req.partenza, geolocator)
    loc_arrivo = get_location(req.arrivo, geolocator)
    loc_tappa = get_location(req.tappa, geolocator) if req.tappa else None

    if not loc_partenza or not loc_arrivo:
        raise HTTPException(status_code=404, detail="Coordinate non trovate.")

    # 3. RECUPERO OSRM
    coords, distanza_totale_km, limiti_strada = fetch_osrm_route(
        loc_partenza, loc_arrivo, loc_tappa, 
        req.andata_ritorno, req.evita_autostrade, 
        categoria=req.categoria_trasporto
    )

    if not coords:
        raise HTTPException(status_code=500, detail="Impossibile calcolare il percorso stradale.")

    # 4. CAMPIONAMENTO
    num_segmenti = max(1, int(distanza_totale_km / 0.3))
    step = max(1, len(coords) // num_segmenti)
    punti_analisi = [coords[i * step] for i in range(num_segmenti)]
    punti_analisi.append(coords[-1]) 
    
    limiti_campionati = [limiti_strada[min(i * step, len(limiti_strada)-1)] for i in range(num_segmenti)]

    altitudini = fetch_elevations(punti_analisi, loc_partenza, loc_arrivo, req.andata_ritorno)

    # 5. SMISTAMENTO SIMULATORI
    if req.categoria_trasporto < 2:
        # LOGICA UMANA E BICI
        peso_utente = float(req.passeggeri) if req.passeggeri > 10 else 75.0
        risultato = run_human_simulation(
            distanza_totale_km, num_segmenti, altitudini, 
            limiti_campionati, peso_utente, req
        )
    else:
        # LOGICA AUTO E MOTO
        massa_totale = car_data.get("peso_vuoto", 1000) + (req.passeggeri * 75)
        crr = 0.012 
        risultato = run_car_simulation(
            distanza_totale_km, num_segmenti, altitudini, 
            limiti_campionati, massa_totale, car_data, req, crr
        )

    # 6. SALVATAGGIO SICURO IN CACHE E AGGIUNTA COORDS
    if isinstance(risultato, dict):
        # --- FIX CRITICO: INCOLLIAMO LE COORDINATE DELLA MAPPA ---
        risultato["coords"] = coords
        
        if USE_CACHE:
            # Cambia a v4 per resettare la cache!
            cache_key_v4 = cache_key.replace("v3_", "v4_") 
            cache.setex(cache_key_v4, 3600, json.dumps(risultato))

    return risultato