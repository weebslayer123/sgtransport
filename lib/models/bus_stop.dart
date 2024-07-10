class BusStop {
  String busStopCode;
  String roadName;
  String description;
  double latitude;
  double longitude;

  BusStop({
    required this.busStopCode,
    required this.roadName,
    required this.description,
    required this.latitude,
    required this.longitude,
  });

  // Implementing BusStop.fromJson
  factory BusStop.fromJson(Map<String, dynamic> json) {
    return BusStop(
      busStopCode: json['BusStopCode'] as String,
      roadName: json['RoadName'] as String,
      description: json['Description'] as String,
      latitude: json['Latitude'] as double,
      longitude: json['Longitude'] as double,
    );
  }
}
