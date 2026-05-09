// lib/price_tire_settings.dart
import 'package:flutter/material.dart';

class PriceTireSettings extends StatefulWidget {
  final double initialFuelPrice;
  final double initialEnergyPrice;
  final double baseCostEuro; // Costo base (es. modalità Veloce) per calcolare il malus in Euro
  final Function(double fuel, double energy, double tireMalus, TimeOfDay departureTime) onChanged;

  const PriceTireSettings({
    Key? key, 
    this.initialFuelPrice = 1.85, 
    this.initialEnergyPrice = 0.25,
    required this.baseCostEuro,
    required this.onChanged,
  }) : super(key: key);

  @override
  _PriceTireSettingsState createState() => _PriceTireSettingsState();
}

class _PriceTireSettingsState extends State<PriceTireSettings> {
  late TextEditingController _fuelCtrl;
  late TextEditingController _energyCtrl;
  String _selectedTire = 'Estivi';
  TimeOfDay _departureTime = TimeOfDay.now();

  final Map<String, double> _tireMalusMap = {
    'Estivi': 1.0,
    '4 Stagioni': 1.03, // +3%
    'Invernali': 1.05,  // +5%
  };

  @override
  void initState() {
    super.initState();
    _fuelCtrl = TextEditingController(text: widget.initialFuelPrice.toString());
    _energyCtrl = TextEditingController(text: widget.initialEnergyPrice.toString());
  }

  void _notifyChanges() {
    double fuel = double.tryParse(_fuelCtrl.text.replaceAll(',', '.')) ?? 1.85;
    double energy = double.tryParse(_energyCtrl.text.replaceAll(',', '.')) ?? 0.25;
    double malus = _tireMalusMap[_selectedTire] ?? 1.0;
    widget.onChanged(fuel, energy, malus, _departureTime);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        // --- LA TUA LINEA VERDE DRITTA IN ALTO ---
        border: const Border(top: BorderSide(color: Colors.tealAccent, width: 4)),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("IMPOSTAZIONI ECONOMICHE E MECCANICHE", 
            style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
          const SizedBox(height: 15),
          
          Row(
            children: [
              // 1. SELETTORE ORARIO DI PARTENZA
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: () async {
                    TimeOfDay? t = await showTimePicker(
                      context: context, 
                      initialTime: _departureTime,
                      builder: (context, child) => Theme(data: ThemeData.dark(), child: child!),
                    );
                    if (t != null) {
                      setState(() => _departureTime = t);
                      _notifyChanges();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.black, 
                      borderRadius: BorderRadius.circular(8), 
                      border: Border.all(color: Colors.teal.withOpacity(0.5))
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time, color: Colors.tealAccent, size: 16),
                        const SizedBox(width: 8),
                        Text("Partenza: ${_departureTime.format(context)}", 
                             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // 2. INPUT PREZZI
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _fuelCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(labelText: "Benzina €/L", isDense: true, border: OutlineInputBorder()),
                  onChanged: (_) => _notifyChanges(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _energyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(labelText: "Energia €/kWh", isDense: true, border: OutlineInputBorder()),
                  onChanged: (_) => _notifyChanges(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          const Text("PNEUMATICI (Attrito e Malus calcolati istantaneamente):", 
            style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          
          // 3. SELEZIONE PNEUMATICI CON PERCENTUALE E MALUS IN ROSSO
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _tireMalusMap.keys.map((type) {
              bool isSel = _selectedTire == type;
              int pct = ((_tireMalusMap[type]! - 1.0) * 100).round();
              
              // Calcolo del malus in Euro (differenza rispetto alla gomma estiva)
              double extraEuro = (widget.baseCostEuro * _tireMalusMap[type]!) - widget.baseCostEuro;

              return ChoiceChip(
                backgroundColor: Colors.black,
                selectedColor: Colors.teal.withOpacity(0.2),
                side: BorderSide(color: isSel ? Colors.tealAccent : Colors.white24, width: 1.5),
                label: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: type, 
                        style: TextStyle(color: isSel ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)
                      ),
                      if (pct > 0) 
                        TextSpan(
                          text: " (+$pct%) ", 
                          style: TextStyle(color: isSel ? Colors.white70 : Colors.grey, fontSize: 11)
                        ),
                      if (extraEuro > 0.01) 
                        TextSpan(
                          text: "+${extraEuro.toStringAsFixed(2)}€", 
                          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)
                        ),
                    ],
                  ),
                ),
                selected: isSel,
                onSelected: (val) {
                  if (val) {
                    setState(() => _selectedTire = type);
                    _notifyChanges();
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}