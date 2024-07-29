import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utilities/api_calls.dart';
import '../models/train_stations_repository.dart';
import '../models/train_crowd_density.dart';
import '../widgets/navigation_bar.dart';

class TrainScreen extends StatefulWidget {
  const TrainScreen({super.key});

  @override
  State<TrainScreen> createState() => _TrainScreenState();
}

class _TrainScreenState extends State<TrainScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance; // Define the auth object
  TrainStation _selectedTrainStation = TrainStation(
    stnCode: '',
    stnName: '',
    trainLine: '',
    trainLineCode: '',
  );

  List<CrowdDensity> _crowdDensityList = [];
  bool _isLoading = false;
  String _errorMessage = '';
  final TrainStationsRepository _trainStationsRepository =
      TrainStationsRepository();
  final TextEditingController _searchController = TextEditingController();
  List<TrainStation> _filteredTrainStations = [];
  List<TrainStation> _searchHistory = [];
  TrainStation? _searchedStation;
  String _selectedLineCode = 'All';

  @override
  void initState() {
    super.initState();
    _filteredTrainStations = _trainStationsRepository.allTrainStations;
    _searchController.addListener(_filterTrainStations);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCrowdDensity(String trainLine) async {
    try {
      setState(() {
        _isLoading = true;
      });
      List<CrowdDensity> crowdDensityList =
          await ApiCalls().fetchCrowdDensity(trainLine);
      setState(() {
        _crowdDensityList = crowdDensityList;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  void _filterTrainStations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTrainStations = _trainStationsRepository.allTrainStations
          .where((station) =>
              station.stnName.toLowerCase().contains(query) ||
              station.stnCode.toLowerCase().contains(query))
          .toList();
      if (_selectedLineCode != 'All') {
        _filteredTrainStations = _filteredTrainStations
            .where((station) => station.trainLineCode == _selectedLineCode)
            .toList();
      }
      _searchedStation =
          null; // Reset searched station if user types something new
    });
  }

  void _onSelected(TrainStation selection) {
    setState(() {
      _searchController.text = '${selection.stnName} (${selection.stnCode})';
      _searchedStation = selection;
      _searchHistory.insert(
          0, selection); // Add the selection to search history
    });
    _fetchCrowdDensity(selection
        .trainLineCode); // Fetch crowd density for the selected train line
  }

  void _showMRTMap() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('images/mrt_map.png'),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _filterByLine(String lineCode) {
    setState(() {
      _selectedLineCode = lineCode;
      _searchController.clear();
      if (lineCode == 'All') {
        _filteredTrainStations = _trainStationsRepository.allTrainStations;
      } else {
        _filteredTrainStations = _trainStationsRepository.allTrainStations
            .where((station) => station.trainLineCode == lineCode)
            .toList();
      }
      _searchedStation = null;
    });
    if (lineCode != 'All') {
      _fetchCrowdDensity(lineCode);
    }
  }

  String _formatCrowdLevel(String level) {
    switch (level) {
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
    switch (level) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Train', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list, color: Colors.white),
            onSelected: (String value) {
              _filterByLine(value);
            },
            itemBuilder: (BuildContext context) {
              return <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'All',
                  child: Text('All Lines'),
                ),
                const PopupMenuItem<String>(
                  value: 'NSL',
                  child: Text('North-South Line (NSL)'),
                ),
                const PopupMenuItem<String>(
                  value: 'EWL',
                  child: Text('East-West Line (EWL)'),
                ),
                const PopupMenuItem<String>(
                  value: 'NEL',
                  child: Text('North East Line (NEL)'),
                ),
                const PopupMenuItem<String>(
                  value: 'CCL',
                  child: Text('Circle Line (CCL)'),
                ),
                const PopupMenuItem<String>(
                  value: 'DTL',
                  child: Text('Downtown Line (DTL)'),
                ),
                const PopupMenuItem<String>(
                  value: 'TEL',
                  child: Text('Thomson-East Coast Line (TEL)'),
                ),
              ];
            },
          ),
        ],
      ),
      bottomNavigationBar: MyBottomNavigationBar(selectedIndexNavBar: 1),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            child: Center(
              child: Column(
                children: [
                  Text(
                    'Hello ${auth.currentUser?.displayName ?? 'me'}',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 16.0),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Autocomplete<TrainStation>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<TrainStation>.empty();
                        }
                        return _filteredTrainStations;
                      },
                      displayStringForOption: (TrainStation option) =>
                          option.stnName,
                      fieldViewBuilder: (BuildContext context,
                          TextEditingController textEditingController,
                          FocusNode focusNode,
                          VoidCallback onFieldSubmitted) {
                        return TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter Train Station',
                            hintStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.search, color: Colors.white),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.clear, color: Colors.white),
                              onPressed: () {
                                textEditingController.clear();
                                setState(() {
                                  _searchedStation = null;
                                });
                              },
                            ),
                          ),
                          onChanged: (value) {
                            _searchController.text = value;
                            _filterTrainStations();
                          },
                        );
                      },
                      onSelected: (TrainStation selection) {
                        _onSelected(selection);
                      },
                      optionsViewBuilder: (BuildContext context,
                          AutocompleteOnSelected<TrainStation> onSelected,
                          Iterable<TrainStation> options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            color: Colors.black,
                            child: Container(
                              width: MediaQuery.of(context).size.width - 16,
                              margin: const EdgeInsets.all(8.0),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(8.0),
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final TrainStation option =
                                      options.elementAt(index);
                                  return GestureDetector(
                                    onTap: () {
                                      onSelected(option);
                                    },
                                    child: ListTile(
                                      title: Text(option.stnName,
                                          style:
                                              TextStyle(color: Colors.white)),
                                      subtitle: Text(option.stnCode,
                                          style:
                                              TextStyle(color: Colors.white)),
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
          Expanded(
            child: _errorMessage.isNotEmpty
                ? Center(
                    child: Text(_errorMessage,
                        style: TextStyle(color: Colors.white)))
                : _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white))
                    : ListView.builder(
                        itemCount: _selectedLineCode == 'All'
                            ? _searchHistory.length
                            : _filteredTrainStations.length,
                        itemBuilder: (context, index) {
                          final trainStation = _selectedLineCode == 'All'
                              ? _searchHistory[index]
                              : _filteredTrainStations[index];
                          final crowdDensity = _crowdDensityList.firstWhere(
                              (density) =>
                                  density.station == trainStation.stnCode,
                              orElse: () => CrowdDensity(
                                  station: 'Unknown', crowdLevel: 'N/A'));
                          return ListTile(
                            title: Text(
                                '${trainStation.stnName} (${trainStation.stnCode})',
                                style: TextStyle(color: Colors.white)),
                            subtitle: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Crowd Level: ',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  TextSpan(
                                    text: _formatCrowdLevel(
                                        crowdDensity.crowdLevel),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _getCrowdLevelColor(
                                          crowdDensity.crowdLevel),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            tileColor: Colors.black,
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _showMRTMap,
              child: Text('Show Map'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Set button color
                foregroundColor: Colors.white, // Set text color
              ),
            ),
          ),
        ],
      ),
    );
  }
}
