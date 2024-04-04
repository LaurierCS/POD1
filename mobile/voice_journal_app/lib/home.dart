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

//init variables
//end of variables
class HomePage extends StatefulWidget {
  Function onNavigateToStats;
  HomePage({super.key, required this.onNavigateToStats});
  
  @override
  State<HomePage> createState() => HomePageState();
}
class RecordingList extends StatelessWidget {
  const RecordingList({super.key});

  Future<List<Recording>> _fetchRecordings() async {
    final box = await Hive.openBox<Recording>('recordings');
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
            child: Text('No recordings created yet.\nTap the + button to create one.'),
          );
        } else {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final reversedIndex = snapshot.data!.length - 1 - index;
              final recording = snapshot.data![reversedIndex];
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
                  child: Text(recording.title),
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
                  child: const RecordingList()
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
