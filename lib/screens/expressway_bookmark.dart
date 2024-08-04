import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BookmarkedExpresswaysScreen extends StatefulWidget {
  const BookmarkedExpresswaysScreen({Key? key}) : super(key: key);

  @override
  _BookmarkedExpresswaysScreenState createState() =>
      _BookmarkedExpresswaysScreenState();
}

class _BookmarkedExpresswaysScreenState
    extends State<BookmarkedExpresswaysScreen> {
  List<Map<String, String>> bookmarkedExpressways = [];

  @override
  void initState() {
    super.initState();
    loadBookmarkedExpressways();
  }

  Future<void> loadBookmarkedExpressways() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? encodedBookmarks =
        prefs.getStringList('bookmarkedExpressways');
    if (encodedBookmarks != null) {
      setState(() {
        bookmarkedExpressways = encodedBookmarks
            .map((encoded) => Map<String, String>.from(jsonDecode(encoded)))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Bookmarked Expressways',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/expressway2.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.7),
          ),
          if (bookmarkedExpressways.isEmpty)
            Center(
              child: Text(
                'Bookmark something for it to appear here',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
            )
          else
            ListView.builder(
              itemCount: bookmarkedExpressways.length,
              itemBuilder: (context, index) {
                final bookmark = bookmarkedExpressways[index];
                return Card(
                  color: Colors.transparent,
                  elevation: 0,
                  margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    title: Text(
                      '${bookmark['startPoint']} > ${bookmark['endPoint']}',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    subtitle: Text(
                      'Travel Time: ${bookmark['estimatedTravelTime']}',
                      style: TextStyle(color: Colors.orange, fontSize: 16),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
