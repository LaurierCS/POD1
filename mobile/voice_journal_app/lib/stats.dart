import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'theme.dart'; // Make sure this is correctly pointing to your theme.dart

enum TimeFrame { all, year, month, week }

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
    'Contempt': '😒',
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
            height: 50,
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
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
                    final String emoji = emotionToEmoji[emotion] ?? '';
                    final String count = data[group.x.toInt()].count.toString();
                    return BarTooltipItem(
                      '$emoji $emotion: $count',
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
          child: PieChart(
            PieChartData(
              sections: pieSections,
              centerSpaceRadius: 0,
              sectionsSpace: 0,
            ),
          ),
        ),
      ),
    ],
  );
}



  Future<List<EmotionCount>> fetchEmotionCountsFromDatabase() async {
    // Mock data fetching logic or actual database fetching logic
    await Future.delayed(const Duration(seconds: 2)); // Simulating network/database delay

    // Example: adjust this to fetch data based on _selectedTimeFrame
    switch (_selectedTimeFrame) {
      case TimeFrame.week:
        // Return weekly data
        break;
      case TimeFrame.month:
        // Return monthly data
        break;
      case TimeFrame.year:
        // Return yearly data
        break;
      case TimeFrame.all:
      default:
        // Return all data
        break;
    }

    return [
      EmotionCount('Happiness', 10),
      EmotionCount('Sadness', 5),
      EmotionCount('Fear', 3),
      // Add more as needed
    ];
  }


  Color getColorForEmotion(String emotion) {
    switch (emotion) {
      case 'Happiness':
        return AppColors.happiness;
      case 'Sadness':
        return AppColors.sadness;
      case 'Fear':
        return AppColors.fear;
      case 'Contempt':
        return AppColors.contempt;
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