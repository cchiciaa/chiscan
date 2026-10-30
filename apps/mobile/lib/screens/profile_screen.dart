import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../widgets/adaptive_container.dart';
import '../widgets/profile_form.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: AdaptiveContainer(
            maxWidth: 640,
            child: profileAsync.when(
              loading: () => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Memuat data profil...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_off_outlined, size: 56, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      const Text('Gagal memuat profil pengguna.'),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => ref.read(profileProvider.notifier).retry(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (profile) => ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                children: [
                  ProfileForm(
                    initialProfile: profile,
                    onSavedSuccessfully: () {
                      // Tetap di halaman profil atau kembali
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
