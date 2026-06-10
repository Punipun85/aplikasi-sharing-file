import 'package:intl/intl.dart';

class Formatters {
  static final _date = DateFormat('dd MMM yyyy, HH:mm');

  static String bytes(int value) {
    if (value < 1024) {
      return '$value B';
    }
    if (value < 1024 * 1024) {
      return '${(value / 1024).toStringAsFixed(1)} KB';
    }
    if (value < 1024 * 1024 * 1024) {
      return '${(value / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(value / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }

  static String date(DateTime value) => _date.format(value.toLocal());
}
