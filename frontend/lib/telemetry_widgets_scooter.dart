// lib/telemetry_widgets_scooter.dart
import 'package:flutter/material.dart';

class TelemetryScooter extends StatelessWidget {
  final Map<String, dynamic> stats;
  final String partenza;
  final String arrivo;
  final String tappa;
  final bool isAndataRitorno;
  final TimeOfDay departureTime; // Ricevuto dal centralino per il calcolo ETA

  const TelemetryScooter({
    Key? key,
    required this.stats,
    required this.partenza,
    required this.arrivo,
    required this.tappa,
    required this.isAndataRitorno,
    required this.departureTime,
  }) : super(key: key);

  // Formatta la durata in formato leggibile (es: 0h 25m)
  String formatTime(double distanceKm, double speedKmh) {
    if (speedKmh <= 0) return "--:--";
    int totalMinutes = ((distanceKm / speedKmh) * 60).round();
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    return "${hours}h ${minutes}m";
  }

  // Calcola l'ora esatta di arrivo basata sulla velocità media del monopattino
  String calculateArrival(double distanceKm, double speedKmh) {
    if (speedKmh <= 0) return "--:--";
    int travelMinutes = ((distanceKm / speedKmh) * 60).round();
    final now = DateTime.now();
    DateTime dep = DateTime(now.year, now.month, now.day, departureTime.hour, departureTime.minute);
    DateTime arr = dep.add(Duration(minutes: travelMinutes));
    return "${arr.hour.toString().padLeft(2, '0')}:${arr.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    double dist = (stats['distanza_km'] ?? 0.0).toDouble();
    double vNorm = (stats['vel_media_normale'] ?? 0.0).toDouble();
    double whTotali = (stats['litri_totali_normale'] ?? 0.0).toDouble(); 

    // --- 1. HEADER ITINERARIO STILIZZATO ---
    Widget header = Container(
      margin: const EdgeInsets.only(bottom: 16, top: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black, 
        borderRadius: BorderRadius.circular(25), 
        border: Border.all(color: Colors.white12)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.straighten, color: Colors.tealAccent, size: 16),
          Text(" $dist km ", style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 13)),
          const VerticalDivider(color: Colors.white24, width: 20, thickness: 1),
          const Icon(Icons.location_on, color: Colors.greenAccent, size: 16),
          Text(" ${partenza.toUpperCase()} ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 12),
          Text(" ${arrivo.toUpperCase()} ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
          const Icon(Icons.flag, color: Colors.redAccent, size: 16),
        ],
      ),
    );

    // --- 2. DASHBOARD DIGITALE ---
    return Column(
      children: [
        header,
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.tealAccent.withOpacity(0.4), width: 2),
            boxShadow: [
              BoxShadow(color: Colors.tealAccent.withOpacity(0.05), blurRadius: 15, spreadRadius: 2)
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Colonna Velocità
              _buildStat(
                icon: Icons.electric_scooter,
                value: "${vNorm.toStringAsFixed(1)} km/h",
                label: "Velocità Media",
                color: Colors.white,
              ),
              
              // Colonna Tempo e ETA
              Column(
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.white70, size: 30),
                  const SizedBox(height: 10),
                  Text(formatTime(dist, vNorm), 
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  // Arrivo Stimato
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.tealAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text("Arrivo ${calculateArrival(dist, vNorm)}", 
                      style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),

              // Colonna Consumo Batteria (Wh)
              _buildStat(
                icon: Icons.battery_charging_full,
                value: "${whTotali.toStringAsFixed(0)} Wh",
                label: "Energia Usata",
                color: Colors.tealAccent,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget helper per le icone e i testi
  Widget _buildStat({required IconData icon, required String value, required String label, required Color color}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 10),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 0.5)),
      ],
    );
  }
}