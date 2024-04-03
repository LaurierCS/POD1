import 'package:flutter/material.dart';
import 'package:voice_journal_app/stats.dart';
import 'package:voice_journal_app/theme.dart';
import 'home.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'schema.dart';
 
void main()async { 
  await Hive.initFlutter(); //Initialize hive for flutter crucial step
  Hive.registerAdapter(RecordingAdapter()); //Register the adapter, essentially telling Hive how to read and write our Recording information into a box
  await Hive.openBox<Recording>('recordings');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EMOZ', // Your app title
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryColor, // Use primaryColor as seed color
          primary: AppColors.primaryColor,
          secondary: AppColors.secondaryColor,
          // Define other custom colors as needed
        ),
        // Customize other theme properties based on AppColors
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.accentColor, // Custom FAB color
        ),
        scaffoldBackgroundColor: AppColors.lightGray, // Background color for Scaffold widgets
        // Add more theme customization as needed
        useMaterial3: true, // Opt-in to use Material 3 features
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

enum Page { stats, home, calendar }

class _MainPageState extends State<MainPage> {
  Page _currPage = Page.home;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currPage.index,
        children: const <Widget>[
          StatsPage(),
          HomePage(),
          Text("Calendar Page"),
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: 80,
        child: BottomNavigationBar(
          currentIndex: _currPage.index,
          onTap: (value) => setState(() => _currPage = Page.values[value]),
          showSelectedLabels: true,
          showUnselectedLabels: false,
          iconSize: 28,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_graph),
              label: 'Stats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.date_range),
              label: 'Calendar',
            ),
          ],
        ),
      ),
    );
  }
}