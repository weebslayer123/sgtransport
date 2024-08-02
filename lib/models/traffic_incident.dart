// traffic_incident.dart

class TrafficIncident {
  final String type;
  final double latitude;
  final double longitude;
  final String message;

  TrafficIncident({
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.message,
  });

  factory TrafficIncident.fromJson(Map<String, dynamic> json) {
    return TrafficIncident(
      type: json['Type'] ?? '',
      latitude: double.tryParse(json['Latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['Longitude'].toString()) ?? 0.0,
      message: json['Message'] ?? '',
    );
  }
}
