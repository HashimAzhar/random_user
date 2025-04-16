import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:random_user/providers/marker_provider.dart';
import 'package:random_user/viewmodels/Google_Maps/map_provider_model.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching the mapLocationProvider
    final locationState = ref.watch(mapLocationProvider);
    final staticMarkers = ref.watch(staticMarkersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Google Maps with Riverpod')),
      body: locationState.when(
        data: (location) {
          // If data is successfully fetched, display the map
          return GoogleMap(
            initialCameraPosition: CameraPosition(target: location, zoom: 14.0),
            markers: {
              Marker(
                markerId: MarkerId('current_location'),
                position: location,
                infoWindow: const InfoWindow(
                  title: 'Current Location',
                  snippet: 'You are here',
                ),
              ),
              ...staticMarkers.map(
                (marker) => Marker(
                  markerId: MarkerId(marker.id),
                  position: marker.position,
                  infoWindow: InfoWindow(
                    title: marker.title,
                    snippet: marker.snippet,
                  ),
                ),
              ),
            },
          );
        },
        loading:
            () => const Center(
              child: CircularProgressIndicator(),
            ), // Show loading indicator while fetching
        error:
            (error, stack) =>
                Center(child: Text('Error: $error')), // Handle error state
      ),
    );
  }
}
