import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:random_user/models/Google_Maps/place_model.dart';

class PlaceSearchState {
  final bool isLoading;
  final List<PlaceModel> results;

  PlaceSearchState({this.isLoading = false, this.results = const []});

  PlaceSearchState copyWith({bool? isLoading, List<PlaceModel>? results}) {
    return PlaceSearchState(
      isLoading: isLoading ?? this.isLoading,
      results: results ?? this.results,
    );
  }
}

class PlaceSearchNotifier extends StateNotifier<PlaceSearchState> {
  PlaceSearchNotifier() : super(PlaceSearchState());

  Future<void> search(String query) async {
    state = state.copyWith(isLoading: true, results: []);
    try {
      final locations = await locationFromAddress(query);
      final places =
          locations.map((loc) {
            return PlaceModel(
              displayName: query,
              lat: loc.latitude,
              lon: loc.longitude,
            );
          }).toList();
      state = state.copyWith(isLoading: false, results: places);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final placeSearchProvider =
    StateNotifierProvider<PlaceSearchNotifier, PlaceSearchState>(
      (ref) => PlaceSearchNotifier(),
    );
