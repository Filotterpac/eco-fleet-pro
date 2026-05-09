# powertrain.py
import powertrain_ice
import powertrain_ev
import powertrain_hybrid

def calcola_consumo_motore(potenza_totale_kw, v_kmh, car_data, is_accel, ek_kwh, distanza_step_km, malus_termico, eff_reale, pendenza, km_percorsi):
    """
    Orchestratore Centrale: Riceve i dati fisici e li dirotta al simulatore specializzato corretto.
    """
    tipo_motore = car_data.get('specifiche_avanzate', {}).get('motore', {}).get('tipo', 'benzina').lower()
    
    # Smistamento Elettrico (BEV)
    if 'elettrico' in tipo_motore or 'bev' in tipo_motore or 'tesla' in tipo_motore:
        # Passiamo una temperatura esterna fittizia di 10°C per simulare l'impatto del riscaldamento
        return powertrain_ev.calcola_ev(potenza_totale_kw, v_kmh, car_data, is_accel, ek_kwh, distanza_step_km, temp_esterna_c=10)
        
    # Smistamento Ibrido (HEV / PHEV)
    elif 'hybrid' in tipo_motore or 'ibrid' in tipo_motore or 'phev' in tipo_motore:
        return powertrain_hybrid.calcola_hybrid(potenza_totale_kw, v_kmh, car_data, is_accel, ek_kwh, distanza_step_km, malus_termico, pendenza, km_percorsi)
        
    # Smistamento Termico Puro (ICE - Benzina, Diesel, GPL, Metano)
    else:
        return powertrain_ice.calcola_ice(potenza_totale_kw, v_kmh, car_data, is_accel, ek_kwh, distanza_step_km, malus_termico, pendenza)