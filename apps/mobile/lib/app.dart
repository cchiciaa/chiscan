import 'package:flutter/material.dart';

import 'routes/app_routes.dart';

class ChiScanApp extends StatelessWidget {
  const ChiScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChiScan',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      initialRoute: AppRoutes.dashboard,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
