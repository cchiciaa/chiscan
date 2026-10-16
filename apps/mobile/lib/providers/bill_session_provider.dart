import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bill_session.dart';
import '../repositories/bill_session_repository.dart';
import '../services/bill_session_api_client.dart';

final billSessionApiClientProvider = Provider<BillSessionApiClient>(
  (ref) => BillSessionApiClient(),
);

final billSessionRepositoryProvider = Provider<BillSessionRepository>(
  (ref) => ApiBillSessionRepository(apiClient: ref.watch(billSessionApiClientProvider)),
);

final billSessionsProvider = AsyncNotifierProvider<BillSessionsNotifier, List<BillSession>>(
  BillSessionsNotifier.new,
);

class BillSessionsNotifier extends AsyncNotifier<List<BillSession>> {
  BillSessionRepository get _repository => ref.read(billSessionRepositoryProvider);

  @override
  Future<List<BillSession>> build() => _repository.fetchSessions();

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.fetchSessions);
  }

  Future<bool> deleteSession(String id) async {
    state = const AsyncLoading();
    try {
      await _repository.deleteSession(id);
      state = await AsyncValue.guard(_repository.fetchSessions);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}

final createSessionProvider = AsyncNotifierProvider<CreateSessionNotifier, void>(
  CreateSessionNotifier.new,
);

class CreateSessionNotifier extends AsyncNotifier<void> {
  BillSessionRepository get _repository => ref.read(billSessionRepositoryProvider);

  @override
  FutureOr<void> build() {}

  Future<bool> submit({
    required String title,
    required String hostName,
    String? id,
  }) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      if (id != null) {
        await _repository.updateSession(
          id: id,
          title: title.trim(),
          hostName: hostName.trim(),
        );
      } else {
        await _repository.createSession(
          title: title.trim(),
          hostName: hostName.trim(),
        );
      }
      ref.invalidate(billSessionsProvider);
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}
