// utils/format_utils.dart
import 'package:intl/intl.dart';

String formatCurrency(double amount) {
  final formatter = NumberFormat('#,##0.00', 'en_US');
  return formatter.format(amount);
}

String formatDate(DateTime date) {
  return DateFormat('MMMM d, y').format(date);
}

String formatDateTime(DateTime dateTime) {
  return DateFormat('MMMM d, y h:mm a').format(dateTime);
}