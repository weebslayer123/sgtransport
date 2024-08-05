import 'package:flutter/material.dart';

class BusBookmarkScreen extends StatelessWidget {
  final List<String> bookmarkedBusStops;
  final List<String> bookmarkedBusNumbers;

  const BusBookmarkScreen({
    Key? key,
    required this.bookmarkedBusStops,
    required this.bookmarkedBusNumbers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Bookmarked Stops and Routes',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
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
          bookmarkedBusStops.isEmpty && bookmarkedBusNumbers.isEmpty
              ? Center(
                  child: Text(
                    'No bookmarks yet.',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : ListView(
                  children: [
                    if (bookmarkedBusStops.isNotEmpty) ...[
                      ListTile(
                        title: Text('Bookmarked Bus Stops',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ),
                      ...bookmarkedBusStops.map((busStopCode) {
                        return ListTile(
                          title: Text(
                            busStopCode,
                            style: TextStyle(color: Colors.white),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.bookmark, color: Colors.yellow),
                            onPressed: () {},
                          ),
                          tileColor: Colors.black,
                        );
                      }).toList(),
                    ],
                    if (bookmarkedBusNumbers.isNotEmpty) ...[
                      ListTile(
                        title: Text('Bookmarked Bus Numbers',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ),
                      ...bookmarkedBusNumbers.map((busNumber) {
                        return ListTile(
                          title: Text(
                            busNumber,
                            style: TextStyle(color: Colors.white),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.bookmark, color: Colors.yellow),
                            onPressed: () {},
                          ),
                          tileColor: Colors.black,
                        );
                      }).toList(),
                    ],
                  ],
                ),
        ],
      ),
    );
  }
}
