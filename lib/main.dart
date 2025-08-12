import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/settings.dart';
import 'services/notification_service.dart';
import 'services/hive_service.dart';
import 'screens/settings_screen.dart';
import 'screens/recurring_tasks_screen.dart';
import 'screens/onetime_tasks_screen.dart';
// 👉 NEU: Notizen-Tab
import 'screens/notes_screen.dart';

Future<void> deleteAllHiveData() async {
  print("🧨 Lösche alle Hive-Daten (Settings, Tasks)...");
  await Hive.deleteBoxFromDisk(HiveService.recurringBoxName);
  await Hive.deleteBoxFromDisk(HiveService.onetimeBoxName);
  await Hive.deleteBoxFromDisk(HiveService.settingsBoxName);
  // 👉 NEU: Notizen-Box ebenfalls löschen
  await Hive.deleteBoxFromDisk(HiveService.notesBoxName);
  print("✅ Alle Hive-Daten wurden gelöscht");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive initialisieren
  await Hive.initFlutter();
  await HiveService.registerAdapters();

  // 👉 Nur für Debug/Entwicklung: Lösche ALLE gespeicherten Daten beim Start
  // await deleteAllHiveData();

  await HiveService.openBoxes();
  await NotificationService().init();
  await NotificationService().requestNotificationPermission();

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
    // 👉 NEU: 3 Tabs (Haushalt, To-Do, Notizen)
    _tabController = TabController(length: 3, vsync: this);

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
        title: const Text('Daily Helper'),
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
          // 👉 NEU: Notizen-Screen
          NotesScreen(),
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
          // 👉 NEU: Dritter Tab
          BottomNavigationBarItem(
            icon: Icon(Icons.note_alt_outlined),
            label: 'Notizen',
          ),
        ],
        currentIndex: _tabController.index,
        selectedItemColor: Colors.teal,
        onTap: _onItemTapped,
      ),
    );
  }
}
