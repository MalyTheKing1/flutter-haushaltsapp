import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/settings.dart';
import 'services/hive_service.dart';
import 'screens/settings_screen.dart';
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
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Box<Settings> _settingsBox;

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box<Settings>(HiveService.settingsBoxName);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _settingsBox.listenable(),
      builder: (context, Box<Settings> box, _) {
        final isDarkMode = box.values.first.isDarkMode;

        return MaterialApp(
          title: 'Haushaltsplaner',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: isDarkMode ? Brightness.dark : Brightness.light,
            primarySwatch: Colors.teal,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: const MainPage(),
        );
      },
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
      appBar: AppBar(
        title: const Text('Haushaltsplaner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
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
            label: 'Haushalt',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_box),
            label: 'To-Do',
          ),
        ],
        currentIndex: _tabController.index,
        selectedItemColor: Colors.teal,
        onTap: _onItemTapped,
      ),
    );
  }
}
