import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive and open the box
  await Hive.initFlutter();
  await Hive.openBox('notesBox');

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes App',
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      // Light theme
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(
          elevation: 2,
        ),
        floatingActionButtonTheme:
        const FloatingActionButtonThemeData(backgroundColor: Colors.teal),
      ),
      // Dark theme
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme:
        ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark),
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(
          elevation: 2,
        ),
        floatingActionButtonTheme:
        const FloatingActionButtonThemeData(backgroundColor: Colors.teal),
      ),
      home: HomePage(isDarkMode: isDarkMode, onToggleTheme: toggleTheme),
    );
  }
}

