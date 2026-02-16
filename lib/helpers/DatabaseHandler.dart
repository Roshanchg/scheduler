import "dart:async";
import 'dart:developer';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:scheduler/Classes/Schedule.dart';
import 'package:scheduler/Enums/RepeatTypes.dart';
import 'package:scheduler/helpers/ExtraHelpers.dart';
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
          "CREATE TABLE $tableSchedules ($colId INTEGER PRIMARY KEY AUTOINCREMENT, $colDate INTEGER UNIQUE NOT NULL,$colRepeat INTEGER NOT NULL CHECK ($colRepeat IN (0,1)), $colTaskFile TEXT NOT NULL, $colTaskRepeatType TEXT  )",
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

  Future<void> deleteSchedule(int id) async {
    final Database db = await DatabaseHandler.instance.database;
    await db.delete(tableSchedules, where: '$colId = ?', whereArgs: [id]);
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
      where: 'date >= ? AND date < ?',
      whereArgs: [startMs, endMs],
      orderBy: 'date ASC',
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
      where: 'date= ?',
      whereArgs: [time],
    );
    return map.isNotEmpty;
  }

  Future<Schedule?> getCertainWeekDaySchedule(int weekday) async {
    Database db = await DatabaseHandler.instance.database; 
    REPEATTYPES? weekDayRepeatToday = mapWeekDayToRepeatType(weekday);
    if (weekDayRepeatToday == null) return null;
    final maps = await db.query(
      tableSchedules,
      where: 'repeat_type = ?',
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
      where: 'repeat=?',
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
      todaySchedule = await getCertainWeekDaySchedule(DateTime.now().weekday);
      if (todaySchedule != null) {
        return todaySchedule;
      } else {
        todaySchedule = await getFullRepeatSchedule();
        return todaySchedule;
      }
    }
  }
}
