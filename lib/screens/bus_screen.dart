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
      });
    } catch (e) {
      // Handle error, e.g., show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load bus stops: $e')),
      );
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
            // Add widget to display bus arrivals for the selected bus stop
          ] else ...[
            const CircularProgressIndicator(),
            const Text('Loading bus stops...'),
          ],
        ],
      ),
    );
  }
}
