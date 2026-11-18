import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLogger {
  AppLogger._();

  static const _logKey = 'chiscan_runtime_logs';
  static const _maxEntries = 200;

  static Future<void> info(String message) => _write('INFO', message);
  static Future<void> warning(String message) => _write('WARNING', message);
  static Future<void> error(String message, [Object? error, StackTrace? stackTrace]) {
    final detail = [
      message,
      if (error != null) 'error=$error',
      if (stackTrace != null) 'stack=$stackTrace',
    ].join(' | ');
    return _write('ERROR', detail);
  }

  static Future<void> _write(String level, String message) async {
    final timestamp = DateTime.now().toIso8601String();
    final entry = '[$timestamp][$level] $message';
    debugPrint(entry);
    final preferences = await SharedPreferences.getInstance();
    final entries = preferences.getStringList(_logKey) ?? <String>[];
    entries.insert(0, entry);
    await preferences.setStringList(
      _logKey,
      entries.take(_maxEntries).toList(),
    );
  }

  static Future<List<String>> readLogs() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_logKey) ?? const [];
  }

  static Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_logKey);
  }
}