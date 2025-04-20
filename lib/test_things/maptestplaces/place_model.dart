class PlaceModel {
  final String displayName;
  final double lat;
  final double lon;

  PlaceModel({required this.displayName, required this.lat, required this.lon});

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      displayName: json['display_name'],
      lat:
          json['lat'] is String
              ? double.parse(json['lat'])
              : json['lat'].toDouble(),
      lon:
          json['lon'] is String
              ? double.parse(json['lon'])
              : json['lon'].toDouble(),
    );
  }
}
