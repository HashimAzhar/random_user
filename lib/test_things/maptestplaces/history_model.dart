class TravelHistory {
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final String startTime;
  final String endTime;
  final String startAddress;
  final String endAddress;

  TravelHistory({
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.startTime,
    required this.endTime,
    required this.startAddress,
    required this.endAddress,
  });

  factory TravelHistory.fromMap(Map<dynamic, dynamic> map) {
    return TravelHistory(
      startLat: map['startLat'],
      startLng: map['startLng'],
      endLat: map['endLat'],
      endLng: map['endLng'],
      startTime: map['startTime'],
      endTime: map['endTime'],
      startAddress: map['startAddress'],
      endAddress: map['endAddress'],
    );
  }

  Map<String, dynamic> toMap() => {
    'startLat': startLat,
    'startLng': startLng,
    'endLat': endLat,
    'endLng': endLng,
    'startTime': startTime,
    'endTime': endTime,
    'startAddress': startAddress,
    'endAddress': endAddress,
  };
}
