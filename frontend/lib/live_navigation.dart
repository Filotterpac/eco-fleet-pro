import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LiveNavigationScreen extends StatefulWidget {
  final Map<String, dynamic> tripData;

  const LiveNavigationScreen({required this.tripData});

  @override
  _LiveNavigationScreenState createState() => _LiveNavigationScreenState();
}

class _LiveNavigationScreenState extends State<LiveNavigationScreen> {
  StreamSubscription<Position>? _positionStream;
  
  double currentSpeedKmh = 0.0;
  double targetSpeedKmh = 0.0;
  String currentMarcia = "--";
  String adviceTitle = "In attesa di segnale GPS...";
  String adviceSubtitle = "Muoviti per iniziare l'analisi";
  Color adviceColor = Colors.grey;
  IconData adviceIcon = Icons.gps_not_fixed;

  List<LatLng> routePoints = [];
  List<dynamic> roadbook = [];

  @override
  void initState() {
    super.initState();
    // Estraiamo i dati passati dalla pagina precedente
    routePoints = (widget.tripData['coords'] as List).map((p) => LatLng(p[0], p[1])).toList();
    roadbook = widget.tripData['roadbook'];
    _startTracking();
  }

  void _startTracking() async {
    // Configuriamo il GPS per aggiornarsi ogni volta che ci muoviamo di almeno 5 metri
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, 
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      if (!mounted) return;

      setState(() {
        // Il GPS ci dà la velocità in metri al secondo. Moltiplichiamo per 3.6 per i km/h.
        currentSpeedKmh = position.speed * 3.6;
        _analyzeEcoDriving(LatLng(position.latitude, position.longitude));
      });
    });
  }

  // IL CERVELLO DELLA NAVIGAZIONE PRETTIVA
  void _analyzeEcoDriving(LatLng userPos) {
    if (roadbook.isEmpty || routePoints.isEmpty) return;

    // 1. Troviamo in che punto esatto del tracciato ci troviamo
    final Distance distanceObj = Distance();
    double minDistance = double.infinity;
    int closestPointIndex = 0;

    for (int i = 0; i < routePoints.length; i++) {
      double dist = distanceObj.as(LengthUnit.Meter, userPos, routePoints[i]);
      if (dist < minDistance) {
        minDistance = dist;
        closestPointIndex = i;
      }
    }

    // 2. A quale riga del "roadbook" corrisponde questo punto?
    int pointsPerSegment = (routePoints.length / roadbook.length).floor();
    int currentRbIndex = (closestPointIndex / pointsPerSegment).floor();
    if (currentRbIndex >= roadbook.length) currentRbIndex = roadbook.length - 1;

    // 3. Guardiamo avanti! (Look-ahead di circa 1 o 2 segmenti stradali)
    int lookAheadIndex = currentRbIndex + 1; // Guarda al segmento successivo
    if (lookAheadIndex >= roadbook.length) lookAheadIndex = roadbook.length - 1;

    var currentRb = roadbook[currentRbIndex];
    var futureRb = roadbook[lookAheadIndex];

    targetSpeedKmh = currentRb['v_ideale'].toDouble();
    currentMarcia = currentRb['marcia'];
    
    double targetFuturo = futureRb['v_ideale'].toDouble();
    double pendenzaFutura = futureRb['pendenza'].toDouble();

    // 4. LOGICA DI ISTRUZIONE AL GUIDATORE
    
    // CASO A: Discesa ripida imminente o forte rallentamento richiesto
    if (targetFuturo < currentSpeedKmh && pendenzaFutura < -1.5) {
      adviceTitle = "STACCA L'ACCELERATORE!";
      adviceSubtitle = "Discesa imminente tra pochi metri. Sfrutta l'inerzia e veleggia.";
      adviceColor = Colors.lightBlueAccent;
      adviceIcon = Icons.arrow_downward;
    } 
    // CASO B: Dobbiamo rallentare per un limite stradale o curva
    else if (targetFuturo < targetSpeedKmh && currentSpeedKmh >= targetFuturo) {
      adviceTitle = "RALLENTA DOLCEMENTE";
      adviceSubtitle = "Abbassa la velocità a ${targetFuturo.toInt()} km/h per il prossimo tratto.";
      adviceColor = Colors.orangeAccent;
      adviceIcon = Icons.warning_amber_rounded;
    }
    // CASO C: Stiamo andando troppo veloci rispetto al target attuale
    else if (currentSpeedKmh > targetSpeedKmh + 5.0) {
      adviceTitle = "TROPPO VELOCE";
      adviceSubtitle = "Stai sprecando carburante. Scendi a ${targetSpeedKmh.toInt()} km/h.";
      adviceColor = Colors.redAccent;
      adviceIcon = Icons.speed;
    }
    // CASO D: Stiamo andando troppo piano (inefficienza per marce basse)
    else if (currentSpeedKmh < targetSpeedKmh - 5.0 && currentSpeedKmh > 5.0) {
      adviceTitle = "ACCELERA AL TARGET";
      adviceSubtitle = "Raggiungi i ${targetSpeedKmh.toInt()} km/h per usare la $currentMarcia.";
      adviceColor = Colors.green;
      adviceIcon = Icons.arrow_upward;
    }
    // CASO E: Perfetti!
    else if (currentSpeedKmh > 5.0) {
      adviceTitle = "GUIDA PERFETTA";
      adviceSubtitle = "Mantieni questo passo. Consumo ottimizzato.";
      adviceColor = Colors.tealAccent;
      adviceIcon = Icons.check_circle_outline;
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel(); // Spegniamo il GPS quando usciamo dalla schermata!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: Text("Live Eco-Drive"),
        backgroundColor: Colors.teal[900],
      ),
      body: Column(
        children: [
          // PANNELLO ISTRUZIONI
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 30, horizontal: 16),
            color: adviceColor.withOpacity(0.2),
            child: Column(
              children: [
                Icon(adviceIcon, size: 60, color: adviceColor),
                SizedBox(height: 10),
                Text(adviceTitle, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: adviceColor), textAlign: TextAlign.center),
                SizedBox(height: 5),
                Text(adviceSubtitle, style: TextStyle(fontSize: 14, color: Colors.white), textAlign: TextAlign.center),
              ],
            ),
          ),
          
          Expanded(
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // TACHIMETRO GPS REALE
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("VELOCITÀ REALE", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text("${currentSpeedKmh.toStringAsFixed(0)}", style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text("km/h", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  // TARGET IDEALE
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("TARGET IDEALE", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text("${targetSpeedKmh.toStringAsFixed(0)}", style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.tealAccent)),
                      Text("in $currentMarcia", style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Nota: Sul simulatore PC la velocità reale potrebbe rimanere a 0 km/h. Per testare il cruscotto dinamico, installa l'app su un telefono vero o usa la simulazione di percorso dell'emulatore.",
              style: TextStyle(color: Colors.grey[600], fontSize: 10, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          )
        ],
      ),
    );
  }
}