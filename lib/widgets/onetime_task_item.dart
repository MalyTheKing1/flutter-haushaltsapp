import 'package:flutter/material.dart';

import '../models/onetime_task.dart';

/// Einzelne Listeneinträge für einmalige Aufgaben
class OnetimeTaskItem extends StatelessWidget {
  final OneTimeTask task;
  final VoidCallback onDelete;

  const OnetimeTaskItem({
    super.key,
    required this.task,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: key,
      title: Text(task.title),
      trailing: IconButton(
        icon: const Icon(Icons.check_box),
        onPressed: onDelete,
        tooltip: 'Aufgabe abhaken und löschen',
      ),
    );
  }
}
