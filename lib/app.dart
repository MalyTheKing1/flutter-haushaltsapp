import 'package:flutter/material.dart';
import 'screens/chores_screen.dart';
import 'screens/todo_screen.dart';

/// MaterialApp und Navigation mit BottomNavigationBar
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    ChoresScreen(),
    TodoScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Haushalts-App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onTabTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Haushalt',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_box),
              label: 'To-Do',
            ),
          ],
        ),
      ),
    );
  }
}