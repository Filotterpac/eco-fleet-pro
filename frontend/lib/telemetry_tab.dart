// lib/telemetry_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'elevation_analysis.dart';
import 'telemetry_widgets.dart'; 
import 'map_helper.dart';      
import 'map_3d_screen.dart'; 
import 'mode_selection_screen.dart';
import 'price_tire_settings.dart'; 

class TelemetryTab extends StatefulWidget {
  final Map<String, dynamic>? currentTripData;
  final String partenza;
  final String arrivo;
  final String tappa;
  final bool isAndataRitorno;

  const TelemetryTab({
    Key? key,
    required this.currentTripData,
    required this.partenza,
    required this.arrivo,
    this.tappa = "",
    this.isAndataRitorno = false,
  }) : super(key: key);

  @override
  _TelemetryTabState createState() => _TelemetryTabState();
}

class _TelemetryTabState extends State<TelemetryTab> {
  bool isSatellite = false;
  final MapController _mapController = MapController();

  // --- STATO LOCALE PER IL RICALCOLO ---
  double _fuelPrice = 1.85;
  double _energyPrice = 0.25;
  double _tireMalus = 1.0; 
  TimeOfDay _departureTime = TimeOfDay.now();

  // Questa funzione è il "segreto" per far funzionare bene la mappa su ogni tratta
  void _centerMap(List<LatLng> points) {
    if (points.isEmpty) return;
    
    // Calcoliamo i confini del percorso
    final bounds = LatLngBounds.fromPoints(points);
    
    // Diamo un comando al controller per inquadrare tutto con un margine (padding)
    _mapController.fitCamera(CameraFit.bounds(
      bounds: bounds, 
      padding: const EdgeInsets.all(50) // 50 pixel di margine dai bordi
    ));
  }

  // --- LOGICA DI AGGIORNAMENTO DINAMICO ---
  @override
  void didUpdateWidget(covariant TelemetryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Se i dati del viaggio sono cambiati rispetto a prima, forziamo il ri-centramento
    if (widget.currentTripData != oldWidget.currentTripData && widget.currentTripData != null) {
      final coords = widget.currentTripData!['coords'] ?? [];
      if (coords.isNotEmpty) {
        List<LatLng> points = (coords as List).map((p) => LatLng(p[0], p[1])).toList();
        
        // Usiamo un piccolo ritardo per assicurarci che la mappa sia pronta a ricevere il comando
        Future.delayed(const Duration(milliseconds: 300), () => _centerMap(points));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentTripData == null || widget.currentTripData!['statistiche'] == null) {
      return const Center(child: Text("Nessun dato. Calcola un viaggio nel Setup 🚗", style: TextStyle(color: Colors.white54)));
    }

    final stats = widget.currentTripData!['statistiche'];
    final roadbook = widget.currentTripData!['roadbook'] ?? [];
    final coords = widget.currentTripData!['coords'] ?? [];
    List<LatLng> routePoints = (coords as List).map((p) => LatLng(p[1], p[0])).toList();

    // ==========================================================
    // LOGICA DI RICALCOLO (Invariata)
    // ==========================================================
    Map<String, dynamic> modStats = Map<String, dynamic>.from(stats);
    bool isHuman = modStats['unita_misura'] == 'Kcal';
    double baseCostVeloce = 0.0;

    if (!isHuman) {
      double bLitri = (stats['litri_totali_veloce'] ?? 0.0).toDouble();
      double bKwh = (stats['kwh_totali_veloce'] ?? 0.0).toDouble();
      baseCostVeloce = (bLitri * _fuelPrice) + (bKwh * _energyPrice);

      for (var mode in ['normale', 'veloce', 'smart', 'target', 'super']) {
        if (modStats['litri_totali_$mode'] != null) {
          modStats['litri_totali_$mode'] = (stats['litri_totali_$mode'] * _tireMalus);
          modStats['consumo_medio_$mode'] = (stats['consumo_medio_$mode'] * _tireMalus);
          modStats['co2_$mode'] = (stats['co2_$mode'] * _tireMalus);
        }
        if (modStats['kwh_totali_$mode'] != null) {
          modStats['kwh_totali_$mode'] = (stats['kwh_totali_$mode'] * _tireMalus);
        }
        double l = modStats['litri_totali_$mode'] ?? 0.0;
        double k = modStats['kwh_totali_$mode'] ?? 0.0;
        modStats['costo_$mode'] = (l * _fuelPrice) + (k * _energyPrice);
      }
    }

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        if (!isHuman)
          SliverToBoxAdapter(
            child: PriceTireSettings(
              initialFuelPrice: _fuelPrice,
              initialEnergyPrice: _energyPrice,
              baseCostEuro: baseCostVeloce,
              onChanged: (f, e, m, t) => setState(() {
                _fuelPrice = f; _energyPrice = e; _tireMalus = m; _departureTime = t;
              }),
            ),
          ),
        
        SliverToBoxAdapter(
          child: DynamicDashboardPanel(
            stats: modStats,
            partenza: widget.partenza,
            arrivo: widget.arrivo,
            tappa: widget.tappa,
            isAndataRitorno: widget.isAndataRitorno,
            departureTime: _departureTime, 
          ),
        ),

        SliverToBoxAdapter(
          child: Container(
            height: 280,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      // Inquadra tutto all'avvio
                      initialCameraFit: routePoints.isNotEmpty 
                        ? CameraFit.bounds(bounds: LatLngBounds.fromPoints(routePoints), padding: const EdgeInsets.all(50))
                        : null,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: isSatellite 
                          ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      ),
                      PolylineLayer(polylines: MapHelper.buildHeatmapPolylines(routePoints, roadbook)),
                      if (routePoints.isNotEmpty)
                        MarkerLayer(markers: [
                          Marker(point: routePoints.first, child: const Icon(Icons.location_on, color: Colors.green, size: 30)),
                          Marker(point: routePoints.last, child: const Icon(Icons.flag, color: Colors.red, size: 30)),
                        ]),
                    ],
                  ),
                  
                  Positioned(
                    top: 10, right: 10,
                    child: Column(
                      children: [
                        FloatingActionButton.small(
                          heroTag: "sat", backgroundColor: Colors.white,
                          onPressed: () => setState(() => isSatellite = !isSatellite), 
                          child: Icon(isSatellite ? Icons.map : Icons.satellite, color: Colors.black87)
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: "center", backgroundColor: Colors.white,
                          onPressed: () => _centerMap(routePoints), 
                          child: const Icon(Icons.center_focus_strong, color: Colors.black87)
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: "3d", backgroundColor: Colors.deepPurpleAccent,
                          onPressed: () {
                            List<double> lats = []; List<double> lons = []; List<double> alts = [];
                            int pts = (routePoints.length / (roadbook.length > 0 ? roadbook.length : 1)).floor();
                            if(pts == 0) pts = 1;
                            for (int i = 0; i < roadbook.length; i++) {
                              int idx = i * pts;
                              if (idx >= routePoints.length) idx = routePoints.length - 1;
                              lats.add(routePoints[idx].latitude);
                              lons.add(routePoints[idx].longitude);
                              alts.add(roadbook[i]['altitudine'].toDouble());
                            }
                            Navigator.push(context, MaterialPageRoute(builder: (context) => Map3DScreen(lats: lats, lons: lons, alts: alts)));
                          }, 
                          child: const Icon(Icons.threed_rotation, color: Colors.white)
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: "btn_altimetry", backgroundColor: Colors.tealAccent,
                          onPressed: () { 
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ElevationAnalysisScreen(roadbook: roadbook, partenza: widget.partenza, arrivo: widget.arrivo))); 
                          }, 
                          child: const Icon(Icons.terrain, color: Colors.black87)
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[700],
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.rocket_launch, color: Colors.white),
              label: const Text("AVVIA CRUSCOTTO PRO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ModeSelectionScreen(tripData: widget.currentTripData!))),
            ),
          ),
        ),
      ],
      body: Container(
        color: Colors.black,
        child: RoadbookList(roadbook: roadbook),
      ),
    );
  }
}