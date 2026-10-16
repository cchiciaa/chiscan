import 'package:flutter/material.dart';
import '../models/bill_session.dart';
import '../screens/create_session_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/session_detail_screen.dart';

class AppRoutes {
  static const String dashboard = '/';
  static const String createSession = '/create-session';
  static const String sessionDetail = '/session-detail';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case dashboard:
        return MaterialPageRoute<void>(
          builder: (_) => const DashboardScreen(),
          settings: settings,
        );
      case createSession:
        final session = settings.arguments as BillSession?;
        return MaterialPageRoute<void>(
          builder: (_) => CreateSessionScreen(sessionToEdit: session),
          settings: settings,
        );
      case sessionDetail:
        final session = settings.arguments as BillSession;
        return MaterialPageRoute<void>(
          builder: (_) => SessionDetailScreen(session: session),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const DashboardScreen(),
          settings: settings,
        );
    }
  }
}
