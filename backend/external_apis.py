import requests
from geopy.geocoders import Nominatim
# Import the new point functions
from database_mappe import salva_osrm, leggi_osrm, salva_geocode, leggi_geocode, salva_topo_point, leggi_topo_point
from database_vehicles import load_vehicles

class CustomLocation:
    def __init__(self, lat, lon):
        self.latitude = lat
        self.longitude = lon

def get_location(query, geolocator):
    if not query or str(query).strip() == "":
        return None
    try:
        if "," in query:
            parts = query.split(",")
            if len(parts) == 2:
                return CustomLocation(float(parts[0].strip()), float(parts[1].strip()))
    except ValueError:
        pass 
    
    # --- NUOVO: CERCHIAMO NEL DATABASE PRIMA DI CHIAMARE INTERNET ---
    cached_coords = leggi_geocode(query)
    if cached_coords:
        print(f"📍 Database Locale: Coordinate di '{query}' caricate dal disco!")
        return CustomLocation(cached_coords[0], cached_coords[1])
        
    print(f"🌍 Rete: Cerco le coordinate di '{query}' su Nominatim...")
    location = geolocator.geocode(query)
    
    if location:
        # SALVIAMO IL RISULTATO PER IL FUTURO
        salva_geocode(query, location.latitude, location.longitude)
        return CustomLocation(location.latitude, location.longitude)
        
    return None

def fetch_osrm_route(loc_partenza, loc_arrivo, loc_tappa=None, andata_ritorno=False, evita_autostrade=False, categoria=2):
    """
    Recupera il percorso da OSRM gestendo profili multi-modali, caching locale e limiti di velocità.
    """
    # 1. MAPPING CATEGORIA -> PROFILO OSRM
    profili = {0: "foot", 1: "bike", 2: "driving", 3: "driving"}
    profilo = profili.get(categoria, "driving")

    # 2. COSTRUZIONE WAYPOINTS (Preservata logica originale)
    waypoints = [f"{loc_partenza.longitude},{loc_partenza.latitude}"]
    if loc_tappa:
        waypoints.append(f"{loc_tappa.longitude},{loc_tappa.latitude}")
    waypoints.append(f"{loc_arrivo.longitude},{loc_arrivo.latitude}")
    
    if andata_ritorno:
        waypoints.append(f"{loc_partenza.longitude},{loc_partenza.latitude}")

    coords_str = ";".join(waypoints)
    
    # 3. CONTROLLO CACHE LOCALE (Preservata logica originale)
    dati_percorso = leggi_osrm(coords_str)
    
    if dati_percorso:
        print(f"🗺️  Database Locale: Percorso OSRM ({profilo}) caricato dal disco!")
    else:
        print(f"🌍 Rete: Percorso OSRM ({profilo}) non trovato, scarico da Internet...")
        
        # Gestione parametro 'exclude' per autostrade (solo se in modalità driving)
        exclude = "&exclude=motorway" if evita_autostrade and profilo == "driving" else ""
        
        url_osrm = (
            f"http://router.project-osrm.org/route/v1/{profilo}/{coords_str}"
            f"?overview=full&geometries=geojson&annotations=speed{exclude}"
        )
        
        response = requests.get(url_osrm)
        if response.status_code == 200:
            dati_percorso = response.json()
            salva_osrm(coords_str, dati_percorso) 
        else:
            # Fallback in caso di errore di rete
            print(f"❌ Errore OSRM API: {response.status_code}")
            return [], 0, []

    # 4. ESTRAZIONE DATI (Preservata logica originale)
    coords = dati_percorso['routes'][0]['geometry']['coordinates']
    distanza_totale_km = dati_percorso['routes'][0]['distance'] / 1000
    
    try:
        velocita_ms = []
        for leg in dati_percorso['routes'][0]['legs']:
            # Alcuni profili (specialmente foot) potrebbero non avere annotazioni speed ovunque
            if 'annotation' in leg and 'speed' in leg['annotation']:
                velocita_ms.extend(leg['annotation']['speed'])
        
        # Calcolo limiti strada (Preservata logica di arrotondamento originale)
        # Per piedi/bici mettiamo un limite minimo di 3 km/h invece di 30
        min_limit = 30 if categoria >= 2 else 3
        limiti_strada = [max(min_limit, round((v * 3.6) / 10) * 10) for v in velocita_ms]
        
        # Se mancano annotazioni (es. tratti pedonali non mappati bene), riempiamo con default
        if not limiti_strada:
            limiti_strada = [min_limit] * len(coords)
        else:
            limiti_strada.append(limiti_strada[-1])
            
    except (KeyError, TypeError):
        limiti_strada = [50 if categoria >= 2 else 5] * len(coords)
        
    return coords, distanza_totale_km, limiti_strada

def fetch_elevations(punti_analisi, loc_partenza, loc_arrivo, andata_ritorno):
    altitudini = [0.0] * len(punti_analisi)
    punti_da_scaricare = []
    indici_da_scaricare = []

    print(f"🔍 Analisi di {len(punti_analisi)} punti altimetrici...")

    # 1. Controlliamo il Database per OGNI singolo punto
    for i, p in enumerate(punti_analisi):
        # OSRM returns [lon, lat], so p[1] is lat, p[0] is lon
        lat = p[1]
        lon = p[0]
        cached_elevation = leggi_topo_point(lat, lon)
        
        if cached_elevation is not None:
            altitudini[i] = cached_elevation
        else:
            punti_da_scaricare.append((lat, lon))
            indici_da_scaricare.append(i)

    if not punti_da_scaricare:
        print("⛰️  Tutte le altimetrie caricate dal Database Locale (0 buchi)!")
        return altitudini

    print(f"🌍 Rete: {len(punti_da_scaricare)} punti mancanti, scarico da Internet...")

    # 2. Scarichiamo solo i punti mancanti a blocchi di 90
    for i in range(0, len(punti_da_scaricare), 90):
        chunk = punti_da_scaricare[i:i+90]
        chunk_indices = indici_da_scaricare[i:i+90]
        
        locations = "|".join([f"{lat},{lon}" for lat, lon in chunk])
        
        try:
            dati_topo = requests.get(f"https://api.opentopodata.org/v1/srtm30m?locations={locations}", timeout=10).json()
            
            if dati_topo and 'results' in dati_topo:
                for j, res in enumerate(dati_topo['results']):
                    elevation = res['elevation']
                    original_index = chunk_indices[j]
                    
                    # Salva in array
                    altitudini[original_index] = elevation
                    
                    # 3. Salva nel Database per il futuro!
                    salva_topo_point(chunk[j][0], chunk[j][1], elevation)
        except Exception as e:
            print(f"⚠️ Errore API su un blocco: {e}")
            # Se fallisce, restano a 0, ma riproveremo la prossima volta

    return altitudini