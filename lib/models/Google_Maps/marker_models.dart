import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

@immutable
class MapMarker {
  final String id;
  final LatLng position;
  final String? title;
  final String? snippet;

  const MapMarker({
    required this.id,
    required this.position,
    this.title,
    this.snippet,
  });

  MapMarker copyWith({
    String? id,
    LatLng? position,
    String? title,
    String? snippet,
  }) {
    return MapMarker(
      id: id ?? this.id,
      position: position ?? this.position,
      title: title ?? this.title,
      snippet: snippet ?? this.snippet,
    );
  }
}
