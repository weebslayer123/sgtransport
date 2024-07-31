class FaultyTrafficLight {
  final String alarmID;
  final String nodeID;
  final int type;
  final String startDate;
  final String? endDate; // Optional as it might be empty
  final String message;

  FaultyTrafficLight({
    required this.alarmID,
    required this.nodeID,
    required this.type,
    required this.startDate,
    this.endDate,
    required this.message,
  });

  factory FaultyTrafficLight.fromJson(Map<String, dynamic> json) {
    return FaultyTrafficLight(
      alarmID: json['AlarmID'] as String,
      nodeID: json['NodeID'] as String,
      type: json['Type'] as int,
      startDate: json['StartDate'] as String,
      endDate: json['EndDate'] as String?,
      message: json['Message'] as String,
    );
  }
}
