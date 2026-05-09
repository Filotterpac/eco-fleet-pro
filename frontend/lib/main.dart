import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'setup_tab.dart';
import 'telemetry_tab.dart';
import 'gps_service.dart'; 

void main() => runApp(EcoApp());

class EcoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eco Fleet Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.teal,
        colorScheme: const ColorScheme.dark(
          primary: Colors.teal, 
          secondary: Colors.tealAccent,
          surface: Color(0xFF1E1E1E),
        ),
      ),
      home: MainDashboard(),
    );
  }
}

class MainDashboard extends StatefulWidget {
  @override
  _MainDashboardState createState() => _MainDashboardState();
}

// L'aggiunta di SingleTickerProviderStateMixin è essenziale per le animazioni delle tab
class _MainDashboardState extends State<MainDashboard> with SingleTickerProviderStateMixin {

  final String apiUrl = 'https://eco-fleet-pro-api.onrender.com/api';
  //final String apiUrl = 'http://10.0.2.2:8000/api';

  late TabController _tabController; // <-- IL NOSTRO CONTROLLER DELLE TAB

  List<String> vehicleNames = [];
  String? selectedVehicle;
  
  final _partenzaCtrl = TextEditingController(text: "Milano");
  final _arrivoCtrl = TextEditingController(text: "Roma");
  final _tappaCtrl = TextEditingController(); 
  final _targetCtrl = TextEditingController(text: "5.0");
  final _passCtrl = TextEditingController(text: "1");
  final superVeloceController = TextEditingController(); 
  
  bool isRealMode = false; 
  bool evitaAutostrade = false; 
  bool isAndataRitorno = false; 
  bool isLoading = false;
  int currentCategory = 2;
  Map<String, dynamic>? currentTripData;

  @override
  void initState() {
    super.initState();
    // INIZIALIZZIAMO IL CONTROLLER QUI
    _tabController = TabController(length: 2, vsync: this);
    fetchVehicles(); 
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchVehicles({int categoria = 2, String? subTipo}) async {
    String url = '$apiUrl/vehicles/$categoria';
    if (subTipo != null) url += '?sub_tipo=$subTipo';

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        setState(() {
          vehicleNames = data.keys.toList();
          selectedVehicle = vehicleNames.isNotEmpty ? vehicleNames.first : null;
        });
      }
    } catch (e) {
      debugPrint("Errore caricamento mezzi: $e");
    }
  }

  Future<void> calculateRoute(Map<String, dynamic> extraConfig) async { 
    if (selectedVehicle == null && extraConfig['categoria'] > 1) return; 
    
    setState(() => isLoading = true);
    
    try {
      final res = await http.post(
        Uri.parse('$apiUrl/plan_route'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "partenza": _partenzaCtrl.text,
          "arrivo": _arrivoCtrl.text,
          "passeggeri": int.tryParse(_passCtrl.text) ?? 1,
          "target_l": double.tryParse(_targetCtrl.text) ?? 5.0,
          "car_model": selectedVehicle ?? "Nessuno",
          "is_real_mode": isRealMode,
          "tappa": _tappaCtrl.text, 
          "andata_ritorno": isAndataRitorno, 
          "evita_autostrade": evitaAutostrade,
          "super_veloce_offset": int.tryParse(superVeloceController.text) ?? 0,
          "categoria_trasporto": extraConfig['categoria'],
          "pedestrian_mode": extraConfig['modalita_piedi'],
          "micro_mode": extraConfig['modalita_micro'],
          "is_training": extraConfig['training_mode'],
          "target_slope": extraConfig['target_slope']
        }),
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        
        if (decoded is Map<String, dynamic>) {
          setState(() {
            currentTripData = decoded;
          });
          // USIAMO IL CONTROLLER ESPLICITO PER CAMBIARE PAGINA (Senza crash!)
          _tabController.animateTo(1);
        } else {
          debugPrint("⚠️ Errore: Il backend ha restituito una Lista invece di una Map!");
        }
      } else {
        debugPrint("❌ Errore Backend: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("🚨 Errore calcolo: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _rilevaGPS() async {
    setState(() => isLoading = true); 
    try {
      final posizione = await GpsService.ottieniPosizione();
      if (posizione != null) {
        setState(() {
          _partenzaCtrl.text = "${posizione.latitude}, ${posizione.longitude}";
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Errore GPS: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _swapDestinations() {
    setState(() {
      String temp = _partenzaCtrl.text;
      _partenzaCtrl.text = _arrivoCtrl.text;
      _arrivoCtrl.text = temp;
    });
  }

  void _showAddVehicleDialog() {
    TextEditingController nomeCtrl = TextEditingController();
    TextEditingController tipoCtrl = TextEditingController(text: "Diesel");
    TextEditingController pesoCtrl = TextEditingController(text: "1500");
    TextEditingController cxCtrl = TextEditingController(text: "0.30");
    TextEditingController areaCtrl = TextEditingController(text: "2.20");
    TextEditingController effCtrl = TextEditingController(text: "0.35");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Nuovo Veicolo", style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView( 
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: "Nome")),
              TextField(controller: tipoCtrl, decoration: const InputDecoration(labelText: "Tipo")),
              TextField(controller: pesoCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Peso")),
              TextField(controller: cxCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Cx")),
              TextField(controller: areaCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Area Frontale")),
              TextField(controller: effCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Efficienza")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annulla")),
          ElevatedButton(
            onPressed: () async {
              if (nomeCtrl.text.isNotEmpty) {
                Map<String, dynamic> nuovoAuto = {
                  "nome": "${nomeCtrl.text} (${tipoCtrl.text})",
                  "peso_vuoto": int.tryParse(pesoCtrl.text) ?? 1500,
                  "cx": double.tryParse(cxCtrl.text) ?? 0.30,
                  "area_frontale": double.tryParse(areaCtrl.text) ?? 2.2,
                  "efficienza_motore": double.tryParse(effCtrl.text) ?? 0.35,
                };
                
                final response = await http.post(
                  Uri.parse('$apiUrl/vehicles/$currentCategory'),
                  headers: {'Content-Type': 'application/json'}, 
                  body: jsonEncode(nuovoAuto)
                );
                
                if (response.statusCode == 200) {
                  setState(() {
                    vehicleNames.add(nuovoAuto["nome"]);
                    selectedVehicle = nuovoAuto["nome"];
                  });
                }
              }
              Navigator.pop(context);
            },
            child: const Text("Salva"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Eco Fleet Pro Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController, // <-- USIAMO IL CONTROLLER
          indicatorColor: Colors.tealAccent,
          labelColor: Colors.tealAccent,
          unselectedLabelColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.settings), text: "Setup Viaggio"),
            Tab(icon: Icon(Icons.analytics), text: "Foglio di Calcolo"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController, // <-- USIAMO IL CONTROLLER
        physics: const NeverScrollableScrollPhysics(), 
        children: [
          SetupTab(
            vehicleNames: vehicleNames,
            selectedVehicle: selectedVehicle,
            onVehicleChanged: (val) => setState(() => selectedVehicle = val),
            onAddVehicle: _showAddVehicleDialog, 
            partenzaCtrl: _partenzaCtrl,
            arrivoCtrl: _arrivoCtrl,
            tappaCtrl: _tappaCtrl,
            passCtrl: _passCtrl,
            targetCtrl: _targetCtrl,
            isRealMode: isRealMode,
            onRealModeChanged: (val) => setState(() => isRealMode = val),
            evitaAutostrade: evitaAutostrade, 
            onEvitaAutostradeChanged: (val) => setState(() => evitaAutostrade = val ?? false), 
            isAndataRitorno: isAndataRitorno,
            onAndataRitornoChanged: (val) => setState(() => isAndataRitorno = val ?? false),
            onGeolocate: _rilevaGPS, 
            onSwapDestinations: _swapDestinations,
            isLoading: isLoading,
            onCalculate: (extraConfig) => calculateRoute(extraConfig),
            superVeloceController: superVeloceController,
            onCategoryChanged: (cat) {
              setState(() => currentCategory = cat);
              String? defaultSub;
              if (cat == 0) defaultSub = "Camminata";
              if (cat == 1) defaultSub = "Bicicletta"; 
              fetchVehicles(categoria: cat, subTipo: defaultSub);
            },
            onSubModeChanged: (sub) {
              fetchVehicles(categoria: currentCategory, subTipo: sub);
            },
          ),
          
          TelemetryTab(
            currentTripData: currentTripData,
            partenza: _partenzaCtrl.text,
            arrivo: _arrivoCtrl.text,
            tappa: _tappaCtrl.text,
            isAndataRitorno: isAndataRitorno,
          ),
        ],
      ),
    );
  }
}