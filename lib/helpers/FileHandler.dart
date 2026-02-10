import 'dart:io';
import 'dart:convert';
import 'dart:developer';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:scheduler/Enums/TaskTypes.dart';
import 'package:flutter/material.dart';
import 'package:scheduler/Classes/Task.dart';

class FileHandler {
  static const String dirName = "tasks";
  static const String tempDirName = "temp";
  static const String backupDirName = "backups";

  static Future<void> init_dirs() async {
    await getTasksDirectory();
    await getTempDirectory();
    await getBackupDirectory();
  }

  static Future<Directory> getTasksDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final tasksDir = Directory('${appDir.path}/$dirName');
    if (!await tasksDir.exists()) {
      await tasksDir.create(recursive: true);
      log("Tasks Dir created at: ${tasksDir.path}");
    }
    return tasksDir;
  }

  static Future<Directory> getTempDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final tempDir = Directory('${appDir.path}/$tempDirName');
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
      log("Temp dir created at ${tempDir.path}");
    }
    return tempDir;
  }

  static Future<Directory> getBackupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${appDir.path}/$backupDirName');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
      log("Created BackupDir at ${backupDir.path}");
    }
    return backupDir;
  }

  static Future<File> loadFileToBackup(File toBeBackedFile) async {
    final backupDir = await getBackupDirectory();
    const String backupFileName = 'task_backup.json';
    File backupFile = File("${backupDir.path}/$backupFileName");
    return toBeBackedFile.copy(backupFile.path);
  }

  static Future<File> loadBackupFileAsNewTasksFile(File? backupFile) async {
    final backupDir = await getBackupDirectory();
    final tasksDir = await getTasksDirectory();
    if (backupFile == null) {
      const String backupFileName = 'task_backup.json';
      backupFile = File("${backupDir.path}/$backupFileName");
    }
    File taskFile = File("${tasksDir.path}/task_${Uuid().v4()}.json");
    return backupFile.copy(taskFile.path);
  }

  static Future<File> loadCurrentTasksFileToTemp(File taskFile) async {
    final tempDir = await getTempDirectory();
    const String tempFileName = 'task_temp.json';
    final File tempFile = File("${tempDir.path}/$tempFileName");
    return taskFile.copy(tempFile.path);
  }

  Future<File> insertTaskTemp(Task task) async {
    final tasksDir = await getTempDirectory();
    const String fileName = 'task_add.json';
    final file = File('${tasksDir.path}/$fileName');

    final jsonContent = jsonEncode(task.toMap());
    await file.writeAsString(jsonContent);
    log('Task ${task.name} added to $fileName');
    return file;
  }

  Future<File> copyTempTaskToMain(File tempFile) async {
    final tasksDir = await getTasksDirectory();
    final uuidFile = File('${tasksDir.path}/task_${const Uuid().v4()}.json');
    return tempFile.copy(uuidFile.path);
  }

  static Future<List<Task>> readAllTasks(String taskFileName) async {
    final tasksDir = await getTasksDirectory();
    final taskFile = File("${tasksDir.path}/$taskFileName");
    final List<Task> tasks = [];

    if (await taskFile.exists()) {
      try {
        final content = await taskFile.readAsString();
        if (content.trim().isEmpty) return tasks;

        final List<dynamic> jsonList = jsonDecode(content);
        for (var item in jsonList) {
          if (item is Map<String, dynamic>) {
            final map = item.map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            );
            tasks.add(Task.fromMap(map));
          }
        }
      } catch (e) {
        log("Failed to read tasks from $taskFileName: $e");
      }
    }

    return tasks;
  }

  static Future<void> clearTempDirectory() async {
    final tempDir = await getTempDirectory();
    await clearDirectory(tempDir);
  }

  static Future<void> clearTasksDirectory() async {
    final tasksDir = await getTasksDirectory();
    await clearDirectory(tasksDir);
  }

  static Future<void> clearBackupDirectory() async {
    final backupDir = await getBackupDirectory();
    await clearDirectory(backupDir);
  }

  static Future<void> clearDirectory(Directory dir) async {
    await for (final entity in dir.list(recursive: true)) {
      try {
        if (entity is File) {
          await entity.delete();
        } else if (entity is Directory) {
          await entity.delete(recursive: true);
        }
      } catch (e) {
        log("Failed to clear Dir ${dir.path}: $e");
      }
    }
  }
}
