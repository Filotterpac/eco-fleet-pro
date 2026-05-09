"""
=========================================================
FILE: trip_simulator_human.py
SCOPO: Simulatore di viaggio esclusivo per Pedoni e Bici Muscolari.
COSA FA: 
 1. Cicla il percorso segmento per segmento (come le auto).
 2. Usa bio_physics per calcolare le Kcal bruciate e il tempo.
 3. Impacchetta i dati replicando ESATTAMENTE la struttura 
    delle auto (Normale, Target, Veloce, ecc.) per non 
    rompere il frontend in Flutter.
=========================================================
"""
from bio_physics import calcola_sforzo_umano, tobler_speed

def run_human_simulation(distanza_km, num_segmenti, altitudini, limiti, peso_utente, req):
    roadbook = []
    energia_totale_kcal = 0.0
    tempo_totale_h = 0.0
    step_km = distanza_km / max(1, num_segmenti)
    
    # Velocità base scelta in base alla modalità
    if req.pedestrian_mode == "Corsa":
        v_base = 10.0
    elif req.micro_mode == "Bicicletta" and req.categoria_trasporto == 1:
        v_base = 15.0 # Bici muscolare
    else:
        v_base = 5.0  # Camminata standard

    for i in range(num_segmenti):
        # 1. Calcolo Pendenza
        pendenza = ((altitudini[i+1] - altitudini[i]) / (step_km * 1000)) * 100
        
        # 2. Calcolo Velocità reale (rallentata dalla salita)
        v_reale = tobler_speed(v_base, pendenza)
        
        # 3. Calcolo Tempo e Calorie
        durata_h = step_km / v_reale
        kcal_al_minuto = calcola_sforzo_umano(peso_utente, pendenza, v_reale, req.pedestrian_mode)
        kcal_segmento = kcal_al_minuto * (durata_h * 60)
        
        energia_totale_kcal += kcal_segmento
        tempo_totale_h += durata_h

        # 4. Scrittura del Roadbook per Flutter
        roadbook.append({
            "km": round((i+1)*step_km, 2),
            "pendenza": round(pendenza, 1),
            "altitudine": round(altitudini[i+1], 1),
            "v_ideale": round(v_reale, 1),
            "consumo_ist": round(kcal_segmento, 2),
            "marcia": "Kcal", # L'unità di misura che Flutter leggerà
            "limite_strada": limiti[i]
        })

    # Calcoli finali
    vel_media = round(distanza_km / max(0.001, tempo_totale_h), 1)
    consumo_medio = round(energia_totale_kcal / max(0.001, distanza_km), 1) # Kcal/km
    kcal_tot = round(energia_totale_kcal, 1)

    # --- IL TRUCCO PER NON ROMPERE FLUTTER ---
    # Replicamo la stessa struttura generata da genera_pacchetto_stat() in trip_simulator.py
    # Riempiamo tutto con i dati della camminata/corsa, impostando costi e CO2 a zero.
    
    stats_unificate = {
        "distanza_km": round(distanza_km, 1),
        "unita_misura": "Kcal", # Flag utile per la UI
        
        # Modalità NORMALE (Usata dalla TelemetryTab)
        "vel_media_normale": vel_media, 
        "consumo_medio_normale": consumo_medio, 
        "litri_totali_normale": kcal_tot, 
        "kwh_totali_normale": 0.0, 
        "costo_normale": 0.0, 
        "co2_normale": 0.0,

        # Modalità TARGET (Eco)
        "vel_media_target": vel_media, 
        "consumo_medio_target": consumo_medio, 
        "litri_totali_target": kcal_tot, 
        "kwh_totali_target": 0.0, 
        "costo_target": 0.0, 
        "co2_target": 0.0,

        # Modalità VELOCE
        "vel_media_veloce": vel_media, 
        "consumo_medio_veloce": consumo_medio, 
        "litri_totali_veloce": kcal_tot, 
        "kwh_totali_veloce": 0.0, 
        "costo_veloce": 0.0, 
        "co2_veloce": 0.0,
        
        # Modalità SMART
        "vel_media_smart": vel_media, 
        "consumo_medio_smart": consumo_medio, 
        "litri_totali_smart": kcal_tot, 
        "kwh_totali_smart": 0.0, 
        "costo_smart": 0.0, 
        "co2_smart": 0.0,
        
        # Modalità SUPER VELOCE
        "vel_media_superveloce": vel_media, 
        "consumo_medio_superveloce": consumo_medio, 
        "litri_totali_superveloce": kcal_tot, 
        "kwh_totali_superveloce": 0.0, 
        "costo_superveloce": 0.0, 
        "co2_superveloce": 0.0,
    }

    warnings = []
    if req.is_training:
        warnings.append("💪 Modalità Allenamento Attiva: calcolo calorie massimizzato.")
    else:
        warnings.append("🚶 Percorso base calcolato con equazioni metaboliche ACSM.")

    return {
        "roadbook": roadbook,
        "statistiche": stats_unificate,
        "warnings": warnings,
        "dislivello_positivo_m": 0 # Lo calcoli eventualmente nell'engine
    }