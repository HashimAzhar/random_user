import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:random_user/widgets/name_input_dialog.dart';

class MapState {
  final List<LatLng> points;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Set<Polygon> polygons;

  MapState({
    this.points = const [],
    this.markers = const {},
    this.polylines = const {},
    this.polygons = const {},
  });

  MapState copyWith({
    List<LatLng>? points,
    Set<Marker>? markers,
    Set<Polyline>? polylines,
    Set<Polygon>? polygons,
  }) {
    return MapState(
      points: points ?? this.points,
      markers: markers ?? this.markers,
      polylines: polylines ?? this.polylines,
      polygons: polygons ?? this.polygons,
    );
  }
}

class MapProvider extends StateNotifier<MapState> {
  MapProvider() : super(MapState());

  Future<void> addPoint(LatLng point, BuildContext context) async {
    final updatedPoints = List<LatLng>.from(state.points);
    final updatedMarkers = Set<Marker>.from(state.markers);
    final updatedPolylines = Set<Polyline>.from(state.polylines);

    final existingIndex = updatedPoints.indexWhere((p) => _isClose(p, point));
    if (existingIndex != -1 && updatedPoints.length >= 3) {
      final polygonName = await NameInputDialog.show(
        context,
        "Enter Polygon Name",
      );
      if (polygonName == null || polygonName.isEmpty) return;

      final newPolygon = Polygon(
        polygonId: const PolygonId('polygon'),
        points: updatedPoints,
        fillColor: Colors.blue.withOpacity(0.4),
        strokeColor: Colors.red,
        strokeWidth: 3,
      );

      final center = _getPolygonCenter(updatedPoints);
      final polygonLabel = Marker(
        markerId: const MarkerId('polygon_label'),
        position: center,
        infoWindow: InfoWindow(title: polygonName),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );

      state = state.copyWith(
        points: [],
        markers: {polygonLabel},
        polylines: {},
        polygons: {newPolygon},
      );
      return;
    }

    final markerName = await NameInputDialog.show(context, "Enter Marker Name");
    if (markerName == null || markerName.isEmpty) return;

    updatedPoints.add(point);
    updatedMarkers.add(
      Marker(
        markerId: MarkerId('marker_${updatedPoints.length}'),
        position: point,
        infoWindow: InfoWindow(title: markerName),
        onTap: () => addPoint(point, context),
      ),
    );

    if (updatedPoints.length >= 2) {
      updatedPolylines.add(
        Polyline(
          polylineId: PolylineId('polyline_${updatedPoints.length}'),
          points: updatedPoints.sublist(updatedPoints.length - 2),
          width: 3,
          color: Colors.blue,
        ),
      );
    }

    state = state.copyWith(
      points: updatedPoints,
      markers: updatedMarkers,
      polylines: updatedPolylines,
    );
  }

  bool _isClose(LatLng a, LatLng b, {double threshold = 0.0003}) {
    final dx = (a.latitude - b.latitude).abs();
    final dy = (a.longitude - b.longitude).abs();
    return dx < threshold && dy < threshold;
  }

  LatLng _getPolygonCenter(List<LatLng> points) {
    double lat = 0;
    double lng = 0;
    for (var p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }
}

final mapProvider = StateNotifierProvider<MapProvider, MapState>((ref) {
  return MapProvider();
});
