import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);
final _date = DateFormat('d MMM yyyy');
final _shortDate = DateFormat('EEE, d MMM');
final _time = DateFormat('h:mm a');

String formatMoney(num amount) => _currency.format(amount);

String formatDate(DateTime? date, {String fallback = 'Not set'}) =>
    date == null ? fallback : _date.format(date);

String formatShortDate(DateTime date) => _shortDate.format(date);

String formatTime(DateTime time) => _time.format(time);

String formatTimeRange(DateTime start, DateTime end) =>
    '${formatTime(start)} – ${formatTime(end)}';

/// Strips the time component so dates can be compared by calendar day.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Whole calendar days from [from] to [to]; negative when [to] is earlier.
int daysBetween(DateTime from, DateTime to) =>
    dateOnly(to).difference(dateOnly(from)).inDays;

String relativeDays(int days) {
  if (days == 0) return 'today';
  if (days == 1) return 'tomorrow';
  if (days == -1) return 'yesterday';
  return days > 0 ? 'in $days days' : '${-days} days ago';
}

DateTime combine(DateTime date, TimeOfDay time) =>
    DateTime(date.year, date.month, date.day, time.hour, time.minute);
