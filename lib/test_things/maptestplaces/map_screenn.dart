import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
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

      final polylinePoints =
          coords.map<LatLng>((e) => LatLng(e[1], e[0])).toList();

      setState(() {
        _distanceText = '$distanceKm km';
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            color: Colors.blue,
            width: 5,
            points: polylinePoints,
          ),
        };
      });
    }
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
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              _fromPlace!.lat < _toPlace!.lat ? _fromPlace!.lat : _toPlace!.lat,
              _fromPlace!.lon < _toPlace!.lon ? _fromPlace!.lon : _toPlace!.lon,
            ),
            northeast: LatLng(
              _fromPlace!.lat > _toPlace!.lat ? _fromPlace!.lat : _toPlace!.lat,
              _fromPlace!.lon > _toPlace!.lon ? _fromPlace!.lon : _toPlace!.lon,
            ),
          ),
          100,
        ),
      );
    }
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
