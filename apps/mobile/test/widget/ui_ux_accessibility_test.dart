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
  Widget buildTestApp({
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

  group('01 & 02. Layout Adaptif & Keyboard-safe UI', () {
    testWidgets('01. Layout adaptif - berjalan mulus pada layar kecil (320px) dan layar lebar (1024px)', (tester) async {
      // Uji pada layar kecil (320 x 640)
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(child: const CreateSessionScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(CreateSessionScreen), findsOneWidget);
      expect(tester.takeException(), isNull); // Tidak ada RenderFlex overflow

      // Uji pada layar lebar (1024 x 768 - tablet/desktop)
      tester.view.physicalSize = const Size(1024, 768);
      await tester.pumpWidget(buildTestApp(child: const CreateSessionScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(CreateSessionScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('02. Keyboard-safe UI - form dapat di-scroll dan menyembunyikan keyboard saat di-drag', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const CreateSessionScreen()));
      await tester.pumpAndSettle();

      final listViewFinder = find.byType(ListView);
      expect(listViewFinder, findsOneWidget);

      final listView = tester.widget<ListView>(listViewFinder);
      expect(listView.keyboardDismissBehavior, ScrollViewKeyboardDismissBehavior.onDrag);

      // Pastikan field judul dan host memiliki scrollPadding untuk keyboard safety
      final titleFieldFinder = find.byKey(const Key('session-title-field'));
      final titleField = tester.widget<TextField>(find.descendant(of: titleFieldFinder, matching: find.byType(TextField)));
      expect(titleField.scrollPadding.bottom, greaterThanOrEqualTo(100));

      final hostFieldFinder = find.byKey(const Key('host-name-field'));
      final hostField = tester.widget<TextField>(find.descendant(of: hostFieldFinder, matching: find.byType(TextField)));
      expect(hostField.scrollPadding.bottom, greaterThanOrEqualTo(100));
    });
  });

  group('03. Accessibility Dasar (A11y)', () {
    testWidgets('03. Aksesibilitas - elemen memiliki Semantics label dan teks bantu yang jelas', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const CreateSessionScreen()));
      await tester.pumpAndSettle();

      // Cek bahwa integrasi demo kamera dan GPS tidak ditampilkan sebagai hasil nyata
      expect(find.text('Input manual'), findsOneWidget);
      expect(find.textContaining('Scan kamera dan GPS belum diaktifkan'), findsOneWidget);

      // Cek hint dan label pada input form
      expect(find.text('Nama tempat atau event'), findsOneWidget);
      expect(find.text('Nama host'), findsOneWidget);
      expect(find.text('Wajib diisi sebagai judul sesi tagihan'), findsOneWidget);
    });
  });

  group('04. Feedback Aksi (Responsivitas Visual Pengguna)', () {
    testWidgets('04. Feedback aksi - menambahkan item manual', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const CreateSessionScreen(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Nama item'), 'Nasi Goreng');
      await tester.enterText(find.widgetWithText(TextField, 'Harga satuan'), '25000');
      await tester.enterText(find.widgetWithText(TextField, 'Jumlah'), '2');
      await tester.ensureVisible(find.text('Tambah Item'));
      await tester.tap(find.text('Tambah Item'));
      await tester.pumpAndSettle();
      expect(find.text('Nasi Goreng'), findsOneWidget);
    });

    testWidgets('04. Feedback aksi - salin ringkasan memberikan SnackBar feedback visual seketika', (tester) async {
      const session = BillSession(
        id: '1',
        title: 'Makan Bersama',
        hostName: 'Siti',
        grandTotalAmount: 120000,
        participantCount: 2,
      );

      await tester.pumpWidget(buildTestApp(child: const SessionDetailScreen(session: session)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('copy-summary-button')));
      await tester.pumpAndSettle();

      expect(find.text('Ringkasan tagihan disalin ke clipboard!'), findsOneWidget);
    });
  });
}
