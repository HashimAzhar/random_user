import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapWithHistoryScreen extends StatelessWidget {
  final Map<String, dynamic> trip;

  MapWithHistoryScreen(this.trip);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Trip History Map")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(
            trip['polyline'][0]['latitude'],
            trip['polyline'][0]['longitude'],
          ),
          zoom: 12,
        ),
        markers: _getMarkersFromPolyline(trip['polyline']),
        polylines: {
          Polyline(
            polylineId: PolylineId('history'),
            points:
                trip['polyline']
                    .map(
                      (point) => LatLng(point['latitude'], point['longitude']),
                    )
                    .toList(),
            color: Colors.grey, // Grey polyline for history
            width: 5,
          ),
        },
      ),
    );
  }

  Set<Marker> _getMarkersFromPolyline(List<dynamic> polyline) {
    Set<Marker> markers = {};
    if (polyline.isNotEmpty) {
      markers.add(
        Marker(
          markerId: MarkerId('start'),
          position: LatLng(polyline[0]['latitude'], polyline[0]['longitude']),
          infoWindow: InfoWindow(title: "Start"),
        ),
      );
      markers.add(
        Marker(
          markerId: MarkerId('end'),
          position: LatLng(
            polyline.last['latitude'],
            polyline.last['longitude'],
          ),
          infoWindow: InfoWindow(title: "End"),
        ),
      );
    }
    return markers;
  }
}

class MapScreenFromHistory extends StatelessWidget {
  final LatLng startLocation;
  final LatLng endLocation;
  final String startAddress;
  final String endAddress;
  final String distance;
  final String duration;
  final List<LatLng> routePoints;

  const MapScreenFromHistory({
    Key? key,
    required this.startLocation,
    required this.endLocation,
    required this.startAddress,
    required this.endAddress,
    required this.distance,
    required this.duration,
    required this.routePoints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Set<Polyline> polylines = {};
    if (routePoints.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('coveredPath'),
          color: Colors.grey,
          width: 5,
          points: routePoints,
        ),
      );
      polylines.add(
        Polyline(
          polylineId: const PolylineId('fullRoute'),
          color: Colors.blue,
          width: 3,
          points: [
            startLocation,
            endLocation,
          ], // Display a simple line to the destination
        ),
      );
    } else {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          color: Colors.blue,
          width: 5,
          points: [startLocation, endLocation],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Past Trip')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: startLocation, zoom: 15),
        markers: {
          Marker(
            markerId: const MarkerId('start'),
            position: startLocation,
            infoWindow: InfoWindow(title: startAddress),
          ),
          Marker(
            markerId: const MarkerId('end'),
            position: endLocation,
            infoWindow: InfoWindow(title: endAddress),
          ),
        },
        polylines: polylines,
      ),
    );
  }
}
