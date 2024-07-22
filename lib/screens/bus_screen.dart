import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
  TextEditingController _searchController = TextEditingController();

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

  Future<void> _launchMap(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Bus Arrival',
              style: TextStyle(
                  color: Colors.white)), // Set AppBar text color to white
          backgroundColor: Colors.black, // Set AppBar background color to black
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
        body: Container(
          color: Colors.black, // Set background color to black
          child: Column(
            children: [
              Text(
                'Hello ${auth.currentUser?.displayName}',
                style:
                    TextStyle(color: Colors.white), // Set text color to white
              ),
              if (_allBusStops.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Autocomplete<BusStop>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<BusStop>.empty();
                      }
                      return _allBusStops.where((BusStop busStop) {
                        return busStop.description.toLowerCase().contains(
                                textEditingValue.text.toLowerCase()) ||
                            busStop.roadName
                                .toLowerCase()
                                .contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    displayStringForOption: (BusStop option) =>
                        option.description,
                    onSelected: (BusStop selection) {
                      setState(() {
                        _selectedBusStop = selection;
                        _fetchBusArrivals(selection);
                      });
                    },
                    fieldViewBuilder: (BuildContext context,
                        TextEditingController fieldTextEditingController,
                        FocusNode fieldFocusNode,
                        VoidCallback onFieldSubmitted) {
                      _searchController = fieldTextEditingController;
                      return TextField(
                        controller: fieldTextEditingController,
                        focusNode: fieldFocusNode,
                        style: TextStyle(
                            color: Colors.white), // Set text color to white
                        decoration: InputDecoration(
                          labelText: 'Search Bus Stop',
                          labelStyle: TextStyle(
                              color: Colors
                                  .white70), // Set label text color to white
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                  ),
                ),
                if (_isLoadingArrivals) ...[
                  const CircularProgressIndicator(),
                  const Text('Loading bus arrivals...',
                      style: TextStyle(
                          color: Colors.white)), // Set text color to white
                ] else ...[
                  Expanded(
                    child: ListView.builder(
                      itemCount: _busArrivals.length,
                      itemBuilder: (context, index) {
                        BusArrival arrival = _busArrivals[index];
                        return ListTile(
                          title: Text('Service No: ${arrival.serviceNo}',
                              style: TextStyle(
                                  color:
                                      Colors.white)), // Set text color to white
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: arrival.nextBus.map((NextBus nextBus) {
                              return Text(
                                  'Next Bus: ${nextBus.computeArrival()} mins, Load: ${nextBus.load}',
                                  style: TextStyle(
                                      color: Colors
                                          .white)); // Set text color to white
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_selectedBusStop != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          _launchMap(
                            _selectedBusStop!.latitude,
                            _selectedBusStop!.longitude,
                          );
                        },
                        child: Text('Show Map'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue, // Set button color
                          foregroundColor: Colors.white, // Set text color
                        ),
                      ),
                    ),
                ],
              ] else ...[
                const CircularProgressIndicator(),
                const Text('Loading bus stops...',
                    style: TextStyle(
                        color: Colors.white)), // Set text color to white
              ],
            ],
          ),
        ),
        bottomNavigationBar: MyBottomNavigationBar(selectedIndexNavBar: 0),
      ),
    );
  }
}
