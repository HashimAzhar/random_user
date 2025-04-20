import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PlaceSearchScreen extends StatefulWidget {
  const PlaceSearchScreen({super.key});

  @override
  State<PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends State<PlaceSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _places = [];

  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() => _places = []);
      return;
    }

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&countrycodes=pk&format=json',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'FlutterApp', // Nominatim requires a custom User-Agent
        },
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _places = data.map<Map<String, dynamic>>((item) => item).toList();
        });
      } else {
        print("Failed to fetch data");
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _onPlaceTap(Map<String, dynamic> place) {
    print("Selected: ${place['display_name']}");
    // you can use: place['lat'], place['lon'], place['display_name']
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Place Search")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: "Search a place",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _places.length,
                itemBuilder: (context, index) {
                  final place = _places[index];
                  return ListTile(
                    title: Text(place['display_name']),
                    onTap: () => _onPlaceTap(place),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
