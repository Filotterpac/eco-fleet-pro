// lib/setup_forms.dart
import 'package:flutter/material.dart';
import 'setup_ui_components.dart';

// ==========================================
// 1. SEZIONE SCELTA VEICOLO / PROFILO
// ==========================================
class VehicleSelectionSection extends StatelessWidget {
  final int categoryIndex;
  final String pedestrianMode;
  final String microMode;
  final Function(String) onPedestrianModeChanged;
  final Function(String) onMicroModeChanged;
  final String? selectedVehicle;
  final List<String> vehicleNames;
  final Function(String?) onVehicleChanged;
  final VoidCallback onAddVehicle;

  const VehicleSelectionSection({
    Key? key, required this.categoryIndex, required this.pedestrianMode, required this.microMode,
    required this.onPedestrianModeChanged, required this.onMicroModeChanged, required this.selectedVehicle,
    required this.vehicleNames, required this.onVehicleChanged, required this.onAddVehicle,
  }) : super(key: key);

  String _getDynamicTitle() {
    switch (categoryIndex) {
      case 0: return "PROFILO PEDONALE";
      case 1: return "MEZZO MICROMOBILITÀ";
      case 2: return "VEICOLO (AUTO)";
      case 3: return "VEICOLO (MOTO)";
      default: return "VEICOLO";
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: _getDynamicTitle(),
      titleColor: Colors.tealAccent,
      child: _buildDynamicSubSection(),
    );
  }

  Widget _buildDynamicSubSection() {
    if (categoryIndex == 0) {
      // --- CATEGORIA 0: PIEDI ---
      return Row(
        children: [
          Expanded(child: BigSelectionButton(label: "Camminata", isSelected: pedestrianMode == "Camminata", onTap: () => onPedestrianModeChanged("Camminata"))),
          const SizedBox(width: 10),
          Expanded(child: BigSelectionButton(label: "Corsa", isSelected: pedestrianMode == "Corsa", onTap: () => onPedestrianModeChanged("Corsa"))),
        ],
      );
    } else if (categoryIndex == 1) {
      // --- CATEGORIA 1: MICROMOBILITÀ (Pulsantoni + Tendina!) ---
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: BigSelectionButton(label: "Bicicletta", isSelected: microMode == "Bicicletta", onTap: () => onMicroModeChanged("Bicicletta"))),
              const SizedBox(width: 10),
              Expanded(child: BigSelectionButton(label: "Monopattino", isSelected: microMode == "Monopattino", onTap: () => onMicroModeChanged("Monopattino"))),
            ],
          ),
          const SizedBox(height: 15),
          // ECCO LA TENDINA CHE MANCAVA!
          Row(
            children: [
              Icon(microMode == "Bicicletta" ? Icons.pedal_bike : Icons.electric_scooter, color: Colors.tealAccent),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedVehicle,
                    items: vehicleNames.map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 14)))).toList(),
                    onChanged: onVehicleChanged,
                    decoration: const InputDecoration(labelText: "Seleziona Modello", border: InputBorder.none),
                  ),
                ),
              ),
              IconButton(icon: const Icon(Icons.add_circle, color: Colors.tealAccent), onPressed: onAddVehicle),
            ],
          ),
        ],
      );
    } else {
      // --- CATEGORIA 2 e 3: AUTO E MOTO (Solo tendina) ---
      return Row(
        children: [
          Icon(categoryIndex == 2 ? Icons.directions_car : Icons.motorcycle, color: Colors.tealAccent),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                isExpanded: true, 
                value: selectedVehicle,
                items: vehicleNames.map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 14)))).toList(),
                onChanged: onVehicleChanged,
                decoration: const InputDecoration(labelText: "Seleziona Modello", border: InputBorder.none),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.add_circle, color: Colors.tealAccent), onPressed: onAddVehicle),
        ],
      );
    }
  }
}

// ==========================================
// 2. SEZIONE ALLENAMENTO
// ==========================================
class TrainingSection extends StatelessWidget {
  final bool isTrainingMode;
  final ValueChanged<bool> onTrainingModeChanged;
  final double targetSlope;
  final ValueChanged<double> onTargetSlopeChanged;

  const TrainingSection({
    Key? key, required this.isTrainingMode, required this.onTrainingModeChanged, required this.targetSlope, required this.onTargetSlopeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: "MODALITÀ ALLENAMENTO",
      titleColor: Colors.redAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: const Text("Attiva Ricerca Salite", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("Cerca i percorsi con dislivello per bruciare Kcal", style: TextStyle(fontSize: 11, color: Colors.grey)),
            value: isTrainingMode, activeColor: Colors.redAccent, contentPadding: EdgeInsets.zero,
            onChanged: onTrainingModeChanged,
          ),
          if (isTrainingMode) ...[
            const SizedBox(height: 10),
            Text("Pendenza Media Target: ${targetSlope.toInt()}%", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            Slider(
              value: targetSlope, min: 0, max: 15, divisions: 15,
              activeColor: Colors.redAccent, inactiveColor: Colors.grey[800], label: "${targetSlope.toInt()}%",
              onChanged: onTargetSlopeChanged,
            ),
          ]
        ],
      ),
    );
  }
}

// ==========================================
// 3. SEZIONE ITINERARIO E OPZIONI
// ==========================================
class ItinerarySection extends StatelessWidget {
  final int categoryIndex;
  final TextEditingController partenzaCtrl;
  final TextEditingController arrivoCtrl;
  final TextEditingController tappaCtrl;
  final TextEditingController passCtrl;
  final TextEditingController targetCtrl;
  final TextEditingController superVeloceController;
  final bool isRealMode;
  final Function(bool) onRealModeChanged;
  final bool evitaAutostrade;
  final Function(bool?) onEvitaAutostradeChanged;
  final bool isAndataRitorno;
  final Function(bool?) onAndataRitornoChanged;
  final VoidCallback onGeolocate;
  final VoidCallback onSwapDestinations;

  const ItinerarySection({
    Key? key, required this.categoryIndex, required this.partenzaCtrl, required this.arrivoCtrl, required this.tappaCtrl,
    required this.passCtrl, required this.targetCtrl, required this.superVeloceController, required this.isRealMode,
    required this.onRealModeChanged, required this.evitaAutostrade, required this.onEvitaAutostradeChanged,
    required this.isAndataRitorno, required this.onAndataRitornoChanged, required this.onGeolocate, required this.onSwapDestinations,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: "ITINERARIO",
      titleColor: Colors.orangeAccent,
      child: Column(
        children: [
          LocationField(label: "Da", controller: partenzaCtrl, icon: Icons.radio_button_unchecked, iconColor: Colors.blueAccent, actionIcon: Icons.gps_fixed, onAction: onGeolocate),
          LocationField(label: "Tappa (Opzionale)", controller: tappaCtrl, icon: Icons.stop_circle_outlined, iconColor: Colors.yellowAccent, actionIcon: Icons.swap_vert, onAction: onSwapDestinations),
          LocationField(label: "A", controller: arrivoCtrl, icon: Icons.location_on, iconColor: Colors.redAccent, isLast: true),
          const SizedBox(height: 15),

          if (categoryIndex == 2 || categoryIndex == 3) ...[
            Row(
              children: [
                Expanded(child: SmallField(label: "Passeggeri", ctrl: passCtrl, icon: Icons.people)),
                const SizedBox(width: 20),
                Expanded(child: SmallField(label: "Target Consumo", ctrl: targetCtrl, icon: Icons.track_changes)),
              ],
            ),
            const SizedBox(height: 10),
            SmallField(label: "Extra Limite (+ km/h)", ctrl: superVeloceController, icon: Icons.bolt, iconColor: Colors.orange),
            const Divider(height: 30, color: Colors.white24),
            Row(
              children: [
                const Text("Simula Traffico Reale", style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Switch(value: isRealMode, onChanged: onRealModeChanged, activeColor: Colors.tealAccent),
              ],
            ),
          ],

          CheckboxListTile(title: const Text("Evita Autostrade"), value: evitaAutostrade, onChanged: onEvitaAutostradeChanged, controlAffinity: ListTileControlAffinity.leading, activeColor: Colors.tealAccent, contentPadding: EdgeInsets.zero),
          CheckboxListTile(title: const Text("Andata e Ritorno"), value: isAndataRitorno, onChanged: onAndataRitornoChanged, controlAffinity: ListTileControlAffinity.leading, activeColor: Colors.tealAccent, contentPadding: EdgeInsets.zero),
        ],
      ),
    );
  }
}