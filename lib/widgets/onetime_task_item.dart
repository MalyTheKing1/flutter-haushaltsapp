import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/onetime_task.dart';

/// Einzelne Listeneinträge für einmalige Aufgaben mit Animation + Bearbeiten per LongPress
class OnetimeTaskItem extends StatefulWidget {
  final OneTimeTask task;
  final VoidCallback onDelete;

  const OnetimeTaskItem({
    super.key,
    required this.task,
    required this.onDelete,
  });

  @override
  State<OnetimeTaskItem> createState() => _OnetimeTaskItemState();
}

class _OnetimeTaskItemState extends State<OnetimeTaskItem>
    with SingleTickerProviderStateMixin {
  double _opacity = 1.0;
  double _scale = 1.0;
  bool _isAnimating = false;
  Color _tileColor = Colors.transparent;

  void _handleCheck() async {
    if (_isAnimating) return;

    setState(() {
      _isAnimating = true;
      _scale = 1.2;
      _tileColor = Colors.green.withOpacity(0.3);
    });

    HapticFeedback.lightImpact();

    await Future.delayed(const Duration(milliseconds: 100));
    setState(() {
      _scale = 1.0;
    });

    await Future.delayed(const Duration(milliseconds: 150));
    setState(() {
      _tileColor = Colors.transparent;
    });

    await Future.delayed(const Duration(milliseconds: 100));
    setState(() {
      _opacity = 0.0;
    });

    await Future.delayed(const Duration(milliseconds: 300));
    widget.onDelete();
  }

  void _editTaskTitle(BuildContext context) async {
    final TextEditingController controller =
        TextEditingController(text: widget.task.title);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aufgabe bearbeiten'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Neuer Titel'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Abbrechen
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      setState(() {
        widget.task.title = result.trim();
      });

      // Persistiere Änderung in Hive, falls möglich
      try {
        await widget.task.save();
      } catch (e) {
        debugPrint('Konnte Aufgabe nicht speichern: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: _opacity,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: _tileColor,
          child: ListTile(
            key: widget.key,
            title: Text(widget.task.title),
            trailing: IconButton(
              icon: const Icon(Icons.check_box),
              onPressed: _handleCheck,
              tooltip: 'Aufgabe abhaken und löschen',
            ),
            onLongPress: () => _editTaskTitle(context),
          ),
        ),
      ),
    );
  }
}
