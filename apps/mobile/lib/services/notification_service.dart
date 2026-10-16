enum NotificationPermissionStatus {
  granted,
  denied,
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.sentAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime sentAt;
}

class NotificationResult {
  const NotificationResult({
    required this.isSuccess,
    this.notification,
    this.errorMessage,
    this.isPermissionDenied = false,
  });

  final bool isSuccess;
  final AppNotification? notification;
  final String? errorMessage;
  final bool isPermissionDenied;

  factory NotificationResult.permissionDenied() => const NotificationResult(
        isSuccess: false,
        isPermissionDenied: true,
        errorMessage: 'Izin notifikasi tidak diberikan. Pemberitahuan tagihan dinonaktifkan.',
      );

  factory NotificationResult.failure(String message) => NotificationResult(
        isSuccess: false,
        errorMessage: message,
      );

  factory NotificationResult.success(AppNotification notification) => NotificationResult(
        isSuccess: true,
        notification: notification,
      );
}

class NotificationService {
  NotificationService({NotificationPermissionStatus initialPermission = NotificationPermissionStatus.granted})
      : _permissionStatus = initialPermission;

  NotificationPermissionStatus _permissionStatus;
  final List<AppNotification> _history = [];

  NotificationPermissionStatus get permissionStatus => _permissionStatus;
  List<AppNotification> get history => List.unmodifiable(_history);

  void setPermissionStatusForTesting(NotificationPermissionStatus status) {
    _permissionStatus = status;
  }

  Future<NotificationPermissionStatus> requestNotificationPermission() async {
    return _permissionStatus;
  }

  Future<NotificationResult> sendBillReminder({
    required String sessionTitle,
    required int totalAmount,
    required int participantCount,
  }) async {
    if (_permissionStatus != NotificationPermissionStatus.granted) {
      return NotificationResult.permissionDenied();
    }

    final notification = AppNotification(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: 'Pengingat Tagihan: $sessionTitle',
      body: 'Total Rp $totalAmount untuk $participantCount orang siap dibayar.',
      sentAt: DateTime.now(),
    );

    _history.insert(0, notification);
    return NotificationResult.success(notification);
  }
}
