import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'place_model.dart';

class SearchTextField extends StatefulWidget {
  final String label;
  final Function(PlaceModel) onPlaceSelected;

  const SearchTextField({
    super.key,
    required this.label,
    required this.onPlaceSelected,
  });

  @override
  State<SearchTextField> createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends State<SearchTextField> {
  final TextEditingController _controller = TextEditingController();
  List<PlaceModel> _suggestions = [];

  // This method handles the search logic
  void _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json',
    );

    final response = await http.get(url, headers: {'User-Agent': 'FlutterApp'});

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        _suggestions = data.map((e) => PlaceModel.fromJson(e)).toList();
      });
    }
  }

  // This method selects a place from suggestions
  void _selectPlace(PlaceModel place) {
    _controller.text = place.displayName;
    setState(() => _suggestions = []); // Hide suggestions after selecting
    widget.onPlaceSelected(place);
  }

  // This method uses current location
  Future<void> _useCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('Location permission denied');
        return;
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
        final place = PlaceModel(
          displayName: data['display_name'] ?? 'Current Location',
          lat: position.latitude,
          lon: position.longitude,
        );

        _selectPlace(place); // Select the current location after fetching it
      } else {
        print('Failed to reverse geocode location');
      }
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged:
                    _searchPlaces, // This triggers the search when text changes
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
                onPressed:
                    _useCurrentLocation, // This triggers fetching current location
              ),
          ],
        ),
        if (_suggestions.isNotEmpty)
          Container(
            height: 200,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final place = _suggestions[index];
                return ListTile(
                  title: Text(place.displayName),
                  onTap: () => _selectPlace(place),
                );
              },
            ),
          ),
      ],
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:random_user/viewmodels/Google_Maps/place_search_view_model.dart';

// class SearchPlacesScreen extends ConsumerWidget {
//   final String label;
//   const SearchPlacesScreen({super.key, required this.label});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final controller = TextEditingController();
//     final state = ref.watch(placeSearchProvider);
//     final notifier = ref.read(placeSearchProvider.notifier);

//     return Scaffold(
//       appBar: AppBar(title: Text('Search $label')),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: TextField(
//               controller: controller,
//               decoration: InputDecoration(
//                 hintText: 'Enter place name',
//                 suffixIcon: IconButton(
//                   icon: const Icon(Icons.search),
//                   onPressed: () {
//                     if (controller.text.isNotEmpty) {
//                       notifier.search(controller.text);
//                     }
//                   },
//                 ),
//               ),
//             ),
//           ),
//           if (state.isLoading)
//             const CircularProgressIndicator()
//           else
//             Expanded(
//               child: ListView.builder(
//                 itemCount: state.results.length,
//                 itemBuilder: (context, index) {
//                   final place = state.results[index];
//                   return ListTile(
//                     title: Text('${place.lat}, ${place.lon}'),
//                     onTap: () => Navigator.pop(context, place),
//                   );
//                 },
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
