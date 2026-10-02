import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bill_session.dart';
import '../repositories/bill_session_repository.dart';

final billSessionRepositoryProvider = Provider<BillSessionRepository>(
  (ref) => InMemoryBillSessionRepository(),
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
}

final createSessionProvider = AsyncNotifierProvider<CreateSessionNotifier, void>(
  CreateSessionNotifier.new,
);

class CreateSessionNotifier extends AsyncNotifier<void> {
  BillSessionRepository get _repository => ref.read(billSessionRepositoryProvider);

  @override
  Future<void> build() async {}

  Future<bool> submit({required String title, required String hostName}) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      await _repository.createSession(title: title.trim(), hostName: hostName.trim());
      ref.invalidate(billSessionsProvider);
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}
