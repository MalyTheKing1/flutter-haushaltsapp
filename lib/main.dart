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

/// Haupt-App Widget
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

/// Hauptseite mit BottomNavigationBar + Swipe-Funktion
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Wenn per Swipe gewechselt wird → BottomNavigationBar aktualisieren
    _tabController.addListener(() {
      if (_tabController.indexIsChanging == false) {
        setState(() {}); // rebuild für neuen Index
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Wechsel durch Tippen auf BottomNavigationBar
  void _onItemTapped(int index) {
    _tabController.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        controller: _tabController,
        children: const [
          RecurringTasksScreen(),
          OneTimeTasksScreen(),
        ],
      ),
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
        currentIndex: _tabController.index,
        selectedItemColor: Colors.teal,
        onTap: _onItemTapped,
      ),
    );
  }
}
