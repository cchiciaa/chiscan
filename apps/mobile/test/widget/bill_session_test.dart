import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chiscan_mobile/models/bill_session.dart';
import 'package:chiscan_mobile/repositories/bill_session_repository.dart';
import 'package:chiscan_mobile/screens/create_session_screen.dart';
import 'package:chiscan_mobile/screens/dashboard_screen.dart';
import 'package:chiscan_mobile/providers/bill_session_provider.dart';

class FakeBillSessionRepository implements BillSessionRepository {
  FakeBillSessionRepository({
    this.sessions = const [],
    this.failure,
    this.fetchCompleter,
    this.submitCompleter,
  });

  List<BillSession> sessions;
  Object? failure;
  Completer<List<BillSession>>? fetchCompleter;
  Completer<BillSession>? submitCompleter;
  int createCount = 0;
  int updateCount = 0;
  int deleteCount = 0;

  @override
  Future<List<BillSession>> fetchSessions() async {
    if (fetchCompleter != null) return fetchCompleter!.future;
    if (failure != null) throw failure!;
    return sessions;
  }

  @override
  Future<BillSession> createSession({required String title, required String hostName}) async {
    createCount++;
    if (submitCompleter != null) return submitCompleter!.future;
    if (failure != null) throw failure!;
    final session = BillSession(
      id: 'new-$createCount',
      title: title,
      hostName: hostName,
      grandTotalAmount: 0,
      participantCount: 0,
    );
    sessions = [session, ...sessions];
    return session;
  }

  @override
  Future<BillSession> updateSession({
    required String id,
    required String title,
    required String hostName,
  }) async {
    updateCount++;
    if (failure != null) throw failure!;
    final index = sessions.indexWhere((s) => s.id == id);
    if (index == -1) throw Exception('Sesi tidak ditemukan.');
    final updated = sessions[index].copyWith(title: title, hostName: hostName);
    sessions = [...sessions]..[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteSession(String id) async {
    deleteCount++;
    if (failure != null) throw failure!;
    sessions = sessions.where((s) => s.id != id).toList();
  }
}

Widget wrap(Widget child, BillSessionRepository repository) {
  return ProviderScope(
    overrides: [billSessionRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('menampilkan initial loading', (tester) async {
    final completer = Completer<List<BillSession>>();
    final repository = FakeBillSessionRepository(fetchCompleter: completer);
    await tester.pumpWidget(wrap(const DashboardScreen(), repository));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    completer.complete([]);
    await tester.pumpAndSettle();
  });

  testWidgets('menampilkan data berhasil dimuat', (tester) async {
    final repository = FakeBillSessionRepository(
      sessions: [
        const BillSession(
          id: '1',
          title: 'Makan Siang',
          hostName: 'Dina',
          grandTotalAmount: 120000,
          participantCount: 2,
        ),
      ],
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
    repository.sessions = [
      const BillSession(
        id: '2',
        title: 'Kopi',
        hostName: 'Raka',
        grandTotalAmount: 50000,
        participantCount: 1,
      ),
    ];
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Kopi'), findsOneWidget);
  });

  testWidgets('menampilkan validasi input form', (tester) async {
    await tester.pumpWidget(wrap(const CreateSessionScreen(), FakeBillSessionRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create-session-button')));
    await tester.pumpAndSettle();
    expect(find.text('Nama sesi wajib diisi.'), findsOneWidget);
    expect(find.text('Nama host wajib diisi.'), findsOneWidget);
  });

  testWidgets('menampilkan loading submit dan mencegah double tap', (tester) async {
    final completer = Completer<BillSession>();
    final repository = FakeBillSessionRepository(submitCompleter: completer);
    await tester.pumpWidget(wrap(const CreateSessionScreen(), repository));
    await tester.enterText(find.byKey(const Key('session-title-field')), 'Makan Bersama');
    await tester.enterText(find.byKey(const Key('host-name-field')), 'Sari');
    await tester.tap(find.byKey(const Key('create-session-button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('create-session-button')));
    expect(repository.createCount, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    completer.complete(
      const BillSession(
        id: 'new',
        title: 'Makan Bersama',
        hostName: 'Sari',
        grandTotalAmount: 0,
        participantCount: 0,
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('CRUD Update - memperbarui sesi yang sudah ada', (tester) async {
    final repository = FakeBillSessionRepository(
      sessions: [
        const BillSession(
          id: '1',
          title: 'Makan Siang Lama',
          hostName: 'Budi',
          grandTotalAmount: 50000,
          participantCount: 1,
        ),
      ],
    );
    await tester.pumpWidget(wrap(const DashboardScreen(), repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('edit-session-1')));
    await tester.pumpAndSettle();

    expect(find.text('Ubah Sesi Tagihan'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('session-title-field')), 'Makan Siang Baru');
    await tester.tap(find.byKey(const Key('create-session-button')));
    await tester.pumpAndSettle();

    expect(repository.updateCount, 1);
    expect(find.text('Makan Siang Baru'), findsOneWidget);
  });

  testWidgets('CRUD Delete - menghapus sesi dengan konfirmasi dialog', (tester) async {
    final repository = FakeBillSessionRepository(
      sessions: [
        const BillSession(
          id: '1',
          title: 'Sesi Hapus',
          hostName: 'Budi',
          grandTotalAmount: 50000,
          participantCount: 1,
        ),
      ],
    );
    await tester.pumpWidget(wrap(const DashboardScreen(), repository));
    await tester.pumpAndSettle();
    expect(find.text('Sesi Hapus'), findsOneWidget);

    await tester.tap(find.byKey(const Key('delete-session-1')));
    await tester.pumpAndSettle();

    expect(find.text('Hapus Sesi?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-delete-button')));
    await tester.pumpAndSettle();

    expect(repository.deleteCount, 1);
    expect(find.text('Sesi Hapus'), findsNothing);
    expect(find.text('Belum ada sesi tagihan.'), findsOneWidget);
  });

  test('Persistence Test - data tersimpan di SharedPreferences dan bertahan setelah restart', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await SharedPreferences.getInstance();

    final repoFirstRun = LocalBillSessionRepository(storage);
    final initialList = await repoFirstRun.fetchSessions();
    expect(initialList.isNotEmpty, true);

    final created = await repoFirstRun.createSession(
      title: 'Nasi Padang Berkah',
      hostName: 'Ahmad',
    );
    expect(created.title, 'Nasi Padang Berkah');

    final updated = await repoFirstRun.updateSession(
      id: created.id,
      title: 'Nasi Padang Berkah VIP',
      hostName: 'Ahmad Fauzi',
    );
    expect(updated.title, 'Nasi Padang Berkah VIP');

    // Simulasikan app restart dengan instansiasi repository baru membaca storage yang sama
    final repoSecondRun = LocalBillSessionRepository(storage);
    final reloadedSessions = await repoSecondRun.fetchSessions();

    final persistentSession = reloadedSessions.firstWhere((s) => s.id == created.id);
    expect(persistentSession.title, 'Nasi Padang Berkah VIP');
    expect(persistentSession.hostName, 'Ahmad Fauzi');

    // Uji penghapusan data
    await repoSecondRun.deleteSession(created.id);
    final afterDelete = await repoSecondRun.fetchSessions();
    expect(afterDelete.any((s) => s.id == created.id), false);
  });
}
