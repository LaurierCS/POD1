import 'package:flutter/material.dart';

class DayDetailsPage extends StatelessWidget {
  final DateTime selectedDate;

  const DayDetailsPage({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Day Details'),
      ),
      body: Column(
        children: <Widget>[
          // Display the selected date
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '${selectedDate.year}-${selectedDate.month}-${selectedDate.day}',
              style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
          ),
          // Display hourly basis vertically
          Expanded(
            child: ListView.builder(
              itemCount: 24,
              itemBuilder: (BuildContext context, int index) {
                String hour = '${index.toString().padLeft(2, '0')}:00';
                return ListTile(
                  title: Text(hour),
                  // Dont need an
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
