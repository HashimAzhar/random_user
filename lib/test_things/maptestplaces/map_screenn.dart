import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:random_user/test_things/maptestplaces/place_model.dart';
import 'package:random_user/test_things/maptestplaces/search_textfield.dart';

class MapScreenn extends StatefulWidget {
  const MapScreenn({super.key});

  @override
  State<MapScreenn> createState() => _MapScreennState();
}

class _MapScreennState extends State<MapScreenn> {
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

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final hasPermission = await Geolocator.requestPermission();
    if (hasPermission == LocationPermission.denied ||
        hasPermission == LocationPermission.deniedForever) {
      return;
    }

    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(pos.latitude, pos.longitude);
    });
  }

  Future<void> _drawRoute() async {
    if (_fromPlace == null || _toPlace == null) return;

    final from = '${_fromPlace!.lon},${_fromPlace!.lat}';
    final to = '${_toPlace!.lon},${_toPlace!.lat}';

    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/$from;$to?overview=full&geometries=geojson',
    );

    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final route = data['routes'][0];
      final distanceKm = (route['distance'] / 1000).toStringAsFixed(2);
      final List coords = route['geometry']['coordinates'];

      setState(() {
        _distanceText = '$distanceKm km';
        _fullRoute = coords.map<LatLng>((e) => LatLng(e[1], e[0])).toList();
        _coveredPointIndex = 0;
        _updatePolylines();

        // Zoom to fit the entire route
        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(_boundsFromLatLngList(_fullRoute), 100),
        );
      });
    }
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
  }

  void _updatePolylines() {
    if (_fullRoute.isEmpty) return;

    final List<LatLng> coveredPath = _fullRoute.sublist(
      0,
      _coveredPointIndex + 1,
    );
    final List<LatLng> remainingPath = _fullRoute.sublist(_coveredPointIndex);

    setState(() {
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
    });
  }

  void _onFromSelected(PlaceModel place) {
    setState(() {
      _fromPlace = place;
      _markers.add(
        Marker(
          markerId: const MarkerId('from'),
          position: LatLng(place.lat, place.lon),
          infoWindow: const InfoWindow(title: 'From'),
        ),
      );
    });
    _maybeDrawRoute();
  }

  void _onToSelected(PlaceModel place) {
    setState(() {
      _toPlace = place;
      _markers.add(
        Marker(
          markerId: const MarkerId('to'),
          position: LatLng(place.lat, place.lon),
          infoWindow: const InfoWindow(title: 'To'),
        ),
      );
    });
    _maybeDrawRoute();
  }

  void _maybeDrawRoute() {
    if (_fromPlace != null && _toPlace != null) {
      _drawRoute();
    }
  }

  void _startTracking() {
    if (_tracking) return;

    setState(() {
      _tracking = true;
      if (_currentPosition != null && _fullRoute.isNotEmpty) {
        _coveredPointIndex = _findClosestPointIndex(_currentPosition!);
        _updatePolylines();
      }
    });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      final newPosition = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentPosition = newPosition;
        _coveredPointIndex = _findClosestPointIndex(newPosition);
        _updatePolylines();
        _sendLocationToFirebase(newPosition);
      });
    });
  }

  int _findClosestPointIndex(LatLng position) {
    if (_fullRoute.isEmpty) return 0;

    double minDistance = double.infinity;
    int closestIndex = 0;

    for (int i = 0; i < _fullRoute.length; i++) {
      final double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _fullRoute[i].latitude,
        _fullRoute[i].longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  void _sendLocationToFirebase(LatLng position) {
    final locationData = {
      'lat': position.latitude,
      'lng': position.longitude,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _locationRef.once().then((DatabaseEvent event) {
      final currentLocations = event.snapshot.value;
      if (currentLocations is Map) {
        final locationsMap = Map<String, dynamic>.from(currentLocations);
        if (locationsMap.length >= 10) {
          final firstLocationKey = locationsMap.keys.first;
          _locationRef.child(firstLocationKey).remove();
        }
      }
      _locationRef.push().set(locationData);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('World Route Finder')),
      body:
          _currentPosition == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: SearchTextField(
                      label: "From Location",
                      onPlaceSelected: _onFromSelected,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: SearchTextField(
                      label: "To Location",
                      onPlaceSelected: _onToSelected,
                    ),
                  ),
                  if (_distanceText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        "Distance: $_distanceText",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: _startTracking,
                    child: Text(
                      _tracking ? 'Tracking Started' : 'Start Tracking',
                    ),
                  ),
                  Expanded(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _currentPosition!,
                        zoom: 10,
                      ),
                      onMapCreated: (controller) => _mapController = controller,
                      markers: _markers,
                      polylines: _polylines,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                    ),
                  ),
                ],
              ),
    );
  }
}
