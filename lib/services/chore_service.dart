import '../models/chore.dart';

/// Verwaltet die Haushaltsaufgaben (derzeit nur im Speicher)
class ChoreService {
  final List<Chore> _chores = [
    Chore(title: "Bad putzen"),
    Chore(title: "Staubsaugen"),
  ];

  List<Chore> get chores => _chores;

  void addChore(String title) {
    _chores.add(Chore(title: title));
  }

  void removeChore(int index) {
    _chores.removeAt(index);
  }

  void toggleChore(int index) {
    _chores[index].isDone = !_chores[index].isDone;
  }
}