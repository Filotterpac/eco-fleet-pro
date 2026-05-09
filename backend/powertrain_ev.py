# powertrain_ev.py
import math

def calcola_ev(potenza_meccanica_kw, v_kmh, car_data, is_accel, ek_kwh, distanza_step_km, temp_esterna_c=20):
    """
    Simulatore ad alta fedeltà per Veicoli Elettrici (BEV).
    """
    # 1. DATI VEICOLO E POWERTRAIN
    # (Se i dati mancano, assumiamo una BEV media tipo ID.3 o Model 3 Standard Range)
    pot_max_kw = car_data.get("specifiche_avanzate", {}).get("motore", {}).get("potenza_max_cv", 204) / 1.36
    
    # 2. ASSORBIMENTI AUSILIARI (HVAC & BMS)
    # L'elettronica di base (BMS, Inverter in standby, Infotainment) assorbe sempre circa 300W
    potenza_aux_kw = 0.300
    
    # Simulazione Climatizzatore (HVAC)
    delta_t = abs(22 - temp_esterna_c) # Target abitacolo 22°C
    if delta_t > 0:
        ha_pompa_calore = car_data.get("specifiche_avanzate", {}).get("hvac", {}).get("pompa_calore", True)
        if ha_pompa_calore:
            # Pompa di calore: COP variabile da 2.0 a 3.5 a seconda del freddo
            cop = max(1.5, 3.5 - (delta_t * 0.05))
            potenza_hvac = (delta_t * 0.15) / cop
        else:
            # Resistenza PTC tradizionale (Riscaldatore Joule puro, COP = 1)
            potenza_hvac = delta_t * 0.15
        
        potenza_aux_kw += min(potenza_hvac, 5.0) # Cap massimo del clima a 5 kW

    # Energia spesa per tenere accesa la macchina in questo segmento
    tempo_ore = (distanza_step_km / v_kmh) if v_kmh > 0 else 0
    kwh_aux_segmento = potenza_aux_kw * tempo_ore

    # Se siamo fermi o a passo d'uomo, il consumo è dominato dagli ausiliari
    if v_kmh < 2.0:
        return {"litri_100km": 0.0, "kwh_100km": (kwh_aux_segmento / max(0.1, distanza_step_km)) * 100}

    # 3. MAPPA DI EFFICIENZA MOTORE/INVERTER (Dinamica)
    # Efficienza di picco tipica Inverter SiC + Motore sincrono = ~94%
    eff_picco = 0.94
    load_factor = abs(potenza_meccanica_kw) / pot_max_kw
    
    if v_kmh < 25:
        # Basse velocità: Perdite nel Rame dominanti. Peggiora se c'è molta coppia (alto carico)
        eff_motore = eff_picco - 0.10 - (load_factor * 0.05)
    elif v_kmh > 110:
        # Alte velocità: Field Weakening e perdite nel Ferro (Correnti parassite)
        eff_motore = eff_picco - ((v_kmh - 110) * 0.002)
    else:
        # Sweet spot (25-110 km/h)
        if load_factor < 0.1:
            eff_motore = eff_picco - 0.05 # L'inverter è meno efficiente a carichi minimi
        else:
            eff_motore = eff_picco

    # 4. GESTIONE TRAZIONE E RIGENERAZIONE (Regen Blending)
    if potenza_meccanica_kw > 0:
        # FASE DI TRAZIONE
        pot_elettrica_kw = potenza_meccanica_kw / eff_motore
    else:
        # FASE DI RIGENERAZIONE (Discesa o frenata)
        if v_kmh < 10:
            # Sotto i 10 km/h la f.c.e.m. è troppo bassa, i freni meccanici si occupano di fermare l'auto
            pot_elettrica_kw = 0.0
        else:
            # Batteria e chimica limitano la ricarica (es. max 60 kW in regen continuo per non rovinare le celle)
            regen_max_kw = pot_max_kw * 0.40 # Solitamente il regen max è circa il 40-50% della potenza max
            potenza_regen_utile = max(potenza_meccanica_kw, -regen_max_kw)
            
            # Parte dell'energia va persa nei freni meccanici se la discesa è troppo ripida
            pot_elettrica_kw = potenza_regen_utile * eff_motore # Valore negativo!

    # 5. RESISTENZA INTERNA BATTERIA (Joule Heating)
    # P_loss = I^2 * R. Per semplificare, assumiamo una perdita quadratica rispetto alla potenza prelevata.
    # Ad alti carichi, fino al 4-5% dell'energia diventa calore nelle celle.
    perdita_batteria_kw = (pot_elettrica_kw**2) * 0.00015 
    
    if pot_elettrica_kw > 0:
        potenza_dalla_batteria = pot_elettrica_kw + perdita_batteria_kw
    else:
        # In ricarica, la batteria riceve MENO energia di quanta l'inverter le invia, perché un po' si perde in calore
        potenza_dalla_batteria = pot_elettrica_kw + perdita_batteria_kw # Ricorda: pot_elettrica_kw è negativa qui

    # Consumo di crociera e pendenza
    kwh_100km_base = ((potenza_dalla_batteria * tempo_ore) / distanza_step_km) * 100

    # 6. TRANSIENTI E ACCELERAZIONI (Massa inerziale)
    kwh_100km_accel = 0.0
    if is_accel and ek_kwh > 0 and distanza_step_km > 0:
        # L'accelerazione pura richiede potenza extra, applichiamo l'efficienza del motore
        kwh_richiesti = ek_kwh / eff_motore
        # Aggiungiamo le perdite termiche della batteria per lo spunto di corrente
        kwh_spesi = kwh_richiesti + ((kwh_richiesti**2) * 0.00015 * (3600 / max(1, v_kmh)))
        kwh_100km_accel = (kwh_spesi / distanza_step_km) * 100

    # 7. SOMMA FINALE
    consumo_totale_kwh_100km = kwh_100km_base + kwh_100km_accel + ((kwh_aux_segmento / distanza_step_km) * 100)

    # In forte discesa, il valore finale PUÒ essere negativo (L'auto sta ricaricando nel calcolo complessivo)
    return {"litri_100km": 0.0, "kwh_100km": consumo_totale_kwh_100km}