// lib/map_helper.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapHelper {
  static List<Polyline> buildHeatmapPolylines(
      List<LatLng> routePoints, List<dynamic> roadbook) {
    List<Polyline> polylines = [];
    if (roadbook.isEmpty || routePoints.isEmpty) return polylines;

    int pointsPerSegment = (routePoints.length / roadbook.length).floor();
    if (pointsPerSegment == 0) pointsPerSegment = 1;

    for (int i = 0; i < roadbook.length; i++) {
      int startIndex = i * pointsPerSegment;
      int endIndex = (i == roadbook.length - 1)
          ? routePoints.length
          : (i + 1) * pointsPerSegment + 1;

      if (endIndex > routePoints.length) endIndex = routePoints.length;

      // Ensure valid sublist range
      if (startIndex >= routePoints.length) break;

      List<LatLng> segmentCoords = routePoints.sublist(startIndex, endIndex);

      // We read the consumption for this specific segment to determine color
      double cons = roadbook[i]['consumo_ist'].toDouble();
      Color segColor;
      if (cons <= 1.5) {
        segColor = Colors.greenAccent;
      } else if (cons <= 4.0) {
        segColor = Colors.lightGreen;
      } else if (cons <= 6.0) {
        segColor = Colors.orangeAccent;
      } else {
        segColor = Colors.redAccent;
      }

      polylines.add(Polyline(
          points: segmentCoords, color: segColor, strokeWidth: 5.0));
    }
    return polylines;
  }
}