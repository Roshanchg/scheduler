enum TASKTYPES { FUN, STUDY, SLEEP, WAKE_UP, EXERCISE, EAT, OTHERS }

extension TaskTypesX on TASKTYPES {
  String get label {
    switch (this) {
      case TASKTYPES.EAT:
        {
          return "Eat";
        }
      case TASKTYPES.FUN:
        {
          return "Fun";
        }
      case TASKTYPES.SLEEP:
        {
          return "Sleep";
        }
      case TASKTYPES.WAKE_UP:
        {
          return "Wake Up";
        }
      case TASKTYPES.EXERCISE:
        {
          return "Exercise";
        }
      case TASKTYPES.STUDY:
        {
          return "Study";
        }
      case TASKTYPES.OTHERS:
        {
          return "Others";
        }
    }
  }
}
