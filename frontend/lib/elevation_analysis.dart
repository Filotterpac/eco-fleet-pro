import 'package:flutter/material.dart';
import 'elevation_chart.dart'; 

class ElevationAnalysisScreen extends StatelessWidget {
  final List<dynamic> roadbook;
  final String partenza;
  final String arrivo;

  const ElevationAnalysisScreen({
    Key? key,
    required this.roadbook,
    required this.partenza,
    required this.arrivo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (roadbook.isEmpty) return Scaffold(appBar: AppBar(title: const Text("Errore")));

    // Recupero dell'altitudine 
    double altPartenza = roadbook.first['altitudine'].toDouble();
    double altArrivo = roadbook.last['altitudine'].toDouble();

    // 1. Calcoli Globali
    double maxAlt = roadbook[0]['altitudine'].toDouble();
    double minAlt = roadbook[0]['altitudine'].toDouble();
    double dislivelloPositivo = 0;

    for (int i = 0; i < roadbook.length; i++) {
      double alt = roadbook[i]['altitudine'].toDouble();
      if (alt > maxAlt) maxAlt = alt;
      if (alt < minAlt) minAlt = alt;
      
      if (i > 0) {
        double diff = alt - roadbook[i - 1]['altitudine'].toDouble();
        if (diff > 0) dislivelloPositivo += diff;
      }
    }

    // 2. Troviamo le "Grandi Salite"
    List<Map<String, dynamic>> salite = [];
    bool inSalita = false;
    double inizioKm = 0;
    double inizioAlt = 0;
    List<double> consumiSalita = [];

    for (var rb in roadbook) {
      if (rb['pendenza'] >= 1.0) {
        if (!inSalita) {
          inSalita = true;
          inizioKm = rb['km'].toDouble(); 
          inizioAlt = rb['altitudine'].toDouble(); 
          consumiSalita = [];
        }
        consumiSalita.add(rb['consumo_ist'].toDouble()); 
      } else {
        if (inSalita) {
          inSalita = false;
          double fineKm = rb['km'].toDouble(); 
          double fineAlt = rb['altitudine'].toDouble(); 
          
          double distanza = fineKm - inizioKm;
          
          if (distanza >= 0.6) {
            double avgConsumo = consumiSalita.reduce((a, b) => a + b) / consumiSalita.length;
            salite.add({
              "km_inizio": inizioKm,
              "km_fine": fineKm,
              "dislivello": fineAlt - inizioAlt,
              "distanza": distanza,
              "consumo_medio": avgConsumo
            });
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: const Text("Analisi Altimetrica"),
        backgroundColor: Colors.teal[900],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("ITINERARIO", style: TextStyle(color: Colors.grey, fontSize: 12)),
          Text(
            "$partenza (${altPartenza.toStringAsFixed(0)}m) ➔ $arrivo (${altArrivo.toStringAsFixed(0)}m)", 
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
          ),
          const SizedBox(height: 20),
          
          const Text("PROFILO ALTIMETRICO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
          const SizedBox(height: 10),
          ElevationChart(roadbook: roadbook),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(child: _buildInfoCard("Altitudine Max", "${maxAlt.toStringAsFixed(0)} m", Icons.landscape, Colors.orange)),
              const SizedBox(width: 10),
              Expanded(child: _buildInfoCard("Dislivello Totale", "+${dislivelloPositivo.toStringAsFixed(0)} m", Icons.trending_up, Colors.green)),
            ],
          ),
          const SizedBox(height: 20),

          const Text("SALITE RILEVATE SUL PERCORSO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.tealAccent)),
          const Divider(color: Colors.teal),
          
          if (salite.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("Nessuna salita impegnativa rilevata.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
            ),

          ...salite.map((s) => Card(
            color: Colors.grey[900],
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Da Km ${s['km_inizio'].toStringAsFixed(1)} a Km ${s['km_fine'].toStringAsFixed(1)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      Text("Lunga ${s['distanza'].toStringAsFixed(1)} km", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text("Dislivello", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text("+${s['dislivello'].toStringAsFixed(0)} m", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                        ],
                      ),
                      Column(
                        children: [
                          const Text("Consumo Medio", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text("${s['consumo_medio'].toStringAsFixed(1)} L/100", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
          )).toList()
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}