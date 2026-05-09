from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from models import RouteRequest, Vehicle
from database_vehicles import load_vehicles, add_vehicle_to_db
from engine import generate_telemetry
from fastapi import Request
from fastapi.responses import HTMLResponse
import plotly.graph_objects as go


app = FastAPI(title="EcoDrive API Pro Modular")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

@app.get("/api/vehicles/{categoria}")
def get_vehicles(categoria: int,sub_tipo: str = None):
    """Ritorna la lista dei veicoli a Flutter in base alla categoria (0,1,2,3)"""
    return load_vehicles(categoria, sub_tipo)

@app.post("/api/vehicles/{categoria}")
async def add_vehicle(categoria: int, veh: Vehicle, sub_tipo: str = None):
    """Salva un nuovo veicolo nel file JSON corretto"""
    try:
        add_vehicle_to_db(veh, categoria, sub_tipo)
        return {"message": f"Veicolo {veh.nome} salvato con successo!"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/plan_route")
def plan_route(req: RouteRequest):
    """Calcola il percorso, la fisica e genera il roadbook"""
    
    # 1. Determiniamo la sottocategoria per caricare il JSON giusto
    sub_tipo = req.pedestrian_mode if req.categoria_trasporto == 0 else req.micro_mode
    
    # 2. Carichiamo i veicoli della categoria corretta
    vehicles = load_vehicles(categoria=req.categoria_trasporto, sub_tipo=sub_tipo)
    
    # 3. Controllo di sicurezza sul modello
    model_name = req.car_model
    if model_name == "Nessuno" or model_name not in vehicles:
        if vehicles:
            model_name = list(vehicles.keys())[0] # Prendi il primo profilo disponibile (es. Camminata)
        else:
            raise HTTPException(status_code=404, detail=f"Nessun profilo trovato per categoria {req.categoria_trasporto}")
    
    car_data = vehicles[model_name]
    
    # 4. Generazione telemetria
    risultato_completo = generate_telemetry(req, car_data)
    
    return risultato_completo


@app.post("/api/3d_route", response_class=HTMLResponse)
async def generate_3d_route(request: Request):
    data = await request.json()
    lats = data.get("lats", [])
    lons = data.get("lons", [])
    alts = data.get("alts", [])
    
    # Creiamo il modello 3D del percorso
    fig = go.Figure(data=[go.Scatter3d(
        x=lons, 
        y=lats, 
        z=alts,
        mode='lines+markers',
        marker=dict(size=4, color=alts, colorscale='Turbo', opacity=0.9),
        line=dict(color='white', width=3)
    )])
    
    # Rimuoviamo assi e griglie per un look "olografico" da film sci-fi
    fig.update_layout(
        title=dict(text="Gemello Digitale Altimetrico", font=dict(color="cyan", size=18)),
        scene=dict(
            bgcolor="black",
            xaxis=dict(showbackground=False, showgrid=False, zeroline=False, showticklabels=False, title=""),
            yaxis=dict(showbackground=False, showgrid=False, zeroline=False, showticklabels=False, title=""),
            zaxis=dict(showbackground=False, showgrid=True, zeroline=False, title="Altitudine (m)", gridcolor="#333333")
        ),
        paper_bgcolor="black", 
        font=dict(color="white"),
        margin=dict(l=0, r=0, b=0, t=40)
    )
    
    # Restituiamo il codice HTML puro
    return fig.to_html(include_plotlyjs="cdn", full_html=True)