import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../utilities/api_calls.dart';
import '../widgets/navigation_bar.dart';
import '../models/travel_time_segment.dart';

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

  List<TravelTimeSegment> travelTimeSegments = [];
  List<String> startPoints = [];
  List<String> endPoints = [];
  List<Map<String, String>> searchHistory = [];
  String startPoint = '';
  String endPoint = '';
  String estimatedTravelTime = '';

  @override
  void initState() {
    super.initState();
    fetchTravelTimeSegments();
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
        break; // Assuming direct segment between start and end
      }
    }

    if (!found) {
      estimatedTravelTime =
          'No direct segment found between $startPoint and $endPoint';
    } else {
      estimatedTravelTime = '$totalTime minutes';
    }

    setState(() {
      searchHistory.add({
        'startPoint': startPoint,
        'endPoint': endPoint,
        'estimatedTravelTime': estimatedTravelTime,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('ExpressWay', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
        ),
        body: Container(
          color: Colors.black,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TypeAheadField(
                  textFieldConfiguration: TextFieldConfiguration(
                    controller: _startPointController,
                    focusNode: _startPointFocusNode,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter Start Point',
                      hintStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.search, color: Colors.white),
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
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
                    _startPointController.text = suggestion.toString();
                    updateEndPoints(suggestion.toString());
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TypeAheadField(
                  textFieldConfiguration: TextFieldConfiguration(
                    controller: _endPointController,
                    focusNode: _endPointFocusNode,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter End Point',
                      hintStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.search, color: Colors.white),
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  suggestionsCallback: (pattern) {
                    return endPoints.where((point) => point.contains(pattern));
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
              Expanded(
                child: ListView.builder(
                  itemCount: searchHistory.length,
                  itemBuilder: (context, index) {
                    final history = searchHistory[index];
                    return Card(
                      color: Colors.white,
                      margin:
                          EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Start Point: ${history['startPoint']}',
                                style: TextStyle(
                                    color: Colors.purple, fontSize: 20)),
                            Text('End Point: ${history['endPoint']}',
                                style: TextStyle(
                                    color: Colors.purple, fontSize: 16)),
                            SizedBox(height: 8),
                            Text(
                                'Time Estimation: ${history['estimatedTravelTime']}',
                                style: TextStyle(
                                    color: Colors.orange, fontSize: 20)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Center(
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _startPointController.clear();
                          _endPointController.clear();
                          endPoints.clear();
                          estimatedTravelTime = '';
                          searchHistory.clear();
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
        ),
        bottomNavigationBar: MyBottomNavigationBar(selectedIndexNavBar: 3),
      ),
    );
  }
}
