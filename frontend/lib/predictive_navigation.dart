import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

// Importiamo i nostri 3 file "aiutanti"
import 'eco_nav_logic.dart';
import 'eco_nav_widgets.dart';
import 'road_painter.dart';

class PredictiveNavigationScreen extends StatefulWidget {
  final Map<String, dynamic> tripData;
  final String selectedMode;
  
  const PredictiveNavigationScreen({
    Key? key, 
    required this.tripData, 
    required this.selectedMode
  }) : super(key: key);

  @override
  _PredictiveNavigationScreenState createState() => _PredictiveNavigationScreenState();
}

class _PredictiveNavigationScreenState extends State<PredictiveNavigationScreen> {
  final MapController _mapController = MapController();
  final EcoNavLogic _logic = EcoNavLogic(); // Il nostro cervello per Voce e Tempi
  StreamSubscription<Position>? _positionStream;
  
  List<LatLng> routePoints = [];
  List<dynamic> roadbook = [];
  LatLng? currentPosition;
  
  // Variabili per il cruscotto
  double speed = 0, target = 0, limit = 50, slope = 0, nextSlope = 0, distNext = 300;
  String advice = "In attesa...", etaEco = "--", timeRem = "--";
  Color advColor = Colors.grey; 
  IconData advIcon = Icons.gps_not_fixed;

  @override
  void initState() {
    super.initState();
    routePoints = (widget.tripData['coords'] as List).map((p) => LatLng(p[0], p[1])).toList();
    roadbook = widget.tripData['roadbook'];
    
    // Calcoliamo i tempi iniziali chiamando la funzione col NOME CORRETTO
    var times = _logic.calculateETA(widget.tripData['statistiche']);
    etaEco = times['eco']!; 
    timeRem = times['rimasto']!;
    
    _startTracking();
  }

  void _startTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)
    ).listen((p) {
      if (!mounted) return;
      setState(() {
        speed = p.speed * 3.6; 
        currentPosition = LatLng(p.latitude, p.longitude);
        _mapController.move(currentPosition!, 16.0); // Centra la mappa
        _processPhysics(currentPosition!); // Calcola le pendenze
      });
    });
  }

  // IL MOTORE FISICO PREDITTIVO
  void _processPhysics(LatLng userPos) {
    if (roadbook.isEmpty || routePoints.isEmpty) return;

    final Distance distanceObj = Distance();
    double minDistance = double.infinity;
    int closestPointIndex = 0;

    // Trova il punto più vicino sulla mappa
    for (int i = 0; i < routePoints.length; i++) {
      double dist = distanceObj.as(LengthUnit.Meter, userPos, routePoints[i]);
      if (dist < minDistance) {
        minDistance = dist;
        closestPointIndex = i;
      }
    }

    int pointsPerSegment = (routePoints.length / roadbook.length).floor();
    int currentRbIndex = (closestPointIndex / pointsPerSegment).floor();
    if (currentRbIndex >= roadbook.length) currentRbIndex = roadbook.length - 1;

    int lookAheadIndex = currentRbIndex + 1; 
    if (lookAheadIndex >= roadbook.length) lookAheadIndex = roadbook.length - 1;

    var currentRb = roadbook[currentRbIndex];
    var futureRb = roadbook[lookAheadIndex];

    target = currentRb['v_ideale_${widget.selectedMode}'].toDouble();
    slope = currentRb['pendenza'].toDouble();
    nextSlope = futureRb['pendenza'].toDouble();
    limit = currentRb['limite_strada'].toDouble();
    double targetFuturo = futureRb['v_ideale'].toDouble();
    
    int puntiMancanti = ((currentRbIndex + 1) * pointsPerSegment) - closestPointIndex;
    distNext = (puntiMancanti / pointsPerSegment) * 300.0;
    if (distNext < 10) distNext = 10;

    // Logica dei Consigli a schermo
    if (slope < -1.0 && nextSlope > 1.0) {
      advice = "VELEGGIA! (Salita tra ${distNext.toInt()}m)";
      advColor = Colors.lightBlueAccent; advIcon = Icons.waves;
    } else if (slope > 1.0 && nextSlope < -1.0) {
      advice = "SCOLLINAMENTO (Discesa tra ${distNext.toInt()}m)";
      advColor = Colors.orangeAccent; advIcon = Icons.arrow_outward;
    } else if (targetFuturo < target) {
      advice = "RALLENTA (Limite tra ${distNext.toInt()}m)";
      advColor = Colors.orangeAccent; advIcon = Icons.warning_amber_rounded;
    } else if (speed > limit) {
      advice = "OLTRE IL LIMITE STRADALE!";
      advColor = Colors.red; advIcon = Icons.dangerous;
    } else if (speed > target + 5.0) {
      advice = "TROPPO VELOCE (Spreco Energia)";
      advColor = Colors.redAccent; advIcon = Icons.speed;
    } else {
      advice = "PASSO OTTIMALE";
      advColor = Colors.greenAccent; advIcon = Icons.check_circle_outline;
    }

    // Facciamo parlare l'assistente vocale usando il NOME CORRETTO
    _logic.speakAdvice(advice, distNext);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(title: Text("Eco-Navigator Pro"), backgroundColor: Colors.teal[900]),
      body: Column(children: [
        // 1. Mappa
        Expanded(flex: 4, child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: routePoints.isNotEmpty ? routePoints.first : LatLng(0,0), initialZoom: 16),
          children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png')],
        )),
        
        // 2. Pannello Consiglio
        AdvicePanel(title: advice, color: advColor, icon: advIcon),
        
        // 3. Disegno Strada
        Container(height: 70, child: CustomPaint(painter: RoadProfilePainter(slope, nextSlope), child: Container())),
        
        // 4. Cruscotto (Usa i nomi dei widget corretti)
        Expanded(flex: 2, child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          DashboardItem(label: "LIMIT", value: "${limit.toInt()}", color: Colors.red),
          DashboardItem(label: "SPEED", value: "${speed.toInt()}"),
          DashboardItem(label: "TARGET", value: "${target.toInt()}", color: Colors.greenAccent),
        ])),
        
        // 5. Orario di Arrivo
        Padding(
          padding: EdgeInsets.all(8), 
          child: Text("Arrivo stimato: $etaEco ($timeRem)", style: TextStyle(color: Colors.tealAccent))
        ),
      ]),
    );
  }

  @override
  void dispose() { 
    _positionStream?.cancel(); 
    super.dispose(); 
  }
}