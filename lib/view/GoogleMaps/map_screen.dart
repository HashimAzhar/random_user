import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_user/viewmodels/Google_Maps/map_provider_model.dart';
import 'package:random_user/widgets/google_map_widget.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(mapLocationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Polygon Drawing Map')),
      body: locationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (location) => GoogleMapWidget(location: location),
      ),
    );
  }
}
