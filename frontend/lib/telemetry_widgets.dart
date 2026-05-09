// lib/telemetry_widgets.dart
import 'package:flutter/material.dart';
import 'telemetry_widgets_cars.dart';
import 'telemetry_widgets_ev.dart';
import 'telemetry_widgets_human.dart';
import 'telemetry_widgets_hybrid.dart';
import 'telemetry_widgets_moto.dart';
import 'telemetry_widgets_scooter.dart';
import 'telemetry_widgets_bike.dart';

class DynamicDashboardPanel extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool isAndataRitorno;
  final String partenza;
  final String arrivo;
  final String tappa;
  final TimeOfDay departureTime; // <-- Riceve l'orario dal Tab

  const DynamicDashboardPanel({
    Key? key,
    required this.stats,
    required this.isAndataRitorno,
    required this.partenza,
    required this.arrivo,
    required this.tappa,
    required this.departureTime, // <-- Obbligatorio
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String unita = stats['unita_misura'] ?? 'L';
    double litri = (stats['litri_totali_normale'] ?? 0).toDouble();
    double kwh = (stats['kwh_totali_normale'] ?? 0).toDouble();

    // SMISTAMENTO CON PASSAGGIO ORARIO
    if (unita == 'Kcal') {
      return TelemetryHuman(stats: stats, partenza: partenza, arrivo: arrivo, tappa: tappa, isAndataRitorno: isAndataRitorno, departureTime: departureTime);
    } 
    if (unita == 'Wh') {
      // In base alla complessità puoi distinguere tra Scooter e Bike
      return TelemetryScooter(stats: stats, partenza: partenza, arrivo: arrivo, tappa: tappa, isAndataRitorno: isAndataRitorno, departureTime: departureTime);
    }
    if (kwh > 0 && litri > 0) {
      return TelemetryHybrid(stats: stats, partenza: partenza, arrivo: arrivo, tappa: tappa, isAndataRitorno: isAndataRitorno, departureTime: departureTime);
    }
    if (kwh > 0 && litri == 0) {
      return TelemetryEV(stats: stats, partenza: partenza, arrivo: arrivo, tappa: tappa, isAndataRitorno: isAndataRitorno, departureTime: departureTime);
    }

    return TelemetryCars(stats: stats, partenza: partenza, arrivo: arrivo, tappa: tappa, isAndataRitorno: isAndataRitorno, departureTime: departureTime);
  }
}

// La RoadbookList rimane in fondo a questo file come l'hai configurata




class RoadbookList extends StatelessWidget {
  final List<dynamic> roadbook;
  const RoadbookList({required this.roadbook});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: roadbook.length,
      itemBuilder: (context, index) {
        final rb = roadbook[index];
        return Card(
          color: const Color(0xFF1E1E1E),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(rb['pendenza'] > 0 ? Icons.trending_up : Icons.trending_down, color: rb['pendenza'] > 2 ? Colors.red : rb['pendenza'] < -2 ? Colors.green : Colors.grey, size: 20),
                Text("${rb['limite_strada']}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, background: Paint()..color = Colors.red..style = PaintingStyle.stroke..strokeWidth = 14)),
              ],
            ),
            title: Text('Km ${rb["km"]} | Consigliata: ${rb["v_ideale"]} km/h in ${rb["marcia"]}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: Text('Pend: ${rb["pendenza"]}% | Alt: ${rb["altitudine"]}m | Cons: ${rb["consumo_ist"]}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ),
        );
      },
    );
  }
}