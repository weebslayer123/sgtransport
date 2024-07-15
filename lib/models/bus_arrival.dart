class BusArrival {
  String serviceNo;
  List<NextBus> nextBus;

  BusArrival({
    required this.serviceNo,
    required this.nextBus,
  });

  factory BusArrival.fromJson(Map<String, dynamic> json) {
    return BusArrival(
      serviceNo: json['ServiceNo'] as String,
      nextBus: [
        if (json['NextBus'] != null) NextBus.fromJson(json['NextBus']),
        if (json['NextBus2'] != null) NextBus.fromJson(json['NextBus2']),
        if (json['NextBus3'] != null) NextBus.fromJson(json['NextBus3']),
      ],
    );
  }
}

class NextBus {
  String estimatedArrival;
  String load;
  String feature;
  String type;

  NextBus({
    required this.estimatedArrival,
    required this.load,
    required this.feature,
    required this.type,
  });

  factory NextBus.fromJson(Map<String, dynamic> json) {
    return NextBus(
      estimatedArrival: json['EstimatedArrival'] as String,
      load: json['Load'] as String,
      feature: json['Feature'] as String,
      type: json['Type'] as String,
    );
  }

  String computeArrival() {
    if (estimatedArrival != '') {
      var nextBus = DateTime.parse(estimatedArrival);
      var difference = nextBus.difference(DateTime.now()).inMinutes;
      return difference.toString();
    }
    return '';
  }
}
