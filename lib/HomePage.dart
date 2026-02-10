// ignore_for_file: camel_case_types

import 'package:flutter/material.dart';
import 'package:scheduler/AddTaskPage.dart';
import 'package:scheduler/Enums/TaskTypes.dart';
import 'package:scheduler/helpers/ExtraHelpers.dart';

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

class _cardsContainerState extends State<CardsContainer> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.zero,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 8,
        itemBuilder: (context, index) => ItemCard(index: index),
      ),
    );
  }
}

class ItemCard extends StatelessWidget {
  final int index;
  const ItemCard({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    if (index == 0) {
      return Column(
        children: [
          SizedBox(
            height: 300,
            child: Card(
              child: Padding(
                padding: EdgeInsetsGeometry.all(20),
                child: Column(
                  spacing: 32,
                  children: [
                    Row(
                      textDirection: TextDirection.ltr,
                      spacing: 16,
                      children: [
                        Icon(Icons.circle_outlined),
                        Expanded(child: Text("The Next Task", maxLines: 1)),
                        getIconForTaskType(null),
                        Text("24:00"),
                      ],
                    ),

                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 24,
                        children: [
                          SizedBox(
                            height: 100,
                            child: Text(
                              "This is a description for the task added by user ...fffaufbiuwbaugbgu",
                            ),
                          ),
                          Align(
                            alignment: AlignmentGeometry.bottomRight,
                            child: TextButton(
                              onPressed: () {},
                              child: Text("show more"),
                            ),
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
              padding: EdgeInsetsGeometry.all(20),
              child: Row(
                spacing: 12,
                children: [
                  Icon(Icons.circle_outlined),
                  Expanded(child: Text("Lesser Task")),
                  Icon(Icons.school),
                  Text("12:09"),
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
