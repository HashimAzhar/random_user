// map_view_model.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:random_user/test_things/maptestplaces/place_model.dart';

final mapViewModelProvider = AsyncNotifierProvider<MapViewModel, void>(
  MapViewModel.new,
);

class MapViewModel extends AsyncNotifier<void> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  PlaceModel? _fromPlace;
  PlaceModel? _toPlace;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  String _distanceText = "";
  List<LatLng> _fullRoute = [];
  int _coveredPointIndex = 0;
  bool _tracking = false;
  StreamSubscription<Position>? _positionStream;

  final DatabaseReference _locationRef = FirebaseDatabase.instance.ref(
    'live_tracking',
  );

  // 👇 Exposed Getters for UI to use
  LatLng? get currentPosition => _currentPosition;
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;
  String get distanceText => _distanceText;
  bool get tracking => _tracking;

  @override
  Future<void> build() async {
    await _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final hasPermission = await Geolocator.requestPermission();
    if (hasPermission == LocationPermission.denied ||
        hasPermission == LocationPermission.deniedForever)
      return;

    final pos = await Geolocator.getCurrentPosition();
    _currentPosition = LatLng(pos.latitude, pos.longitude);
    state = const AsyncData(null);
  }

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  void setFromPlace(PlaceModel place) {
    _fromPlace = place;
    _markers.add(
      Marker(
        markerId: const MarkerId('from'),
        position: LatLng(place.lat, place.lon),
        infoWindow: const InfoWindow(title: 'From'),
      ),
    );
    _maybeDrawRoute();
    state = const AsyncData(null);
  }

  void setToPlace(PlaceModel place) {
    _toPlace = place;
    _markers.add(
      Marker(
        markerId: const MarkerId('to'),
        position: LatLng(place.lat, place.lon),
        infoWindow: const InfoWindow(title: 'To'),
      ),
    );
    _maybeDrawRoute();
    state = const AsyncData(null);
  }

  void _maybeDrawRoute() {
    if (_fromPlace != null && _toPlace != null) {
      _drawRoute();
    }
  }

  Future<void> _drawRoute() async {
    final from = '${_fromPlace!.lon},${_fromPlace!.lat}';
    final to = '${_toPlace!.lon},${_toPlace!.lat}';
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/$from;$to?overview=full&geometries=geojson',
    );
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final route = data['routes'][0];
      _distanceText = (route['distance'] / 1000).toStringAsFixed(2);
      final coords = route['geometry']['coordinates'];
      _fullRoute = coords.map<LatLng>((e) => LatLng(e[1], e[0])).toList();
      _coveredPointIndex = 0;
      _updatePolylines();

      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(_boundsFromLatLngList(_fullRoute), 100),
      );

      state = const AsyncData(null);
    }
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      x0 ??= latLng.latitude;
      x1 ??= latLng.latitude;
      y0 ??= latLng.longitude;
      y1 ??= latLng.longitude;

      x0 = x0 < latLng.latitude ? x0 : latLng.latitude;
      x1 = x1 > latLng.latitude ? x1 : latLng.latitude;
      y0 = y0 < latLng.longitude ? y0 : latLng.longitude;
      y1 = y1 > latLng.longitude ? y1 : latLng.longitude;
    }
    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
  }

  void _updatePolylines() {
    final List<LatLng> coveredPath = _fullRoute.sublist(
      0,
      _coveredPointIndex + 1,
    );
    final List<LatLng> remainingPath = _fullRoute.sublist(_coveredPointIndex);

    _polylines = {
      Polyline(
        polylineId: const PolylineId('coveredPath'),
        color: Colors.grey,
        width: 5,
        points: coveredPath,
      ),
      Polyline(
        polylineId: const PolylineId('remainingPath'),
        color: Colors.blue,
        width: 5,
        points: remainingPath,
      ),
    };
  }

  void startTracking() {
    if (_tracking || _currentPosition == null) return;

    _tracking = true;
    _coveredPointIndex = _findClosestPointIndex(_currentPosition!);
    _updatePolylines();
    state = const AsyncData(null);

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      final newPosition = LatLng(position.latitude, position.longitude);
      _currentPosition = newPosition;
      _coveredPointIndex = _findClosestPointIndex(newPosition);
      _updatePolylines();
      _sendLocationToFirebase(newPosition);
      state = const AsyncData(null);
    });
  }

  int _findClosestPointIndex(LatLng position) {
    double minDistance = double.infinity;
    int closestIndex = 0;

    for (int i = 0; i < _fullRoute.length; i++) {
      final d = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _fullRoute[i].latitude,
        _fullRoute[i].longitude,
      );
      if (d < minDistance) {
        minDistance = d;
        closestIndex = i;
      }
    }
    return closestIndex;
  }

  void _sendLocationToFirebase(LatLng position) async {
    final locationData = {
      'lat': position.latitude,
      'lng': position.longitude,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final event = await _locationRef.once();
    final currentLocations = event.snapshot.value;

    if (currentLocations is Map) {
      final locationsMap = Map<String, dynamic>.from(currentLocations);
      if (locationsMap.length >= 10) {
        final firstKey = locationsMap.keys.first;
        _locationRef.child(firstKey).remove();
      }
    }

    _locationRef.push().set(locationData);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    // super.dispose();
  }
}
