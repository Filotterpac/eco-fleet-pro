// lib/telemetry_widgets_bike.dart
import 'package:flutter/material.dart';

class TelemetryBike extends StatelessWidget {
  final Map<String, dynamic> stats;
  final String partenza;
  final String arrivo;
  final String tappa;
  final bool isAndataRitorno;

  const TelemetryBike({Key? key, required this.stats, required this.partenza, required this.arrivo, required this.tappa, required this.isAndataRitorno}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double vNorm = (stats['vel_media_normale'] ?? 0.0).toDouble();
    double energia = (stats['litri_totali_normale'] ?? 0.0).toDouble();
    String unita = stats['unita_misura'] ?? 'Kcal';

    return Container(
      padding: const EdgeInsets.all(15), margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blueAccent)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        Column(children: [
          const Icon(Icons.pedal_bike, color: Colors.blueAccent, size: 30), 
          Text("${vNorm.toStringAsFixed(1)} km/h", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)), 
          const Text("Velocità Media", style: TextStyle(fontSize: 11, color: Colors.grey))
        ]),
        Column(children: [
          Icon(unita == 'Wh' ? Icons.battery_charging_full : Icons.local_fire_department, color: unita == 'Wh' ? Colors.tealAccent : Colors.orangeAccent, size: 30), 
          Text("${energia.toStringAsFixed(0)} $unita", style: TextStyle(color: unita == 'Wh' ? Colors.tealAccent : Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 16)), 
          const Text("Consumo", style: TextStyle(fontSize: 11, color: Colors.grey))
        ]),
      ]),
    );
  }
}