// lib/widgets/onetime_task_item.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/onetime_task.dart';

/// Einzelne Listeneinträge für einmalige Aufgaben mit Animation + Bearbeiten per LongPress
class OnetimeTaskItem extends StatefulWidget {
  final OneTimeTask task;
  final VoidCallback onDelete;

  // 👉 Optionales Leading-Widget (z. B. unser Reorder-Drag-Handle)
  final Widget? leading;

  const OnetimeTaskItem({
    super.key,
    required this.task,
    required this.onDelete,
    this.leading,
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
    setState(() => _scale = 1.0);

    await Future.delayed(const Duration(milliseconds: 150));
    setState(() => _tileColor = Colors.transparent);

    await Future.delayed(const Duration(milliseconds: 100));
    setState(() => _opacity = 0.0);

    await Future.delayed(const Duration(milliseconds: 300));
    widget.onDelete();
  }

  Future<void> _editTaskTitle(BuildContext context) async {
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
            // 👈 Kompaktes Drag-Handle (Reorder via ReorderableDragStartListener im Screen)
            minLeadingWidth: 28,        // engerer Abstand zwischen Handle und Text
            leading: widget.leading,
            // 👉 Long-Press NUR auf dem Text/Body → öffnet Edit sofort beim Halten
            title: GestureDetector(
              behavior: HitTestBehavior.opaque, // größerer Trefferbereich um den Text
              onLongPress: () {
                HapticFeedback.selectionClick();
                _editTaskTitle(context); // sofort beim Halten öffnen
              },
              child: Text(widget.task.title),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.check_box),
              onPressed: _handleCheck,
              tooltip: 'Aufgabe abhaken und löschen',
            ),
          ),
        ),
      ),
    );
  }
}
