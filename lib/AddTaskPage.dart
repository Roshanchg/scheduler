import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:scheduler/Classes/Schedule.dart';
import 'package:scheduler/Enums/RepeatTypes.dart';
import 'package:scheduler/Enums/TaskTypes.dart';
import 'package:scheduler/helpers/DatabaseHandler.dart';
import 'package:scheduler/helpers/ExtraHelpers.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});
  @override
  State<StatefulWidget> createState() => _addTaskPageState();
}

class _addTaskPageState extends State<AddTaskPage> {
  GlobalKey key = GlobalKey();

  TimeOfDay? selTime;
  DateTime? selectedDate = DateTime.now();
  Schedule? curSchedule;
  REPEATTYPES? selRepeatType;

  bool isLoading = true;

  Future<void> loadSchedules() async {
    if (selectedDate == null) return;

    setState(() {
      isLoading = true;
    });
    curSchedule = await DatabaseHandler.instance.getTodaySchedule();
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
      appBar: AppBar(title: Text("Add A Schedule")),
      body: ScheduleTabBody(context),
      floatingActionButton: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          minimumSize: Size(100, 50),
        ),
        onPressed: () => _showTaskAddDrawer(context),
        child: Text("Add Task"),
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
              title: Text("Add Task"),
              content: Container(
                width: 800,
                padding: EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 10,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Task"),
                    TextField(),
                    Text("Task Description"),
                    TextField(maxLines: null),
                    Row(
                      children: [
                        Text("Task Type"),
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
                        Text("Select Time: "),
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
                          onPressed: () => {log(selTime!.toString())},
                          icon: Icon(Icons.check),
                        ),
                        IconButton(
                          onPressed: () => {Navigator.pop(context)},
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
                      curSchedule = await DatabaseHandler.instance
                          .getCertainScheduleFromTime(selectedDate!);

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
                      if (tempSelRepeatType == REPEATTYPES.EveryDay) {
                        curSchedule = await DatabaseHandler.instance
                            .getFullRepeatSchedule();
                      } else {
                        curSchedule = await DatabaseHandler.instance
                            .getCertainWeekDaySchedule(
                              mapRepeatTypeToWeekDay(selRepeatType!),
                            );
                      }
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

        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : (curSchedule == null)
              ? const Center(child: Text("No Tasks Found "))
              : ListView.builder(
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    final schedule = curSchedule!;
                    return ListTile(
                      title: Text(schedule.taskFile),
                      subtitle: Text(
                        TimeOfDay.fromDateTime(schedule.date).format(context),
                      ),
                      leading: Icon(
                        schedule.repeat ? Icons.repeat : Icons.task_alt,
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
