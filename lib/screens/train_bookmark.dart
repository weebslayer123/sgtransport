import 'package:flutter/material.dart';
import '../models/train_stations_repository.dart';
import '../models/train_crowd_density.dart';
import '../utilities/api_calls.dart';

class TrainBookmarkScreen extends StatefulWidget {
  final List<TrainStation> bookmarkedStations;

  const TrainBookmarkScreen({Key? key, required this.bookmarkedStations})
      : super(key: key);

  @override
  _TrainBookmarkScreenState createState() => _TrainBookmarkScreenState();
}

class _TrainBookmarkScreenState extends State<TrainBookmarkScreen> {
  List<CrowdDensity> _crowdDensityList = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.bookmarkedStations.isNotEmpty) {
      _fetchCrowdDensityForBookmarks();
    }
  }

  Future<void> _fetchCrowdDensityForBookmarks() async {
    setState(() {
      _isLoading = true;
    });
    ApiCalls apiCalls = ApiCalls();
    try {
      // Extract unique train lines from bookmarked stations
      List<String> trainLines = widget.bookmarkedStations
          .map((station) => station.trainLineCode)
          .toSet()
          .toList();

      List<CrowdDensity> allCrowdDensityList = [];
      for (String trainLine in trainLines) {
        List<CrowdDensity> crowdDensityList =
            await apiCalls.fetchCrowdDensity(trainLine);
        allCrowdDensityList.addAll(crowdDensityList);
      }

      setState(() {
        _crowdDensityList = allCrowdDensityList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching crowd density: $e';
        _isLoading = false;
      });
    }
  }

  String _formatCrowdLevel(String level) {
    switch (level.toLowerCase()) {
      case 'l':
        return 'Low';
      case 'h':
        return 'High';
      case 'm':
        return 'Moderate';
      default:
        return 'N/A';
    }
  }

  Color _getCrowdLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'l':
        return Colors.green;
      case 'h':
        return Colors.red;
      case 'm':
        return Colors.orange;
      default:
        return Colors.white;
    }
  }

  CrowdDensity? _getCrowdDensityForStation(String stationCode) {
    return _crowdDensityList.firstWhere(
      (density) => density.station == stationCode,
      orElse: () => CrowdDensity(station: stationCode, crowdLevel: 'n/a'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title:
            Text('Bookmarked Stations', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Colors.white, // Change the back arrow color to white
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/mrt_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.5), // Dark overlay
          ),
          _isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.white))
              : _errorMessage.isNotEmpty
                  ? Center(
                      child: Text(_errorMessage,
                          style: TextStyle(color: Colors.white)))
                  : widget.bookmarkedStations.isEmpty
                      ? Center(
                          child: Text(
                            'No bookmarked stations.',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : ListView.builder(
                          itemCount: widget.bookmarkedStations.length,
                          itemBuilder: (context, index) {
                            final station = widget.bookmarkedStations[index];
                            final crowdDensity =
                                _getCrowdDensityForStation(station.stnCode);
                            final crowdLevel = _formatCrowdLevel(
                                crowdDensity?.crowdLevel ?? 'N/A');
                            final crowdColor = _getCrowdLevelColor(
                                crowdDensity?.crowdLevel ?? 'n/a');

                            return ListTile(
                              title: Text(
                                '${station.stnName} (${station.stnCode})',
                                style: TextStyle(color: Colors.white),
                              ),
                              subtitle: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Crowd Level: ',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    TextSpan(
                                      text: crowdLevel,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: crowdColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: IconButton(
                                icon:
                                    Icon(Icons.bookmark, color: Colors.yellow),
                                onPressed: () {
                                  // Optionally implement unbookmarking logic here if needed
                                },
                              ),
                              tileColor: Colors.black,
                            );
                          },
                        ),
        ],
      ),
    );
  }
}
