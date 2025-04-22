// // lib/view_models/live_location_view_model.dart

// import 'dart:async';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:random_user/models/Google_Maps/tracked_location_model.dart';
// import 'package:random_user/services/location_service.dart';

// final liveLocationViewModelProvider =
//     StateNotifierProvider<LiveLocationViewModel, List<TrackedLocation>>(
//       (ref) => LiveLocationViewModel(),
//     );

// class LiveLocationViewModel extends StateNotifier<List<TrackedLocation>> {
//   LiveLocationViewModel() : super([]);

//   final LocationService _locationService = LocationService();
//   final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
//     'live_location',
//   );

//   StreamSubscription<TrackedLocation>? _locationSubscription;
//   Timer? _saveTimer;
//   TrackedLocation? _latestLocation;

//   void startTracking(String userId) {
//     _locationSubscription = _locationService.getLocationStream().listen((
//       location,
//     ) {
//       _latestLocation = location;
//     });

//     _saveTimer = Timer.periodic(Duration(seconds: 30), (_) {
//       if (_latestLocation != null) {
//         _addLocationToFirebase(userId, _latestLocation!);
//         _addToLocalList(_latestLocation!);
//       }
//     });
//   }

//   void stopTracking() {
//     _locationSubscription?.cancel();
//     _saveTimer?.cancel();
//   }

//   void _addToLocalList(TrackedLocation location) {
//     if (state.length >= 10) {
//       state = [...state.sublist(1), location];
//     } else {
//       state = [...state, location];
//     }
//   }

//   void _addLocationToFirebase(String userId, TrackedLocation location) async {
//     final userRef = _dbRef.child(userId).child("locations");

//     DataSnapshot snapshot = await userRef.get();
//     Map<String, dynamic> existing = {};
//     if (snapshot.exists) {
//       existing = Map<String, dynamic>.from(snapshot.value as Map);
//     }

//     if (existing.length >= 10) {
//       final oldestKey = existing.keys.first;
//       await userRef.child(oldestKey).remove();
//     }

//     await userRef.push().set(location.toMap());
//   }
// }
