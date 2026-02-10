import 'package:scheduler/Enums/RepeatTypes.dart';

class Schedule {
  final int? id;
  final DateTime date;
  final bool repeat;
  final String taskFile;
  final REPEATTYPES? repeatType;
  const Schedule({
    this.id,
    required this.date,
    required this.repeat,
    required this.taskFile,
    required this.repeatType,
  });

  Schedule copyWith({
    int? id,
    DateTime? date,
    bool? repeat,
    String? taskFile,
    REPEATTYPES? repeatType,
  }) {
    return Schedule(
      id: id ?? this.id,
      date: date ?? this.date,
      repeat: repeat ?? this.repeat,
      taskFile: taskFile ?? this.taskFile,
      repeatType: repeatType ?? this.repeatType,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'date': date.millisecondsSinceEpoch,
      'repeat': repeat ? 1 : 0,
      'task_file': taskFile,
      'repeat_type': repeatType,
    };
  }

  factory Schedule.fromMap(Map<String, Object?> map) {
    return Schedule(
      id: map['id'] as int,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      repeat: (map['repeat'] as int) == 1,
      taskFile: map['task_file'] as String,
      repeatType: map['repeat_type'] as REPEATTYPES,
    );
  }
  @override
  String toString() {
    return 'Schedule{id:$id,date:$date,repeat:$repeat,task_file:$taskFile,repeat_type:$repeatType}';
  }
}
