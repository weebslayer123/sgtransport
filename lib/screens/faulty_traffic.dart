import 'package:flutter/material.dart';
import '../models/faulty_traffic_light.dart';
import '../models/traffic_incident.dart';
import '../utilities/api_calls.dart';
import '../widgets/navigation_bar.dart';

class FaultyTrafficLightsScreen extends StatefulWidget {
  const FaultyTrafficLightsScreen({Key? key}) : super(key: key);

  @override
  _FaultyTrafficLightsScreenState createState() =>
      _FaultyTrafficLightsScreenState();
}

class _FaultyTrafficLightsScreenState extends State<FaultyTrafficLightsScreen> {
  late Future<List<FaultyTrafficLight>> _futureFaultyTrafficLights;
  late Future<List<TrafficIncident>> _futureTrafficIncidents;

  @override
  void initState() {
    super.initState();
    _futureFaultyTrafficLights = ApiCalls().fetchFaultyTrafficLights();
    _futureTrafficIncidents = ApiCalls().fetchTrafficIncidents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title:
            const Text('Traffic Status', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      extendBody: true,
      bottomNavigationBar: Container(
        color: Colors.transparent,
        child: MyBottomNavigationBar(selectedIndexNavBar: 4),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/traffic_light_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          Column(
            children: [
              Flexible(
                flex: 1,
                child: FutureBuilder<List<FaultyTrafficLight>>(
                  future: _futureFaultyTrafficLights,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child:
                              CircularProgressIndicator(color: Colors.white));
                    } else if (snapshot.hasError) {
                      return Center(
                          child: Text('Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.white)));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                          child: Text('No faulty traffic lights found',
                              style: TextStyle(color: Colors.white)));
                    } else {
                      final faultyTrafficLights = snapshot.data!;
                      return ListView.builder(
                        itemCount: faultyTrafficLights.length,
                        itemBuilder: (context, index) {
                          final light = faultyTrafficLights[index];
                          return ListTile(
                            title: Text('${light.nodeID} (${light.type})',
                                style: const TextStyle(color: Colors.white)),
                            subtitle: Text(
                                '${light.message}\nStart: ${light.startDate}',
                                style: const TextStyle(color: Colors.white)),
                            trailing: light.endDate != null
                                ? Text('End: ${light.endDate}',
                                    style: const TextStyle(color: Colors.white))
                                : const Text('Ongoing',
                                    style: TextStyle(color: Colors.orange)),
                            tileColor: Colors.black.withOpacity(0.5),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
              Flexible(
                flex: 2,
                child: FutureBuilder<List<TrafficIncident>>(
                  future: _futureTrafficIncidents,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child:
                              CircularProgressIndicator(color: Colors.white));
                    } else if (snapshot.hasError) {
                      return Center(
                          child: Text('Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.white)));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                          child: Text('No traffic incidents found',
                              style: TextStyle(color: Colors.white)));
                    } else {
                      final trafficIncidents = snapshot.data!;
                      return ListView.builder(
                        itemCount: trafficIncidents.length,
                        itemBuilder: (context, index) {
                          final incident = trafficIncidents[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  incident.type,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  incident.message,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  'Location: ${incident.latitude}, ${incident.longitude}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
