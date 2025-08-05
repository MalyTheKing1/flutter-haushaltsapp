import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'services/hive_service.dart';
import 'screens/recurring_tasks_screen.dart';
import 'screens/onetime_tasks_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive initialisieren
  await Hive.initFlutter();
  await HiveService.registerAdapters();
  await HiveService.openBoxes();

  runApp(const MyApp());
}

/// Haupt-App Widget mit zwei Tabs
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Haushaltsplaner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainPage(),
    );
  }
}

/// Hauptseite mit BottomNavigationBar (2 Tabs)
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  static final List<Widget> _tabs = <Widget>[
    const RecurringTasksScreen(),
    const OneTimeTasksScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.repeat),
            label: 'Wiederkehrend',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_box),
            label: 'Einmalig',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        onTap: _onItemTapped,
      ),
    );
  }
}
