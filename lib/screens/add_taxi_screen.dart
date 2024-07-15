import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/taxi_fare.dart';
import '../utilities/firebase_calls.dart';

class AddTaxiScreen extends StatefulWidget {
  @override
  _AddTaxiScreenState createState() => _AddTaxiScreenState();
}

class _AddTaxiScreenState extends State<AddTaxiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _fareController = TextEditingController();
  final _dateController = TextEditingController();

  Future<void> _addTaxiFare() async {
    if (_formKey.currentState?.validate() ?? false) {
      await FirebaseFirestore.instance.collection('fares').add({
        'origin': _originController.text,
        'dest': _destinationController.text,
        'fare': _fareController.text,
        'date': _dateController.text,
        'userid': 'YOUR_USER_ID',
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Taxi Fare'),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextFormField(
                  controller: _originController,
                  decoration: InputDecoration(labelText: 'Origin'),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter the origin';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _destinationController,
                  decoration: InputDecoration(labelText: 'Destination'),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter the destination';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _fareController,
                  decoration: InputDecoration(labelText: 'Fare'),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter the fare';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _dateController,
                  decoration: InputDecoration(labelText: 'Date'),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter the date';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _addTaxiFare,
                  child: Text('Add'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
