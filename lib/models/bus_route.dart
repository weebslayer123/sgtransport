class BusRoute {
  String serviceNo;
  String operator;
  String direction; // Add this line
  int stopSequence;
  String busStopCode;
  String distance;
  String wdFirstBus;
  String wdLastBus;
  String satFirstBus;
  String satLastBus;
  String sunFirstBus;
  String sunLastBus;

  BusRoute({
    required this.serviceNo,
    required this.operator,
    required this.direction, // Add this line
    required this.stopSequence,
    required this.busStopCode,
    required this.distance,
    required this.wdFirstBus,
    required this.wdLastBus,
    required this.satFirstBus,
    required this.satLastBus,
    required this.sunFirstBus,
    required this.sunLastBus,
  });

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    return BusRoute(
      serviceNo: json['ServiceNo'] as String,
      operator: json['Operator'] as String,
      direction: json['Direction'].toString(), // Convert to string
      stopSequence: json['StopSequence'] as int,
      busStopCode: json['BusStopCode'] as String,
      distance: json['Distance'].toString(), // Convert to string
      wdFirstBus: json['WD_FirstBus'].toString(), // Convert to string
      wdLastBus: json['WD_LastBus'].toString(), // Convert to string
      satFirstBus: json['SAT_FirstBus'].toString(), // Convert to string
      satLastBus: json['SAT_LastBus'].toString(), // Convert to string
      sunFirstBus: json['SUN_FirstBus'].toString(), // Convert to string
      sunLastBus: json['SUN_LastBus'].toString(), // Convert to string
    );
  }
}
