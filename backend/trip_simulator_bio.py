# trip_simulator_bio.py
from bio_physics import calcola_sforzo_umano, stima_velocita_pendenza

def run_bio_simulation(distanza_totale_km, num_segmenti, altitudini, limiti_campionati, massa_totale, car_data, req):
    """
    Simulatore dedicato alla mobilità dolce (Pedoni, Bici, Monopattini).
    Calcola l'energia in Kcal (per umani) o Wh (per mezzi elettrici leggeri).
    """
    roadbook = []
    energia_totale_consumata = 0.0 # Possono essere Kcal o Wh
    tempo_totale_ore = 0.0
    
    # 1. Capire che veicolo stiamo analizzando
    is_muscolare = car_data.get("muscolare", False)
    v_base = car_data.get("specifiche_avanzate", {}).get("velocita_base_kmh", 5.0)
    
    # Se è una bici o monopattino, possiamo avere una V_base più alta
    if req.categoria_trasporto == 1 and not is_muscolare:
        v_base = 20.0 # Monopattino/E-Bike viaggiano sui 20-25 km/h
    elif req.categoria_trasporto == 1 and is_muscolare:
        v_base = 15.0 # Bici muscolare

    distanza_step_km = distanza_totale_km / num_segmenti

    # 2. Ciclo Segmento per Segmento
    for i in range(num_segmenti):
        h1 = altitudini[i]
        h2 = altitudini[i+1]
        
        # Pendenza in percentuale
        pendenza = ((h2 - h1) / (distanza_step_km * 1000)) * 100
        
        # La velocità varia in base alla pendenza (soprattutto se sei a piedi o in bici)
        v_ideale = stima_velocita_pendenza(v_base, pendenza)
        
        tempo_step_ore = distanza_step_km / v_ideale
        tempo_totale_ore += tempo_step_ore
        
        # CALCOLO ENERGETICO
        if is_muscolare:
            # Piedi o Bici Muscolare (Calcoliamo le Kcal)
            kcal_min = calcola_sforzo_umano(massa_totale, pendenza, v_ideale, req.pedestrian_mode)
            energia_step = kcal_min * (tempo_step_ore * 60) # Kcal totali del segmento
        else:
            # Monopattino o E-Bike (Calcoliamo i Wh). *Nota: Aggiungeremo la fisica elettrica qui*
            energia_step = 10.0 # Placeholder temporaneo per test
            
        energia_totale_consumata += energia_step

        # Aggiunta al Roadbook
        roadbook.append({
            "km": round((i + 1) * distanza_step_km, 2),
            "pendenza": round(pendenza, 1),
            "altitudine": round(h2, 1),
            "v_ideale": round(v_ideale, 1),
            "marcia": "Muscolare" if is_muscolare else "Elettrico", # Flutter si aspetta questo campo
            "limite_strada": limiti_campionati[i]
        })

    # 3. Formattazione Statistiche per Flutter
    # Flutter si aspetta dizionari specifici, li creiamo fittizi ma corretti
    
    # Il consumo medio lo esprimiamo in Kcal/10km per gli umani o Wh/km per l'elettrico
    consumo_medio = energia_totale_consumata / (distanza_totale_km / 10) if is_muscolare else energia_totale_consumata / distanza_totale_km

    stats_dict = {
        "distanza_km": round(distanza_totale_km, 1),
        "vel_media_normale": round(distanza_totale_km / tempo_totale_ore, 1), 
        "consumo_medio_normale": round(consumo_medio, 1), 
        "litri_totali_normale": round(energia_totale_consumata, 1), # Flutter legge i litri per mostrare il valore principale. Noi gli passiamo le Kcal/Wh!
        "kwh_totali_normale": 0.0, 
        "costo_normale": 0.0, 
        "co2_normale": 0.0,
    }

    return {
        "roadbook": roadbook,
        "statistiche": stats_dict,
        "warnings": ["Modalità Allenamento Attiva" if req.is_training else "Percorso Eco Consigliato"]
    }