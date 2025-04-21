// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:random_user/viewmodels/Google_Maps/location_view_model.dart';

// import 'package:firebase_database/firebase_database.dart';

// // Firebase Database reference for live tracking
// final locationRefProvider = Provider<DatabaseReference>((ref) {
//   return FirebaseDatabase.instance.ref('live_tracking');
// });

// // ViewModel Provider: For managing location-related logic
// final locationViewModelProvider =
//     StateNotifierProvider<LocationViewModel, LocationModel?>((ref) {
//   final locationRef = ref.watch(locationRefProvider);
//   return LocationViewModel(locationRef);
// });
