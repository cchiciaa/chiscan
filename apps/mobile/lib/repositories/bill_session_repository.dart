import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bill_session.dart';
import '../services/bill_session_api_client.dart';

abstract interface class BillSessionRepository {
  Future<List<BillSession>> fetchSessions();
  Future<BillSession> createSession({
    required String title,
    required String hostName,
    List<BillParticipant>? participants,
    List<BillItem>? items,
  });
  Future<BillSession> updateSession({
    required String id,
    required String title,
    required String hostName,
    List<BillParticipant>? participants,
    List<BillItem>? items,
  });
  Future<void> deleteSession(String id);
}

class LocalBillSessionRepository implements BillSessionRepository {
  LocalBillSessionRepository([SharedPreferences? preferences]) : _preferences = preferences;

  static const String storageKey = 'chiscan_bill_sessions';
  SharedPreferences? _preferences;

  Future<SharedPreferences> get _storage async =>
      _preferences ??= await SharedPreferences.getInstance();

  @override
  Future<List<BillSession>> fetchSessions() async {
    final prefs = await _storage;
    final jsonString = prefs.getString(storageKey);
    if (jsonString == null) {
      await _saveSessions(prefs, const []);
      return const [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((item) => BillSession.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<BillSession> createSession({
    required String title,
    required String hostName,
    List<BillParticipant>? participants,
    List<BillItem>? items,
  }) async {
    final prefs = await _storage;
    final sessions = (await fetchSessions()).toList();
    final savedParticipants = participants ?? const [];
    final savedItems = items ?? const [];
    final subtotal = savedItems.fold<int>(0, (sum, item) => sum + item.totalPrice);
    final newSession = BillSession(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      hostName: hostName,
      grandTotalAmount: subtotal,
      participantCount: savedParticipants.length,
      participants: savedParticipants,
      items: savedItems,
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
    List<BillParticipant>? participants,
    List<BillItem>? items,
  }) async {
    final prefs = await _storage;
    final sessions = (await fetchSessions()).toList();
    final index = sessions.indexWhere((s) => s.id == id);
    if (index == -1) {
      throw Exception('Sesi tidak ditemukan.');
    }
    final savedParticipants = participants ?? sessions[index].participants;
    final savedItems = items ?? sessions[index].items;
    final updated = sessions[index].copyWith(
      title: title,
      hostName: hostName,
      participants: savedParticipants,
      items: savedItems,
      participantCount: savedParticipants.length,
      grandTotalAmount: savedItems.fold<int>(
        0,
        (sum, item) => sum + item.totalPrice,
      ),
    );
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
      : _sessions = initialSessions ?? [];

  final List<BillSession> _sessions;

  @override
  Future<List<BillSession>> fetchSessions() async => List.unmodifiable(_sessions);

  @override
  Future<BillSession> createSession({
    required String title,
    required String hostName,
    List<BillParticipant>? participants,
    List<BillItem>? items,
  }) async {
    final savedParticipants = participants ?? const [];
    final savedItems = items ?? const [];
    final subtotal = savedItems.fold<int>(0, (sum, item) => sum + item.totalPrice);
    final session = BillSession(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      hostName: hostName,
      grandTotalAmount: subtotal,
      participantCount: savedParticipants.length,
      participants: savedParticipants,
      items: savedItems,
    );
    _sessions.insert(0, session);
    return session;
  }

  @override
  Future<BillSession> updateSession({
    required String id,
    required String title,
    required String hostName,
    List<BillParticipant>? participants,
    List<BillItem>? items,
  }) async {
    final index = _sessions.indexWhere((s) => s.id == id);
    if (index == -1) throw Exception('Sesi tidak ditemukan.');
    final savedParticipants = participants ?? _sessions[index].participants;
    final savedItems = items ?? _sessions[index].items;
    final updated = _sessions[index].copyWith(
      title: title,
      hostName: hostName,
      participants: savedParticipants,
      items: savedItems,
      participantCount: savedParticipants.length,
      grandTotalAmount: savedItems.fold<int>(
        0,
        (sum, item) => sum + item.totalPrice,
      ),
    );
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
  Future<BillSession> createSession({
    required String title,
    required String hostName,
    List<BillParticipant>? participants,
    List<BillItem>? items,
  }) =>
      _apiClient.createSession(
        title: title,
        hostName: hostName,
        participants: participants,
        items: items,
      );

  @override
  Future<BillSession> updateSession({
    required String id,
    required String title,
    required String hostName,
    List<BillParticipant>? participants,
    List<BillItem>? items,
  }) =>
      _apiClient.updateSession(
        id: id,
        title: title,
        hostName: hostName,
        participants: participants,
        items: items,
      );

  @override
  Future<void> deleteSession(String id) => _apiClient.deleteSession(id);
}
