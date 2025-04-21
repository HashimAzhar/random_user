import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:random_user/test_things/maptestplaces/place_model.dart';

class PlaceNotifier extends AsyncNotifier<List<PlaceModel>> {
  late Ref _ref;

  @override
  Future<List<PlaceModel>> build() async {
    _ref = ref;
    return [];
  }

  Future<void> searchPlaces(String query) async {
    if (query.isEmpty) {
      state = const AsyncData([]);
      return;
    }

    state = const AsyncLoading();

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'FlutterApp'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        final places = data.map((e) => PlaceModel.fromJson(e)).toList();
        state = AsyncData(places);
      } else {
        state = AsyncError("Failed to fetch places", StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncError(e.toString(), st);
    }
  }

  Future<PlaceModel?> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${position.latitude}&lon=${position.longitude}&format=json',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'FlutterApp'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PlaceModel(
          displayName: data['display_name'] ?? 'Current Location',
          lat: position.latitude,
          lon: position.longitude,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

final placeNotifierProvider =
    AsyncNotifierProvider<PlaceNotifier, List<PlaceModel>>(
      () => PlaceNotifier(),
    );
