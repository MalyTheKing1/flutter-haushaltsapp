import 'package:flutter/material.dart';
import '../services/todo_service.dart';
import '../widgets/todo_item.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final TodoService _todoService = TodoService();

  void _addTodo() {
    setState(() {
      _todoService.addTodo("Neues To-Do");
    });
  }

  @override
  Widget build(BuildContext context) {
    final todos = _todoService.todos;

    return Scaffold(
      appBar: AppBar(title: const Text("To-Do Liste")),
      body: ListView.builder(
        itemCount: todos.length,
        itemBuilder: (context, index) {
          return TodoItem(
            todo: todos[index],
            onDelete: () {
              setState(() {
                _todoService.removeTodo(index);
              });
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTodo,
        child: const Icon(Icons.add),
      ),
    );
  }
}