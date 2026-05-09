import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'eco_nav_logic.dart';
import 'eco_nav_widgets.dart';
import 'road_painter.dart';

class PredictiveNavigationScreen extends StatefulWidget {
  final Map<String, dynamic> tripData;
  const PredictiveNavigationScreen({required this.tripData});
  @override
  _PredictiveNavigationScreenState createState() => _PredictiveNavigationScreenState();
}

class _PredictiveNavigationScreenState extends State<PredictiveNavigationScreen> {
  final MapController _mapController = MapController();
  final EcoNavLogic _logic = EcoNavLogic();
  StreamSubscription<Position>? _positionStream;
  
  LatLng? currentPos;
  double speed = 0, target = 0, limit = 50, slope = 0, nextSlope = 0, distNext = 300;
  String advice = "In attesa...", etaEco = "--", etaStd = "--", timeRem = "--";
  Color advColor = Colors.grey; IconData advIcon = Icons.gps_not_fixed;

  @override
  void initState() {
    super.initState();
    var times = _logic.calculateETA(widget.tripData['statistiche']);
    etaStd = times['std']!; etaEco = times['eco']!; timeRem = times['rimasto']!;
    _startTracking();
  }

  void _startTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)
    ).listen((p) {
      setState(() {
        speed = p.speed * 3.6; currentPos = LatLng(p.latitude, p.longitude);
        _mapController.move(currentPos!, 16.0);
        _processPhysics(currentPos!);
      });
    });
  }

  void _processPhysics(LatLng pos) {
    // ... [Inserisci qui la logica di _analyzeEcoDriving del sorgente 20 aggiornando le variabili locali] ...
    // Esempio chiamata voce:
    _logic.speakAdvice(advice, distNext);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Column(children: [
        Expanded(flex: 4, child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: LatLng(0,0), initialZoom: 16),
          children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png')],
        )),
        AdvicePanel(title: advice, color: advColor, icon: advIcon),
        Container(height: 70, child: CustomPaint(painter: RoadProfilePainter(slope, nextSlope), child: Container())),
        Expanded(flex: 2, child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          DashboardItem(label: "LIMIT", value: "${limit.toInt()}", color: Colors.red),
          DashboardItem(label: "SPEED", value: "${speed.toInt()}"),
          DashboardItem(label: "TARGET", value: "${target.toInt()}", color: Colors.green),
        ])),
      ]),
    );
  }

  @override
  void dispose() { _positionStream?.cancel(); super.dispose(); }
}