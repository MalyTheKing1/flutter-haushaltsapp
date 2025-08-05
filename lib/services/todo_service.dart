import '../models/todo.dart';

/// Verwaltet die To-Do Liste (derzeit nur im Speicher)
class TodoService {
  final List<Todo> _todos = [
    Todo(title: "Milch kaufen"),
    Todo(title: "E-Mail schreiben"),
  ];

  List<Todo> get todos => _todos;

  void addTodo(String title) {
    _todos.add(Todo(title: title));
  }

  void removeTodo(int index) {
    _todos.removeAt(index);
  }
}