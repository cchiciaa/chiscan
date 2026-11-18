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

  group('P7 Advanced Features - Input Manual', () {
    testWidgets('1. Kamera tidak menampilkan data simulasi', (tester) async {
      await tester.pumpWidget(
        buildTestScope(
          child: const CreateSessionScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Input manual'), findsOneWidget);
      expect(find.textContaining('Scan kamera dan GPS belum diaktifkan'), findsOneWidget);
      expect(find.byKey(const Key('scan-receipt-button')), findsNothing);
    });

    testWidgets('2. Lokasi tidak menampilkan data simulasi', (tester) async {
      await tester.pumpWidget(
        buildTestScope(
          child: const CreateSessionScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('nama, peserta, dan item harus dimasukkan manual'), findsOneWidget);
      expect(find.byKey(const Key('detect-location-button')), findsNothing);
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

      expect(find.textContaining('Pengingat "Makan Bareng Tim" disalin'), findsOneWidget);
    });

    testWidgets('6. Pengingat dapat disalin tanpa memerlukan izin notifikasi platform', (tester) async {
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

      expect(find.textContaining('Pengingat "Makan Bareng Tim" disalin'), findsOneWidget);
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
        participants: [
          BillParticipant(id: 'p1', name: 'Ahmad'),
          BillParticipant(id: 'p2', name: 'Siti'),
          BillParticipant(id: 'p3', name: 'Budi'),
        ],
      );

      await tester.pumpWidget(
        buildTestScope(
          child: const SessionDetailScreen(session: session),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Makan Siang Sederhana'), findsOneWidget);
      expect(find.byKey(const Key('session-detail-total-amount')), findsOneWidget);
      expect(find.text('Estimasi: Rp 50000 / orang'), findsOneWidget);

      await tester.tap(find.byKey(const Key('copy-summary-button')));
      await tester.pumpAndSettle();

      expect(find.text('Ringkasan tagihan disalin ke clipboard!'), findsOneWidget);
    });
  });
}
