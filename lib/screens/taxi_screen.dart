import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utilities/api_calls.dart';
import '../models/taxi_stand.dart';
import '../widgets/navigation_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaxiScreen extends StatefulWidget {
  const TaxiScreen({Key? key}) : super(key: key);

  @override
  _TaxiScreenState createState() => _TaxiScreenState();
}

class _TaxiScreenState extends State<TaxiScreen> {
  List<TaxiStand>? _allTaxiStands = [];
  TaxiStand? _selectedTaxiStand;
  final ApiCalls _apiCalls = ApiCalls();
  final FirebaseAuth auth = FirebaseAuth.instance; // Ensure this is initialized

  @override
  void initState() {
    super.initState();
    fetchTaxiStands();
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
        total += double.parse(doc['fare']);
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Taxi', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      16.0, 32.0, 16.0, 8.0), // Adjusted top padding
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Hello ${auth.currentUser?.displayName}',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Autocomplete<TaxiStand>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<TaxiStand>.empty();
                          }
                          return _allTaxiStands!.where((TaxiStand stand) {
                            return stand.name
                                .toLowerCase()
                                .contains(textEditingValue.text.toLowerCase());
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
                                icon: Icon(Icons.clear, color: Colors.white),
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
                      ),
                    ),
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
                      final fares = snapshot.data!.docs;
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
                      return Text('Total amount spent: \$${snapshot.data}',
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
