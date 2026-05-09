import sqlite3
import json
import hashlib
import os

DB_NAME = "open_data_cache.db"

def init_db():
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS osrm_cache (query_hash TEXT PRIMARY KEY, data TEXT)''')
    c.execute('''CREATE TABLE IF NOT EXISTS topo_cache (query_hash TEXT PRIMARY KEY, data TEXT)''')
    c.execute('''CREATE TABLE IF NOT EXISTS geocode_cache (query_hash TEXT PRIMARY KEY, lat REAL, lon REAL)''')
    # --- NEW TABLE FOR INDIVIDUAL POINTS ---
    c.execute('''CREATE TABLE IF NOT EXISTS topo_points_cache (coord_hash TEXT PRIMARY KEY, elevation REAL)''')
    conn.commit()
    conn.close()

init_db()

def _get_hash(stringa):
    return hashlib.md5(stringa.encode('utf-8')).hexdigest()

# ... (Keep existing OSRM and Geocode functions) ...
def salva_osrm(coords_str, dati_json):
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute("INSERT OR REPLACE INTO osrm_cache VALUES (?, ?)", (_get_hash(coords_str), json.dumps(dati_json)))
    conn.commit()
    conn.close()

def leggi_osrm(coords_str):
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute("SELECT data FROM osrm_cache WHERE query_hash=?", (_get_hash(coords_str),))
    row = c.fetchone()
    conn.close()
    return json.loads(row[0]) if row else None

def salva_geocode(query, lat, lon):
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute("INSERT OR REPLACE INTO geocode_cache VALUES (?, ?, ?)", (_get_hash(query.lower().strip()), lat, lon))
    conn.commit()
    conn.close()

def leggi_geocode(query):
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute("SELECT lat, lon FROM geocode_cache WHERE query_hash=?", (_get_hash(query.lower().strip()),))
    row = c.fetchone()
    conn.close()
    return row 

# --- NEW INDIVIDUAL POINT ELEVATION FUNCTIONS ---
def salva_topo_point(lat, lon, elevation):
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    # Round coordinates to 4 decimal places (approx 11 meters) to increase cache hits
    coord_str = f"{round(lat, 4)},{round(lon, 4)}"
    c.execute("INSERT OR REPLACE INTO topo_points_cache VALUES (?, ?)", (_get_hash(coord_str), elevation))
    conn.commit()
    conn.close()

def leggi_topo_point(lat, lon):
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    coord_str = f"{round(lat, 4)},{round(lon, 4)}"
    c.execute("SELECT elevation FROM topo_points_cache WHERE coord_hash=?", (_get_hash(coord_str),))
    row = c.fetchone()
    conn.close()
    return row[0] if row else None