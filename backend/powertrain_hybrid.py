# powertrain_hybrid.py
import energy_vectors

def calcola_hybrid(potenza_totale_kw, v_kmh, car_data, is_accel, ek_kwh, distanza_step_km, malus_termico, pendenza, km_percorsi):
    """
    Simulatore EMS (Energy Management System) ad altissima fedeltà per veicoli HEV (Full Hybrid) e PHEV (Plug-in).
    """
    tipo_motore = car_data.get('specifiche_avanzate', {}).get('motore', {}).get('tipo', 'ibrido_benzina').lower()
    
    # Riconoscimento Chimica Termica (GPL o Benzina)
    if "diesel" in tipo_motore: fuel, unita = energy_vectors.get_fuel_specs("diesel")
    elif "gpl" in tipo_motore: fuel, unita = energy_vectors.get_fuel_specs("gpl")
    else: fuel, unita = energy_vectors.get_fuel_specs("benzina")

    # Specifiche Powertrain
    pot_max_ice_kw = car_data.get("specifiche_avanzate", {}).get("motore", {}).get("potenza_max_cv", 100) / 1.36
    pot_max_ev_kw = car_data.get("specifiche_avanzate", {}).get("motore", {}).get("potenza_ev_cv", 50) / 1.36
    eff_ice_picco = car_data.get("efficienza_motore", 0.38) # Le ibride usano spesso Ciclo Atkinson (efficienza maggiore)
    eff_ev = 0.92
    
    # 1. LOGICA PHEV (Plug-in) vs HEV (Full Hybrid)
    is_phev = "plug-in" in tipo_motore or "phev" in tipo_motore
    autonomia_ev_dichiarata = car_data.get("specifiche_avanzate", {}).get("batteria", {}).get("autonomia_ev_km", 0)
    
    # Determiniamo se la batteria principale ha energia per la trazione pura (Charge Depleting Mode)
    batteria_carica = True if (is_phev and km_percorsi < autonomia_ev_dichiarata) else False

    risultato = {"litri_100km": 0.0, "kwh_100km": 0.0}

    # ---------------------------------------------------------
    # CASO A: DISCESA E RIGENERAZIONE (Per tutte le ibride)
    # ---------------------------------------------------------
    if potenza_totale_kw <= 0:
        if v_kmh < 10:
            return risultato # Sotto i 10 km/h intervengono i freni meccanici
            
        # L'Inverter cattura la potenza negativa. Recupero limitato dalla potenza del motore EV
        regen_utile_kw = max(potenza_totale_kw, -pot_max_ev_kw)
        pot_elettrica_kw = regen_utile_kw * 0.70 # Efficienza rigenerativa MGU-K + Batteria
        
        # Le PHEV salvano tutto in batteria. Le HEV pure, ma lo riuseranno al prossimo semaforo
        risultato["kwh_100km"] = ((pot_elettrica_kw / v_kmh) * 100)
        return risultato

    # ---------------------------------------------------------
    # CASO B: MODALITÀ EV PURA (PHEV Carico o Veleggiamento a bassa velocità)
    # ---------------------------------------------------------
    soglia_ev_kw = pot_max_ev_kw * 0.8 # Limite prima che il termico si accenda per forza
    
    if batteria_carica or (v_kmh < 40 and potenza_totale_kw < soglia_ev_kw):
        # La potenza rientra nei limiti elettrici, il motore ICE resta SPENTO.
        # Nessun malus termico viene applicato perché non c'è combustione.
        pot_elettrica_kw = potenza_totale_kw / eff_ev
        
        kwh_100km = (pot_elettrica_kw / max(1, v_kmh)) * 100
        
        # Accelerazione puramente elettrica
        if is_accel and ek_kwh > 0 and distanza_step_km > 0:
            kwh_accel = (ek_kwh / eff_ev) / distanza_step_km * 100
            kwh_100km += kwh_accel
            
        risultato["kwh_100km"] = kwh_100km
        return risultato

    # ---------------------------------------------------------
    # CASO C: MODALITÀ IBRIDA (Power Split & Load Leveling)
    # ---------------------------------------------------------
    # Il motore termico si accende. Grazie al ripartitore di coppia (e-CVT),
    # il motore viene tenuto vicino al suo regime di massima efficienza termodinamica.
    
    # 1. Load Leveling: L'ICE si fa carico della potenza costante (Crociera/Salita)
    potenza_ice_kw = potenza_totale_kw
    
    # L'efficienza non crolla come nei termici puri perché non viaggia sottocoppia
    # Assumiamo un'efficienza stabilizzata altissima (Ciclo Atkinson)
    eff_reale_ice = eff_ice_picco * 0.90 
    
    kg_carburante_h = potenza_ice_kw / (fuel["potere_calorifico_kwh_kg"] * eff_reale_ice)
    litri_h = (kg_carburante_h / (fuel["densita_g_l"] / 1000)) * malus_termico
    risultato["litri_100km"] = (litri_h / v_kmh) * 100

    # 2. Torque Fill Elettrico: Le accelerazioni brusche le fa il motore EV
    if is_accel and ek_kwh > 0 and distanza_step_km > 0:
        # L'energia cinetica viene prelevata dalla batteria, NON dalla benzina!
        kwh_accel = (ek_kwh / eff_ev)
        risultato["kwh_100km"] = (kwh_accel / distanza_step_km) * 100

    return risultato