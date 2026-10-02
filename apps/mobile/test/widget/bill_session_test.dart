import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chiscan_mobile/models/bill_session.dart';
import 'package:chiscan_mobile/repositories/bill_session_repository.dart';
import 'package:chiscan_mobile/screens/create_session_screen.dart';
import 'package:chiscan_mobile/screens/dashboard_screen.dart';
import 'package:chiscan_mobile/providers/bill_session_provider.dart';

class FakeBillSessionRepository implements BillSessionRepository {
  FakeBillSessionRepository({this.sessions = const [], this.failure, this.delay});

  List<BillSession> sessions;
  Object? failure;
  Duration? delay;
  int createCount = 0;

  @override
  Future<List<BillSession>> fetchSessions() async {
    if (delay != null) await Future<void>.delayed(delay!);
    if (failure != null) throw failure!;
    return sessions;
  }

  @override
  Future<BillSession> createSession({required String title, required String hostName}) async {
    createCount++;
    if (delay != null) await Future<void>.delayed(delay!);
    if (failure != null) throw failure!;
    return BillSession(id: 'new', title: title, hostName: hostName, grandTotalAmount: 0, participantCount: 0);
  }
}

Widget wrap(Widget child, FakeBillSessionRepository repository) {
  return ProviderScope(
    overrides: [billSessionRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('menampilkan initial loading', (tester) async {
    final repository = FakeBillSessionRepository(delay: const Duration(seconds: 1));
    await tester.pumpWidget(wrap(const DashboardScreen(), repository));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('menampilkan data berhasil dimuat', (tester) async {
    final repository = FakeBillSessionRepository(
      sessions: [const BillSession(id: '1', title: 'Makan Siang', hostName: 'Dina', grandTotalAmount: 120000, participantCount: 2)],
    );
    await tester.pumpWidget(wrap(const DashboardScreen(), repository));
    await tester.pumpAndSettle();
    expect(find.text('Makan Siang'), findsOneWidget);
    expect(find.text('Host: Dina • 2 orang'), findsOneWidget);
  });

  testWidgets('menampilkan empty state', (tester) async {
    await tester.pumpWidget(wrap(const DashboardScreen(), FakeBillSessionRepository()));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada sesi tagihan.'), findsOneWidget);
  });

  testWidgets('menampilkan error dan retry berhasil', (tester) async {
    final repository = FakeBillSessionRepository(failure: Exception('offline'));
    await tester.pumpWidget(wrap(const DashboardScreen(), repository));
    await tester.pumpAndSettle();
    expect(find.text('Sesi tagihan gagal dimuat.'), findsOneWidget);
    repository.failure = null;
    repository.sessions = [const BillSession(id: '2', title: 'Kopi', hostName: 'Raka', grandTotalAmount: 50000, participantCount: 1)];
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Kopi'), findsOneWidget);
  });

  testWidgets('menampilkan validasi input form', (tester) async {
    await tester.pumpWidget(wrap(const CreateSessionScreen(), FakeBillSessionRepository()));
    await tester.tap(find.byKey(const Key('create-session-button')));
    await tester.pump();
    expect(find.text('Nama sesi wajib diisi.'), findsOneWidget);
    expect(find.text('Nama host wajib diisi.'), findsOneWidget);
  });

  testWidgets('menampilkan loading submit dan mencegah double tap', (tester) async {
    final repository = FakeBillSessionRepository(delay: const Duration(seconds: 1));
    await tester.pumpWidget(wrap(const CreateSessionScreen(), repository));
    await tester.enterText(find.byKey(const Key('session-title-field')), 'Makan Bersama');
    await tester.enterText(find.byKey(const Key('host-name-field')), 'Sari');
    await tester.tap(find.byKey(const Key('create-session-button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('create-session-button')));
    expect(repository.createCount, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
