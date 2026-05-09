import 'package:flutter/material.dart';
import 'road_painter.dart';

class AdvicePanel extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;

  const AdvicePanel({required this.title, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: color.withOpacity(0.2),
      child: Row(children: [
        Icon(icon, size: 30, color: color),
        SizedBox(width: 15),
        Expanded(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color))),
      ]),
    );
  }
}

class DashboardItem extends StatelessWidget {
  final String label;
  final String value;
  final String subValue;
  final Color color;

  const DashboardItem({required this.label, required this.value, this.subValue = "", this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(label, style: TextStyle(color: Colors.grey, fontSize: 10)),
      Text(value, style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: color)),
      if (subValue.isNotEmpty) Text(subValue, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    ]);
  }
}