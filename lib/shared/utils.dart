import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:easyorder/models/cart_item_model.dart';
import 'package:easyorder/models/order_model.dart';
import 'package:easyorder/models/order_status.dart';
import 'package:easyorder/models/time_difference.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

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

Future<File> generateCsv(List<OrderModel> orders, DateTime now) async {
  final List<List<dynamic>> rows = <List<dynamic>>[];

  final List<dynamic> header = <dynamic>[];
  header.addAll(<String>[
    'Status',
    'Number',
    'Customer',
    'Date',
    'Due Date',
    'Description',
    'Total Price',
    'Item Quantity',
    'Item Name',
    'Item Price'
  ]);
  rows.add(header);

  for (int i = 0; i < orders.length; i++) {
    final List<dynamic> row = <dynamic>[];

    final OrderModel order = orders[i];
    row.add(order.status == OrderStatus.completed ? 'COMPLETED' : 'PENDING');
    row.add(order.number);
    row.add(order.customer.name);
    row.add(order.date);
    row.add(order.dueDate ?? '');
    row.add(order.description ?? '');

    if (order.cart != null) {
      row.add(order.cart?.price);
      for (final CartItemModel cartItem in order.cart!.cartItems) {
        row.add(cartItem.quantity);
        row.add(cartItem.product.name);
        row.add(cartItem.product.price);
      }
    }

    rows.add(row);
  }

  final DateTime now = DateTime.now();
  final String fileSuffix = DateFormat('yyyyMMddHHmmss').format(now);

  // final Directory? directory = await getExternalStorageDirectory();
  final Directory directory = await getApplicationCacheDirectory();
  // if (directory == null) {
  //   logger.d('Cannot find external storage directory');
  //   return;
  // }

  final File file = File('${directory.path}/orders_$fileSuffix.csv');
  // final File file = MemoryFileSystem().file('tmp.csv');
  final String csv = const ListToCsvConverter().convert(rows);
  file.writeAsString(csv);

  return file;
}

Future<String> writeImageToStorage(Uint8List bytes, String filename) async {
  final Directory output = await getTemporaryDirectory();
  final String screenshotFilePath = '${output.path}/$filename';
  final File screenshotFile = File(screenshotFilePath);
  await screenshotFile.writeAsBytes(bytes);
  return screenshotFilePath;
}
