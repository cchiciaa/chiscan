import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ApiProfileRepository(),
);

final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserProfile>(
  ProfileNotifier.new,
);

class ProfileNotifier extends AsyncNotifier<UserProfile> {
  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  @override
  Future<UserProfile> build() => _repository.fetchProfile();

  Future<bool> updateProfile({
    required String name,
    required String email,
    required String phoneNumber,
    required String bankName,
    required String accountNumber,
  }) async {
    final current = state.valueOrNull ?? UserProfile.defaultProfile;
    final updated = current.copyWith(
      name: name.trim(),
      email: email.trim(),
      phoneNumber: phoneNumber.trim(),
      bankName: bankName.trim(),
      accountNumber: accountNumber.trim(),
    );

    state = const AsyncLoading();
    try {
      final saved = await _repository.updateProfile(updated);
      state = AsyncData(saved);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.fetchProfile);
  }
}
