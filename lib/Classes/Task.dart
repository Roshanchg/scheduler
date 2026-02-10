import 'package:flutter/material.dart';
import 'package:scheduler/Enums/TaskTypes.dart';

class Task {
  final int id;
  final String name;
  final String desc;
  final TASKTYPES type;
  final bool isAlarm;
  final TimeOfDay time;
  const Task({
    required this.id,
    required this.time,
    required this.name,
    required this.desc,
    required this.type,
    required this.isAlarm,
  });
  Map<String, String> toMap() {
    return {
      'id': id.toString(),
      'name': name,
      'desc': desc,
      'type': type.name,
      'isAlarm': (isAlarm) ? '1' : '0',
      'time':
          '${time.hour.toString().padLeft(2, "0")}:${time.minute.toString().padLeft(2, "0")}',
    };
  }

  static TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(":");
    final time = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    return time;
  }

  factory Task.fromMap(Map<String, String> map) {
    return Task(
      id: int.parse(map['id']!),
      name: map['name']!,
      desc: map['desc']!,
      type: TASKTYPES.values.byName(map['type']!),
      isAlarm: (int.parse(map['isAlarm']!) == 1),
      time: _parseTime(map['time']!),
    );
  }
}
