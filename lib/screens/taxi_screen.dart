import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utilities/api_calls.dart';
import '../models/taxi_stand.dart';
import '../widgets/navigation_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/edit_taxi_fare_screen.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'taxi_bookmark.dart';

class TaxiScreen extends StatefulWidget {
  const TaxiScreen({Key? key}) : super(key: key);

  @override
  _TaxiScreenState createState() => _TaxiScreenState();
}

class _TaxiScreenState extends State<TaxiScreen> {
  List<TaxiStand>? _allTaxiStands = [];
  TaxiStand? _selectedTaxiStand;
  final ApiCalls _apiCalls = ApiCalls();
  final FirebaseAuth auth = FirebaseAuth.instance;
  String _selectedSortOption =
      'Date (Oldest to Newest)'; // Default sorting option
  List<String> bookmarkedTaxiStands = []; // Add this line

  @override
  void initState() {
    super.initState();
    fetchTaxiStands();
    _loadBookmarkedStands(); // Add this line
  }

  Future<void> _loadBookmarkedStands() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      bookmarkedTaxiStands = prefs.getStringList('bookmarkedTaxiStands') ?? [];
    });
  }

  Future<void> fetchTaxiStands() async {
    try {
      final stands = await _apiCalls.fetchTaxiStands();
      setState(() {
        _allTaxiStands = stands;
      });
    } catch (e) {
      print('Error fetching taxi stands: $e');
    }
  }

  Future<void> _launchMap(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  Stream<double> getTotalFareStream() {
    return FirebaseFirestore.instance
        .collection('fares')
        .snapshots()
        .map((snapshot) {
      double total = 0.0;
      for (var doc in snapshot.docs) {
        total += doc['fare'] is int ? doc['fare'].toDouble() : doc['fare'];
      }
      return total;
    });
  }

  Future<void> _deleteFare(DocumentSnapshot fare) async {
    await FirebaseFirestore.instance.collection('fares').doc(fare.id).delete();
  }

  void _showDeleteDialog(BuildContext context, DocumentSnapshot fare) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Fare', style: TextStyle(color: Colors.white)),
          content: Text('Are you sure you want to delete this fare?',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _deleteFare(fare);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  List<QueryDocumentSnapshot> _sortFares(List<QueryDocumentSnapshot> fares) {
    switch (_selectedSortOption) {
      case 'Date (Oldest to Newest)':
        fares.sort((a, b) => DateFormat('dd/MM/yyyy')
            .parse(a['date'])
            .compareTo(DateFormat('dd/MM/yyyy').parse(b['date'])));
        break;
      case 'Date (Newest to Oldest)':
        fares.sort((a, b) => DateFormat('dd/MM/yyyy')
            .parse(b['date'])
            .compareTo(DateFormat('dd/MM/yyyy').parse(a['date'])));
        break;
      case 'Fare (Cheapest to Most Expensive)':
        fares.sort((a, b) => (a['fare'] as num).compareTo(b['fare'] as num));
        break;
      case 'Fare (Most Expensive to Cheapest)':
        fares.sort((a, b) => (b['fare'] as num).compareTo(a['fare'] as num));
        break;
      case 'Origin (A to Z)':
        fares.sort(
            (a, b) => (a['origin'] as String).compareTo(b['origin'] as String));
        break;
      case 'Origin (Z to A)':
        fares.sort(
            (a, b) => (b['origin'] as String).compareTo(a['origin'] as String));
        break;
    }
    return fares;
  }

  Future<void> _toggleBookmark(TaxiStand stand) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> bookmarkedStands =
        prefs.getStringList('bookmarkedTaxiStands') ?? [];
    if (bookmarkedStands.contains(stand.name)) {
      bookmarkedStands.remove(stand.name);
    } else {
      bookmarkedStands.add(stand.name);
    }
    await prefs.setStringList('bookmarkedTaxiStands', bookmarkedStands);
    setState(() {
      bookmarkedTaxiStands = bookmarkedStands;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true, // Extend body behind AppBar
        appBar: AppBar(
          title: const Text('Taxi', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.bookmark, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookmarksScreen(
                      bookmarkedTaxiStands: bookmarkedTaxiStands,
                      allTaxiStands: _allTaxiStands ?? [],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('images/taxi.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              color: Colors.black.withOpacity(
                  0.7), // To make sure text is visible over the background
            ),
            Column(
              children: [
                SizedBox(height: 80.0), // Adjust the height as needed
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          'Hello ${auth.currentUser?.displayName}',
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(height: 8.0), // Adjusted the spacing here
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black
                                .withOpacity(0.5), // Dark background
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Autocomplete<TaxiStand>(
                            optionsBuilder:
                                (TextEditingValue textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return const Iterable<TaxiStand>.empty();
                              }
                              return _allTaxiStands!.where((TaxiStand stand) {
                                return stand.name.toLowerCase().contains(
                                    textEditingValue.text.toLowerCase());
                              });
                            },
                            displayStringForOption: (TaxiStand option) =>
                                option.name,
                            onSelected: (TaxiStand selection) {
                              setState(() {
                                _selectedTaxiStand = selection;
                              });
                            },
                            fieldViewBuilder: (BuildContext context,
                                TextEditingController textEditingController,
                                FocusNode focusNode,
                                VoidCallback onFieldSubmitted) {
                              return TextField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Search Taxi Stand',
                                  hintStyle: TextStyle(color: Colors.white70),
                                  border: InputBorder.none,
                                  prefixIcon:
                                      Icon(Icons.search, color: Colors.white),
                                  suffixIcon: IconButton(
                                    icon:
                                        Icon(Icons.clear, color: Colors.white),
                                    onPressed: () {
                                      textEditingController.clear();
                                      setState(() {
                                        _selectedTaxiStand = null;
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                            optionsViewBuilder: (BuildContext context,
                                AutocompleteOnSelected<TaxiStand> onSelected,
                                Iterable<TaxiStand> options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  color: Colors.black.withOpacity(
                                      0.8), // Adjust dropdown color
                                  child: Container(
                                    width: MediaQuery.of(context).size.width -
                                        32, // Adjust the width to match the TextField
                                    child: ListView.builder(
                                      padding: const EdgeInsets.all(8.0),
                                      itemCount: options.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        final TaxiStand option =
                                            options.elementAt(index);
                                        final isBookmarked =
                                            bookmarkedTaxiStands
                                                .contains(option.name);
                                        return GestureDetector(
                                          onTap: () {
                                            onSelected(option);
                                          },
                                          child: ListTile(
                                            title: Text(option.name,
                                                style: TextStyle(
                                                    color: Colors.white)),
                                            trailing: IconButton(
                                              icon: Icon(
                                                isBookmarked
                                                    ? Icons.bookmark
                                                    : Icons.bookmark_border,
                                                color: isBookmarked
                                                    ? Colors.yellow
                                                    : Colors.white,
                                              ),
                                              onPressed: () {
                                                _toggleBookmark(option);
                                              },
                                            ),
                                            tileColor: Colors.black,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  margin:
                      EdgeInsets.only(top: 8.0), // Reduced the top margin here
                  child: DropdownButton<String>(
                    value: _selectedSortOption,
                    dropdownColor: Colors.black.withOpacity(0.8),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedSortOption = newValue!;
                      });
                    },
                    items: <String>[
                      'Date (Oldest to Newest)',
                      'Date (Newest to Oldest)',
                      'Fare (Cheapest to Most Expensive)',
                      'Fare (Most Expensive to Cheapest)',
                      'Origin (A to Z)',
                      'Origin (Z to A)',
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('fares')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }
                      var fares = snapshot.data!.docs;
                      fares = _sortFares(fares); // Apply sorting
                      if (fares.isEmpty) {
                        return Center(
                          child: Text(
                            'Add a taxi fare for it to show up here',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: fares.length,
                        itemBuilder: (context, index) {
                          final fare = fares[index];
                          return ListTile(
                            title: Text('${fare['origin']} > ${fare['dest']}',
                                style: TextStyle(color: Colors.white)),
                            subtitle: Text('${fare['date']}',
                                style: TextStyle(color: Colors.white70)),
                            trailing: Text('\$${fare['fare']}',
                                style: TextStyle(color: Colors.white)),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditTaxiFareScreen(fare: fare),
                                ),
                              );
                            },
                            onLongPress: () {
                              _showDeleteDialog(context, fare);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: StreamBuilder<double>(
                    stream: getTotalFareStream(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Text('Total amount spent: \$0.0',
                            style: TextStyle(color: Colors.white));
                      }
                      return Text(
                          'Total amount spent: \$${snapshot.data!.toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.white));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/add_taxi');
                    },
                    child: Text('Add Taxi Fare'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // Set button color
                      foregroundColor: Colors.white, // Set text color
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      if (_selectedTaxiStand != null) {
                        _launchMap(
                          _selectedTaxiStand!.latitude,
                          _selectedTaxiStand!.longitude,
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('No Taxi Stand Selected'),
                              content: Text(
                                  'Please search and select a taxi stand.'),
                              actions: <Widget>[
                                TextButton(
                                  child: Text('OK'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                    child: Text('Show Map'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // Set button color
                      foregroundColor: Colors.white, // Set text color
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: MyBottomNavigationBar(selectedIndexNavBar: 2),
      ),
    );
  }
}
