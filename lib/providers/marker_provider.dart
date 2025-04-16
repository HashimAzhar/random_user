import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_user/models/Google_Maps/custom_marker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

final staticMarkersProvider = Provider<List<CustomMarker>>((ref) {
  return [
    CustomMarker(
      id: 'gujrat',
      position: const LatLng(32.573074, 74.100502),
      title: 'Gujrat',
      snippet: 'You are here',
    ),
    CustomMarker(
      id: 'fatupura',
      position: const LatLng(32.568761, 74.083557),
      title: 'Fatupura',
      snippet: 'House',
    ),
  ];
});
