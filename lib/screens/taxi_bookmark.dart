import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/taxi_stand.dart';

class BookmarksScreen extends StatefulWidget {
  final List<String> bookmarkedTaxiStands;
  final List<TaxiStand> allTaxiStands;

  BookmarksScreen(
      {required this.bookmarkedTaxiStands, required this.allTaxiStands});

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
            .map((name) =>
                widget.allTaxiStands.firstWhere((stand) => stand.name == name))
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Bookmarked Taxi Stands',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/taxibookmark.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.7),
          ),
          if (_bookmarkedStands.isEmpty)
            Center(
              child: Text(
                'Bookmark something for it to appear here',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: ListView.builder(
                itemCount: _bookmarkedStands.length,
                itemBuilder: (context, index) {
                  final stand = _bookmarkedStands[index];
                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      leading: Icon(Icons.local_taxi, color: Colors.yellow),
                      title: Text(
                        stand.name,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        '${stand.latitude}, ${stand.longitude}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      trailing: Icon(Icons.map, color: Colors.yellow),
                      onTap: () {
                        _launchMap(stand.latitude, stand.longitude);
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
