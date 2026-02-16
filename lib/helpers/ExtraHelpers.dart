import "dart:developer";

import "package:flutter/material.dart";
import "package:flutter/widgets.dart";
import "package:scheduler/Classes/Schedule.dart";
import "package:scheduler/Enums/RepeatTypes.dart";
import "package:scheduler/Enums/TaskTypes.dart";

DateTime getNextDate(DateTime initialDate, int daysGap) {
  DateTime nextDate = initialDate.add(Duration(days: daysGap));
  return nextDate;
}

int getPriority(Schedule schedule) {
  return (schedule.repeat)
      ? (schedule.repeatType == REPEATTYPES.EveryDay)
            ? 1
            : 2
      : 3;
}

REPEATTYPES? mapWeekDayToRepeatType(int weekday) {
  if (weekday == 1) {
    return REPEATTYPES.Monday;
  }
  if (weekday == 2) {
    return REPEATTYPES.Tuesday;
  }
  if (weekday == 3) {
    return REPEATTYPES.Wednesday;
  }
  if (weekday == 4) {
    return REPEATTYPES.Thursday;
  }
  if (weekday == 5) {
    return REPEATTYPES.Friday;
  }
  if (weekday == 6) {
    return REPEATTYPES.Saturday;
  }
  if (weekday == 7) {
    return REPEATTYPES.Sunday;
  }
  return null;
}

REPEATTYPES? mapToRepeatType(String repStr) {
  for (REPEATTYPES e in REPEATTYPES.values) {
    if (e.toString() == repStr) {
      return e;
    }
  }
  return null;
}

int mapRepeatTypeToWeekDay(REPEATTYPES? repeatType) {
  if (repeatType == null) return -1;
  switch (repeatType) {
    case REPEATTYPES.Monday:
      return 1;
    case REPEATTYPES.Tuesday:
      return 2;
    case REPEATTYPES.Wednesday:
      return 3;
    case REPEATTYPES.Thursday:
      return 4;
    case REPEATTYPES.Friday:
      return 5;
    case REPEATTYPES.Saturday:
      return 6;
    case REPEATTYPES.Sunday:
      return 7;
    case REPEATTYPES.EveryDay:
      log("everyday repeat type was sent to be maapped :ERROR ");
      return 0;
  }
}

IconData getIconDataForTaskType(TASKTYPES? taskType) {
  if (taskType == null) {
    return (Icons.category);
  }

  switch (taskType) {
    case TASKTYPES.FUN:
      {
        return (Icons.celebration);
      }
    case TASKTYPES.EAT:
      {
        return (Icons.restaurant);
      }
    case TASKTYPES.EXERCISE:
      {
        return (Icons.directions_run);
      }
    case TASKTYPES.SLEEP:
      {
        return (Icons.bed);
      }
    case TASKTYPES.STUDY:
      {
        return (Icons.book);
      }
    case TASKTYPES.WAKE_UP:
      {
        return (Icons.alarm_on);
      }
    default:
      {
        return (Icons.category);
      }
  }
}

String parseTimeToPrettyString(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, "0")}:${time.minute.toString().padLeft(2, "0")}';
}
