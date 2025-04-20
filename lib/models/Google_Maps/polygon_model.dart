import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PolygonModelState {
  final Set<Marker> markers;
  final Set<Polygon> polygons;

  PolygonModelState({this.markers = const {}, this.polygons = const {}});

  PolygonModelState copyWith({Set<Marker>? markers, Set<Polygon>? polygons}) {
    return PolygonModelState(
      markers: markers ?? this.markers,
      polygons: polygons ?? this.polygons,
    );
  }
}
