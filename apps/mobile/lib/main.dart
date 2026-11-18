import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'services/app_logger.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      AppLogger.error(
        'Flutter framework error',
        details.exception,
        details.stack,
      );
    };
    await AppLogger.info('ChiScan application started');
    runApp(const ProviderScope(child: ChiScanApp()));
  }, (error, stackTrace) {
    AppLogger.error('Unhandled application error', error, stackTrace);
  });
}
