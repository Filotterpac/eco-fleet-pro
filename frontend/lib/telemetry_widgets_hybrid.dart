// lib/telemetry_widgets_hybrid.dart
import 'package:flutter/material.dart';

class TelemetryHybrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  final String partenza, arrivo, tappa;
  final bool isAndataRitorno;
  final TimeOfDay departureTime;

  const TelemetryHybrid({
    Key? key, 
    required this.stats, 
    required this.partenza, 
    required this.arrivo, 
    required this.tappa, 
    required this.isAndataRitorno, 
    required this.departureTime
  }) : super(key: key);

  String formatTime(double distanceKm, double speedKmh) {
    if (speedKmh <= 0) return "--:--";
    int m = ((distanceKm / speedKmh) * 60).round();
    return "${m ~/ 60}h ${m % 60}m";
  }

  String calculateArrival(double distanceKm, double speedKmh) {
    if (speedKmh <= 0) return "--:--";
    int m = ((distanceKm / speedKmh) * 60).round();
    final now = DateTime.now();
    DateTime dep = DateTime(now.year, now.month, now.day, departureTime.hour, departureTime.minute);
    DateTime arr = dep.add(Duration(minutes: m));
    return "${arr.hour.toString().padLeft(2, '0')}:${arr.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    double dist = (stats['distanza_km'] ?? 0.0).toDouble();
    double vVel = (stats['vel_media_veloce'] ?? 0.0).toDouble();
    
    // Baseline per i confronti (Modalità Veloce)
    int baseTime = vVel > 0 ? ((dist / vVel) * 60).round() : 0;
    double baseCosto = (stats['costo_veloce'] ?? 0).toDouble();
    double baseCo2 = (stats['co2_veloce'] ?? 0).toDouble();

    // HEADER STILIZZATO (Itinerario)
    Widget header = Container(
      margin: const EdgeInsets.only(bottom: 16, top: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white12)),
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

    return Column(
      children: [
        header,
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: ['super', 'veloce', 'smart', 'normale', 'target'].map((mode) {
                String title = mode == 'target' ? 'Eco' : mode[0].toUpperCase() + mode.substring(1);
                double speed = (stats['vel_media_$mode'] ?? 0.0).toDouble();
                if (speed <= 0) return const SizedBox.shrink();
                
                return _buildHybridCard(title, mode, speed, dist, baseTime, baseCosto, baseCo2);
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHybridCard(String title, String key, double speed, double dist, int baseTime, double baseCosto, double baseCo2) {
    int timeMin = ((dist / speed) * 60).round();
    int dT = timeMin - baseTime;
    double litri = (stats['litri_totali_$key'] ?? 0.0).toDouble();
    double kwh = (stats['kwh_totali_$key'] ?? 0.0).toDouble();
    double costo = (stats['costo_$key'] ?? 0.0).toDouble();
    double co2 = (stats['co2_$key'] ?? 0.0).toDouble();

    double avgLitri = dist > 0 ? (litri / dist) * 100 : 0;
    double avgKwh = dist > 0 ? (kwh / dist) * 100 : 0;
    
    Color color = title == 'Super' ? Colors.deepOrange : title == 'Veloce' ? Colors.redAccent : title == 'Smart' ? Colors.purpleAccent : title == 'Normale' ? Colors.blueAccent : Colors.greenAccent;

    return Container(
      width: 155, // Leggermente più larga per i doppi vettori
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.6), width: 1.5)),
      child: Column(children: [
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 12),
        Text("${speed.toStringAsFixed(1)} km/h", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.timer_outlined, size: 14, color: Colors.white70),
          const SizedBox(width: 4),
          Text(formatTime(dist, speed), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ]),
        Text("Arrivo ${calculateArrival(dist, speed)}", style: TextStyle(color: color.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.bold)),
        if (dT != 0) Text("(${dT > 0 ? '+' : ''}$dT min)", style: TextStyle(color: dT > 0 ? Colors.orangeAccent : Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
        
        const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(color: Colors.white24, height: 1)),
        
        // DOPPIO VETTORE (Benzina + Elettrico)
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text("💧 ", style: TextStyle(fontSize: 12)),
          Text("${avgLitri.toStringAsFixed(1)} L/100", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text("⚡ ", style: TextStyle(fontSize: 12)),
          Text("${avgKwh.toStringAsFixed(1)} kWh/100", style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 13)),
        ]),

        const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(color: Colors.white24, height: 1)),
        
        // COSTO E CO2 CON DELTA COLORATI
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.euro, size: 12, color: Colors.yellowAccent),
          Text("${costo.toStringAsFixed(2)}€", style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
        if ((costo - baseCosto).abs() > 0.1) 
          Text("(${(costo - baseCosto) > 0 ? '+' : ''}${(costo - baseCosto).toStringAsFixed(1)} €)", 
            style: TextStyle(color: (costo - baseCosto) > 0 ? Colors.redAccent : Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),

        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.eco, size: 12, color: Colors.lightGreen),
          Text("${co2.toStringAsFixed(1)}kg", style: const TextStyle(color: Colors.lightGreen, fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
        if ((co2 - baseCo2).abs() > 0.1) 
          Text("(${(co2 - baseCo2) > 0 ? '+' : ''}${(co2 - baseCo2).toStringAsFixed(1)} kg)", 
            style: TextStyle(color: (co2 - baseCo2) > 0 ? Colors.redAccent : Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}