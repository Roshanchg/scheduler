import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:scheduler/Classes/Schedule.dart';
import 'package:scheduler/Classes/Task.dart';
import 'package:scheduler/Enums/RepeatTypes.dart';
import 'package:scheduler/Enums/TaskTypes.dart';
import 'package:scheduler/helpers/DatabaseHandler.dart';
import 'package:scheduler/helpers/ExtraHelpers.dart';
import 'package:scheduler/helpers/FileHandler.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});
  @override
  State<StatefulWidget> createState() => _addTaskPageState();
}

class _addTaskPageState extends State<AddTaskPage> {
  GlobalKey key = GlobalKey();

  DateTime? selectedDate = DateTime.now();
  Schedule? curSchedule;
  REPEATTYPES? selRepeatType;
  bool isLoading = true;
  List<Task> taskList = [];

  // Dialogue box input options
  String insertedName = "";
  String insertedDescription = "";
  TimeOfDay? selTime;
  bool selIsAarm = false;

  Future<void> loadSchedules() async {
    setState(() {
      isLoading = true;
    });
    if (selRepeatType != null) {
      curSchedule = await DatabaseHandler.instance.getCertainWeekDaySchedule(
        selRepeatType,
      );
      log("loading task from Week $selRepeatType");
    } else {
      if (selectedDate == null) return;

      curSchedule = await DatabaseHandler.instance.getCertainScheduleFromTime(
        selectedDate!,
      );
      log("loading task from date: $selectedDate");
    }
    if (curSchedule != null) {
      taskList = await FileHandler.readAllTasks(curSchedule!.taskFile);
      if (taskList.length > 0) {
        log("Task lisst : ${taskList.first.toString()}");
      }
    }
    log("Loaded schedule: $curSchedule, task length: ${taskList.length}");
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    loadSchedules();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add A Schedule")),
      body: ScheduleTabBody(context),
      floatingActionButton: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          minimumSize: Size(100, 50),
        ),
        onPressed: () => _showTaskAddDrawer(context),
        child: const Text("Add Task"),
      ),
    );
  }

  void _showTaskAddDrawer(BuildContext context) {
    TASKTYPES selectedType = TASKTYPES.values.first;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              scrollable: true,
              title: const Text("Add Task"),
              content: Container(
                width: 800,
                padding: EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 10,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Task"),
                    TextField(
                      onChanged: (value) {
                        insertedName = value;
                      },
                    ),
                    const Text("Task Description"),
                    TextField(
                      maxLines: null,
                      onChanged: (value) => {insertedDescription = value},
                    ),
                    Row(
                      children: [
                        const Text("Task Type"),
                        SizedBox(width: 20),
                        DropdownButton<TASKTYPES>(
                          dropdownColor: Color(0xff181818),
                          value: selectedType,
                          items: TASKTYPES.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type.label),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setLocalState(() {
                              selectedType = newValue!;
                              log(selectedType.toString());
                            });
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text("Alarm? "),
                        Checkbox(
                          value: selIsAarm,
                          onChanged: (value) => {
                            setLocalState(() => selIsAarm = value!),
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text("Select Time: "),
                        TextButton(
                          onPressed: () async {
                            final tempSelTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (tempSelTime != null) {
                              setLocalState(() {
                                selTime = tempSelTime;
                                log(selTime.toString());
                              });
                            }
                          },
                          child: (selTime == null)
                              ? Text("Select Time")
                              : Text(selTime.toString()),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: () async {
                            if (selTime == null) {
                              log("Sel time null: ${selTime.toString()}");
                              final messenger = ScaffoldMessenger.of(context);
                              messenger.clearSnackBars();
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Please Select a time'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            if (curSchedule == null) {
                              File taskFile = await FileHandler.insertNewTask(
                                Task(
                                  time: selTime!,
                                  name: insertedName,
                                  desc: insertedDescription,
                                  type: selectedType,
                                  isAlarm: selIsAarm,
                                ),
                                null,
                              );
                              await DatabaseHandler.instance.insertSchedule(
                                Schedule(
                                  date: (selectedDate == null)
                                      ? DateTime.now()
                                      : selectedDate!,
                                  repeat:
                                      (selRepeatType == REPEATTYPES.EveryDay),
                                  taskFile: taskFile.path,
                                  repeatType: selRepeatType,
                                ),
                              );
                              log(taskFile.path);
                            } else {
                              String filename = curSchedule!.taskFile;
                              await FileHandler.insertNewTask(
                                Task(
                                  time: selTime!,
                                  name: insertedName,
                                  desc: insertedDescription,
                                  type: selectedType,
                                  isAlarm: selIsAarm,
                                ),
                                filename,
                              );
                            }
                            Navigator.pop(context);
                            loadSchedules();
                            selTime = null;
                          },
                          icon: Icon(Icons.check),
                        ),
                        IconButton(
                          onPressed: () {
                            selTime = null;
                            insertedName = "";
                            insertedDescription = "";
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.cancel_outlined),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget ScheduleTabBody(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsetsGeometry.all(8),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        (selectedDate == null ||
                            !isSameDate(selectedDate!, DateTime.now()) ||
                            selRepeatType != null)
                        ? Colors.white
                        : Colors.blue,
                  ),
                  onPressed: () async {
                    setState(() {
                      selectedDate = DateTime.now();
                      selRepeatType = null;
                    });
                    await loadSchedules();
                    setState(() {});
                  },
                  child: const Text("Today"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        ((selectedDate == null ||
                                isSameDate(selectedDate!, DateTime.now())) ||
                            selRepeatType != null)
                        ? Colors.white
                        : Colors.blue,
                  ),
                  onPressed: () async {
                    final tempSelDate = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (tempSelDate != null) {
                      setState(() {
                        selectedDate = tempSelDate;
                        selRepeatType = null;
                      });
                      await loadSchedules();

                      setState(() {});
                    }
                  },
                  child:
                      (selectedDate == null ||
                          isSameDate(DateTime.now(), selectedDate!))
                      ? Text("Pick Date")
                      : Text("${selectedDate!.month}:${selectedDate!.day}"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                key: key,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: (selRepeatType == null)
                        ? Colors.white
                        : Colors.blue,
                  ),

                  onPressed: () async {
                    final RenderBox renderBox =
                        key.currentContext!.findRenderObject() as RenderBox;
                    final position = renderBox.localToGlobal(Offset.zero);

                    final tempSelRepeatType = await showMenu<REPEATTYPES>(
                      color: Color(0xff181818),
                      context: context,
                      position: RelativeRect.fromLTRB(
                        position.dx,
                        position.dy,
                        MediaQuery.of(context).size.width,
                        MediaQuery.of(context).size.height,
                      ),
                      items: REPEATTYPES.values.map((type) {
                        return PopupMenuItem<REPEATTYPES>(
                          value: type,
                          child: Text(
                            type.name,
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                    );
                    if (tempSelRepeatType != null) {
                      setState(() {
                        selRepeatType = tempSelRepeatType;
                        selectedDate = null;
                      });
                      await loadSchedules();
                      setState(() {});
                    }
                  },
                  child: (selRepeatType == null)
                      ? Text("Repeat")
                      : Text(selRepeatType!.name),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1),
        // BODY CONTENT
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : (curSchedule == null || taskList.isEmpty)
              ? const Center(child: Text("No Tasks Found "))
              : ListView.builder(
                  itemCount: taskList.length,
                  itemBuilder: (context, index) {
                    final task = taskList[index];
                    return Padding(
                      padding: EdgeInsetsGeometry.all(20),
                      child: Row(
                        spacing: 10,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(task.name),
                            ),
                          ),
                          Icon(getIconDataForTaskType(task.type)),
                          Text(parseTimeToPrettyString(task.time)),
                          IconButton(onPressed: () {}, icon: Icon(Icons.edit)),
                          IconButton(
                            onPressed: () {
                              FileHandler.removeTask(
                                curSchedule!.taskFile,
                                task,
                              );
                              setState(() {});
                              loadSchedules();
                              setState(() {});
                            },
                            icon: Icon(Icons.delete),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  bool isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}
