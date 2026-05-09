# bio_physics.py
import math

def calcola_sforzo_umano(peso_kg, pendenza, velocita_kmh, modalita="Camminata"):
    """
    Calcola il consumo metabolico (Kcal/min) usando le equazioni ACSM.
    VO2 = 3.5 (riposo) + 0.1*vel (orizzontale) + 1.8*vel*pendenza (verticale)
    """
    v_m_min = (velocita_kmh * 1000) / 60
    G = max(0, pendenza / 100) # Solo pendenze positive per lo sforzo metabolico primario
    
    if modalita == "Camminata":
        vo2 = 3.5 + (0.1 * v_m_min) + (1.8 * v_m_min * G)
    else: # Corsa o Bici Muscolare (adattata)
        vo2 = 3.5 + (0.2 * v_m_min) + (0.9 * v_m_min * G)
    
    # Kcal/min = (VO2 * peso * 5) / 1000
    kcal_min = (vo2 * peso_kg * 5) / 1000
    return max(0.5, kcal_min)

def tobler_speed(v_base, pendenza):
    """
    Funzione di Tobler: calcola la velocità effettiva in base alla pendenza.
    In salita si rallenta drasticamente, in discesa si accelera solo lievemente.
    """
    G = pendenza / 100
    # Tobler exponential: v = 6 * exp(-3.5 * |G + 0.05|)
    fattore = math.exp(-3.5 * abs(G + 0.05))
    v_effettiva = v_base * (fattore / 0.8) # Normalizzato sulla velocità base
    return max(1.5, min(v_base * 1.3, v_effettiva))

def calcola_potenza_elettrica_micro(v_kmh, pendenza, massa_totale, car_data):
    """
    Calcola i Watt necessari per un monopattino o e-bike.
    """
    v_ms = v_kmh / 3.6
    rho = 1.225
    f_aero = 0.5 * rho * car_data.get("cx", 0.8) * car_data.get("area_frontale", 0.6) * (v_ms**2)
    f_rot = massa_totale * 9.81 * 0.015 # Resistenza rotolamento media
    f_pend = massa_totale * 9.81 * (pendenza / 100)
    
    potenza_ruota_w = (f_aero + f_rot + f_pend) * v_ms
    efficienza = car_data.get("efficienza_motore", 0.8)
    
    # Se potenza è negativa (discesa), il motore non consuma (o recupera poco in questi mezzi)
    return max(0, potenza_ruota_w / efficienza) if potenza_ruota_w > 0 else 0