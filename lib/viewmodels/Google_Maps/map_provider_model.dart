// map_location_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

// AsyncNotifier to manage location fetching
class MapLocationNotifier extends AsyncNotifier<LatLng> {
  @override
  Future<LatLng> build() async {
    final location = Location();

    // Request permission
    final hasPermission = await location.hasPermission();
    if (hasPermission == PermissionStatus.denied) {
      final permissionResult = await location.requestPermission();
      if (permissionResult != PermissionStatus.granted) {
        throw Exception('Location permission not granted');
      }
    }

    // Enable location service if not enabled
    final serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      final serviceRequestResult = await location.requestService();
      if (!serviceRequestResult) {
        throw Exception('Location service not enabled');
      }
    }

    // Get current location
    final currentLocation = await location.getLocation();
    return LatLng(currentLocation.latitude!, currentLocation.longitude!);
  }

  Future<LatLng> refreshLocation() async {
    state = const AsyncLoading();
    final newLocation = await build();
    state = AsyncData(newLocation);
    return newLocation;
  }
}

// Provider for MapLocationNotifier
final mapLocationProvider = AsyncNotifierProvider<MapLocationNotifier, LatLng>(
  () => MapLocationNotifier(),
);
