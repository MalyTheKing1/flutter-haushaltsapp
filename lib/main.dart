// lib/main.dart
import 'dart:async'; // für Timer
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/settings.dart';
import 'services/notification_service.dart';
import 'services/hive_service.dart';
import 'screens/settings_screen.dart';
import 'screens/recurring_tasks_screen.dart';
import 'screens/onetime_tasks_screen.dart';
// Notizen-Tab (normal)
import 'screens/notes_screen.dart';
// Geheimer Notizen-Screen (eigene Seite mit Zurück-Pfeil)
import 'screens/secret_notes_screen.dart';

Future<void> deleteAllHiveData() async {
  print("🧨 Lösche alle Hive-Daten (Settings, Tasks)...");
  await Hive.deleteBoxFromDisk(HiveService.recurringBoxName);
  await Hive.deleteBoxFromDisk(HiveService.onetimeBoxName);
  await Hive.deleteBoxFromDisk(HiveService.settingsBoxName);
  // Notizen-Box ebenfalls löschen
  await Hive.deleteBoxFromDisk(HiveService.notesBoxName);
  print("✅ Alle Hive-Daten wurden gelöscht");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive initialisieren
  await Hive.initFlutter();
  await HiveService.registerAdapters();

  // Nur für Debug/Entwicklung: Lösche ALLE gespeicherten Daten beim Start
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

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ▶ Secret-Hold State
  Timer? _secretTimer;
  bool _secretPressActive = false;

  // ▶ Guard gegen Re-Entrancy/Navigationsrennen
  bool _secretRouteOpen = false;

  @override
  void initState() {
    super.initState();
    // 3 Tabs (Haushalt, To-Do, Notizen)
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
    _cancelSecretTimer(); // sicherheitshalber abbrechen
    _tabController.dispose();
    super.dispose();
  }

  /// Wechsel durch Tippen auf BottomNavigationBar
  void _onItemTapped(int index) {
    _tabController.animateTo(index);
  }

  // -----------------------------------------
  // Secret-Flow (robust mit LongPressStart/End)
  // -----------------------------------------

  void _cancelSecretTimer() {
    _secretTimer?.cancel();
    _secretTimer = null;
    _secretPressActive = false;
  }

  // Start bei LongPressStart
  void _startSecretHold() {
    if (_secretRouteOpen) return; // bereits unterwegs → ignorieren
    _cancelSecretTimer();
    _secretPressActive = true;

    _secretTimer = Timer(const Duration(seconds: 2), () async {
      if (!_secretPressActive || !mounted || _secretRouteOpen) return;
      _secretPressActive = false;

      final ok = await _showPinDialog();
      if (!mounted || _secretRouteOpen) return;

      if (ok) {
        _secretRouteOpen = true; // Guard setzen, bevor wir navigieren
        _cancelSecretTimer();

        // Navigation in geheimen Bereich (eigene Seite mit Back-Pfeil)
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const SecretNotesScreen()))
            .then((_) {
          // Nach Rückkehr Guard zurücksetzen
          _secretRouteOpen = false;
          _cancelSecretTimer();
        });
      }
    });
  }

  // Ende bei LongPressEnd/Cancel
  void _endSecretHold() {
    _cancelSecretTimer();
  }

  /// PIN-Dialog (beliebige Länge möglich)
  Future<bool> _showPinDialog() async {
    // 👇 PIN hier frei ändern (beliebige Länge möglich)
    const String correctPin = '6789';

    final int expectedLen = correctPin.length;
    final controller = TextEditingController();
    String? errorText;

    if (!mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // absichtliches Schließen verhindern
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('PIN eingeben'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: expectedLen, // folgt der PIN-Länge
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    counterText: '',
                    hintText: '•' * expectedLen,
                    errorText: errorText,
                  ),
                  onSubmitted: (_) {
                    final ok = controller.text == correctPin;
                    if (!ok) {
                      setState(() => errorText = 'Falscher PIN');
                    } else {
                      Navigator.of(ctx).pop(true);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () {
                  final ok = controller.text == correctPin;
                  if (!ok) {
                    setState(() => errorText = 'Falscher PIN');
                  } else {
                    Navigator.of(ctx).pop(true);
                  }
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );

    return result ?? false;
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
          // Notizen-Screen (normal)
          NotesScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.repeat),
            label: 'Haushalt',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.check_box),
            label: 'To-Do',
          ),
          // Dritter Tab – Icon bekommt Long-Press für Secret-Flow
  BottomNavigationBarItem(
            icon: GestureDetector(
              behavior: HitTestBehavior.opaque, // großzügige Hitbox
              onLongPressStart: (_) => _startSecretHold(), // ▶ Start 2s
              onLongPressEnd:   (_) => _endSecretHold(),   // ▶ Abbruch beim Loslassen
              onLongPressCancel: _endSecretHold,           // ▶ Abbruch bei Abbruch
              child: const Icon(Icons.note_alt_outlined),
            ),
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
