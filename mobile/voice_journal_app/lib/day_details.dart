import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:voice_journal_app/Playback.dart';
import 'package:voice_journal_app/RecordingPage.dart';
import 'package:voice_journal_app/theme.dart';
import 'schema.dart';

class DayDetailsPage extends StatelessWidget {
  final DateTime selectedDate;

  const DayDetailsPage({Key? key, required this.selectedDate}) : super(key: key);

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
            child: FutureBuilder(
              future: _getRecordings(),
              builder: (context, AsyncSnapshot<List<Recording>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  // Group recordings by hour
                  final Map<int, List<Recording>> recordingsByHour = {};
                  for (var recording in snapshot.data!) {
                    final hour = recording.timeStamp.hour;
                    if (!recordingsByHour.containsKey(hour)) {
                      recordingsByHour[hour] = [];
                    }
                    recordingsByHour[hour]!.add(recording);
                  }

                  // Display recordings for each hour
                  return ListView.builder(
                    itemCount: 24,
                    itemBuilder: (BuildContext context, int index) {
                      final hour = index.toString().padLeft(2, '0');
                      final recordings = (recordingsByHour[index] ?? []);

                      // Create a list of ListTile widgets for each recording
                      final listTiles = recordings.map((recording) {
                        return ListTile(
                          title: TextButton(
                            onPressed: () {
                              displayRecording(recording);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const PlaybackPage(title: 'playback page')),
                              );
                            },
                            style: ButtonStyle(
                              foregroundColor: MaterialStateProperty.all<Color>(AppColors.lightGray),
                              backgroundColor: MaterialStateProperty.all<Color>(AppColors.mutedTeal),
                            ),
                            child: Text(recording.title), // Accessing title from the Recording object
                          ),
                        );
                      }).toList();

    // Return a Column widget with all the ListTile widgets
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hour: $hour'), // Display hour
        const SizedBox(height: 15,),
        ...listTiles, // Add all ListTile widgets
      ],
    );
  },
);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Recording>> _getRecordings() async {
    final box = Hive.box<Recording>('recordings');
    final allRecordings = box.values.toList();
    final recordingsForSelectedDate = allRecordings.where((recording) {
      final recordingDate = recording.timeStamp;
      return recordingDate.year == selectedDate.year &&
          recordingDate.month == selectedDate.month &&
          recordingDate.day == selectedDate.day;
    }).toList();
    return recordingsForSelectedDate;
  }
}
