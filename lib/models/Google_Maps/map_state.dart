import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:random_user/models/Google_Maps/place_model.dart';

class MapState {
  final GoogleMapController? controller;
  final LatLng? currentPosition;
  final PlaceModel? fromPlace;
  final PlaceModel? toPlace;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final String distanceText;
  final List<LatLng> fullRoute;
  final int coveredPointIndex;
  final bool tracking;
  final bool tripInProgress;

  MapState({
    this.controller,
    this.currentPosition,
    this.fromPlace,
    this.toPlace,
    this.markers = const {},
    this.polylines = const {},
    this.distanceText = '',
    this.fullRoute = const [],
    this.coveredPointIndex = 0,
    this.tracking = false,
    this.tripInProgress = false,
  });

  MapState copyWith({
    GoogleMapController? controller,
    LatLng? currentPosition,
    PlaceModel? fromPlace,
    PlaceModel? toPlace,
    Set<Marker>? markers,
    Set<Polyline>? polylines,
    String? distanceText,
    List<LatLng>? fullRoute,
    int? coveredPointIndex,
    bool? tracking,
    bool? tripInProgress,
  }) {
    return MapState(
      controller: controller ?? this.controller,
      currentPosition: currentPosition ?? this.currentPosition,
      fromPlace: fromPlace ?? this.fromPlace,
      toPlace: toPlace ?? this.toPlace,
      markers: markers ?? this.markers,
      polylines: polylines ?? this.polylines,
      distanceText: distanceText ?? this.distanceText,
      fullRoute: fullRoute ?? this.fullRoute,
      coveredPointIndex: coveredPointIndex ?? this.coveredPointIndex,
      tracking: tracking ?? this.tracking,
      tripInProgress: tripInProgress ?? this.tripInProgress,
    );
  }
}
