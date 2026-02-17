import 'package:flutter/material.dart';
import 'package:scheduler/AddTaskPage.dart';
import 'package:scheduler/HomePage.dart';
import 'package:scheduler/helpers/DatabaseHandler.dart';
import 'package:scheduler/helpers/FileHandler.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FileHandler.init_dirs();
  await DatabaseHandler.instance.clearExpiredRows();
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Scheduler",
      navigatorKey: GlobalKey<NavigatorState>(),
      navigatorObservers: [routeObserver],
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xff1c1c1c),
        textTheme: Typography.whiteCupertino,
        cardTheme: CardThemeData(color: Color(0xff181818)),
        iconTheme: IconThemeData(color: Colors.white),
        dialogTheme: DialogThemeData(
          backgroundColor: Color(0xff1c1c1c),
          iconColor: Colors.white,
        ),
        appBarTheme: AppBarThemeData(
          backgroundColor: Color(0xff181818),
          foregroundColor: Colors.white,
        ),
      ),

      routes: {
        '/': (context) => HomePage(),
        '/addTask': (context) => AddTaskPage(),
      },
    );
  }
}
