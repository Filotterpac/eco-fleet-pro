# physics.py
import math
import powertrain

def calcola_consumo(v_kmh, pendenza, massa_totale, car_data, crr=0.012, is_real_mode=False, tipo_strada="extraurbano", v_prec_kmh=None, lunghezza_segmento_km=0.3, km_percorsi=0.0):
    if v_kmh <= 0: return {"litri_100km": 0.0, "kwh_100km": 0.0}
    v_ms = v_kmh / 3.6
    
    # 1. Resistenze Base (Aero, Rotolamento, Salita)
    f_aero = 0.5 * 1.225 * car_data.get("cx", 0.3) * car_data.get("area_frontale", 2.2) * (v_ms**2)
    f_rot = massa_totale * 9.81 * crr
    f_pend = massa_totale * 9.81 * (pendenza / 100)
    
    forza_tot = f_aero + f_rot + f_pend 
    potenza_alla_ruota_w = forza_tot * v_ms
    
    # 2. Attriti Meccanici Driveline
    eff_driveline = car_data.get("specifiche_avanzate", {}).get("resistenza_meccanica", {}).get("efficienza_totale_driveline", 0.90)
    
    if forza_tot > 0:
        potenza_motore_w = potenza_alla_ruota_w / eff_driveline
    else:
        potenza_motore_w = potenza_alla_ruota_w * eff_driveline # In rigenerazione, la scatola del cambio ruba energia 
        
    # 3. Servizi Ausiliari Termici (Gli EV li calcolano nel loro file dedicato)
    ausiliari_w = 400 if is_real_mode else 0 
    potenza_totale_kw = (potenza_motore_w + ausiliari_w) / 1000
    
    # Efficienza Dinamica per ICE/Hybrid
    eff_max = car_data.get("efficienza_motore", 0.35)
    eff_reale = eff_max
    malus_termico = 1.0

    if is_real_mode:
        pot_max_kw = car_data.get("specifiche_avanzate", {}).get("motore", {}).get("potenza_max_cv", 100) / 1.36
        if pot_max_kw > 0:
            load_factor = min(1.0, max(0, potenza_totale_kw / pot_max_kw))
            eff_min = 0.25 
            if load_factor < 0.15: eff_reale = eff_min
            elif load_factor > 0.70: eff_reale = eff_max
            else: eff_reale = eff_min + (eff_max - eff_min) * ((load_factor - 0.15) / 0.55)
        
        if km_percorsi < 8.0:
            malus_termico = 1.0 + 0.30 * (1.0 - (km_percorsi / 8.0))

    # 4. Energia Cinetica Universale (Accelerazioni e Stop&Go)
    is_accel = False
    ek_kwh = 0.0
    
    if v_prec_kmh is not None and v_kmh > v_prec_kmh:
        is_accel = True
        v_ms_iniziale = v_prec_kmh / 3.6
        ek_kwh += (0.5 * massa_totale * (v_ms**2 - v_ms_iniziale**2)) / 3600000

    if is_real_mode:
        fermate_su_100km = 80 if tipo_strada == "urbano" else (20 if tipo_strada == "extraurbano" else 2)
        v_calo_ms = max(0, v_kmh - 20) / 3.6
        ek_joule_stat = 0.5 * massa_totale * (v_ms**2 - v_calo_ms**2)
        fermate_segmento = fermate_su_100km * (lunghezza_segmento_km / 100.0)
        
        if fermate_segmento > 0:
            is_accel = True
            ek_kwh += (ek_joule_stat / 3600000) * fermate_segmento

    # 5. DELEGA COMPLETA
    return powertrain.calcola_consumo_motore(
        potenza_totale_kw, v_kmh, car_data, is_accel, ek_kwh, lunghezza_segmento_km, malus_termico, eff_reale, pendenza, km_percorsi
    )

def scegli_marcia(v_kmh):
    if v_kmh < 25: return "2ª"
    elif v_kmh < 45: return "3ª"
    elif v_kmh < 65: return "4ª"
    elif v_kmh < 85: return "5ª"
    else: return "6ª"

def applica_veleggio_predittivo(roadbook, car_data, massa_totale, crr=0.012):
    rho, g = 1.225, 9.81
    cx = car_data.get("cx", 0.29)
    area = car_data.get("area_frontale", 2.12)
    distanza_veleggio_metri = 300.0 
    
    for i in range(len(roadbook) - 1):
        segmento_attuale = roadbook[i]
        discesa_imminente = False
        distanza_analizzata = 0.0
        
        for j in range(i + 1, len(roadbook)):
            distanza_analizzata += 300.0 
            if roadbook[j]['pendenza'] <= -2.0:
                discesa_imminente = True
                break
            if distanza_analizzata > distanza_veleggio_metri: break 
                
        if discesa_imminente and segmento_attuale['pendenza'] >= 0:
            v_iniziale_ms = segmento_attuale['v_ideale'] / 3.6
            f_resistente_tot = (0.5 * rho * cx * area * (v_iniziale_ms**2)) + (massa_totale * g * crr) + (massa_totale * g * (segmento_attuale['pendenza'] / 100))
            decelerazione = -f_resistente_tot / massa_totale
            
            v_quadrato_finale = (v_iniziale_ms**2) + (2 * decelerazione * 300.0)
            
            if v_quadrato_finale > 0:
                v_finale_kmh = math.sqrt(v_quadrato_finale) * 3.6
                if v_finale_kmh >= 50.0:
                    # In veleggio, il consumo crolla fisicamente a 0, sia kWh che Litri!
                    segmento_attuale['consumo_ist'] = 0.0 
                    segmento_attuale['v_ideale'] = (segmento_attuale['v_ideale'] + v_finale_kmh) / 2 
                    segmento_attuale['marcia'] = "Veleggio"
    return roadbook