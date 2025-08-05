import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/onetime_task.dart';
import '../services/hive_service.dart';

/// UI-Element für einmalige Aufgaben
class OneTimeTaskItem extends StatelessWidget {
  final OneTimeTask task;

  const OneTimeTaskItem({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      key: key,
      child: ListTile(
        title: Text(task.title),
        trailing: IconButton(
          icon: const Icon(Icons.check, color: Colors.green),
          onPressed: () {
            Hive.box<OneTimeTask>(HiveService.onetimeBoxName).delete(task.key);
          },
        ),
        onLongPress: () {
          Hive.box<OneTimeTask>(HiveService.onetimeBoxName).delete(task.key);
        },
      ),
    );
  }
}
