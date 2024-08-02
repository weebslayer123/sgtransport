import 'package:flutter/material.dart';
import '../models/taxi_stand.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class BookmarksScreen extends StatefulWidget {
  final List<String> bookmarkedTaxiStands;
  final List<TaxiStand> allTaxiStands; // Add this line

  BookmarksScreen(
      {required this.bookmarkedTaxiStands,
      required this.allTaxiStands}); // Update constructor

  @override
  _BookmarksScreenState createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<TaxiStand> _bookmarkedStands = [];

  @override
  void initState() {
    super.initState();
    _loadBookmarkedStands();
  }

  Future<void> _loadBookmarkedStands() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? bookmarkedNames = prefs.getStringList('bookmarkedTaxiStands');
    if (bookmarkedNames != null) {
      setState(() {
        _bookmarkedStands = widget.bookmarkedTaxiStands
            .map((name) => widget.allTaxiStands.firstWhere(
                (stand) => stand.name == name)) // Use widget.allTaxiStands
            .toList();
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bookmarked Taxi Stands'),
      ),
      body: ListView.builder(
        itemCount: _bookmarkedStands.length,
        itemBuilder: (context, index) {
          final stand = _bookmarkedStands[index];
          return ListTile(
            title: Text(stand.name),
            onTap: () {
              _launchMap(stand.latitude, stand.longitude);
            },
          );
        },
      ),
    );
  }
}
