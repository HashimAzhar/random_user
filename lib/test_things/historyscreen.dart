import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:random_user/test_things/maptestplaces/mapwith_history_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late DatabaseReference _historyRef;
  List<Map<String, dynamic>> _historyList = [];
  final String _userId = 'sampleUserId'; // Replace with actual user ID

  StreamSubscription<DatabaseEvent>? _historySubscription;

  @override
  void initState() {
    super.initState();
    _historyRef = FirebaseDatabase.instance.ref('location_history/$_userId');
    _fetchHistory();
  }

  @override
  void dispose() {
    _historySubscription?.cancel();
    super.dispose();
  }

  void _fetchHistory() {
    _historySubscription = _historyRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) {
        setState(() => _historyList = []);
        return;
      }

      final List<Map<String, dynamic>> loadedTrips = [];

      data.forEach((key, value) {
        final tripData = value as Map<dynamic, dynamic>;
        loadedTrips.add({
          'id': key,
          'start_location': tripData['start_location'],
          'end_location': tripData['end_location'],
          'start_address': tripData['start_address'],
          'end_address': tripData['end_address'],
          'distance': tripData['distance'],
          'duration': tripData['duration'],
          'timestamp': tripData['timestamp'],
          'route_points':
              (tripData['route_points'] as List<dynamic>?)
                  ?.map(
                    (item) => LatLng(
                      (item as Map)['lat'] as double,
                      (item as Map)['lng'] as double,
                    ),
                  )
                  .toList() ??
              [],
        });
      });

      loadedTrips.sort(
        (a, b) =>
            (b['timestamp'] as String).compareTo(a['timestamp'] as String),
      );
      setState(() => _historyList = loadedTrips);
    });
  }

  void _selectTrip(Map<String, dynamic> trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MapScreenFromHistory(
              startLocation: LatLng(
                trip['start_location']['lat'] as double,
                trip['start_location']['lng'] as double,
              ),
              endLocation: LatLng(
                trip['end_location']['lat'] as double,
                trip['end_location']['lng'] as double,
              ),
              startAddress: trip['start_address'] as String,
              endAddress: trip['end_address'] as String,
              distance: trip['distance'] as String,
              duration: trip['duration'] as String,
              routePoints: trip['route_points'] as List<LatLng>,
            ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Journey History')),
      body:
          _historyList.isEmpty
              ? const Center(child: Text('No history available'))
              : ListView.builder(
                itemCount: _historyList.length,
                itemBuilder: (context, index) {
                  final trip = _historyList[index];
                  final startLatLng = LatLng(
                    trip['start_location']['lat'] as double,
                    trip['start_location']['lng'] as double,
                  );
                  final endLatLng = LatLng(
                    trip['end_location']['lat'] as double,
                    trip['end_location']['lng'] as double,
                  );

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'From: ${trip['start_address']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'To: ${trip['end_address']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Distance: ${trip['distance']}'),
                          Text('Duration: ${trip['duration']} minutes'),
                          Text('Date: ${_formatDate(trip['timestamp'])}'),
                        ],
                      ),
                      onTap: () => _selectTrip(trip),
                    ),
                  );
                },
              ),
    );
  }
}
