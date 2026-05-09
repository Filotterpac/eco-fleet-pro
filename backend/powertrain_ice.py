# powertrain_ice.py

# Dizionario chimico isolato per i motori termici
ICE_FUELS = {
    "benzina": {"potere_calorifico_kwh_kg": 12.2, "densita_g_l": 745, "unita": "Litri"},
    "diesel":  {"potere_calorifico_kwh_kg": 11.8, "densita_g_l": 835, "unita": "Litri"},
    "gpl":     {"potere_calorifico_kwh_kg": 12.8, "densita_g_l": 510, "unita": "Litri"},
    "metano":  {"potere_calorifico_kwh_kg": 13.9, "densita_g_l": 1000, "unita": "Kg"} # Il metano si calcola in Kg (densità fittizia a 1000 per neutralizzarla nel calcolo)
}

def calcola_ice(potenza_totale_kw, v_kmh, car_data, is_accel, ek_kwh, distanza_step_km, malus_termico, pendenza):
    """
    Simulatore ad alta fedeltà per Motori a Combustione Interna.
    """
    tipo_motore = car_data.get('specifiche_avanzate', {}).get('motore', {}).get('tipo', 'benzina').lower()
    
    # Riconoscimento carburante
    if "diesel" in tipo_motore: fuel = ICE_FUELS["diesel"]
    elif "gpl" in tipo_motore: fuel = ICE_FUELS["gpl"]
    elif "metano" in tipo_motore: fuel = ICE_FUELS["metano"]
    else: fuel = ICE_FUELS["benzina"]

    pot_max_kw = car_data.get("specifiche_avanzate", {}).get("motore", {}).get("potenza_max_cv", 100) / 1.36
    eff_picco = car_data.get("efficienza_motore", 0.35)
    
    # 1. CUT-OFF REALE E CONSUMO AL MINIMO
    # Se andiamo a più di 20 km/h e non c'è richiesta di potenza (discesa o veleggiamento), gli iniettori si spengono.
    if potenza_totale_kw <= 0 and v_kmh > 20:
        return {"litri_100km": 0.0, "kwh_100km": 0.0}
    
    # Se la potenza richiesta è 0 o negativa ma siamo fermi o quasi (es. semaforo), il motore gira al minimo.
    # Un motore consuma circa 0.6 - 1.2 litri/ora al minimo a seconda della cilindrata/potenza.
    if potenza_totale_kw <= 0 and v_kmh <= 20:
        consumo_minimo_kg_h = (pot_max_kw * 0.015) # Proxy empirico: auto più potenti consumano più al minimo
        consumo_minimo_l_h = consumo_minimo_kg_h / (fuel["densita_g_l"] / 1000)
        # Se siamo fermi (0 km/h), per non dividere per zero, diamo il consumo orario proporzionato al segmento
        if v_kmh < 1.0: 
            # Ritorna un valore fittizio alto per far capire che stare fermi peggiora la media 100km
            return {"litri_100km": (consumo_minimo_l_h * 100) / max(1, v_kmh), "kwh_100km": 0.0} 
        
        litri_100km_minimo = (consumo_minimo_l_h / v_kmh) * 100
        return {"litri_100km": litri_100km_minimo * malus_termico, "kwh_100km": 0.0}

    # 2. CURVA DI EFFICIENZA DINAMICA (BSFC Approx)
    # L'efficienza di un termico crolla ai bassi carichi e scende leggermente a gas spalancato (arricchimento)
    load_factor = min(1.0, potenza_totale_kw / pot_max_kw)
    
    if load_factor < 0.10:
        # Traffico lento / fil di gas: efficienza pessima (motore strozzato dalla farfalla)
        eff_reale = eff_picco * 0.40
    elif load_factor < 0.30:
        # Carico medio-basso
        eff_reale = eff_picco * 0.75
    elif load_factor < 0.75:
        # Sweet spot del motore (crociera autostradale o leggera accelerazione)
        eff_reale = eff_picco
    else:
        # Full gas (WOT - Wide Open Throttle): la centralina ingrassa la miscela per non fondere (lambda < 1)
        eff_reale = eff_picco * 0.85 

    # 3. CALCOLO CHIMICO DELLA COMBUSTIONE
    energia_richiesta_kwh = potenza_totale_kw # in 1 ora
    kg_carburante_h = energia_richiesta_kwh / (fuel["potere_calorifico_kwh_kg"] * eff_reale)
    
    # Trasformiamo in Volume (Litri) - eccetto per il metano che resta in Kg
    unita_h = kg_carburante_h / (fuel["densita_g_l"] / 1000)
    
    # Applichiamo il malus termico (motore freddo ha più attriti e combustione peggiore)
    unita_h *= malus_termico
    
    consumo_base_100km = (unita_h / v_kmh) * 100

    # 4. PENALITÀ TRANSIENTI (Accelerazione)
    # Quando si accelera rapidamente, la pompa di ripresa / mappa arricchisce molto
    penalita_accel = 0.0
    if is_accel and ek_kwh > 0 and distanza_step_km > 0:
        kg_accel = ek_kwh / (fuel["potere_calorifico_kwh_kg"] * eff_reale * 0.9) # Efficienza peggiorata in transitorio
        unita_accel = kg_accel / (fuel["densita_g_l"] / 1000)
        unita_accel *= malus_termico
        penalita_accel = (unita_accel / distanza_step_km) * 100

    consumo_finale = consumo_base_100km + penalita_accel

    # Nota: Per il Metano, "litri_100km" in realtà contiene i "Kg/100km". 
    # È perfetto così, il frontend Flutter mostrerà il numero corretto e i calcoli economici torneranno!
    return {"litri_100km": consumo_finale, "kwh_100km": 0.0}