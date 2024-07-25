class TravelTimeSegment {
  final String name;
  final int direction;
  final String farEndPoint;
  final String startPoint;
  final String endPoint;
  final int estTime;

  TravelTimeSegment({
    required this.name,
    required this.direction,
    required this.farEndPoint,
    required this.startPoint,
    required this.endPoint,
    required this.estTime,
  });

  factory TravelTimeSegment.fromJson(Map<String, dynamic> json) {
    return TravelTimeSegment(
      name: json['Name'] as String,
      direction: json['Direction'] as int,
      farEndPoint: json['FarEndPoint'] as String,
      startPoint: json['StartPoint'] as String,
      endPoint: json['EndPoint'] as String,
      estTime: json['EstTime'] as int,
    );
  }
}
