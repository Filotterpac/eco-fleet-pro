// lib/telemetry_widgets_moto.dart
import 'package:flutter/material.dart';
import 'telemetry_widgets_cars.dart'; 

class TelemetryMoto extends StatelessWidget {
  final Map<String, dynamic> stats;
  final String partenza, arrivo, tappa;
  final bool isAndataRitorno;
  final TimeOfDay departureTime; // AGGIUNTO

  const TelemetryMoto({
    Key? key, 
    required this.stats, 
    required this.partenza, 
    required this.arrivo, 
    required this.tappa, 
    required this.isAndataRitorno,
    required this.departureTime // AGGIUNTO
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sfrutta l'architettura completa di TelemetryCars (Header stilizzato, ETA, Delta colorati)
    // rendendo il codice pulito e privo di duplicazioni.
    return TelemetryCars(
      stats: stats, 
      partenza: partenza, 
      arrivo: arrivo, 
      tappa: tappa, 
      isAndataRitorno: isAndataRitorno,
      departureTime: departureTime,
    );
  }
}