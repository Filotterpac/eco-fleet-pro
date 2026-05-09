import sqlite3
import json
import pandas as pd
import plotly.express as px

DB_NAME = "open_data_cache.db"

def visualizza_mappa_globale():
    print("🔍 Scansione del database in corso...")
    
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    
    # Estraiamo i dati dalla cache altimetrica (che contiene il JSON completo di Lat, Lon e Alt)
    # Cerchiamo nella tabella 'topo_cache' che abbiamo usato fino ad ora
    try:
        c.execute("SELECT data FROM topo_cache")
        rows = c.fetchall()
    except sqlite3.OperationalError:
        print("Errore: Tabella non trovata. Assicurati che il nome del DB sia corretto.")
        return
    finally:
        conn.close()

    if not rows:
        print("⚠️ Nessun dato trovato nel database! Calcola qualche percorso nell'app prima.")
        return

    lats = []
    lons = []
    alts = []

    # Spacchettiamo i JSON
    for row in rows:
        try:
            dati = json.loads(row[0])
            if 'results' in dati:
                for punto in dati['results']:
                    if 'location' in punto and 'elevation' in punto:
                        lats.append(punto['location']['lat'])
                        lons.append(punto['location']['lng'])
                        alts.append(punto['elevation'])
        except Exception as e:
            pass # Ignoriamo eventuali righe corrotte

    print(f"✅ Trovati {len(lats)} punti geografici salvati nel tuo Database!")

    if len(lats) == 0:
        print("I dati non contengono coordinate valide.")
        return

    # Creiamo un DataFrame (Tabella dati per Plotly)
    df = pd.DataFrame({
        'Latitudine': lats,
        'Longitudine': lons,
        'Altitudine (m)': alts
    })

    # Generiamo la mappa
    print("🌍 Generazione della mappa interattiva nel browser...")
    fig = px.scatter_mapbox(
        df, 
        lat="Latitudine", 
        lon="Longitudine", 
        color="Altitudine (m)",
        color_continuous_scale="Turbo", # Colori dal blu (basso) al rosso (alto)
        zoom=5, 
        height=800,
        title="Eco Fleet Pro - Mappa Globale dei Dati Raccolti",
        opacity=0.6 # Leggera trasparenza per vedere la densità dei punti
    )

    # Applichiamo un design elegante scuro (non richiede chiavi API Mapbox!)
    fig.update_layout(
        mapbox_style="carto-darkmatter", 
        margin={"r":0,"t":50,"l":0,"b":0},
        paper_bgcolor="black",
        font=dict(color="cyan")
    )

    fig.show()

if __name__ == "__main__":
    visualizza_mappa_globale()