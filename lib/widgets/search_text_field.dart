import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_user/test_things/maptestplaces/place_model.dart';
import 'package:random_user/viewmodels/Google_Maps/place_notifier.dart';

class SearchTextField extends ConsumerStatefulWidget {
  final String label;
  final Function(PlaceModel) onPlaceSelected;

  const SearchTextField({
    super.key,
    required this.label,
    required this.onPlaceSelected,
  });

  @override
  ConsumerState<SearchTextField> createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends ConsumerState<SearchTextField> {
  final TextEditingController _controller = TextEditingController();

  void _onSearchChanged(String query) {
    ref.read(placeNotifierProvider.notifier).searchPlaces(query);
  }

  void _useCurrentLocation() async {
    final place =
        await ref.read(placeNotifierProvider.notifier).getCurrentLocation();
    if (place != null) {
      _controller.text = place.displayName;
      widget.onPlaceSelected(place);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = ref.watch(placeNotifierProvider);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  labelText: widget.label,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (widget.label == "From Location")
              IconButton(
                icon: const Icon(Icons.my_location),
                onPressed: _useCurrentLocation,
              ),
          ],
        ),
        suggestions.when(
          data: (places) {
            if (places.isEmpty) return const SizedBox();
            return SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: places.length,
                itemBuilder: (context, index) {
                  final place = places[index];
                  return ListTile(
                    title: Text(place.displayName),
                    onTap: () {
                      _controller.text = place.displayName;
                      widget.onPlaceSelected(place);
                    },
                  );
                },
              ),
            );
          },
          loading:
              () => const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
          error:
              (e, _) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Error: $e"),
              ),
        ),
      ],
    );
  }
}
