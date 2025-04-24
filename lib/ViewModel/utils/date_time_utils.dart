import 'package:intl/intl.dart';
import 'dart:ui' show PlatformDispatcher;

const String dateTimeFormat = 'dd/MM/yyyy';

extension DateTimeUtils on DateTime {
  String format({String pattern = dateTimeFormat, String? locale}) {
    locale ??= PlatformDispatcher.instance.locale.toString();

    return DateFormat(pattern, locale).format(this);
  }
}
