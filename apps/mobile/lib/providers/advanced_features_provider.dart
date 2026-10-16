import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/camera_scan_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';

final cameraScanServiceProvider = Provider<CameraScanService>(
  (ref) => CameraScanService(),
);

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);
