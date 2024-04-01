import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'schema.dart'; // Your schema import
import 'stats.dart'; // Your StatsPage import
import 'theme.dart'; // Your theme import
import 'home.dart'; // Your HomePage import

void main() async {
  // Ensure widgets are initialized
  // WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register the adapter
  Hive.registerAdapter(RecordingAdapter());


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
      home: const HomePage(),
    );
  }
}
