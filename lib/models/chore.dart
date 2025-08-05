/// Einfaches Datenmodell für Haushaltsaufgaben
class Chore {
  String title;
  bool isDone;

  Chore({required this.title, this.isDone = false});
}