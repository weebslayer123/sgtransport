class BusRoute {
  String serviceNo;
  String operator;
  String direction;
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
    required this.direction,
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
      direction: json['Direction'].toString(),
      stopSequence: json['StopSequence'] as int,
      busStopCode: json['BusStopCode'] as String,
      distance: json['Distance'].toString(),
      wdFirstBus: json['WD_FirstBus'].toString(),
      wdLastBus: json['WD_LastBus'].toString(),
      satFirstBus: json['SAT_FirstBus'].toString(),
      satLastBus: json['SAT_LastBus'].toString(),
      sunFirstBus: json['SUN_FirstBus'].toString(),
      sunLastBus: json['SUN_LastBus'].toString(),
    );
  }
}
