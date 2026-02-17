import "dart:async";
import 'dart:developer';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:scheduler/Classes/Schedule.dart';
import 'package:scheduler/Enums/RepeatTypes.dart';
import 'package:scheduler/helpers/ExtraHelpers.dart';
import 'package:scheduler/helpers/FileHandler.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHandler {
  static final DatabaseHandler instance = DatabaseHandler._();
  static Database? _db;
  static const tableSchedules = 'Schedules';
  static const colId = 'id';
  static const colDate = 'date';
  static const colRepeat = 'repeat';
  static const colTaskFile = 'task_file';
  static const colTaskRepeatType = 'repeat_type';
  DatabaseHandler._();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await init_db();
    return _db!;
  }

  Future<Database> init_db() async {
    final path = join(await getDatabasesPath(), "schedule_db.db");
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          "CREATE TABLE $tableSchedules ($colId INTEGER PRIMARY KEY AUTOINCREMENT, $colDate INTEGER NOT NULL,$colRepeat INTEGER NOT NULL CHECK ($colRepeat IN (0,1)), $colTaskFile TEXT NOT NULL, $colTaskRepeatType TEXT  )",
        );
        await db.execute(
          "CREATE INDEX idx_schedules_date ON $tableSchedules ($colDate)",
        );
      },
    );
  }

  Future<Schedule> insertSchedule(Schedule schedule) async {
    final Database db = await DatabaseHandler.instance.database;
    final id = await db.insert(
      tableSchedules,
      schedule.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return schedule.copyWith(id: id);
  }

  Future<List<Schedule>> getSchedules() async {
    final Database db = await DatabaseHandler.instance.database;
    final List<Map<String, Object?>> scheduleMaps = await db.query(
      tableSchedules,
    );
    return scheduleMaps.map(Schedule.fromMap).toList();
  }

  Future<void> updateSchedule(int oldScheduleId, Schedule newSchedule) async {
    final Database db = await DatabaseHandler.instance.database;
    await db.update(
      tableSchedules,
      newSchedule.toMap(),
      where: "$colId=?",
      whereArgs: [oldScheduleId],
    );
  }

  Future<Schedule?> getCertainScheduleFromTime(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(Duration(days: 1));
    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;
    final Database db = await DatabaseHandler.instance.database;
    final maps = await db.query(
      tableSchedules,
      where:
          '$colDate >= ? AND $colDate < ? AND $colRepeat = 0 AND $colTaskRepeatType = null',
      whereArgs: [startMs, endMs],
      orderBy: '$colDate ASC',
    );
    if (maps.isEmpty) return null;
    return maps.map(Schedule.fromMap).toList().first;
  }

  Future<bool> doesCollide(Schedule schedule) async {
    return doesCollideTime(schedule.date);
  }

  Future<bool> doesCollideTime(DateTime dateTime) async {
    Database db = await DatabaseHandler.instance.database;
    int time = dateTime.millisecondsSinceEpoch;
    final map = await db.query(
      tableSchedules,
      where: '$colDate= ?',
      whereArgs: [time],
    );
    return map.isNotEmpty;
  }

  Future<Schedule?> getCertainWeekDaySchedule(
    REPEATTYPES? weekDayRepeatToday,
  ) async {
    if (weekDayRepeatToday == null) return null;
    if (weekDayRepeatToday == REPEATTYPES.EveryDay)
      return await getFullRepeatSchedule();
    Database db = await DatabaseHandler.instance.database;

    final maps = await db.query(
      tableSchedules,
      where: '$colTaskRepeatType = ?',
      whereArgs: [weekDayRepeatToday.toString()],
    );
    if (maps.isNotEmpty && maps.length > 1) {
      log(
        "getCertainWeekDaySchedule returned map with more than one item inside the map from query. $weekDayRepeatToday may have many rows ",
      );
    }
    if (maps.isNotEmpty) {
      return maps.map(Schedule.fromMap).toList().first;
    }
    return null;
  }

  Future<Schedule?> getFullRepeatSchedule() async {
    Database db = await DatabaseHandler.instance.database;
    final map = await db.query(
      tableSchedules,
      where: '$colRepeat=?',
      whereArgs: [1],
    );
    if (map.isNotEmpty) {
      if (map.length > 1) {
        log("getFullRepeatSchedule returned map with length ${map.length}");
      }
      return map.map(Schedule.fromMap).toList().first;
    }
    return null;
  }

  Future<Schedule?> getTodaySchedule() async {
    Schedule? todaySchedule = await getCertainScheduleFromTime(DateTime.now());
    if (todaySchedule != null) {
      return todaySchedule;
    } else {
      todaySchedule = await getCertainWeekDaySchedule(
        mapWeekDayToRepeatType(DateTime.now().weekday),
      );
      if (todaySchedule != null) {
        return todaySchedule;
      } else {
        todaySchedule = await getFullRepeatSchedule();
        return todaySchedule;
      }
    }
  }

  Future<void> remove_db() async {
    final dbPath = join(await getDatabasesPath(), "schedule_db.db");
    deleteDatabase(dbPath);
  }

  Future<void> clearExpiredRows() async {
    final db = await DatabaseHandler.instance.database;
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final startMs = start.millisecondsSinceEpoch;
    final toBeRemovedMaps = await db.query(
      tableSchedules,
      where: "$colDate < ? AND $colRepeat = 0 AND $colTaskRepeatType = null",
      whereArgs: [startMs],
    );
    if (toBeRemovedMaps.isEmpty) return;
    toBeRemovedMaps.forEach((map) async {
      final schedule = Schedule.fromMap(map);
      await FileHandler.removeTaskFile(schedule.taskFile);
      await db.delete(
        tableSchedules,
        where: "$colId = ?",
        whereArgs: [schedule.id],
      );
    });
  }

  Future<void> deleteSchedule(Schedule schedule) async {
    final db = await DatabaseHandler.instance.database;
    await FileHandler.removeTaskFile(schedule.taskFile);
    await db.delete(
      tableSchedules,
      where: "$colId=?",
      whereArgs: [schedule.id],
    );
  }

  Future<bool> doesCollideRepeat(
    REPEATTYPES? repeatType,
    bool fullRepeat,
  ) async {
    if (fullRepeat) {
      return (await getFullRepeatSchedule() == null);
    }
    if (repeatType == null) {
      return false;
    }
    return (await getCertainWeekDaySchedule(repeatType) == null);
  }
}
