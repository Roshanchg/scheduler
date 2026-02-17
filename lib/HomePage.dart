// ignore_for_file: camel_case_types

import 'package:flutter/material.dart';
import 'package:scheduler/AddTaskPage.dart';
import 'package:scheduler/Classes/Schedule.dart';
import 'package:scheduler/Classes/Task.dart';
import 'package:scheduler/Enums/TaskTypes.dart';
import 'package:scheduler/helpers/DatabaseHandler.dart';
import 'package:scheduler/helpers/ExtraHelpers.dart';
import 'package:scheduler/helpers/FileHandler.dart';
import 'package:scheduler/main.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Schedule"),
        leading: IconButton(onPressed: () => {}, icon: Icon(Icons.menu)),
        actions: [
          IconButton(
            onPressed: () => {Navigator.pushNamed(context, "/addTask")},
            icon: Icon(Icons.mode_edit),
          ),
        ],
      ),
      body: CardsContainer(),
      backgroundColor: Color(0xff1c1c1c),
    );
  }
}

class CardsContainer extends StatefulWidget {
  const CardsContainer({super.key});
  @override
  State<StatefulWidget> createState() => _cardsContainerState();
}

class _cardsContainerState extends State<CardsContainer> with RouteAware {
  Schedule? activeSchedule;
  List<Task> taskList = [];

  bool isLoading = true;

  void loadSchedule() async {
    setState(() {
      isLoading = true;
    });
    activeSchedule = await DatabaseHandler.instance.getTodaySchedule();
    if (activeSchedule != null) {
      taskList = await FileHandler.getNonExpiredTaskList(
        activeSchedule!.taskFile,
      );
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  void didPopNext() {
    loadSchedule();
    super.didPopNext();
  }

  @override
  void initState() {
    super.initState();
    loadSchedule();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : (activeSchedule == null || taskList.isEmpty)
        ? const Center(child: Text("No Tasks Scheduled for Today"))
        : Container(
            padding: EdgeInsets.zero,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: taskList.length,
              itemBuilder: (context, index) =>
                  ItemCard(index: index, task: taskList[index]),
            ),
          );
  }
}

class ItemCard extends StatelessWidget {
  final int index;
  final Task task;
  const ItemCard({super.key, required this.index, required this.task});

  String _parseTimeToPrettyString(TimeOfDay time) {
    int hour = time.hour;
    int minute = time.minute;
    String hourStr = (hour.toString().length < 2) ? "0$hour" : hour.toString();
    String minuteStr = (minute.toString().length < 2)
        ? "0$minute"
        : minute.toString();
    return "$hourStr : $minuteStr";
  }

  @override
  Widget build(BuildContext context) {
    if (index == 0) {
      return Column(
        children: [
          SizedBox(
            height: 300,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  spacing: 32,
                  children: [
                    Row(
                      textDirection: TextDirection.ltr,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          spacing: 20,
                          children: [
                            Icon(Icons.circle_outlined),
                            (task.name.isEmpty)
                                ? const Text(
                                    "No Name Task",
                                    style: TextStyle(color: Colors.grey),
                                  )
                                : Text(task.name, maxLines: 1),
                          ],
                        ),
                        Row(
                          spacing: 20,
                          children: [
                            Icon(getIconDataForTaskType(task.type)),
                            Text(
                              _parseTimeToPrettyString(task.time),
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 24,
                        children: [
                          Align(
                            alignment: AlignmentGeometry.topLeft,
                            child: SizedBox(
                              height: 100,
                              child: SingleChildScrollView(
                                child: (task.desc.isEmpty)
                                    ? const Text(
                                        "No Description added .... ",
                                        style: TextStyle(color: Colors.grey),
                                      )
                                    : Text(task.desc),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(
                                (task.isAlarm)
                                    ? Icons.alarm_on_sharp
                                    : Icons.alarm_off_sharp,
                              ),
                              TextButton(
                                onPressed: () {},
                                child: Text("show more"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 80,
          child: Card(
            color: Color(0xff1f1f1f),

            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    spacing: 20,
                    children: [
                      Icon(Icons.circle_outlined),
                      (task.name.isEmpty)
                          ? const Text(
                              "No Name Task",
                              style: TextStyle(color: Colors.grey),
                            )
                          : Text(task.name),
                    ],
                  ),
                  Row(
                    spacing: 20,
                    children: [
                      Icon(getIconDataForTaskType(task.type)),
                      Text(
                        _parseTimeToPrettyString(task.time),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 12),
      ],
    );
  }
}
