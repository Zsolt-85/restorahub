import 'package:intl/intl.dart';

class FormatHelper {
  static final _dateFormat = DateFormat('EEE, MMM d, yyyy');
  static final _timeFormat = DateFormat('h:mm a');
  static final _dateTimeFormat = DateFormat('EEE, MMM d, yyyy · h:mm a');

  static String formatDate(DateTime dateTime) =>
      _dateFormat.format(dateTime.toLocal());

  static String formatTime(DateTime dateTime) =>
      _timeFormat.format(dateTime.toLocal());

  static String formatDateTime(DateTime dateTime) =>
      _dateTimeFormat.format(dateTime.toLocal());

  static String formatCurrency(double amount, {String currency = 'RON'}) {
    final formatted = NumberFormat('#,##0.00', 'en_US').format(amount);
    return '$formatted $currency';
  }
}
