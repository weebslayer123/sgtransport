import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utilities/api_calls.dart';
import '../widgets/navigation_bar.dart';
import '../models/travel_time_segment.dart';
import '../screens/expressway_bookmark.dart';

class ExpressWayScreen extends StatefulWidget {
  const ExpressWayScreen({Key? key}) : super(key: key);

  @override
  _ExpressWayScreenState createState() => _ExpressWayScreenState();
}

class _ExpressWayScreenState extends State<ExpressWayScreen> {
  final TextEditingController _startPointController = TextEditingController();
  final TextEditingController _endPointController = TextEditingController();
  final FocusNode _startPointFocusNode = FocusNode();
  final FocusNode _endPointFocusNode = FocusNode();
  final FirebaseAuth auth = FirebaseAuth.instance;

  List<TravelTimeSegment> travelTimeSegments = [];
  List<String> startPoints = [];
  List<String> endPoints = [];
  List<Map<String, String>> searchHistory = [];
  List<Map<String, String>> bookmarkedExpressways = [];
  String startPoint = '';
  String endPoint = '';
  String estimatedTravelTime = '';

  @override
  void initState() {
    super.initState();
    fetchTravelTimeSegments();
    loadSearchHistory();
    loadBookmarkedExpressways();
  }

  @override
  void dispose() {
    _startPointController.dispose();
    _endPointController.dispose();
    _startPointFocusNode.dispose();
    _endPointFocusNode.dispose();
    super.dispose();
  }

  Future<void> fetchTravelTimeSegments() async {
    ApiCalls apiCalls = ApiCalls();
    try {
      List<TravelTimeSegment> segments =
          await apiCalls.fetchEstimatedTravelTimes();
      setState(() {
        travelTimeSegments = segments;
        startPoints = segments.map((e) => e.startPoint).toSet().toList();
      });
    } catch (e) {
      print('Error fetching travel times: $e');
    }
  }

  void updateEndPoints(String startPoint) {
    setState(() {
      endPoints = travelTimeSegments
          .where((segment) => segment.startPoint == startPoint)
          .map((segment) => segment.endPoint)
          .toSet()
          .toList();
    });
  }

  void calculateEstimatedTravelTime() {
    startPoint = _startPointController.text;
    endPoint = _endPointController.text;
    int totalTime = 0;
    bool found = false;

    for (var segment in travelTimeSegments) {
      if (segment.startPoint == startPoint && segment.endPoint == endPoint) {
        totalTime += segment.estTime;
        found = true;
        break;
      }
    }

    if (!found) {
      estimatedTravelTime =
          'No direct segment found between $startPoint and $endPoint';
    } else {
      estimatedTravelTime = '$totalTime minutes';
    }

    bool isDuplicate = searchHistory.any((history) =>
        history['startPoint'] == startPoint && history['endPoint'] == endPoint);

    if (!isDuplicate) {
      setState(() {
        searchHistory.add({
          'startPoint': startPoint,
          'endPoint': endPoint,
          'estimatedTravelTime': estimatedTravelTime,
        });
      });
      saveSearchHistory();
    }
  }

  Future<void> saveSearchHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> encodedHistory =
        searchHistory.map((history) => jsonEncode(history)).toList();
    await prefs.setStringList('searchHistory', encodedHistory);
  }

  Future<void> loadSearchHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? encodedHistory = prefs.getStringList('searchHistory');
    if (encodedHistory != null) {
      setState(() {
        searchHistory = encodedHistory
            .map((encoded) => Map<String, String>.from(jsonDecode(encoded)))
            .toList();
      });
    }
  }

  Future<void> saveBookmarkedExpressways() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> encodedBookmarks =
        bookmarkedExpressways.map((bookmark) => jsonEncode(bookmark)).toList();
    await prefs.setStringList('bookmarkedExpressways', encodedBookmarks);
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

  void toggleBookmark(Map<String, String> expressway) {
    bool isBookmarked = bookmarkedExpressways.any((bookmark) =>
        bookmark['startPoint'] == expressway['startPoint'] &&
        bookmark['endPoint'] == expressway['endPoint']);
    if (isBookmarked) {
      setState(() {
        bookmarkedExpressways.removeWhere((bookmark) =>
            bookmark['startPoint'] == expressway['startPoint'] &&
            bookmark['endPoint'] == expressway['endPoint']);
      });
    } else {
      setState(() {
        bookmarkedExpressways.add(expressway);
      });
    }
    saveBookmarkedExpressways();
  }

  void deleteHistoryItem(int index) {
    setState(() {
      searchHistory.removeAt(index);
    });
    saveSearchHistory();
  }

  void _showDeleteDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Entry', style: TextStyle(color: Colors.white)),
          content: Text('Are you sure you want to delete this entry?',
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
                deleteHistoryItem(index);
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
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text('ExpressWay', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.bookmark, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookmarkedExpresswaysScreen(),
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
                  image: AssetImage('images/expressway.png'),
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
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          'Hello ${auth.currentUser?.displayName}',
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(height: 8.0),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: TypeAheadField(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: _startPointController,
                              focusNode: _startPointFocusNode,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Enter Start Point',
                                hintStyle: TextStyle(color: Colors.white70),
                                prefixIcon:
                                    Icon(Icons.search, color: Colors.white),
                                filled: true,
                                fillColor: Colors.transparent,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide(color: Colors.white70),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                              ),
                              onChanged: (value) {
                                updateEndPoints(value);
                              },
                            ),
                            suggestionsCallback: (pattern) {
                              return startPoints
                                  .where((point) => point.contains(pattern));
                            },
                            itemBuilder: (context, suggestion) {
                              return ListTile(
                                title: Text(suggestion.toString(),
                                    style: TextStyle(color: Colors.black)),
                              );
                            },
                            onSuggestionSelected: (suggestion) {
                              _startPointController.text =
                                  suggestion.toString();
                              updateEndPoints(suggestion.toString());
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TypeAheadField(
                      textFieldConfiguration: TextFieldConfiguration(
                        controller: _endPointController,
                        focusNode: _endPointFocusNode,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter End Point',
                          hintStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(Icons.search, color: Colors.white),
                          filled: true,
                          fillColor: Colors.transparent,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: Colors.white70),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                      ),
                      suggestionsCallback: (pattern) {
                        return endPoints
                            .where((point) => point.contains(pattern));
                      },
                      itemBuilder: (context, suggestion) {
                        return ListTile(
                          title: Text(suggestion.toString(),
                              style: TextStyle(color: Colors.black)),
                        );
                      },
                      onSuggestionSelected: (suggestion) {
                        _endPointController.text = suggestion.toString();
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: searchHistory.length,
                    itemBuilder: (context, index) {
                      final history = searchHistory[index];
                      final isBookmarked = bookmarkedExpressways.any(
                          (bookmark) =>
                              bookmark['startPoint'] == history['startPoint'] &&
                              bookmark['endPoint'] == history['endPoint']);
                      return GestureDetector(
                        onLongPress: () {
                          _showDeleteDialog(context, index);
                        },
                        child: Card(
                          color: Colors.transparent,
                          elevation: 0,
                          margin: EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${history['startPoint']} >',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 20)),
                                    Text('${history['endPoint']}',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 16)),
                                    SizedBox(height: 8),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                              text: 'Travel Time: ',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20)),
                                          TextSpan(
                                              text: history[
                                                  'estimatedTravelTime'],
                                              style: TextStyle(
                                                  color: Colors.orange,
                                                  fontSize: 20)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: Icon(
                                    isBookmarked
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    color: isBookmarked
                                        ? Colors.yellow
                                        : Colors.white,
                                  ),
                                  onPressed: () {
                                    toggleBookmark(history);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _startPointController.clear();
                            _endPointController.clear();
                            endPoints.clear();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Clear Inputs'),
                      ),
                      SizedBox(height: 8.0),
                      ElevatedButton(
                        onPressed: calculateEstimatedTravelTime,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Show Estimated Time'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: MyBottomNavigationBar(selectedIndexNavBar: 3),
      ),
    );
  }
}
