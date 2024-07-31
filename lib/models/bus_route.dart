class BusRoute {
  final String serviceNo;
  final String operator;
  final int direction;
  final int stopSequence;
  final String busStopCode;
  final double distance;
  final String wdFirstBus;
  final String wdLastBus;
  final String satFirstBus;
  final String satLastBus;
  final String sunFirstBus;
  final String sunLastBus;

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
      serviceNo: json['ServiceNo'],
      operator: json['Operator'],
      direction: json['Direction'],
      stopSequence: json['StopSequence'],
      busStopCode: json['BusStopCode'],
      distance: json['Distance'],
      wdFirstBus: json['WD_FirstBus'],
      wdLastBus: json['WD_LastBus'],
      satFirstBus: json['SAT_FirstBus'],
      satLastBus: json['SAT_LastBus'],
      sunFirstBus: json['SUN_FirstBus'],
      sunLastBus: json['SUN_LastBus'],
    );
  }
}
