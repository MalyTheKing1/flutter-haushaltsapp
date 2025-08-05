import 'package:hive/hive.dart';

part 'onetime_task.g.dart';

/// Modell für einmalige Aufgaben
@HiveType(typeId: 1)
class OneTimeTask extends HiveObject {
  @HiveField(0)
  String title;

  OneTimeTask({required this.title});
}
