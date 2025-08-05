import 'package:flutter/material.dart';
import '../services/chore_service.dart';
import '../widgets/chore_item.dart';

class ChoresScreen extends StatefulWidget {
  const ChoresScreen({super.key});

  @override
  State<ChoresScreen> createState() => _ChoresScreenState();
}

class _ChoresScreenState extends State<ChoresScreen> {
  final ChoreService _choreService = ChoreService();

  void _addChore() {
    setState(() {
      _choreService.addChore("Neue Aufgabe");
    });
  }

  @override
  Widget build(BuildContext context) {
    final chores = _choreService.chores;

    return Scaffold(
      appBar: AppBar(title: const Text("Haushaltsaufgaben")),
      body: ListView.builder(
        itemCount: chores.length,
        itemBuilder: (context, index) {
          return ChoreItem(
            chore: chores[index],
            onToggle: () {
              setState(() {
                _choreService.toggleChore(index);
              });
            },
            onDelete: () {
              setState(() {
                _choreService.removeChore(index);
              });
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addChore,
        child: const Icon(Icons.add),
      ),
    );
  }
}