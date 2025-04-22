import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:random_user/test_things/historyscreen.dart';
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
  bool _tripInProgress = false;
  StreamSubscription<Position>? _positionStream;

  final String _userId = 'sampleUserId'; // Replace with actual user ID
  late DatabaseReference _locationRef;
  late DatabaseReference _historyRef;

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    _locationRef = FirebaseDatabase.instance.ref('live_tracking/$_userId');
    _historyRef = FirebaseDatabase.instance.ref('location_history/$_userId');
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
        _updateMarkers();

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

  void _updateMarkers() {
    _markers.clear();
    if (_fromPlace != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('from'),
          position: LatLng(_fromPlace!.lat, _fromPlace!.lon),
          infoWindow: InfoWindow(
            title: 'From',
            snippet: _fromPlace!.displayName,
          ),
        ),
      );
    }
    if (_toPlace != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('to'),
          position: LatLng(_toPlace!.lat, _toPlace!.lon),
          infoWindow: InfoWindow(title: 'To', snippet: _toPlace!.displayName),
        ),
      );
    }
  }

  void _onFromSelected(PlaceModel place) {
    setState(() {
      _fromPlace = place;
      _updateMarkers();
    });
    _maybeDrawRoute();
  }

  void _onToSelected(PlaceModel place) {
    setState(() {
      _toPlace = place;
      _updateMarkers();
    });
    _maybeDrawRoute();
  }

  void _maybeDrawRoute() {
    if (_fromPlace != null && _toPlace != null) {
      _drawRoute();
    }
  }

  void _startTracking() {
    if (_tracking || _toPlace == null) return;

    setState(() {
      _tracking = true;
      _tripInProgress = true;
      if (_currentPosition != null && _fullRoute.isNotEmpty) {
        _coveredPointIndex = _findClosestPointIndex(_currentPosition!);
        _updatePolylines();
      }
    });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
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
        _checkIfReachedDestination(newPosition);
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
    _locationRef.set(locationData); // Overwrite the last known location
  }

  Future<void> _saveTripToHistory() async {
    if (_fromPlace == null || _toPlace == null || _fullRoute.isEmpty) return;

    final tripData = {
      'start_location': {'lat': _fromPlace!.lat, 'lng': _fromPlace!.lon},
      'end_location': {'lat': _toPlace!.lat, 'lng': _toPlace!.lon},
      'start_address': _fromPlace!.displayName,
      'end_address': _toPlace!.displayName,
      'distance': _distanceText,
      'duration': (_fullRoute.length * 0.1 / 60).toStringAsFixed(
        2,
      ), // Approximate duration
      'timestamp': DateTime.now().toIso8601String(),
      'route_points':
          _fullRoute
              .map(
                (latlng) => {'lat': latlng.latitude, 'lng': latlng.longitude},
              )
              .toList(),
    };

    await _historyRef.push().set(tripData);
  }

  void _completeTrip() {
    _positionStream?.cancel();
    setState(() {
      _tracking = false;
      _tripInProgress = false;
    });
  }

  void _checkIfReachedDestination(LatLng currentPosition) {
    if (_toPlace == null || !_tracking) return;

    final distanceToDestination = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      _toPlace!.lat,
      _toPlace!.lon,
    );

    if (distanceToDestination < 20) {
      // Check if within 20 meters
      _completeTrip();
      _saveTripToHistory();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Destination Reached!'),
            content: const Text('You have arrived at your destination.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _refreshMap() async {
    if (_tripInProgress) {
      await _saveTripToHistory();
      _completeTrip();
    }
    _positionStream?.cancel();
    setState(() {
      _markers.clear();
      _polylines.clear();
      _distanceText = '';
      _coveredPointIndex = 0;
      _tracking = false;
      _tripInProgress = false;
      _fromPlace = null;
      _toPlace = null;
      _fullRoute.clear();
    });
    _getCurrentLocation(); // Get current location again after refresh
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('World Route Finder'),
        actions: [
          IconButton(
            onPressed: () async {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
            icon: const Icon(Icons.history),
          ),
        ],
      ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed:
                            (_tracking || _toPlace == null)
                                ? null
                                : _startTracking,
                        child: Text(
                          _tracking
                              ? 'Tracking...'
                              : (_toPlace == null
                                  ? 'Select Destination'
                                  : 'Start Tracking'),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _currentPosition!,
                        zoom: 15, // Increased default zoom
                      ),
                      onMapCreated: (controller) => _mapController = controller,
                      markers: _markers,
                      polylines: _polylines,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _refreshMap,
                        child: const Text('Refresh Map'),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
