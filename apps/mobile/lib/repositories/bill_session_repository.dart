import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bill_session.dart';
import '../services/bill_session_api_client.dart';

abstract interface class BillSessionRepository {
  Future<List<BillSession>> fetchSessions();
  Future<BillSession> createSession({required String title, required String hostName});
  Future<BillSession> updateSession({required String id, required String title, required String hostName});
  Future<void> deleteSession(String id);
}

class LocalBillSessionRepository implements BillSessionRepository {
  LocalBillSessionRepository([SharedPreferences? preferences]) : _preferences = preferences;

  static const String storageKey = 'chiscan_bill_sessions';
  SharedPreferences? _preferences;

  Future<SharedPreferences> get _storage async =>
      _preferences ??= await SharedPreferences.getInstance();

  static const List<BillSession> _defaultSeed = [
    BillSession(
      id: 'demo-1',
      title: 'Makan malam Jumat',
      hostName: 'Nadia',
      grandTotalAmount: 285000,
      participantCount: 4,
    ),
  ];

  @override
  Future<List<BillSession>> fetchSessions() async {
    final prefs = await _storage;
    final jsonString = prefs.getString(storageKey);
    if (jsonString == null) {
      await _saveSessions(prefs, _defaultSeed);
      return _defaultSeed;
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((item) => BillSession.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _defaultSeed;
    }
  }

  @override
  Future<BillSession> createSession({required String title, required String hostName}) async {
    final prefs = await _storage;
    final sessions = (await fetchSessions()).toList();
    final newSession = BillSession(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      hostName: hostName,
      grandTotalAmount: 0,
      participantCount: 0,
    );
    sessions.insert(0, newSession);
    await _saveSessions(prefs, sessions);
    return newSession;
  }

  @override
  Future<BillSession> updateSession({
    required String id,
    required String title,
    required String hostName,
  }) async {
    final prefs = await _storage;
    final sessions = (await fetchSessions()).toList();
    final index = sessions.indexWhere((s) => s.id == id);
    if (index == -1) {
      throw Exception('Sesi tidak ditemukan.');
    }
    final updated = sessions[index].copyWith(title: title, hostName: hostName);
    sessions[index] = updated;
    await _saveSessions(prefs, sessions);
    return updated;
  }

  @override
  Future<void> deleteSession(String id) async {
    final prefs = await _storage;
    final sessions = (await fetchSessions()).toList();
    sessions.removeWhere((s) => s.id == id);
    await _saveSessions(prefs, sessions);
  }

  Future<void> _saveSessions(SharedPreferences prefs, List<BillSession> sessions) async {
    final raw = jsonEncode(sessions.map((s) => s.toJson()).toList());
    await prefs.setString(storageKey, raw);
  }
}

class InMemoryBillSessionRepository implements BillSessionRepository {
  InMemoryBillSessionRepository({List<BillSession>? initialSessions})
      : _sessions = initialSessions ??
            [
              const BillSession(
                id: 'demo-1',
                title: 'Makan malam Jumat',
                hostName: 'Nadia',
                grandTotalAmount: 285000,
                participantCount: 4,
              ),
            ];

  final List<BillSession> _sessions;

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
    _sessions.insert(0, session);
    return session;
  }

  @override
  Future<BillSession> updateSession({
    required String id,
    required String title,
    required String hostName,
  }) async {
    final index = _sessions.indexWhere((s) => s.id == id);
    if (index == -1) throw Exception('Sesi tidak ditemukan.');
    final updated = _sessions[index].copyWith(title: title, hostName: hostName);
    _sessions[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteSession(String id) async {
    _sessions.removeWhere((s) => s.id == id);
  }
}

class ApiBillSessionRepository implements BillSessionRepository {
  ApiBillSessionRepository({BillSessionApiClient? apiClient})
      : _apiClient = apiClient ?? BillSessionApiClient();

  final BillSessionApiClient _apiClient;

  @override
  Future<List<BillSession>> fetchSessions() => _apiClient.getSessions();

  @override
  Future<BillSession> createSession({required String title, required String hostName}) =>
      _apiClient.createSession(title: title, hostName: hostName);

  @override
  Future<BillSession> updateSession({
    required String id,
    required String title,
    required String hostName,
  }) =>
      _apiClient.updateSession(id: id, title: title, hostName: hostName);

  @override
  Future<void> deleteSession(String id) => _apiClient.deleteSession(id);
}
