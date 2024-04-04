import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:voice_journal_app/Emotions_enums.dart';
import 'package:voice_journal_app/Playback.dart';
import 'package:voice_journal_app/RecordingPage.dart';
import 'package:voice_journal_app/theme.dart';
import 'schema.dart';

class DayDetailsPage extends StatelessWidget {
  final DateTime selectedDate;
  final Function updateDays;

  const DayDetailsPage({super.key, required this.selectedDate, required this.updateDays});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Day Details'),
        backgroundColor: AppColors.lightGray,
      ),
      body: Column(
        children: <Widget>[
          // Display the selected date
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: Text(
              '${selectedDate.day} / ${selectedDate.month} / ${selectedDate.year}',
              style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
          ),
          // Display hourly basis vertically
          Expanded(
            child: FutureBuilder(
              future: _getRecordings(),
              builder: (context, AsyncSnapshot<List<Recording>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
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
                      int length = recordings.length;

                      // Create a list of ListTile widgets for each recording
                      final listTiles = recordings.map((recording) {
                        List<Color> emotionColours = [];
                        if(recording.isTranscribed && length != 0){ //if the recording has a transcription and therefore an emotion associated with it
                          for (int i = 0; i < length; i++){ //Iterate through the emotions in the recording and add the colour attached to that emotion to the gradient
                            Emotions emotion = recording.emotion[i];
                            if(emotion == Emotions.happiness){
                              emotionColours.add(AppColors.happiness);
                            } else if(emotion == Emotions.sadness){
                              emotionColours.add(AppColors.sadness);
                            } else if(emotion == Emotions.anger){
                              emotionColours.add(AppColors.anger);
                            } else if(emotion == Emotions.surprise){
                              emotionColours.add(AppColors.surprise);
                            } else if(emotion == Emotions.fear) {
                              emotionColours.add(AppColors.fear);
                            } else if(emotion == Emotions.disgust) {
                              emotionColours.add(AppColors.disgust);
                            }
                          }
                        } else{
                          emotionColours.add(AppColors.mutedTeal);
                        }
                        if(emotionColours.length == 1){ //if there is only one colour in the gradient list this will return an error. So lets just duplicate it.
                          emotionColours.add(emotionColours[0]);
                        }

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: emotionColours,
                              ),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) =>
                                    PlaybackPage(
                                      title: 'playback page',
                                      recording: recording,
                                      callback: () => updateDays(),
                                    )
                                  ),
                                );
                              },
                              style: ButtonStyle(
                                foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                                backgroundColor: MaterialStateProperty.all<Color>(Colors.transparent),
                              ),
                              child: Text(recording.title), // Accessing title from the Recording object
                            ),
                          ),
                        );
                      }).toList();

                      // Return a Column widget with all the ListTile widgets
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(
                            color: AppColors.darkGray, 
                            height: 12,
                          ), // Add a divider
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Text('$hour:00')
                          ), // Display hour
                          listTiles.isEmpty ? const SizedBox(height: 15) : const SizedBox(height: 0),
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
