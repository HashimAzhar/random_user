// import 'dart:async';

// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:random_user/models/Google_Maps/map_state.dart';

// final mapViewModelProvider = AsyncNotifierProvider<MapViewModel, MapState>(
//   () => MapViewModel(),
// );

// class MapViewModel extends AsyncNotifier<MapState> {
//   Timer? _locationTimer;
//   StreamSubscription<LatLng>? _locationSubscription;

//   @override
//   FutureOr<MapState> build() async {
//     // Initialize with default state
//     return MapState();
//   }

//   void setCurrentLocation(LatLng location) {
//     if (state.isLoading || state.hasError) return;
//     state = AsyncData(state.value!.copyWith(currentLocation: location));

//     // If tracking is active, add to live tracking points
//     if (state.value?.isTracking == true) {
//       _addLiveTrackingPoint(location);
//     }
//   }

//   void setFromLocation(LatLng location, String name) {
//     if (state.isLoading || state.hasError) return;
//     state = AsyncData(
//       state.value!.copyWith(
//         fromLocation: location,
//         fromLocationName: name,
//         route: [], // Clear existing route when from location changes
//       ),
//     );
//   }

//   void setToLocation(LatLng location, String name) {
//     if (state.isLoading || state.hasError) return;
//     state = AsyncData(
//       state.value!.copyWith(
//         toLocation: location,
//         toLocationName: name,
//         route: [], // Clear existing route when to location changes
//       ),
//     );
//   }

//   void setRoute(List<LatLng> route) {
//     if (state.isLoading || state.hasError) return;
//     state = AsyncData(state.value!.copyWith(route: route));
//   }

//   void startLiveTracking() {
//     if (state.value == null || state.value!.isTracking) return;

//     state = AsyncData(
//       state.value!.copyWith(isTracking: true, liveTrackingPoints: []),
//     );

//     // Start listening to location updates
//     // Note: Replace with actual location service implementation
//     _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
//       final current = state.value?.currentLocation;
//       if (current != null) {
//         _addLiveTrackingPoint(current);
//       }
//     });
//   }

//   void stopLiveTracking() {
//     _locationTimer?.cancel();
//     _locationSubscription?.cancel();
//     if (state.value != null) {
//       state = AsyncData(state.value!.copyWith(isTracking: false));
//     }
//   }

//   void refreshMap() {
//     _locationTimer?.cancel();
//     _locationSubscription?.cancel();
//     state = AsyncData(MapState(currentLocation: state.value?.currentLocation));
//   }

//   void _addLiveTrackingPoint(LatLng point) {
//     final updated = List<LatLng>.from(state.value!.liveTrackingPoints);
//     updated.add(point);

//     // Keep only the last 20 points for performance
//     if (updated.length > 20) {
//       updated.removeAt(0);
//     }

//     state = AsyncData(state.value!.copyWith(liveTrackingPoints: updated));
//   }

//   @override
//   void dispose() {
//     _locationTimer?.cancel();
//     _locationSubscription?.cancel();
//     // super.dispose();
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:random_user/models/Google_Maps/map_state.dart';
import 'package:random_user/models/Google_Maps/place_model.dart';

class MapController extends StateNotifier<MapState> {
  final Ref ref;

  Timer? locationTimer;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  MapController(this.ref) : super(MapState());

  void setController(GoogleMapController controller) {
    state = state.copyWith(controller: controller);
  }

  Future<void> initLocation() async {
    final Location location = Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
    }

    if (permissionGranted == PermissionStatus.granted) {
      final current = await location.getLocation();
      final currentLatLng = LatLng(current.latitude!, current.longitude!);
      state = state.copyWith(currentPosition: currentLatLng);
      _moveCamera(currentLatLng);
    }
  }

  void _moveCamera(LatLng target) {
    state.controller?.animateCamera(CameraUpdate.newLatLng(target));
  }

  void setFromLocation(PlaceModel place) {
    final marker = Marker(
      markerId: MarkerId('from'),
      position: LatLng(place.lat, place.lon),
      infoWindow: InfoWindow(title: 'Start: ${place.displayName}'),
    );
    state = state.copyWith(
      fromPlace: place,
      markers: {...state.markers, marker},
    );
    _moveCamera(marker.position);
  }

  void setToLocation(PlaceModel place) {
    final marker = Marker(
      markerId: MarkerId('to'),
      position: LatLng(place.lat, place.lon),
      infoWindow: InfoWindow(title: 'End: ${place.displayName}'),
    );
    state = state.copyWith(toPlace: place, markers: {...state.markers, marker});
    _moveCamera(marker.position);
    getRouteAndDistance();
  }

  Future<void> getRouteAndDistance() async {
    if (state.fromPlace == null || state.toPlace == null) return;

    final url =
        'http://router.project-osrm.org/route/v1/driving/${state.fromPlace!.lon},${state.fromPlace!.lat};${state.toPlace!.lon},${state.toPlace!.lat}?overview=full&geometries=geojson';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    final coords = data['routes'][0]['geometry']['coordinates'] as List;
    final distance = data['routes'][0]['distance'] / 1000;
    final duration = data['routes'][0]['duration'] / 60;

    final route = coords.map((c) => LatLng(c[1], c[0])).toList();

    final polyline = Polyline(
      polylineId: PolylineId('route'),
      color: const Color(0xFF2196F3),
      width: 5,
      points: route,
    );

    state = state.copyWith(
      fullRoute: route,
      distanceText:
          "${distance.toStringAsFixed(2)} km / ${duration.toStringAsFixed(0)} min",
      polylines: {polyline},
    );
  }

  void setRoute(List<LatLng> route) {
    final polyline = Polyline(
      polylineId: PolylineId('route'),
      color: const Color(0xFF2196F3),
      width: 5,
      points: route,
    );

    state = state.copyWith(fullRoute: route, polylines: {polyline});
  }

  void startTrip() {
    state = state.copyWith(
      tripInProgress: true,
      tracking: true,
      coveredPointIndex: 0,
    );
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    locationTimer?.cancel();

    locationTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final current = await Location().getLocation();
      final currentLatLng = LatLng(current.latitude!, current.longitude!);

      // Store in Firebase
      final userId = 'user_1'; // You can make this dynamic
      final path = 'tracking/$userId';
      final snapshot = await _database.ref(path).get();

      final locations = <Map<String, dynamic>>[];
      if (snapshot.exists) {
        final existing = Map<String, dynamic>.from(snapshot.value as Map);
        locations.addAll(existing.values.cast<Map<String, dynamic>>());
      }

      if (locations.length >= 10) {
        locations.removeAt(0);
      }

      locations.add({
        'lat': currentLatLng.latitude,
        'lng': currentLatLng.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });

      final updatedMap = {
        for (int i = 0; i < locations.length; i++) 'loc$i': locations[i],
      };

      await _database.ref(path).set(updatedMap);

      _updateCoveredPath(currentLatLng);
    });
  }

  void _updateCoveredPath(LatLng current) {
    final route = state.fullRoute;
    if (route.isEmpty) return;

    int newIndex = state.coveredPointIndex;

    while (newIndex < route.length &&
        _calculateDistance(route[newIndex], current) < 0.05) {
      newIndex++;
    }

    final covered = route.sublist(0, newIndex);
    final remaining = route.sublist(newIndex);

    final coveredPolyline = Polyline(
      polylineId: PolylineId('covered'),
      color: const Color(0xFF4CAF50),
      width: 6,
      points: covered,
    );

    final remainingPolyline = Polyline(
      polylineId: PolylineId('remaining'),
      color: const Color(0xFF2196F3),
      width: 6,
      points: remaining,
    );

    state = state.copyWith(
      polylines: {coveredPolyline, remainingPolyline},
      coveredPointIndex: newIndex,
    );
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    const double R = 6371;
    final dLat = _degToRad(p2.latitude - p1.latitude);
    final dLng = _degToRad(p2.longitude - p1.longitude);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(p1.latitude)) *
            cos(_degToRad(p2.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  void refreshMap() {
    locationTimer?.cancel();
    state = state.copyWith(
      markers: {},
      polylines: {},
      fullRoute: [],
      tracking: false,
      tripInProgress: false,
      coveredPointIndex: 0,
      distanceText: '',
    );
  }

  @override
  void dispose() {
    locationTimer?.cancel();
    super.dispose();
  }
}

final mapControllerProvider = StateNotifierProvider<MapController, MapState>((
  ref,
) {
  return MapController(ref);
});
