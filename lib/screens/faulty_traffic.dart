import 'package:flutter/material.dart';
import '../models/faulty_traffic_light.dart';
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

  @override
  void initState() {
    super.initState();
    _futureFaultyTrafficLights = ApiCalls().fetchFaultyTrafficLights();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title:
            const Text('Faulty Traffic', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white, // Change the back arrow color to white
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    'images/traffic_light_bg.jpg'), // Use the correct background image
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.5), // Dark overlay
          ),
          FutureBuilder<List<FaultyTrafficLight>>(
            future: _futureFaultyTrafficLights,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.white));
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
        ],
      ),
    );
  }
}
