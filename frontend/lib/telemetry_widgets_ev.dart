// lib/telemetry_widgets_ev.dart
import 'package:flutter/material.dart';

class TelemetryEV extends StatelessWidget {
  final Map<String, dynamic> stats;
  final String partenza;
  final String arrivo;
  final String tappa;
  final bool isAndataRitorno;
  final TimeOfDay departureTime;

  const TelemetryEV({
    Key? key,
    required this.stats,
    required this.partenza,
    required this.arrivo,
    required this.tappa,
    required this.isAndataRitorno,
    required this.departureTime,
  }) : super(key: key);

  // Formatta la durata (es: 1h 20m)
  String formatTime(double distanceKm, double speedKmh) {
    if (speedKmh <= 0) return "--:--";
    int totalMinutes = ((distanceKm / speedKmh) * 60).round();
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    return "${hours}h ${minutes}m";
  }

  // Calcola l'ora di arrivo basata sulla partenza impostata
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
    double vVel = (stats['vel_media_veloce'] ?? 0.0).toDouble();
    
    // Baseline per i Delta (Modalità Veloce)
    int baseTime = vVel > 0 ? ((dist / vVel) * 60).round() : 0;
    double baseCosto = (stats['costo_veloce'] ?? 0).toDouble();

    // --- HEADER STILIZZATO (Itinerario Professionale) ---
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

    return Column(
      children: [
        header,
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                _buildEVCard("Super", 'super', Colors.deepOrange, dist, baseTime, baseCosto),
                _buildEVCard("Veloce", 'veloce', Colors.redAccent, dist, baseTime, baseCosto),
                _buildEVCard("Smart", 'smart', Colors.purpleAccent, dist, baseTime, baseCosto),
                _buildEVCard("Normale", 'normale', Colors.blueAccent, dist, baseTime, baseCosto),
                _buildEVCard("Eco", 'target', Colors.greenAccent, dist, baseTime, baseCosto),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEVCard(String title, String key, Color color, double dist, int baseTime, double baseCosto) {
    double speed = (stats['vel_media_$key'] ?? 0.0).toDouble();
    if (speed <= 0) return const SizedBox.shrink();

    int timeMin = ((dist / speed) * 60).round();
    int dT = timeMin - baseTime;
    double costo = (stats['costo_$key'] ?? 0).toDouble();
    double dCosto = costo - baseCosto;

    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.6), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(Icons.bolt, color: color, size: 24),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 12),
          
          Text("${speed.toStringAsFixed(1)} km/h", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_outlined, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Text(formatTime(dist, speed), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          
          // ETA (ORARIO DI ARRIVO)
          Text("Arrivo ${calculateArrival(dist, speed)}", 
            style: TextStyle(color: color.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.bold)),
          
          if (dT != 0) 
            Text("(${dT > 0 ? '+' : ''}$dT min)", 
              style: TextStyle(color: dT > 0 ? Colors.orangeAccent : Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
          
          const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(color: Colors.white24, height: 1)),
          
          // CONSUMO ELETTRICO
          Text("${(stats['consumo_medio_$key'] ?? 0).toStringAsFixed(1)} kWh/100", 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          
          // COSTO ENERGIA
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.euro, size: 12, color: Colors.yellowAccent),
              Text("${costo.toStringAsFixed(2)}€", 
                style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          if (dCosto.abs() > 0.1) 
            Text("(${dCosto > 0 ? '+' : ''}${dCosto.toStringAsFixed(1)} €)", 
              style: TextStyle(color: dCosto > 0 ? Colors.redAccent : Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}