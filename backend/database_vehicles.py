import json
import os
from models import Vehicle

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

def get_db_path(categoria, sub_tipo=None):
    # Logica dinamica per la categoria Micro
    if categoria == 1:
        return os.path.join(BASE_DIR, "bicycles.json" if sub_tipo == "Bicicletta" else "scooters.json")
    
    mappa = {
        0: "pedestrians.json",
        2: "cars.json",     
        3: "moto.json"
    }
    return os.path.join(BASE_DIR, mappa.get(categoria, "cars.json"))

def load_vehicles(categoria=2, sub_tipo=None):
    file_path = get_db_path(categoria, sub_tipo)
    if not os.path.exists(file_path): 
        return {}
    with open(file_path, "r", encoding="utf-8") as f:
        return json.load(f)

def add_vehicle_to_db(veh: Vehicle, categoria=2, sub_tipo=None):
    data = load_vehicles(categoria, sub_tipo)
    veh_dict = veh.dict(exclude_none=True)
    nome_veicolo = veh_dict.pop("nome")
    data[nome_veicolo] = veh_dict
    data[nome_veicolo]["specifiche_avanzate"] = {"tipo": "Custom Utente"}
    
    with open(get_db_path(categoria, sub_tipo), "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4)