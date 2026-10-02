import '../models/bill_session.dart';

abstract interface class BillSessionRepository {
  Future<List<BillSession>> fetchSessions();
  Future<BillSession> createSession({required String title, required String hostName});
}

class InMemoryBillSessionRepository implements BillSessionRepository {
  final List<BillSession> _sessions = [
    const BillSession(
      id: 'demo-1',
      title: 'Makan malam Jumat',
      hostName: 'Nadia',
      grandTotalAmount: 285000,
      participantCount: 4,
    ),
  ];

  @override
  Future<List<BillSession>> fetchSessions() async => List.unmodifiable(_sessions);

  @override
  Future<BillSession> createSession({required String title, required String hostName}) async {
    final session = BillSession(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      hostName: hostName,
      grandTotalAmount: 0,
      participantCount: 0,
    );
    _sessions.add(session);
    return session;
  }
}
