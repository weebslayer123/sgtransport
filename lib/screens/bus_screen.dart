import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utilities/api_calls.dart';
import '../models/bus_arrival.dart';
import '../models/bus_stop.dart';
import '../widgets/navigation_bar.dart';
import 'bus_route_screen.dart';
import 'bus_bookmark.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final FirebaseAuth auth = FirebaseAuth.instance;
  List<String> _bookmarkedBusStops = [];
  List<String> _bookmarkedBusNumbers = [];

  @override
  void initState() {
    super.initState();
    _fetchAllBusStops();
    _loadBookmarks();
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
        return SizedBox.shrink();
    }
    return Image.asset(assetName, width: 24, height: 24);
  }

  Widget _buildWheelchairIcon(String feature) {
    if (feature == 'WAB') {
      return Image.asset('images/wheelchair.png', width: 24, height: 24);
    }
    return SizedBox.shrink();
  }

  Color _getLoadColor(String load) {
    switch (load) {
      case 'Seats Available':
        return Colors.green;
      case 'Standing Available':
        return Colors.yellow;
      case 'Limited Standing':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  Future<void> _loadBookmarks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _bookmarkedBusStops = prefs.getStringList('bookmarkedBusStops') ?? [];
      _bookmarkedBusNumbers = prefs.getStringList('bookmarkedBusNumbers') ?? [];
    });
  }

  Future<void> _saveBookmarks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('bookmarkedBusStops', _bookmarkedBusStops);
    await prefs.setStringList('bookmarkedBusNumbers', _bookmarkedBusNumbers);
  }

  void _toggleBusStopBookmark(BusStop busStop) {
    setState(() {
      if (_bookmarkedBusStops.contains(busStop.busStopCode)) {
        _bookmarkedBusStops.remove(busStop.busStopCode);
      } else {
        _bookmarkedBusStops.add(busStop.busStopCode);
      }
    });
    _saveBookmarks();
  }

  void _toggleBusNumberBookmark(String busNumber) {
    setState(() {
      if (_bookmarkedBusNumbers.contains(busNumber)) {
        _bookmarkedBusNumbers.remove(busNumber);
      } else {
        _bookmarkedBusNumbers.add(busNumber);
      }
    });
    _saveBookmarks();
  }

  bool _isBusStopBookmarked(BusStop busStop) {
    return _bookmarkedBusStops.contains(busStop.busStopCode);
  }

  bool _isBusNumberBookmarked(String busNumber) {
    return _bookmarkedBusNumbers.contains(busNumber);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title:
              const Text('Bus Arrival', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.bookmark),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BusBookmarkScreen(
                      bookmarkedBusStops: _bookmarkedBusStops,
                      bookmarkedBusNumbers: _bookmarkedBusNumbers,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              onPressed: () {
                auth.signOut();
                Navigator.pushReplacementNamed(context, '/');
              },
              icon: const Icon(Icons.logout),
            ),
          ],
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
            Column(
              children: [
                SizedBox(height: 80.0),
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
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.5),
                          hintText: 'Search Bus Stop',
                          hintStyle: TextStyle(color: Colors.white),
                          border: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.white, width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.white, width: 2.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.white, width: 2.0),
                          ),
                          prefixIcon: Icon(Icons.search, color: Colors.white),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.clear, color: Colors.white),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _selectedBusStop = null;
                                _busArrivals = [];
                              });
                            },
                          ),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_selectedBusStop!.busStopCode} - ${_selectedBusStop!.description}',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                              IconButton(
                                icon: Icon(
                                  _isBusStopBookmarked(_selectedBusStop!)
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  _toggleBusStopBookmark(_selectedBusStop!);
                                },
                              ),
                            ],
                          ),
                          Text(
                            _selectedBusStop!.roadName,
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_isLoadingArrivals) ...[
                  const CircularProgressIndicator(),
                  const Text('Loading bus arrivals...',
                      style: TextStyle(color: Colors.white)),
                ] else ...[
                  Expanded(
                    child: ListView.builder(
                      itemCount: _busArrivals.length,
                      itemBuilder: (context, index) {
                        BusArrival arrival = _busArrivals[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                  children: [
                                    Center(
                                      child: Text(
                                        arrival.serviceNo,
                                        style: TextStyle(
                                            fontSize: 20, color: Colors.purple),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      child: IconButton(
                                        icon: Icon(
                                          _isBusNumberBookmarked(
                                                  arrival.serviceNo)
                                              ? Icons.bookmark
                                              : Icons.bookmark_border,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          _toggleBusNumberBookmark(
                                              arrival.serviceNo);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BusRouteScreen(
                                            serviceNo: arrival.serviceNo),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text('View Route'),
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
                                                color: _getLoadColor(nextBus
                                                    .getLoadDescription())),
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
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ],
        ),
        bottomNavigationBar: MyBottomNavigationBar(selectedIndexNavBar: 0),
      ),
    );
  }
}
