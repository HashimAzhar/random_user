// map_view_model.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapViewModel extends ChangeNotifier {
  Set<Marker> _markers = {};

  Set<Marker> get markers => _markers;

  // Function to add a marker
  void addMarker(LatLng position, String title, String snippet) {
    _markers.add(
      Marker(
        markerId: MarkerId(position.toString()), // Unique ID based on position
        position: position,
        infoWindow: InfoWindow(title: title, snippet: snippet),
      ),
    );
    notifyListeners(); // Notify listeners to update the UI
  }
}

// Provider for MapViewModel
final mapViewModelProvider = ChangeNotifierProvider((ref) => MapViewModel());
