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

  // Fetch Bus Stops
  Future<List<BusStop>> fetchBusStops() async {
    String baseURL = 'http://datamall2.mytransport.sg/ltaodataservice/BusStops';

    try {
      final response =
          await http.get(Uri.parse(baseURL), headers: requestHeaders);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<BusStop> busStops = (data['value'] as List)
            .map((busStopJson) => BusStop.fromJson(busStopJson))
            .toList();
        return busStops;
      } else {
        print('Failed to load bus stops. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load bus stops');
      }
    } catch (e) {
      print('Exception: $e');
      throw Exception('Failed to load bus stops');
    }
  }

  // Fetch Bus Arrivals
  Future<List<BusArrival>> fetchBusArrivals(String busStopCode) async {
    String baseURL =
        'http://datamall2.mytransport.sg/ltaodataservice/BusArrivalv2?BusStopCode=$busStopCode';

    try {
      final response =
          await http.get(Uri.parse(baseURL), headers: requestHeaders);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<BusArrival> busArrivals = (data['Services'] as List)
            .map((busArrivalJson) => BusArrival.fromJson(busArrivalJson))
            .toList();
        return busArrivals;
      } else {
        print(
            'Failed to load bus arrivals. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load bus arrivals');
      }
    } catch (e) {
      print('Exception: $e');
      throw Exception('Failed to load bus arrivals');
    }
  }

  // Fetch Platform Crowd Density

  Future<List<CrowdDensity>> fetchCrowdDensityBus() async {
    String baseURL =
        'http://datamall2.mytransport.sg/ltaodataservice/PCDRealTime';

    try {
      final response =
          await http.get(Uri.parse(baseURL), headers: requestHeaders);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<CrowdDensity> crowdDensities = (data['value'] as List)
            .map((crowdDensityJson) => CrowdDensity.fromJson(crowdDensityJson))
            .toList();
        return crowdDensities;
      } else {
        print(
            'Failed to load crowd densities. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load crowd densities');
      }
    } catch (e) {
      print('Exception: $e');
      throw Exception('Failed to load crowd densities');
    }
  }

  // Refer to 2.25 Platform Crowd Density
  Future<List<CrowdDensity>> fetchCrowdDensity(String trainLine) async {
    String baseURL =
        'http://datamall2.mytransport.sg/ltaodataservice/PCDRealTime';
    final response = await http.get(
      Uri.parse('$baseURL?TrainLine=$trainLine'),
      headers: requestHeaders,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<CrowdDensity> crowdDensityList = (data['value'] as List)
          .map((crowdDensityJson) => CrowdDensity.fromJson(crowdDensityJson))
          .toList();
      return crowdDensityList;
    } else {
      print('Failed to load crowd density data: ${response.body}');
      throw Exception('Failed to load crowd density data');
    }
  }

  // Fetch Taxi Stands
  Future<List<TaxiStand>> fetchTaxiStands() async {
    try {
      final response = await http.get(
        Uri.parse('http://datamall2.mytransport.sg/ltaodataservice/TaxiStands'),
        headers: requestHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['value'];
        return data.map((item) => TaxiStand.fromJson(item)).toList();
      } else {
        print(
            'Failed to load taxi stands. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load taxi stands');
      }
    } catch (e) {
      print('Exception: $e');
      throw Exception('Failed to load taxi stands');
    }
  }
}
