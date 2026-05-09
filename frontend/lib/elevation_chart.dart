import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ElevationChart extends StatelessWidget {
  final List<dynamic> roadbook;

  const ElevationChart({Key? key, required this.roadbook}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (roadbook.isEmpty) return Container();

    List<FlSpot> spots = [];
    double maxAlt = 0;
    double minAlt = 9999;

    // Estraiamo i punti (X = km, Y = altitudine)
    for (var rb in roadbook) {
      double km = rb['km'].toDouble();
      double alt = rb['altitudine'].toDouble();
      spots.add(FlSpot(km, alt));
      
      if (alt > maxAlt) maxAlt = alt;
      if (alt < minAlt) minAlt = alt;
    }

    // Aggiungiamo un margine sopra e sotto al grafico
    double minY = (minAlt - 50 < 0) ? 0 : minAlt - 50;
    double maxY = maxAlt + 50;

    return Container(
      height: 220,
      padding: EdgeInsets.only(right: 16, left: 0, top: 20, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              axisNameWidget: Text("Distanza (km)", style: TextStyle(color: Colors.grey, fontSize: 10)),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  // Mostra un'etichetta ogni 20 km per non affollare l'asse X
                  if (value % 20 == 0 || value == 0) {
                    return Text("${value.toInt()}", style: TextStyle(color: Colors.grey, fontSize: 10));
                  }
                  return Container();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  // Mostra le altitudini sull'asse Y
                  if (value % 100 == 0) {
                    return Text("${value.toInt()}m", style: TextStyle(color: Colors.grey, fontSize: 10));
                  }
                  return Container();
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.orangeAccent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false), // Nasconde i puntini singoli
              belowBarData: BarAreaData(
                show: true,
                color: Colors.orangeAccent.withOpacity(0.3), // L'effetto "pieno" sotto la montagna
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              // Il popup quando ci clicchi sopra!
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    "Km: ${spot.x.toStringAsFixed(1)}\nAlt: ${spot.y.toStringAsFixed(0)} m",
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}