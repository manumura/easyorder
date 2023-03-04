import 'package:easyorder/models/time_difference.dart';

int minutesBetween(DateTime from, DateTime to) {
  final DateTime start =
      DateTime(from.year, from.month, from.day, from.hour, from.minute);
  final DateTime end = DateTime(to.year, to.month, to.day, to.hour, to.minute);
  return start.difference(end).inMinutes;
}

TimeDifference calculateTimeDifference(int diffInMinutes) {
  final int days = (diffInMinutes / 1440).floor();
  final int hours = ((diffInMinutes - days * 1440) / 60).floor();
  final int min = diffInMinutes - days * 1440 - hours * 60;
  return TimeDifference(days: days, hours: hours, minutes: min);
}

// int hoursBetween(DateTime from, DateTime to) {
//   final DateTime start =
//       DateTime(from.year, from.month, from.day, from.hour, from.minute);
//   final DateTime end = DateTime(to.year, to.month, to.day, to.hour, to.minute);
//   return start.difference(end).inHours;
// }
//
// TimeDifference calculateTimeDifference(int diffInHours) {
//   final int days = (diffInHours / 24).floor();
//   final int hours = diffInHours - days * 24;
//   return TimeDifference(days: days, hours: hours, minutes: 0);
// }

// bool _isNumeric(String str) {
//   return double.tryParse(str) != null;
// }
