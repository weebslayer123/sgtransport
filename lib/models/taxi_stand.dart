class TaxiStand {
  final String taxiCode;
  final double latitude;
  final double longitude;
  final String bfa;
  final String ownership;
  final String type;
  final String name;

  TaxiStand({
    required this.taxiCode,
    required this.latitude,
    required this.longitude,
    required this.bfa,
    required this.ownership,
    required this.type,
    required this.name,
  });

  factory TaxiStand.fromJson(Map<String, dynamic> json) {
    return TaxiStand(
      taxiCode: json['TaxiCode'] as String,
      latitude: json['Latitude'] as double,
      longitude: json['Longitude'] as double,
      bfa: json['Bfa'] as String,
      ownership: json['Ownership'] as String,
      type: json['Type'] as String,
      name: json['Name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'TaxiCode': taxiCode,
      'Latitude': latitude,
      'Longitude': longitude,
      'Bfa': bfa,
      'Ownership': ownership,
      'Type': type,
      'Name': name,
    };
  }
}
