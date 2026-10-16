import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chiscan_mobile/app.dart';
import 'package:chiscan_mobile/models/bill_session.dart';
import 'package:chiscan_mobile/repositories/bill_session_repository.dart';
import 'package:chiscan_mobile/providers/bill_session_provider.dart';

void main() {
  testWidgets('ChiScanApp smoke test menampilkan judul appBar dan data sesi', (WidgetTester tester) async {
    final fakeRepo = InMemoryBillSessionRepository(
      initialSessions: const [
        BillSession(
          id: '1',
          title: 'Sesi Uji',
          hostName: 'Host Uji',
          grandTotalAmount: 10000,
          participantCount: 1,
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [billSessionRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const ChiScanApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sesi Tagihan'), findsOneWidget);
    expect(find.text('Sesi Uji'), findsOneWidget);
  });
}
