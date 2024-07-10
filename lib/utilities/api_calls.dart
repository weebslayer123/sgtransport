import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bus_arrival.dart';
import '../models/bus_stop.dart';
import '../models/train_crowd_density.dart';
import '../models/taxi_stand.dart';

class ApiCalls {
  Map<String, String> requestHeaders = {
    'Accept': 'application/json',
    'AccountKey': 'SEijCWZMTeezw0/HAUyKOw==', // Updated API Key
  };

  // Refer to 2.4 Bus Stops
  Future<List<BusStop>> fetchBusStops() async {
    String baseURL = 'http://datamall2.mytransport.sg/ltaodataservice/BusStops';

    final response =
        await http.get(Uri.parse(baseURL), headers: requestHeaders);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<BusStop> busStops = (data['value'] as List)
          .map((busStopJson) => BusStop.fromJson(busStopJson))
          .toList();
      return busStops;
    } else {
      throw Exception('Failed to load bus stops');
    }
  }

  // Refer to 2.1 Bus Arrival
  void fetchBusArrival() {
    // TODO return List<BusArrival>
  }

  // Refer to 2.25 Platform Crowd Density
  void fetchCrowdDensity() {
    // TODO return List<CrowdDensity>
  }

  // Refer to 2.10 Taxi Stands
  List<TaxiStand> fetchTaxiStands() {
    // TODO return List<TaxiStand>
    return [];
  }
}
