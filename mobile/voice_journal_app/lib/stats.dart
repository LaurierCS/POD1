import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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

class StatsPageState extends State<StatsPage> {
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
          const SizedBox(height: 10),
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
                            titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xffffffff)),
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
                    final Emotions emotion = data[group.x.toInt()].emotion;
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
              titleStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xffffffff),
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
  // return box.values.toList();
  List<EmotionCount> allData = [
    EmotionCount(Emotions.happiness),
    EmotionCount(Emotions.sadness),
    EmotionCount(Emotions.fear),
    EmotionCount(Emotions.surprise),
    EmotionCount(Emotions.anger),
    EmotionCount(Emotions.disgust),
  ];

  List<EmotionCount> yearData = [
    EmotionCount(Emotions.happiness),
    EmotionCount(Emotions.sadness),
    EmotionCount(Emotions.fear),
    EmotionCount(Emotions.surprise),
    EmotionCount(Emotions.anger),
    EmotionCount(Emotions.disgust),
  ];

  List<EmotionCount> monthData = [
    EmotionCount(Emotions.happiness),
    EmotionCount(Emotions.sadness),
    EmotionCount(Emotions.fear),
    EmotionCount(Emotions.surprise),
    EmotionCount(Emotions.anger),
    EmotionCount(Emotions.disgust),
  ];

  List<EmotionCount> weekData = [
    EmotionCount(Emotions.happiness),
    EmotionCount(Emotions.sadness),
    EmotionCount(Emotions.fear),
    EmotionCount(Emotions.surprise),
    EmotionCount(Emotions.anger),
    EmotionCount(Emotions.disgust),
  ];
  DateTime currTime = DateTime.now();
  for (Recording recordingInstance in box.values){
    if (recordingInstance.timeStamp.isAfter(currTime.subtract(const Duration(days: 365)))){
      for (Emotions emotion in recordingInstance.emotion){
        for (EmotionCount emotionCount in yearData){
          if (emotionCount.emotion == emotion){
            emotionCount.count++;
          }
        }
      }
    }
    if (recordingInstance.timeStamp.isAfter(currTime.subtract(const Duration(days: 30)))){
      for (Emotions emotion in recordingInstance.emotion){
        for (EmotionCount emotionCount in monthData){
          if (emotionCount.emotion == emotion){
            emotionCount.count++;
          }
        }
      }
    }
    if (recordingInstance.timeStamp.isAfter(currTime.subtract(const Duration(days: 7)))){
      for (Emotions emotion in recordingInstance.emotion){
        for (EmotionCount emotionCount in weekData){
          if (emotionCount.emotion == emotion){
            emotionCount.count++;
          }
        }
      }
    }
    for (Emotions emotion in recordingInstance.emotion){
      for (EmotionCount emotionCount in allData){
        if (emotionCount.emotion == emotion){
          emotionCount.count++;
        }
      }
    }
  }


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
}
