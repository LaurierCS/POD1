import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'theme.dart';

enum TimeFrame { all, year, month, week }
enum Emotions {
 	happiness, // id = 0
  sadness, // id = 1
  anger, // id = 2
  fear, // id = 3
  disgust, // id = 4
  surprise, // id = 5
}

class EmotionCount {
  final String emotion;
  final int count;
  EmotionCount(this.emotion, this.count);
}

class StatsPage extends StatefulWidget {
  StatsPage({Key? key}) : super(key: key);
  @override
  _StatsPageState createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
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
                touchTooltipData: BarTouchTooltipData(
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
  List<EmotionCount> allData = [
    EmotionCount('Happiness', 100),
    EmotionCount('Sadness', 70),
    EmotionCount('Fear', 40),
    EmotionCount('Surprise', 80),
    EmotionCount('Anger', 60),
    EmotionCount('Disgust', 20),
  ];

  List<EmotionCount> yearData = [
    EmotionCount('Happiness', 90),
    EmotionCount('Sadness', 50),
    EmotionCount('Fear', 30),
    EmotionCount('Surprise', 70),
    EmotionCount('Anger', 55),
    EmotionCount('Disgust', 15),
  ];

  List<EmotionCount> monthData = [
    EmotionCount('Happiness', 80),
    EmotionCount('Sadness', 40),
    EmotionCount('Fear', 20),
    EmotionCount('Surprise', 60),
    EmotionCount('Anger', 45),
    EmotionCount('Disgust', 5),
  ];

  List<EmotionCount> weekData = [
    EmotionCount('Happiness', 10),
    EmotionCount('Sadness', 7),
    EmotionCount('Fear', 3),
    EmotionCount('Surprise', 5),
    EmotionCount('Anger', 8),
    EmotionCount('Disgust', 4),
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
}