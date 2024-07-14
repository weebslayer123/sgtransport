import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utilities/api_calls.dart';
import '../utilities/firebase_calls.dart';
import '../utilities/my_url_launcher.dart';
import '../models/taxi_stand.dart';
import '../widgets/navigation_bar.dart';
import 'add_taxi_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/taxi_stand.dart';

class TaxiScreen extends StatefulWidget {
  const TaxiScreen({Key? key}) : super(key: key);

  @override
  _TaxiScreenState createState() => _TaxiScreenState();
}

class _TaxiScreenState extends State<TaxiScreen> {
  List<TaxiStand>? _allTaxiStands = [];
  String? _selectedTaxiStand;

  @override
  void initState() {
    super.initState();
    fetchTaxiStands();
  }

  Future<void> fetchTaxiStands() async {
    final response = await http.get(
      Uri.parse('http://datamall2.mytransport.sg/ltaodataservice/TaxiStands'),
      headers: {
        'AccountKey': 'SEijCWZMTeezw0/HAUyKOw==',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['value'];
      setState(() {
        _allTaxiStands = data.map((item) => TaxiStand.fromJson(item)).toList();
      });
    } else {
      throw Exception('Failed to load taxi stands');
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
          title: Text('Delete Fare'),
          content: Text('Are you sure you want to delete this fare?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Taxi'),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            child: Center(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return _allTaxiStands!
                        .map((stand) => stand.name)
                        .where((name) => name.contains(textEditingValue.text));
                  },
                  onSelected: (String selection) {
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
                      decoration: InputDecoration(
                        hintText: 'Enter Taxi Stand',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.clear),
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
              stream:
                  FirebaseFirestore.instance.collection('fares').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final fares = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: fares.length,
                  itemBuilder: (context, index) {
                    final fare = fares[index];
                    return ListTile(
                      title: Text('${fare['origin']} > ${fare['dest']}'),
                      subtitle: Text('${fare['date']}'),
                      trailing: Text('\$${fare['fare']}'),
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
                  return Text('Total amount spent: \$0.0');
                }
                return Text('Total amount spent: \$${snapshot.data}');
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/add_taxi');
                  },
                  child: Text('Add Taxi Fare'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 20),
                  ),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_selectedTaxiStand != null) {
                      final selectedStand = _allTaxiStands!.firstWhere(
                          (stand) => stand.name == _selectedTaxiStand);
                      _launchMap(
                        selectedStand.latitude,
                        selectedStand.longitude,
                      );
                    }
                  },
                  child: Text('Show Map'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: MyBottomNavigationBar(
          selectedIndexNavBar: 2), // Taxi is the third item
    );
  }
}
