# energy_vectors.py

FUEL_DATA = {
    "benzina": {
        "potere_calorifico_kwh_kg": 12.2,
        "densita_g_l": 745,
        "co2_kg_l": 2.31,
        "prezzo_medio_euro": 1.85
    },
    "diesel": {
        "potere_calorifico_kwh_kg": 11.8,  # Più denso energeticamente al litro
        "densita_g_l": 835,
        "co2_kg_l": 2.65,
        "prezzo_medio_euro": 1.75
    },
    "gpl": {
        "potere_calorifico_kwh_kg": 12.8,  # Alto potere calorifico al kg...
        "densita_g_l": 510,                # ...ma bassissima densità al litro
        "co2_kg_l": 1.65,
        "prezzo_medio_euro": 0.70
    },
    "elettrico": {
        "co2_kg_kwh": 0.25,  # Mix energetico medio (0 per rinnovabili 100%)
        "prezzo_medio_euro": 0.35  # Costo medio ricarica
    }
}

def get_fuel_specs(tipo_motore: str):
    tipo = tipo_motore.lower()
    if "diesel" in tipo: return FUEL_DATA["diesel"], "litri"
    if "gpl" in tipo: return FUEL_DATA["gpl"], "litri"
    if "elettrico" in tipo or "bev" in tipo or "tesla" in tipo: return FUEL_DATA["elettrico"], "kwh"
    return FUEL_DATA["benzina"], "litri" # Fallback