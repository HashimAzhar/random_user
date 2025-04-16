import 'package:google_maps_flutter/google_maps_flutter.dart';

class CustomMarker {
  final String id;
  final LatLng position;
  final String title;
  final String snippet;

  CustomMarker({
    required this.id,
    required this.position,
    required this.title,
    required this.snippet,
  });
}
