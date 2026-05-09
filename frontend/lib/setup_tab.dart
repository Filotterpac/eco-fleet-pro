// lib/setup_tab.dart
import 'package:flutter/material.dart';
import 'setup_ui_components.dart';
import 'setup_forms.dart'; // <-- Importiamo i blocchi pesanti!

class SetupTab extends StatefulWidget {
  final List<String> vehicleNames;
  final String? selectedVehicle;
  final Function(String?) onVehicleChanged;
  final VoidCallback onAddVehicle;

  final Function(String) onSubModeChanged; 
  final Function(Map<String, dynamic>) onCalculate;
  
  final TextEditingController partenzaCtrl;
  final TextEditingController arrivoCtrl;
  final TextEditingController tappaCtrl;
  final TextEditingController passCtrl;
  final TextEditingController targetCtrl;
  final bool isRealMode;
  final Function(bool) onRealModeChanged;
  final bool evitaAutostrade;
  final Function(bool?) onEvitaAutostradeChanged;
  final bool isAndataRitorno;
  final Function(bool?) onAndataRitornoChanged;
  final VoidCallback onGeolocate;
  final VoidCallback onSwapDestinations;
  final bool isLoading;
  final TextEditingController superVeloceController;
  final Function(int) onCategoryChanged;
  
  const SetupTab({
    Key? key, required this.vehicleNames, required this.selectedVehicle, required this.onVehicleChanged,
    required this.onAddVehicle, required this.partenzaCtrl, required this.arrivoCtrl,
    required this.tappaCtrl, required this.passCtrl, required this.targetCtrl,
    required this.isRealMode, required this.onRealModeChanged, required this.evitaAutostrade,
    required this.onEvitaAutostradeChanged, required this.isAndataRitorno, required this.onAndataRitornoChanged,
    required this.onGeolocate, required this.onSwapDestinations, required this.isLoading,
    required this.superVeloceController, required this.onCategoryChanged,
    required this.onCalculate, required this.onSubModeChanged, 
  }) : super(key: key);

  @override
  _SetupTabState createState() => _SetupTabState();
}

class _SetupTabState extends State<SetupTab> {
  int _selectedCategoryIndex = 2; // Default Auto 
  String _pedestrianMode = 'Camminata'; 
  String _microMode = 'Bicicletta'; 
  bool _isTrainingMode = false;
  double _targetSlope = 5.0; 

  void _changeCategory(int index) {
    setState(() => _selectedCategoryIndex = index);
    widget.onCategoryChanged(index); 
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // --- 1. RIQUADRO ROSSO: SELETTORE CATEGORIA ---
                  Container(
                    margin: const EdgeInsets.only(top: 20, bottom: 10),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CategoryIconWidget(icon: Icons.directions_walk, label: "Piedi", isSelected: _selectedCategoryIndex == 0, onTap: () => _changeCategory(0)),
                        CategoryIconWidget(icon: Icons.electric_scooter, label: "Micro", isSelected: _selectedCategoryIndex == 1, onTap: () => _changeCategory(1)),
                        CategoryIconWidget(icon: Icons.directions_car, label: "Auto", isSelected: _selectedCategoryIndex == 2, onTap: () => _changeCategory(2)),
                        CategoryIconWidget(icon: Icons.motorcycle, label: "Moto", isSelected: _selectedCategoryIndex == 3, onTap: () => _changeCategory(3)),
                      ],
                    ),
                  ),

                  // --- 2. BLOCCO VEICOLO DINAMICO ---
                  VehicleSelectionSection(
                    categoryIndex: _selectedCategoryIndex, pedestrianMode: _pedestrianMode, microMode: _microMode,
                    selectedVehicle: widget.selectedVehicle, vehicleNames: widget.vehicleNames,
                    onAddVehicle: widget.onAddVehicle, onVehicleChanged: widget.onVehicleChanged,
                    onPedestrianModeChanged: (val) { setState(() => _pedestrianMode = val); widget.onSubModeChanged(val); },
                    onMicroModeChanged: (val) { setState(() => _microMode = val); widget.onSubModeChanged(val); },
                  ),
                  
                  // --- 3. BLOCCO ALLENAMENTO ---
                  if ((_selectedCategoryIndex == 0 && _pedestrianMode == 'Corsa') || (_selectedCategoryIndex == 1 && _microMode == 'Bicicletta'))
                    TrainingSection(
                      isTrainingMode: _isTrainingMode, targetSlope: _targetSlope,
                      onTrainingModeChanged: (val) => setState(() => _isTrainingMode = val),
                      onTargetSlopeChanged: (val) => setState(() => _targetSlope = val),
                    ),

                  // --- 4. BLOCCO ITINERARIO ---
                  ItinerarySection(
                    categoryIndex: _selectedCategoryIndex, partenzaCtrl: widget.partenzaCtrl, arrivoCtrl: widget.arrivoCtrl,
                    tappaCtrl: widget.tappaCtrl, passCtrl: widget.passCtrl, targetCtrl: widget.targetCtrl,
                    superVeloceController: widget.superVeloceController, isRealMode: widget.isRealMode, onRealModeChanged: widget.onRealModeChanged,
                    evitaAutostrade: widget.evitaAutostrade, onEvitaAutostradeChanged: widget.onEvitaAutostradeChanged,
                    isAndataRitorno: widget.isAndataRitorno, onAndataRitornoChanged: widget.onAndataRitornoChanged,
                    onGeolocate: widget.onGeolocate, onSwapDestinations: widget.onSwapDestinations,
                  ),
                ],
              ),
            ),
          ),
          
          // --- PULSANTE GENERA ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                onPressed: widget.isLoading ? null : () {
                  widget.onCalculate({
                    "categoria": _selectedCategoryIndex,
                    "modalita_piedi": _pedestrianMode,
                    "modalita_micro": _microMode,
                    "training_mode": _isTrainingMode,
                    "target_slope": _targetSlope
                  });
                },
                child: widget.isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("GENERA ROADBOOK", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}