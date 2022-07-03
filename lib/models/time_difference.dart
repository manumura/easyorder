class TimeDifference {
  TimeDifference(
      {required this.days, required this.hours, required this.minutes});

  int days;
  int hours;
  int minutes;

  @override
  String toString() {
    return 'TimeDifference{days: $days, hours: $hours, minutes: $minutes}';
  }
}
