import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:voice_journal_app/Emotions_enums.dart';
import 'package:voice_journal_app/Playback.dart';
import 'package:voice_journal_app/stats.dart';
import 'theme.dart';
import 'RecordingPage.dart';
import 'package:hive/hive.dart'; //Importing the local database
import 'package:hive_flutter/hive_flutter.dart';
import 'schema.dart';
import 'Emotions_enums.dart';

//init variables
MaterialStateProperty <Color> emotionColor = MaterialStateProperty.all<Color>(AppColors.mutedTeal);
//end of variables

class HomePage extends StatefulWidget {
  Function onNavigateToStats;
  HomePage({super.key, required this.onNavigateToStats});
  
  @override
  State<HomePage> createState() => HomePageState();
}
class RecordingList extends StatelessWidget {
  const RecordingList({super.key, required this.updateList});
  final Function updateList;
  Future<List<Recording>> _fetchRecordings() async {
    final box = Hive.box<Recording>('recordings');
    return box.values.toList();
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Recording>>(
      future: _fetchRecordings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No recordings created yet.\nTap the + button to create one.',
              textAlign: TextAlign.center,
            ),
          );
        } else {
          return ListView.builder(
            padding: const EdgeInsets.only(top: 16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final reversedIndex = snapshot.data!.length - 1 - index;
              final recording = snapshot.data![reversedIndex];
              int length = recording.emotion.length;
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
                        MaterialPageRoute(builder: (context) => PlaybackPage(title: 'playback page', callback: () => updateList(), recording: recording)),
                      );
                    },
                    style: ButtonStyle(
                      foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                      backgroundColor: MaterialStateProperty.all<Color>(Colors.transparent),
                    ),
                    child: Text(recording.title),
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }
}

class EmotionChart extends StatelessWidget {
  final Function onNavigateToStats;
  const EmotionChart({super.key, required this.onNavigateToStats});

  Future<List<EmotionCount>> fetchWeeklyEmotionCountsFromDatabase() async {
    var box = await Hive.openBox<Recording>('recordings');

    List<EmotionCount> emotionCountList = [
      EmotionCount(Emotions.happiness),
      EmotionCount(Emotions.sadness),
      EmotionCount(Emotions.fear),
      EmotionCount(Emotions.surprise),
      EmotionCount(Emotions.anger),
      EmotionCount(Emotions.disgust),
    ];

    DateTime filterTime = DateTime.now().subtract(const Duration(days: 7));

    for (Recording recordingInstance in box.values){
      if (recordingInstance.timeStamp.isAfter(filterTime)){
        for (Emotions emotion in recordingInstance.emotion){
          for (EmotionCount emotionCount in emotionCountList){
            if (emotionCount.emotion == emotion){
              emotionCount.count++;
            }
          }
        }
      }
    }

    return emotionCountList;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: fetchWeeklyEmotionCountsFromDatabase(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final totalEmotionCount = snapshot.data!.fold<int>(0, (sum, item) => sum + item.count);
          if (totalEmotionCount == 0) {
            return const Center(child: Text('No emotion data yet'));
          }

          // List of bar chart groups with emojis under bars
          List<BarChartGroupData> barGroups = snapshot.data!
              .asMap()
              .entries
              .map((entry) => BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        y: entry.value.count.toDouble(),
                        colors: [getColorForEmotion(entry.value.emotion)],
                        width: 22,
                      ),
                    ],
                  ))
              .toList();

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onNavigateToStats(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: snapshot.data!.fold<int>(0, (max, e) => e.count > max ? e.count : max).toDouble(), // Calculate the maxY value dynamically
                  titlesData: FlTitlesData(
                    bottomTitles: SideTitles(
                      showTitles: true,
                      getTextStyles: (context, value) => const TextStyle(color: Colors.black, fontSize: 14),
                      margin: 12,
                      getTitles: (double value) {
                        return emotionToEmoji[snapshot.data![value.toInt()].emotion] ?? ''; // Using emoji as titles under bars
                      },
                    ),
                    leftTitles: SideTitles(showTitles: false),
                    rightTitles: SideTitles(showTitles: false),
                    topTitles: SideTitles(showTitles: false),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                ),
              ),
            ),
          );
        } else {
          return const Center(child: Text('No recordings created yet'));
        }
      },
    );
  }
}

class HomePageState extends State<HomePage>{
  void updateList(){
    setState(() {
      
    });
  }
  @override
  Widget build(BuildContext context) {
    setState(() {
      
    });
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0), // Horizontal padding for white space
        child: Container(
          padding: const EdgeInsets.only(bottom: 60.0, top: 90.0), // Adjusted to accommodate FAB and title
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end, // Aligns children to the bottom
            crossAxisAlignment: CrossAxisAlignment.stretch, // Stretches children horizontally to match the column width
            children: <Widget>[
              const Text(
                'Emoz',
                textAlign: TextAlign.center, //
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.black, 
                ),
              ),
              const SizedBox(height: 20), // Adds space between the title and the first container
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor, // Background color
                  borderRadius: BorderRadius.circular(10), // Rounds corners
                ), // Placeholder text
                margin: const EdgeInsets.only(bottom: 20, top: 20),
                child: EmotionChart(onNavigateToStats: widget.onNavigateToStats),
              ),
                Expanded( // 
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor, // Background color of the rectangle
                      borderRadius: BorderRadius.circular(10), // Rounded corners
                    ),
                    child: RecordingList(updateList: updateList)
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RecordingPage(title: 'recording page', callback: updateList)),
              );
          },
        backgroundColor: AppColors.accentColor,
        child: const Icon(Icons.add_circle_rounded),
      ),
    );
  }
}
