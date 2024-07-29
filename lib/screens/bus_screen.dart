import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
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
    _fetchAllBusStops();
  }

  Future<void> _fetchAllBusStops() async {
    int skip = 0;
    List<BusStop> busStops = [];

    while (true) {
      List<BusStop> fetchedBusStops = await _fetchBusStops(skip);
      if (fetchedBusStops.isEmpty) {
        break;
      }
      busStops.addAll(fetchedBusStops);
      skip += 500;
    }

    setState(() {
      _allBusStops = busStops;
    });
    _findNearestBusStop();
  }

  Future<List<BusStop>> _fetchBusStops(int skip) async {
    try {
      List<BusStop> busStops = await ApiCalls().fetchBusStops(skip: skip);
      return busStops;
    } catch (e) {
      print('Error fetching bus stops: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load bus stops: $e')),
      );
      return [];
    }
  }

  Future<void> _findNearestBusStop() async {
    try {
      Position position = await _determinePosition();
      print('User location: ${position.latitude}, ${position.longitude}');
      BusStop? nearestBusStop;
      double nearestDistance = double.infinity;

      for (var busStop in _allBusStops) {
        double distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          busStop.latitude,
          busStop.longitude,
        );
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestBusStop = busStop;
        }
      }

      if (nearestBusStop != null) {
        print('Nearest bus stop: ${nearestBusStop.description}');
        setState(() {
          _selectedBusStop = nearestBusStop;
        });
        _fetchBusArrivals(nearestBusStop);
      }
    } catch (e) {
      print('Error finding nearest bus stop: $e');
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied');
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
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

  Widget _buildBusIcon(String type) {
    String assetName;
    switch (type) {
      case 'SD':
        assetName = 'images/single_decker.png';
        break;
      case 'DD':
        assetName = 'images/double_decker.png';
        break;
      case 'BD':
        assetName = 'images/bendy_bus.png';
        break;
      default:
        return SizedBox.shrink(); // Return an empty widget if type is unknown
    }
    return Image.asset(assetName, width: 24, height: 24);
  }

  Widget _buildWheelchairIcon(String feature) {
    if (feature == 'WAB') {
      return Image.asset('images/wheelchair.png', width: 24, height: 24);
    }
    return SizedBox.shrink();
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Autocomplete<BusStop>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<BusStop>.empty();
                    }
                    return _allBusStops.where((BusStop busStop) {
                      return busStop.description
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase()) ||
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
              if (_selectedBusStop != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_selectedBusStop!.busStopCode} - ${_selectedBusStop!.description}',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        Text(
                          _selectedBusStop!.roadName,
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
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
                      return Card(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                arrival.serviceNo,
                                style: TextStyle(
                                    fontSize: 20, color: Colors.purple),
                              ),
                              ...arrival.nextBus.map((NextBus nextBus) {
                                return Column(
                                  children: [
                                    Text(
                                      'Arriving: ${nextBus.computeArrival()} min',
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.orange),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Load: ${nextBus.getLoadDescription()}',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black),
                                        ),
                                        SizedBox(width: 8),
                                        _buildBusIcon(nextBus.type),
                                        SizedBox(width: 8),
                                        _buildWheelchairIcon(nextBus.feature),
                                      ],
                                    ),
                                  ],
                                );
                              }).toList(),
                            ],
                          ),
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
            ],
          ),
        ),
        bottomNavigationBar: MyBottomNavigationBar(selectedIndexNavBar: 0),
      ),
    );
  }
}
