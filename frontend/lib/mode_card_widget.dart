// lib/mode_card_widget.dart
import 'package:flutter/material.dart';

class ModeCardWidget extends StatelessWidget {
  final String modeId;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  final String timeStr;
  final String speedStr;
  final double litri;
  final String eta; // <-- Aggiunto ETA per la card grande
  final int deltaTime;
  final double deltaEuro;
  final double deltaCo2;
  
  final List<String> warnings;

  const ModeCardWidget({
    Key? key,
    required this.modeId, required this.title, required this.subtitle,
    required this.color, required this.icon, required this.isSelected, required this.onTap,
    required this.timeStr, required this.speedStr, required this.litri, required this.eta,
    required this.deltaTime, required this.deltaEuro, required this.deltaCo2,
    this.warnings = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double costo = litri * 1.85;
    double co2 = litri * 2.31;

    Widget buildDelta(double value, String unit, {bool invertColor = false}) {
      if (value == 0) return const SizedBox();
      bool isPositive = value > 0;
      Color dColor = isPositive ? (invertColor ? Colors.redAccent : Colors.redAccent) : Colors.greenAccent;
      String sign = isPositive ? "+" : "";
      return Text(" ($sign${value.toStringAsFixed(1)}$unit)", style: TextStyle(color: dColor, fontSize: 11, fontWeight: FontWeight.bold));
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.black45,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? color : Colors.white24, width: isSelected ? 2 : 1),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, spreadRadius: 1)] : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected ? color : Colors.white54,
                  size: 28
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Colors.white24, height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 1. COLONNA TEMPO E ETA
                Column(
                  children: [
                    const Text("⏱️ TEMPO", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(timeStr, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    Text("🏁 $eta", style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                    if (deltaTime != 0)
                      Text("(${deltaTime > 0 ? '+' : ''}$deltaTime min)", style: TextStyle(color: deltaTime > 0 ? Colors.redAccent : Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                // 2. NUOVA COLONNA LITRI
                Column(
                  children: [
                    const Text("💧 LITRI", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("${litri.toStringAsFixed(1)}L", style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                // 3. COLONNA COSTO
                Column(
                  children: [
                    const Text("💶 COSTO", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("${costo.toStringAsFixed(2)}€", style: const TextStyle(color: Colors.yellowAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                    buildDelta(deltaEuro, "€", invertColor: true),
                  ],
                ),
                // 4. COLONNA CO2
                Column(
                  children: [
                    const Text("🌿 CO2", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("${co2.toStringAsFixed(1)}kg", style: const TextStyle(color: Colors.lightGreen, fontSize: 14, fontWeight: FontWeight.bold)),
                    buildDelta(deltaCo2, "kg", invertColor: true),
                  ],
                ),
              ],
            ),
            if (warnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: warnings.map((w) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 14),
                        const SizedBox(width: 6),
                        Expanded(child: Text(w, style: const TextStyle(color: Colors.amberAccent, fontSize: 11))),
                      ],
                    ),
                  )).toList(),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}