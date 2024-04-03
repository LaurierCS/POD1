import 'dart:js_interop';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:voice_journal_app/schema.dart';
import 'theme.dart';
import 'package:hive/hive.dart';
import 'Emotions_enums.dart';
//initializing variables
enum TimeFrame { all, year, month, week }
List<Emotions> allList =[];
List<Emotions> yearList =[];
List<Emotions> monthList =[];
List<Emotions> weekList =[];
//Done initialization




class EmotionCount {
  final String emotion;
  final int count;
  EmotionCount(this.emotion, this.count);
}

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});
  @override
  StatsPageState createState() => StatsPageState();
}

class StatsPageState extends State<StatsPage> {
  @override
  initState(){ //Page Initialization code, moved frome changed state.
    super.initState();
    //getEmotionsFromDatabase();
  }
  TimeFrame _selectedTimeFrame = TimeFrame.all; // Default to 'all'

  // Mapping emotions to emojis for display under bars and on pie chart sections
  final Map<String, String> emotionToEmoji = {
    'Happiness': '😊',
    'Sadness': '😢',
    'Fear': '😨',
    'Surprise': '😲',
    'Anger': '😠',
    'Disgust': '😖',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emotion Statistics'),
      ),
      body: Column(
        children: [
          // Container for time frame selection
          Container(
            height: 40,
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: TimeFrame.values.map((timeFrame) {
                return ChoiceChip(
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
          SizedBox(height: 10),
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
                            showingTooltipIndicators: [0],
                          ))
                      .toList();
                  // Pie chart sections
                  List<PieChartSectionData> pieSections = snapshot.data!
                      .map((emotionCount) => PieChartSectionData(
                            color: getColorForEmotion(emotionCount.emotion),
                            value: emotionCount.count.toDouble(),
                            title: '${(emotionCount.count / totalEmotionCount * 100).toStringAsFixed(1)}%',
                            radius: MediaQuery.of(context).size.width / 7,
                            titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xffffffff)),
                          ))
                      .toList();
                  return buildCharts(barGroups, pieSections, snapshot.data!);
                } else {
                  return const Center(child: Text('No data found'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
Widget buildCharts(List<BarChartGroupData> barGroups, List<PieChartSectionData> pieSections, List<EmotionCount> data) {
  return Column(
    children: [
      // Bar Chart Expanded Widget
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 65.0),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: data.fold<int>(0, (max, e) => e.count > max ? e.count : max).toDouble(), // Calculate the maxY value dynamically
              titlesData: FlTitlesData(
                bottomTitles: SideTitles(
                  showTitles: true,
                  getTextStyles: (context, value) => const TextStyle(color: Colors.black, fontSize: 14),
                  margin: 16,
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
                    final String emotion = data[group.x.toInt()].emotion;
                    final String count = data[group.x.toInt()].count.toString();
                    return BarTooltipItem(
                      '$emotion: $count',
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
              titleStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xffffffff),
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
  await Future.delayed(const Duration(seconds: 2)); // Simulate network/database delay

  // Example mock data for different spans
  //List<int> values = countEmotions(allList);
  List<EmotionCount> allData = [
    EmotionCount('Happiness', 0),
    EmotionCount('Sadness', 1),
    EmotionCount('Fear', 2),
    EmotionCount('Surprise', 3),
    EmotionCount('Anger', 4),
    EmotionCount('Disgust', 5),
  ];
  List<EmotionCount> yearData = [ 
    EmotionCount('Happiness', 0),
    EmotionCount('Sadness', 1),
    EmotionCount('Fear', 2),
    EmotionCount('Surprise', 3),
    EmotionCount('Anger', 4),
    EmotionCount('Disgust', 5),
  ];

  List<EmotionCount> monthData = [
    EmotionCount('Happiness', 0),
    EmotionCount('Sadness', 1),
    EmotionCount('Fear', 2),
    EmotionCount('Surprise',3),
    EmotionCount('Anger', 4),
    EmotionCount('Disgust', 5),
  ];

  List<EmotionCount> weekData = [
    EmotionCount('Happiness', 0),
    EmotionCount('Sadness', 1),
    EmotionCount('Fear', 2),
    EmotionCount('Surprise', 3),
    EmotionCount('Anger', 4),
    EmotionCount('Disgust', 5),
  ];

  // Switch statement to return data based on selected time span
  switch (_selectedTimeFrame) {
    case TimeFrame.all:
      return allData;
    case TimeFrame.year:
      return yearData;
    case TimeFrame.month:
      return monthData;
    case TimeFrame.week:
      return weekData;
    default:
      return allData; // Default case returns all data
  }
}
  Color getColorForEmotion(String emotion) {
    switch (emotion) {
      case 'Happiness':
        return AppColors.happiness;
      case 'Sadness':
        return AppColors.sadness;
      case 'Fear':
        return AppColors.fear;
      case 'Surprise':
        return AppColors.surprise;
      case 'Anger':
        return AppColors.anger;
      case 'Disgust':
        return AppColors.disgust;
      default:
        return Colors.grey; // A default color for unknown emotions
  }
}
getEmotionsFromDatabase(){
  DateTime dayCheck = DateTime.now().subtract(const Duration(days: 1));
  DateTime monthCheck = DateTime.now().subtract(const Duration(days: 31));
  final rbox = Hive.box<Recording>('recordings');
  int iterator = rbox.length;
  for(int i = 0; i < iterator; i++){
    var fetchedRecording = rbox.getAt(i);
    if(fetchedRecording != null){
      DateTime date = fetchedRecording.timeStamp;
      bool isWeek = checkValid(date, 7); //check if the recording is less than a week old
      if(isWeek){ //if the checked recording is less than a week old then it is therefore also less than a week, month and year old so add it to everything.
        allList.addAll(fetchedRecording.emotion);
        yearList.addAll(fetchedRecording.emotion); 
        weekList.addAll(fetchedRecording.emotion); 
        monthList.addAll(fetchedRecording.emotion);
      } else{ //more than a week old
        bool isMonth = checkValid(date, 31);
        if(isMonth){
          yearList.addAll(fetchedRecording.emotion);
          monthList.addAll(fetchedRecording.emotion);
          allList.addAll(fetchedRecording.emotion);
        } else{ //more than a month old
          bool isYear = checkValid(date, 365);
          if(isYear){
            allList.addAll(fetchedRecording.emotion);
            yearList.addAll(fetchedRecording.emotion);
          } else{ //more than a year old
            allList.addAll(fetchedRecording.emotion); //okay so just add it to the all list.
          }
        }
      }
    }
  }
  print(allList.toString());
  print(monthList.toString());
  print(yearList.toString());
  print(weekList.toString());

}
bool checkValid(DateTime date, int timePeriod){
  DateTime weekCheck = DateTime.now().subtract(Duration(days: timePeriod));
  DateTime now = DateTime.now();
  return date.isAfter(weekCheck) && date.isBefore(now);
}
}
List<int> countEmotions(List list){
  List<int> count = [];
  int hapCount = list.where((item) => item == Emotions.happiness).length;
  int sadCount = list.where((item) => item == Emotions.sadness).length;
  int fearCount = list.where((item) => item == Emotions.fear).length;
  int surpriseCount = list.where((item) => item == Emotions.surprise).length;
  int angreCount = list.where((item) => item == Emotions.anger).length;
  int disCount = list.where((item) => item == Emotions.disgust).length;
  count.add(hapCount);
  count.add(sadCount);
  count.add(fearCount);
  count.add(surpriseCount);
  count.add(angreCount);
  count.add(disCount);
  return count;
}
