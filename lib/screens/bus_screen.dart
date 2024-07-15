import 'package:flutter/material.dart';
import '../utilities/api_calls.dart';
import '../utilities/firebase_calls.dart';
import '../utilities/my_url_launcher.dart';
import '../models/bus_arrival.dart';
import '../models/bus_stop.dart';
import '../widgets/navigation_bar.dart';

class BusScreen extends StatefulWidget {
  const BusScreen({super.key});

  @override
  State<BusScreen> createState() => _BusScreenState();
}

class _BusScreenState extends State<BusScreen> {
  List<BusStop> _allBusStops = [];
  BusStop? _selectedBusStop;
  List<BusArrival> _busArrivals = [];
  bool _isLoadingArrivals = false;

  @override
  void initState() {
    super.initState();
    _fetchBusStops();
  }

  Future<void> _fetchBusStops() async {
    try {
      List<BusStop> busStops = await ApiCalls().fetchBusStops();
      setState(() {
        _allBusStops = busStops;
        _selectedBusStop = busStops.isNotEmpty ? busStops[0] : null;
        if (_selectedBusStop != null) {
          _fetchBusArrivals(_selectedBusStop!);
        }
      });
    } catch (e) {
      print('Error fetching bus stops: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load bus stops: $e')),
      );
    }
  }

  Future<void> _fetchBusArrivals(BusStop busStop) async {
    setState(() {
      _isLoadingArrivals = true;
    });
    try {
      List<BusArrival> busArrivals =
          await ApiCalls().fetchBusArrivals(busStop.busStopCode);
      setState(() {
        _busArrivals = busArrivals;
      });
    } catch (e) {
      print('Error fetching bus arrivals: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load bus arrivals: $e')),
      );
    } finally {
      setState(() {
        _isLoadingArrivals = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Arrival'),
        actions: [
          IconButton(
            onPressed: () {
              auth.signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      bottomNavigationBar: MyBottomNavigationBar(selectedIndexNavBar: 0),
      body: Column(
        children: [
          Text('Hello ${auth.currentUser?.displayName}'),
          if (_allBusStops.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButton<BusStop>(
                value: _selectedBusStop,
                onChanged: (BusStop? newValue) {
                  setState(() {
                    _selectedBusStop = newValue;
                    if (newValue != null) {
                      _fetchBusArrivals(newValue);
                    }
                  });
                },
                items: _allBusStops
                    .map<DropdownMenuItem<BusStop>>((BusStop busStop) {
                  return DropdownMenuItem<BusStop>(
                    value: busStop,
                    child: Text(busStop.description),
                  );
                }).toList(),
              ),
            ),
            if (_isLoadingArrivals) ...[
              const CircularProgressIndicator(),
              const Text('Loading bus arrivals...'),
            ] else ...[
              Expanded(
                child: ListView.builder(
                  itemCount: _busArrivals.length,
                  itemBuilder: (context, index) {
                    BusArrival arrival = _busArrivals[index];
                    return ListTile(
                      title: Text('Service No: ${arrival.serviceNo}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: arrival.nextBus.map((NextBus nextBus) {
                          return Text(
                              'Next Bus: ${nextBus.computeArrival()} mins, Load: ${nextBus.load}');
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ] else ...[
            const CircularProgressIndicator(),
            const Text('Loading bus stops...'),
          ],
        ],
      ),
    );
  }
}
