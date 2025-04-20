import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:random_user/viewmodels/Google_Maps/polyline_model.dart';

class GoogleMapWidget extends ConsumerWidget {
  final LatLng location;

  const GoogleMapWidget({Key? key, required this.location}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapState = ref.watch(mapProvider);
    final mapNotifier = ref.read(mapProvider.notifier);

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: location, zoom: 14),
      markers: mapState.markers,
      polygons: mapState.polygons,
      polylines: mapState.polylines,
      onTap: (point) => mapNotifier.addPoint(point, context), // ✅ pass context
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }
}
