import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:voice_journal_app/schema.dart';
import 'theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'schema.dart';
import 'Emotions_enums.dart';


enum TimeFrame { all, year, month, week }

class EmotionCount {
  final Emotions emotion;
  int count;
  EmotionCount(this.emotion, [this.count=0]);
}

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});
  @override
  StatsPageState createState() => StatsPageState();
}

// Mapping emotions to emojis for display under bars and on pie chart sections
final Map<Emotions, String> emotionToEmoji = {
  Emotions.happiness: '😊',
  Emotions.sadness: '😢',
  Emotions.fear: '😨',
  Emotions.surprise: '😲',
  Emotions.anger: '😠',
  Emotions.disgust: '😖',
};

class StatsPageState extends State<StatsPage> {
  @override
  TimeFrame _selectedTimeFrame = TimeFrame.all; // Default to 'all'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 60.0),
        child: Column(
          children: [
            // Container for time frame selection
            SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: TimeFrame.values.map((timeFrame) {
                  return ChoiceChip(
                    selectedColor: AppColors.secondaryColor,
                    labelStyle: TextStyle(
                      color: _selectedTimeFrame == timeFrame ? Colors.white : Colors.black,
                    ),
                    checkmarkColor: Colors.white,
                    label: Text(timeFrame.toString().split('.').last),
                    selected: _selectedTimeFrame == timeFrame,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedTimeFrame = timeFrame;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<EmotionCount>>(
                future: fetchEmotionCountsFromDatabase(),
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
                    // Pie chart sections
                    List<PieChartSectionData> pieSections = snapshot.data!
                        .map((emotionCount) => PieChartSectionData(
                              color: getColorForEmotion(emotionCount.emotion),
                              value: emotionCount.count.toDouble(),
                              title: '${(emotionCount.count / totalEmotionCount * 100).toStringAsFixed(1)}%',
                              radius: MediaQuery.of(context).size.width / 7,
                              titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xffffffff)),
                            ))
                        .toList();
                    return buildCharts(barGroups, pieSections, snapshot.data!);
                  } else {
                    return const Center(child: Text('No recordings created yet'));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget buildCharts(List<BarChartGroupData> barGroups, List<PieChartSectionData> pieSections, List<EmotionCount> data) {
    return Column(
      children: [
        // Bar Chart Expanded Widget
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 65.0),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: data.fold<int>(0, (max, e) => e.count > max ? e.count : max).toDouble(), // Calculate the maxY value dynamically
                titlesData: FlTitlesData(
                  bottomTitles: SideTitles(
                    showTitles: true,
                    getTextStyles: (context, value) => const TextStyle(color: Colors.black, fontSize: 14),
                    margin: 12,
                    getTitles: (double value) {
                      return emotionToEmoji[data[value.toInt()].emotion] ?? ''; // Using emoji as titles under bars
                    },
                  ),
                  leftTitles: SideTitles(showTitles: false),
                  topTitles: SideTitles(showTitles: false),
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    fitInsideHorizontally: true,
                    tooltipBgColor: Colors.blueGrey,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final Emotions emotion = data[group.x.toInt()].emotion;
                      final String count = data[group.x.toInt()].count.toString();
                      return BarTooltipItem(
                        '${emotion.name}: $count',
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ),
        // Pie Chart Expanded Widget
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
            child: AspectRatio(
              aspectRatio: 1.5, // The aspect ratio you want. For square use 1.
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 0, // Adjust this to change the size of the inner space of the pie chart
                  sectionsSpace: 0, // Adjust this to control the space between sections
                  sections: pieSections.map((section) => 
                    PieChartSectionData(
                      color: section.color,
                      value: section.value,
                      title: section.title,
                      radius: MediaQuery.of(context).size.width / 3, // This increases the pie chart size
                      titleStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<List<EmotionCount>> fetchEmotionCountsFromDatabase() async {
    var box = await Hive.openBox<Recording>('recordings'); // recordings not emotion counts
    //Create emotion counts starting at 0 and cretaing a loop
    //add based on emotion and check that it is within the time frame
    //What I had before but no longer static
    //check date and then subract 30 and if a recording is greater than 30 it goes to add month and so and so on so we could do it at a time for all 4
    //check if it has an emoution add to count if it has it add to the recordings
    //Return as before 
    // Assuming you want to return all items in the box

    List<EmotionCount> emotionCountList = [
      EmotionCount(Emotions.happiness),
      EmotionCount(Emotions.sadness),
      EmotionCount(Emotions.fear),
      EmotionCount(Emotions.surprise),
      EmotionCount(Emotions.anger),
      EmotionCount(Emotions.disgust),
    ];

    DateTime filterTime;
    // Switch statement to select time frame
    switch (_selectedTimeFrame) {
      case TimeFrame.year:
        filterTime = DateTime.now().subtract(const Duration(days: 365));
        break;
      case TimeFrame.month:
        filterTime = DateTime.now().subtract(const Duration(days: 30));
        break;
      case TimeFrame.week:
        filterTime = DateTime.now().subtract(const Duration(days: 7));
        break;
      default:
        filterTime = DateTime.now().subtract(const Duration(days: 365 * 100)); // All time
        break;
    }

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
}

Color getColorForEmotion(Emotions emotion) {
  switch (emotion) {
    case Emotions.happiness:
      return AppColors.happiness;
    case Emotions.sadness:
      return AppColors.sadness;
    case Emotions.fear:
      return AppColors.fear;
    case Emotions.surprise:
      return AppColors.surprise;
    case Emotions.anger:
      return AppColors.anger;
    case Emotions.disgust:
      return AppColors.disgust;
    default:
      return Colors.grey; // A default color for unknown emotions
  }
}