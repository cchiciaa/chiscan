import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chiscan_mobile/models/bill_session.dart';
import 'package:chiscan_mobile/providers/advanced_features_provider.dart';
import 'package:chiscan_mobile/providers/bill_session_provider.dart';
import 'package:chiscan_mobile/repositories/bill_session_repository.dart';
import 'package:chiscan_mobile/screens/create_session_screen.dart';
import 'package:chiscan_mobile/screens/dashboard_screen.dart';
import 'package:chiscan_mobile/screens/session_detail_screen.dart';
import 'package:chiscan_mobile/services/camera_scan_service.dart';
import 'package:chiscan_mobile/services/location_service.dart';
import 'package:chiscan_mobile/services/notification_service.dart';

void main() {
  Widget buildTestScope({
    required Widget child,
    BillSessionRepository? repository,
    CameraScanService? cameraService,
    LocationService? locationService,
    NotificationService? notificationService,
  }) {
    return ProviderScope(
      overrides: [
        if (repository != null) billSessionRepositoryProvider.overrideWithValue(repository),
        if (cameraService != null) cameraScanServiceProvider.overrideWithValue(cameraService),
        if (locationService != null) locationServiceProvider.overrideWithValue(locationService),
        if (notificationService != null) notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: MaterialApp(home: child),
    );
  }

  group('P7 Advanced Features - Kamera (Scan Struk)', () {
    testWidgets('1. Kamera Sukses - memindai struk dan mengisi otomatis nama tempat', (tester) async {
      final cameraService = CameraScanService(initialPermission: CameraPermissionStatus.granted);

      await tester.pumpWidget(
        buildTestScope(
          child: const CreateSessionScreen(),
          cameraService: cameraService,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('scan-receipt-button')));
      await tester.pumpAndSettle();

      expect(find.text('Kopi Kenangan Senopati'), findsOneWidget);
      expect(find.textContaining('Struk berhasil dipindai'), findsOneWidget);
    });

    testWidgets('2. Kamera Izin Ditolak - menampilkan pesan error izin', (tester) async {
      final cameraService = CameraScanService(initialPermission: CameraPermissionStatus.denied);

      await tester.pumpWidget(
        buildTestScope(
          child: const CreateSessionScreen(),
          cameraService: cameraService,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('scan-receipt-button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Izin kamera ditolak'), findsOneWidget);
    });
  });

  group('P7 Advanced Features - Lokasi (GPS Restoran Otomatis)', () {
    testWidgets('3. Lokasi Sukses - mendeteksi GPS dan mengisi nama restoran otomatis', (tester) async {
      final locationService = LocationService(initialPermission: LocationPermissionStatus.granted);

      await tester.pumpWidget(
        buildTestScope(
          child: const CreateSessionScreen(),
          locationService: locationService,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('detect-location-button')));
      await tester.pumpAndSettle();

      expect(find.text('Sederhana Bintaro Sektor 9'), findsOneWidget);
      expect(find.textContaining('Lokasi terdeteksi'), findsOneWidget);
    });

    testWidgets('4. Lokasi Izin Ditolak - menampilkan pesan izin lokasi ditolak', (tester) async {
      final locationService = LocationService(initialPermission: LocationPermissionStatus.denied);

      await tester.pumpWidget(
        buildTestScope(
          child: const CreateSessionScreen(),
          locationService: locationService,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('detect-location-button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Izin lokasi perangkat tidak diizinkan'), findsOneWidget);
    });
  });

  group('P7 Advanced Features - Notifikasi (Bill Reminder & Settlement)', () {
    testWidgets('5. Notifikasi Sukses - mengirim pengingat tagihan dari dashboard', (tester) async {
      final notificationService = NotificationService(initialPermission: NotificationPermissionStatus.granted);
      final repo = InMemoryBillSessionRepository(
        initialSessions: const [
          BillSession(
            id: 'demo-p7',
            title: 'Makan Bareng Tim',
            hostName: 'Nadia',
            grandTotalAmount: 180000,
            participantCount: 3,
          ),
        ],
      );

      await tester.pumpWidget(
        buildTestScope(
          child: const DashboardScreen(),
          repository: repo,
          notificationService: notificationService,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Makan Bareng Tim'), findsOneWidget);
      await tester.tap(find.byKey(const Key('notify-session-demo-p7')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Notifikasi pengingat terkirim'), findsOneWidget);
      expect(notificationService.history.length, 1);
      expect(notificationService.history.first.title, contains('Makan Bareng Tim'));
    });

    testWidgets('6. Notifikasi Izin Ditolak - menampilkan pesan izin ditolak', (tester) async {
      final notificationService = NotificationService(initialPermission: NotificationPermissionStatus.denied);
      final repo = InMemoryBillSessionRepository(
        initialSessions: const [
          BillSession(
            id: 'demo-p7',
            title: 'Makan Bareng Tim',
            hostName: 'Nadia',
            grandTotalAmount: 180000,
            participantCount: 3,
          ),
        ],
      );

      await tester.pumpWidget(
        buildTestScope(
          child: const DashboardScreen(),
          repository: repo,
          notificationService: notificationService,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('notify-session-demo-p7')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Izin notifikasi tidak diberikan'), findsOneWidget);
    });
  });

  group('P7 MVP Flow - SessionDetailScreen & Pembagian Tagihan', () {
    testWidgets('7. Alur MVP - navigasi detail, kalkulasi per orang, dan salin ringkasan', (tester) async {
      const session = BillSession(
        id: '1',
        title: 'Makan Siang Sederhana',
        hostName: 'Ahmad',
        grandTotalAmount: 150000,
        participantCount: 3,
      );

      await tester.pumpWidget(
        buildTestScope(
          child: const SessionDetailScreen(session: session),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Makan Siang Sederhana'), findsOneWidget);
      expect(find.text('Rp 150000'), findsOneWidget);
      expect(find.text('Estimasi: Rp 50000 / orang'), findsOneWidget);

      await tester.tap(find.byKey(const Key('copy-summary-button')));
      await tester.pumpAndSettle();

      expect(find.text('Ringkasan tagihan disalin ke clipboard!'), findsOneWidget);
    });
  });
}
