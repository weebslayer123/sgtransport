import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class EditTaxiFareScreen extends StatefulWidget {
  final DocumentSnapshot fare;

  EditTaxiFareScreen({required this.fare});

  @override
  _EditTaxiFareScreenState createState() => _EditTaxiFareScreenState();
}

class _EditTaxiFareScreenState extends State<EditTaxiFareScreen> {
  final _formKey = GlobalKey<FormState>();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _fareController = TextEditingController();
  final _dateController = TextEditingController();

  var maskFormatter = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void initState() {
    super.initState();
    _originController.text = widget.fare['origin'];
    _destinationController.text = widget.fare['dest'];
    _fareController.text = widget.fare['fare'].toString();
    _dateController.text = widget.fare['date'];
  }

  Future<void> _updateTaxiFare() async {
    if (_formKey.currentState?.validate() ?? false) {
      await FirebaseFirestore.instance
          .collection('fares')
          .doc(widget.fare.id)
          .update({
        'origin': _originController.text,
        'dest': _destinationController.text,
        'fare': double.parse(_fareController.text),
        'date': _dateController.text,
      });
      Navigator.pop(context);
    }
  }

  String? _validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the date';
    }
    try {
      final date = DateFormat('dd/MM/yyyy').parseStrict(value);
      return null;
    } catch (e) {
      return 'Please enter a valid date in dd/MM/yyyy format';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Extend body behind AppBar
      appBar: AppBar(
        title: Text(
          'Edit Taxi Fare',
          style: TextStyle(color: Colors.white), // Change text color to white
        ),
        backgroundColor: Colors.transparent, // Make AppBar transparent
        elevation: 0, // Remove AppBar elevation
        iconTheme:
            IconThemeData(color: Colors.white), // Change icon color to white
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('images/addtaxi.png'), // Image path
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              color: Colors.black.withOpacity(0.7), // To ensure form visibility
            ),
            SingleChildScrollView(
              padding: EdgeInsets.only(top: 80.0), // Add padding to the top
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _originController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Origin',
                          labelStyle: TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter the origin';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _destinationController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Destination',
                          labelStyle: TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter the destination';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _fareController,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Fare',
                          labelStyle: TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter the fare';
                          }
                          if (double.tryParse(value!) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _dateController,
                        inputFormatters: [maskFormatter],
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Date (dd/mm/yyyy)',
                          labelStyle: TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                        ),
                        validator: _validateDate,
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _updateTaxiFare,
                        child: Text('Update'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue, // Set button color
                          foregroundColor: Colors.white, // Set text color
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
