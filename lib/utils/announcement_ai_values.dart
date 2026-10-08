import 'package:flutter/material.dart';

/// Maps only observed, supported values. Unknown values never select defaults.
class AnnouncementAiValues {
  static String normalize(Object? value) =>
      (value?.toString() ?? '').trim().toLowerCase();
  static String? option(
    Object? value,
    Iterable<String> options, {
    String? Function(String)? apiValue,
  }) {
    if (value == null) return null;
    final matches = options
        .where(
          (item) =>
              normalize(item) == normalize(value) ||
              (apiValue != null &&
                  normalize(apiValue(item)) == normalize(value)),
        )
        .toList();
    return matches.length == 1 ? matches.single : null;
  }

  static String? key(Object? value, Map options) {
    if (value == null) return null;
    final matches = options.entries
        .where(
          (e) =>
              normalize(e.key) == normalize(value) ||
              normalize(e.value) == normalize(value),
        )
        .toList();
    return matches.length == 1 ? matches.single.key.toString() : null;
  }

  static List<String> list(
    Object? values,
    Iterable<String> options, {
    String? Function(String)? apiValue,
  }) {
    if (values is! List) return [];
    return values
        .map((v) => option(v, options, apiValue: apiValue))
        .whereType<String>()
        .toSet()
        .toList();
  }

  static List<String> keys(Object? values, Map options) => values is List
      ? values.map((v) => key(v, options)).whereType<String>().toSet().toList()
      : [];
  static Map<String, dynamic>? category(Object? value, Iterable<Map> options) {
    if (value == null) return null;
    final matches = options
        .where(
          (row) => [row['name'], row['label'], row['code']]
              .where((v) => v != null)
              .any((v) => normalize(v) == normalize(value)),
        )
        .toList();
    return matches.length == 1
        ? Map<String, dynamic>.from(matches.single)
        : null;
  }

  static DateTime? date(Object? value) {
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value))
      return null;
    final parsed = DateTime.tryParse(value);
    return parsed != null && parsed.toIso8601String().split('T').first == value
        ? parsed
        : null;
  }

  static TimeOfDay? time(Object? value) {
    if (value is! String || !RegExp(r'^\d{2}:\d{2}$').hasMatch(value))
      return null;
    final parts = value.split(':').map(int.parse).toList();
    return parts[0] < 24 && parts[1] < 60
        ? TimeOfDay(hour: parts[0], minute: parts[1])
        : null;
  }

  static String? number(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim().replaceAll(',', '.');
    final number = double.tryParse(text);
    return number != null && number.isFinite && number >= 0 ? text : null;
  }
}
