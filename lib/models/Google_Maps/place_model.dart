class PlaceModel {
  final String displayName;
  final double lat;
  final double lon;

  PlaceModel({required this.displayName, required this.lat, required this.lon});

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      displayName: json['display_name'],
      lat: double.tryParse(json['lat'].toString()) ?? 0.0,
      lon: double.tryParse(json['lon'].toString()) ?? 0.0,
    );
  }
}
