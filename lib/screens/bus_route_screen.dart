import 'package:flutter/material.dart';
import '../models/bus_route.dart';
import '../models/bus_stop.dart';
import '../utilities/api_calls.dart';

class BusRouteScreen extends StatefulWidget {
  final String serviceNo;

  const BusRouteScreen({Key? key, required this.serviceNo}) : super(key: key);

  @override
  _BusRouteScreenState createState() => _BusRouteScreenState();
}

class _BusRouteScreenState extends State<BusRouteScreen> {
  List<BusRoute> _busRoutes = [];
  List<BusStop> _busStops = [];
  bool _isLoading = true;
  bool _isForwardDirection = true;

  @override
  void initState() {
    super.initState();
    _fetchBusData();
  }

  Future<void> _fetchBusData() async {
    try {
      List<BusRoute> busRoutes =
          await ApiCalls().fetchBusRoutes(widget.serviceNo);
      List<BusStop> busStops = await _fetchAllBusStops();

      setState(() {
        _busRoutes = busRoutes;
        _busStops = busStops;
        _isLoading = false;
      });

      print('Fetched bus routes: ${_busRoutes.length}');
      for (var route in _busRoutes) {
        print(
            'Bus route: ${route.serviceNo}, Direction: ${route.direction}, Bus Stop: ${route.busStopCode}');
      }
    } catch (e) {
      print('Error fetching bus data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<BusStop>> _fetchAllBusStops() async {
    int skip = 0;
    List<BusStop> busStops = [];

    while (true) {
      List<BusStop> fetchedBusStops =
          await ApiCalls().fetchBusStops(skip: skip);
      if (fetchedBusStops.isEmpty) {
        break;
      }
      busStops.addAll(fetchedBusStops);
      skip += 500;
    }

    return busStops;
  }

  BusStop? _findBusStop(String busStopCode) {
    for (var busStop in _busStops) {
      if (busStop.busStopCode == busStopCode) {
        return busStop;
      }
    }
    return null;
  }

  List<BusRoute> _filterBusRoutesByDirection() {
    int direction = _isForwardDirection ? 1 : 2;
    return _busRoutes
        .where((route) => route.direction == direction.toString())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    List<BusRoute> filteredRoutes = _filterBusRoutesByDirection();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            'Bus Route for ${widget.serviceNo}',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.swap_horiz, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isForwardDirection = !_isForwardDirection;
                });
              },
            ),
          ],
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('images/City Bus Aesthetic.jpeg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              color: Colors.black.withOpacity(0.7),
            ),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredRoutes.isEmpty
                    ? Center(
                        child: Text(
                          'No routes found for service ${widget.serviceNo}',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredRoutes.length,
                        itemBuilder: (context, index) {
                          BusRoute route = filteredRoutes[index];
                          BusStop? busStop = _findBusStop(route.busStopCode);

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${route.busStopCode} - ${busStop?.description ?? 'Unknown'}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.blue[200],
                                    ),
                                  ),
                                  Text(
                                    busStop?.roadName ?? 'Unknown Road',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}
