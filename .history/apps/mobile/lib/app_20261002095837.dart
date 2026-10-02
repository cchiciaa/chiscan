import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';

class ChiScanApp extends StatelessWidget {
  const ChiScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChiScan',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const DashboardScreen(),
    );
  }
}
