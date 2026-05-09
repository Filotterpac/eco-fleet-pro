from pydantic import BaseModel
from typing import Optional

class Vehicle(BaseModel):
    nome: str
    peso_vuoto: float
    # Rendi i parametri opzionali mettendo "= None", così una Bici non è costretta ad avere la benzina!
    cx: Optional[float] = None
    area_frontale: Optional[float] = None
    efficienza_motore: Optional[float] = None
    muscolare: Optional[bool] = None
    potere_calorifico_benzina: Optional[float] = None
    densita_benzina: Optional[float] = None

class RouteRequest(BaseModel):
    partenza: str
    arrivo: str
    passeggeri: int = 1
    target_l: float = 5.0
    car_model: str = "Nessuno"
    is_real_mode: bool = False
    
    tappa: Optional[str] = ""
    andata_ritorno: bool = False
    evita_autostrade: bool = False
    super_veloce_offset: int = 0
    
    # --- NUOVI CAMPI FLUTTER PER LE CATEGORIE ---
    categoria_trasporto: int = 2
    pedestrian_mode: str = "Camminata"
    micro_mode: str = "Bicicletta"
    is_training: bool = False
    target_slope: float = 5.0