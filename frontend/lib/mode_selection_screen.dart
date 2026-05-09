// lib/mode_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'predictive_navigation.dart';
import 'mode_card_widget.dart'; 

class ModeSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> tripData;

  const ModeSelectionScreen({Key? key, required this.tripData}) : super(key: key);

  @override
  _ModeSelectionScreenState createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  String selectedMode = 'smart';

  String formatTime(double distanceKm, double speedKmh) {
    if (speedKmh <= 0) return "--:--";
    double hours = distanceKm / speedKmh;
    int h = hours.floor();
    int m = ((hours - h) * 60).round();
    return "${h}h ${m}m";
  }

  String calculateETA(double distanceKm, double speedKmh) {
    if (speedKmh <= 0) return "--:--";
    double hours = distanceKm / speedKmh;
    DateTime arrivalTime = DateTime.now().add(Duration(minutes: (hours * 60).round()));
    return DateFormat('HH:mm').format(arrivalTime);
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.tripData['statistiche'];
    final roadbook = widget.tripData['roadbook'] as List;
    
    double dist = stats['distanza_km'].toDouble();
    double vNorm = stats['vel_media_normale'].toDouble();
    double vVel = stats['vel_media_veloce'].toDouble();
    double vEco = stats['vel_media_target'].toDouble();
    double vSmart = stats['vel_media_smart']?.toDouble() ?? 0.0;
    double vSuper = stats['vel_media_super']?.toDouble() ?? 0.0;

    String etaNorm = calculateETA(dist, vNorm);
    String etaVel = calculateETA(dist, vVel);
    String etaEco = calculateETA(dist, vEco);
    String etaSmart = calculateETA(dist, vSmart);
    String etaSuper = calculateETA(dist, vSuper);

    int timeToMin(double d, double s) => s > 0 ? ((d / s) * 60).round() : 0;
    int baseTime = timeToMin(dist, vVel);
    double baseLitri = stats['litri_totali_veloce'].toDouble();
    double baseCosto = baseLitri * 1.85;
    double baseCo2 = baseLitri * 2.31;

    Map<String, dynamic> getDeltas(double speed, double litri) {
      if (speed == 0 || litri == 0) return {"time": 0, "euro": 0.0, "co2": 0.0};
      return {
        "time": timeToMin(dist, speed) - baseTime,
        "euro": (litri * 1.85) - baseCosto,
        "co2": (litri * 2.31) - baseCo2,
      };
    }

    var dNorm = getDeltas(vNorm, stats['litri_totali_normale'].toDouble());
    var dSmart = getDeltas(vSmart, stats['litri_totali_smart']?.toDouble() ?? 0.0);
    var dEco = getDeltas(vEco, stats['litri_totali_target'].toDouble());
    var dSuper = getDeltas(vSuper, stats['litri_totali_super']?.toDouble() ?? baseLitri);

    int trattiPericolosi = 0;
    int kmOverLimit = 0;
    
    for (var rb in roadbook) {
      double pend = rb['pendenza'].toDouble();
      if (pend > 4.0 || pend < -4.0) trattiPericolosi++;
      if (rb['v_ideale_super'] != null) {
        if (rb['v_ideale_super'] > rb['limite_strada'] + 5) kmOverLimit++;
      }
    }

    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(title: const Text("Analisi Pre-Partenza"), backgroundColor: Colors.teal[900]),
      // --- FIX: Tutto avvolto in un SingleChildScrollView per evitare l'Overflow (Linee Cantiere) ---
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text("Scegli l'assetto del veicolo. I confronti sono rispetto alla rotta Navigatore Classico (Veloce).", 
                style: TextStyle(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
            ),
            
            if (vSuper > 0)
              ModeCardWidget(
                modeId: 'super', title: 'Super Veloce', subtitle: 'Priorità al cronometro. Tolleranza applicata.',
                color: Colors.deepOrange, icon: Icons.flash_on,
                isSelected: selectedMode == 'super', onTap: () => setState(() => selectedMode = 'super'),
                timeStr: formatTime(dist, vSuper), speedStr: "$vSuper km/h", litri: stats['litri_totali_super'].toDouble(),
                eta: etaSuper,
                deltaTime: dSuper['time'], deltaEuro: dSuper['euro'], deltaCo2: dSuper['co2'],
                warnings: [
                  if (kmOverLimit > 0) "Attenzione: in questa modalità superi i limiti in $kmOverLimit tratti.",
                  if (trattiPericolosi > 0) "Rischio elevato su $trattiPericolosi tratti in forte pendenza."
                ],
              ),
            
            ModeCardWidget(
              modeId: 'veloce', title: 'Veloce (Navigatore Classico)', subtitle: 'Guida dinamica al limite di legge.',
              color: Colors.redAccent, icon: Icons.speed,
              isSelected: selectedMode == 'veloce', onTap: () => setState(() => selectedMode = 'veloce'),
              timeStr: formatTime(dist, vVel), speedStr: "$vVel km/h", litri: baseLitri,
              eta: etaVel,
              deltaTime: 0, deltaEuro: 0.0, deltaCo2: 0.0,
            ),

            ModeCardWidget(
              modeId: 'normale', title: 'Normale', subtitle: 'Guida rilassata e fluida.',
              color: Colors.blueAccent, icon: Icons.directions_car,
              isSelected: selectedMode == 'normale', onTap: () => setState(() => selectedMode = 'normale'),
              timeStr: formatTime(dist, vNorm), speedStr: "$vNorm km/h", litri: stats['litri_totali_normale'].toDouble(),
              eta: etaNorm,
              deltaTime: dNorm['time'], deltaEuro: dNorm['euro'], deltaCo2: dNorm['co2'],
            ),

            ModeCardWidget(
              modeId: 'smart', title: 'Smart Pro (Consigliata)', subtitle: 'Veleggio attivo. Usa l\'inerzia a tuo vantaggio.',
              color: Colors.purpleAccent, icon: Icons.auto_awesome,
              isSelected: selectedMode == 'smart', onTap: () => setState(() => selectedMode = 'smart'),
              timeStr: formatTime(dist, vSmart), speedStr: "$vSmart km/h", litri: stats['litri_totali_smart'].toDouble(),
              eta: etaSmart,
              deltaTime: dSmart['time'], deltaEuro: dSmart['euro'], deltaCo2: dSmart['co2'],
              warnings: ["Ottimizzazione calcolata sfruttando l'inerzia su $trattiPericolosi tratti collinari."],
            ),

            ModeCardWidget(
              modeId: 'eco', title: 'Eco Estremo', subtitle: 'Massimo risparmio. Ignora il tempo di arrivo.',
              color: Colors.greenAccent, icon: Icons.eco,
              isSelected: selectedMode == 'eco', onTap: () => setState(() => selectedMode = 'eco'),
              timeStr: formatTime(dist, vEco), speedStr: "$vEco km/h", litri: stats['litri_totali_target'].toDouble(),
              eta: etaEco,
              deltaTime: dEco['time'], deltaEuro: dEco['euro'], deltaCo2: dEco['co2'],
              warnings: ["Guida estrema: il sistema suggerirà forti rallentamenti in salita."],
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent[400],
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 10,
                ),
                icon: const Icon(Icons.rocket_launch, size: 28),
                label: Text("AVVIA NAVIGATORE ${selectedMode.toUpperCase()}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PredictiveNavigationScreen(tripData: widget.tripData, selectedMode: selectedMode),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}