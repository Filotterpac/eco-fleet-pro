# trip_simulator.py
from physics import calcola_consumo, scegli_marcia, applica_veleggio_predittivo
import energy_vectors

def get_tipo_strada(limite_kmh):
    if limite_kmh <= 50: return "urbano"
    elif limite_kmh <= 90: return "extraurbano"
    else: return "autostrada"

def run_simulation(distanza_totale_km, num_segmenti, altitudini, limiti_campionati, massa_totale, car_data, req, crr):
    roadbook = []
    cons_eco, cons_norm, cons_vel, cons_smart, cons_super = [], [], [], [], []
    vel_eco, vel_norm, vel_vel, vel_smart, vel_super = [], [], [], [], []
    
    v_eco_prec = v_norm_prec = v_vel_prec = v_smart_prec = v_super_prec = 30

    # Ricaviamo di cosa si nutre l'auto
    tipo_motore = car_data.get('specifiche_avanzate', {}).get('motore', {}).get('tipo', 'benzina').lower()
    specs, unita = energy_vectors.get_fuel_specs(tipo_motore)

    for i in range(num_segmenti):
        h1, h2 = altitudini[i], altitudini[i+1]
        distanza_step = distanza_totale_km / num_segmenti
        pendenza = ((h2 - h1) / (distanza_step * 1000)) * 100
        limite_attuale = limiti_campionati[i]
        tipo = get_tipo_strada(limite_attuale)
        km_attuale = i * distanza_step

        v_normale = limite_attuale
        v_veloce = min(130, int(limite_attuale * 1.15))

        # SMART Target
        target_smart = limite_attuale
        if pendenza >= 2.0:
            target_smart = int(limite_attuale * 0.85) if limite_attuale >= 90 else int(limite_attuale * 0.90)
        elif pendenza <= -1.5:
            target_smart = min(130, int(limite_attuale * 1.15)) 
        v_smart = max(target_smart, v_smart_prec - 5) if target_smart < v_smart_prec and pendenza > -1.5 else target_smart

        # ECO Target
        v_eco = 30
        for v in range(30, limite_attuale + 1, 2):
            c_test = calcola_consumo(v, pendenza, massa_totale, car_data, crr, req.is_real_mode, tipo, v_eco_prec, distanza_step, km_attuale)
            val_test = c_test["litri_100km"] if unita == "litri" else c_test["kwh_100km"]
            if val_test <= req.target_l:
                v_eco = v
            else:
                break

        v_super = limite_attuale + req.super_veloce_offset

        # CALCOLI FISICI (Ritorna Dizionari Strutturati)
        c_eco_dict = calcola_consumo(v_eco, pendenza, massa_totale, car_data, crr, req.is_real_mode, tipo, v_eco_prec, distanza_step, km_attuale)
        c_norm_dict = calcola_consumo(v_normale, pendenza, massa_totale, car_data, crr, req.is_real_mode, tipo, v_norm_prec, distanza_step, km_attuale)
        c_vel_dict = calcola_consumo(v_veloce, pendenza, massa_totale, car_data, crr, req.is_real_mode, tipo, v_vel_prec, distanza_step, km_attuale)
        c_smart_dict = calcola_consumo(v_smart, pendenza, massa_totale, car_data, crr, req.is_real_mode, tipo, v_smart_prec, distanza_step, km_attuale)
        c_super_dict = calcola_consumo(v_super, pendenza, massa_totale, car_data, crr, req.is_real_mode, tipo, v_super_prec, distanza_step, km_attuale)

        if req.is_real_mode:
            for d in [c_vel_dict, c_super_dict]:
                d["litri_100km"] *= 1.15
                d["kwh_100km"] *= 1.15

        cons_eco.append(c_eco_dict); vel_eco.append(v_eco)
        cons_norm.append(c_norm_dict); vel_norm.append(v_normale)
        cons_vel.append(c_vel_dict); vel_vel.append(v_veloce)
        cons_smart.append(c_smart_dict); vel_smart.append(v_smart)
        cons_super.append(c_super_dict); vel_super.append(v_super)

        # Mostriamo nel Roadbook il vettore dominante (Litri o KWh) per non esplodere la UI
        val_smart = c_smart_dict["litri_100km"] if c_smart_dict["litri_100km"] > 0 else c_smart_dict["kwh_100km"]

        roadbook.append({
            "km": round(km_attuale, 2), "altitudine": round(h1, 0), "pendenza": round(pendenza, 1),
            "limite_strada": limite_attuale, "v_ideale": v_smart,
            "v_ideale_super": v_super, "v_ideale_veloce": v_veloce, "v_ideale_normale": v_normale, "v_ideale_smart": v_smart, "v_ideale_eco": v_eco,
            "marcia": scegli_marcia(v_smart), "consumo_ist": round(val_smart, 2)
        })
        v_eco_prec, v_norm_prec, v_vel_prec, v_smart_prec, v_super_prec = v_eco, v_normale, v_veloce, v_smart, v_super

    roadbook.append({
        "km": round(distanza_totale_km, 2), "altitudine": round(altitudini[-1], 0), "pendenza": 0.0,
        "limite_strada": limiti_campionati[-1] if limiti_campionati else 50, "v_ideale": v_smart_prec,
        "v_ideale_super": v_super_prec, "v_ideale_veloce": v_vel_prec, "v_ideale_normale": v_norm_prec, "v_ideale_smart": v_smart_prec, "v_ideale_eco": v_eco_prec,
        "marcia": scegli_marcia(v_smart_prec), "consumo_ist": 0.0
    })

    roadbook = applica_veleggio_predittivo(roadbook, car_data, massa_totale, crr)

    # ------------ GESTIONE FINANZIARIA COMPLESSA ------------
    def avg(lst): return sum(lst) / len(lst) if lst else 0
    def tot(medie_dict_list, dist, key): 
        # Filtra i None derivati dal veleggio (che abbiamo impostato a 0)
        clean_list = [d[key] for d in medie_dict_list if isinstance(d, dict)]
        return (avg(clean_list) * dist) / 100

    def genera_pacchetto_stat(nome_lista_vel, nome_lista_cons, distanza):
        litri = tot(nome_lista_cons, distanza, "litri_100km")
        kwh = tot(nome_lista_cons, distanza, "kwh_100km")
        
        # Una vettura PHEV/HEV sommerà i costi di entrambi i vettori energetici
        costo_litri = litri * energy_vectors.FUEL_DATA["benzina"]["prezzo_medio_euro"] 
        if "diesel" in tipo_motore: costo_litri = litri * energy_vectors.FUEL_DATA["diesel"]["prezzo_medio_euro"]
        elif "gpl" in tipo_motore: costo_litri = litri * energy_vectors.FUEL_DATA["gpl"]["prezzo_medio_euro"]
        
        costo_kwh = kwh * energy_vectors.FUEL_DATA["elettrico"]["prezzo_medio_euro"]
        
        costo_totale = costo_litri + costo_kwh
        co2_totale = (litri * energy_vectors.FUEL_DATA["benzina"]["co2_kg_l"]) + (kwh * energy_vectors.FUEL_DATA["elettrico"]["co2_kg_kwh"])
        
        # Consumo medio visualizzato come L/100 o kWh/100 a seconda del motore
        clean_cons = [d for d in nome_lista_cons if isinstance(d, dict)]
        consumo_medio = avg([d["litri_100km"] for d in clean_cons]) if litri > 0 else avg([d["kwh_100km"] for d in clean_cons])
        
        return round(avg(nome_lista_vel), 1), round(consumo_medio, 1), round(litri, 1), round(kwh, 1), round(costo_totale, 2), round(co2_totale, 1)

    v_n, cm_n, l_n, k_n, cost_n, co2_n = genera_pacchetto_stat(vel_norm, cons_norm, distanza_totale_km)
    v_v, cm_v, l_v, k_v, cost_v, co2_v = genera_pacchetto_stat(vel_vel, cons_vel, distanza_totale_km)
    v_s, cm_s, l_s, k_s, cost_s, co2_s = genera_pacchetto_stat(vel_smart, cons_smart, distanza_totale_km)
    v_e, cm_e, l_e, k_e, cost_e, co2_e = genera_pacchetto_stat(vel_eco, cons_eco, distanza_totale_km)
    v_sup, cm_sup, l_sup, k_sup, cost_sup, co2_sup = genera_pacchetto_stat(vel_super, cons_super, distanza_totale_km)

    stats = {
        "distanza_km": round(distanza_totale_km, 1),
        "vel_media_normale": v_n, "consumo_medio_normale": cm_n, "litri_totali_normale": l_n, "kwh_totali_normale": k_n, "costo_normale": cost_n, "co2_normale": co2_n,
        "vel_media_veloce": v_v, "consumo_medio_veloce": cm_v, "litri_totali_veloce": l_v, "kwh_totali_veloce": k_v, "costo_veloce": cost_v, "co2_veloce": co2_v,
        "vel_media_smart": v_s, "consumo_medio_smart": cm_s, "litri_totali_smart": l_s, "kwh_totali_smart": k_s, "costo_smart": cost_s, "co2_smart": co2_s,
        "vel_media_target": v_e, "consumo_medio_target": cm_e, "litri_totali_target": l_e, "kwh_totali_target": k_e, "costo_target": cost_e, "co2_target": co2_e,
        "vel_media_super": v_sup, "consumo_medio_super": cm_sup, "litri_totali_super": l_sup, "kwh_totali_super": k_sup, "costo_super": cost_sup, "co2_super": co2_sup,
    }

# ... qui c'è il dizionario stats ...

    warnings = []
    # 👇 FIX: Aggiunto "req." qui!
    if req.is_real_mode:
        warnings.append("Traffico Reale Attivo: stima ritardi applicata.")

    # --- IL RITORNO CORRETTO CHE FLUTTER SI ASPETTA ---
    return {
        "roadbook": roadbook,
        "statistiche": stats,
        "warnings": warnings,
        "coords": [] 
    }

    return roadbook, stats, warnings