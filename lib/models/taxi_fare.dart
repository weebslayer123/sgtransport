class TaxiFare {
  String origin;
  String dest;
  double fare;
  String date;

  TaxiFare({
    required this.origin,
    required this.dest,
    required this.fare,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'origin': origin,
      'dest': dest,
      'fare': fare,
      'date': date,
    };
  }
}
