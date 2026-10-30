import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chiscan_mobile/models/user_profile.dart';
import 'package:chiscan_mobile/providers/profile_provider.dart';
import 'package:chiscan_mobile/repositories/profile_repository.dart';
import 'package:chiscan_mobile/widgets/profile_form.dart';

void main() {
  Widget buildTestScope({
    required Widget child,
    ProfileRepository? repository,
  }) {
    return ProviderScope(
      overrides: [
        if (repository != null) profileRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('Pemisahan Tanggung Jawab - ProfileForm (Input & Status UI)', () {
    testWidgets('1. Render Awal - menampilkan field input dan inisial avatar pengguna', (tester) async {
      const testProfile = UserProfile(
        id: 'user-1',
        name: 'Nadia Pratama',
        email: 'nadia@chiscan.app',
        phoneNumber: '081234567890',
        bankName: 'BCA',
        accountNumber: '8830123456',
      );

      final repo = InMemoryProfileRepository(initialProfile: testProfile);

      await tester.pumpWidget(
        buildTestScope(
          child: const ProfileForm(initialProfile: testProfile),
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NP'), findsOneWidget); // Inisial Nadia Pratama
      expect(find.text('Nadia Pratama'), findsOneWidget);
      expect(find.text('nadia@chiscan.app'), findsOneWidget);
      expect(find.text('081234567890'), findsOneWidget);
      expect(find.text('8830123456'), findsOneWidget);
      expect(find.byKey(const Key('profile-submit-button')), findsOneWidget);
    });

    testWidgets('2. Validasi Input - menampilkan pesan error saat field nama dikosongkan', (tester) async {
      const testProfile = UserProfile(
        id: 'user-1',
        name: 'Nadia Pratama',
        email: 'nadia@chiscan.app',
        phoneNumber: '081234567890',
        bankName: 'BCA',
        accountNumber: '8830123456',
      );

      final repo = InMemoryProfileRepository(initialProfile: testProfile);

      await tester.pumpWidget(
        buildTestScope(
          child: const ProfileForm(initialProfile: testProfile),
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      // Kosongkan nama
      await tester.enterText(find.byKey(const Key('profile-name-field')), '');
      await tester.tap(find.byKey(const Key('profile-submit-button')));
      await tester.pumpAndSettle();

      expect(find.text('Nama lengkap wajib diisi.'), findsOneWidget);
    });

    testWidgets('3. Submit Sukses - memperbarui profil dan menampilkan feedback SnackBar', (tester) async {
      const initialProfile = UserProfile(
        id: 'user-1',
        name: 'Nadia Pratama',
        email: 'nadia@chiscan.app',
        phoneNumber: '081234567890',
        bankName: 'BCA',
        accountNumber: '8830123456',
      );

      final repo = InMemoryProfileRepository(initialProfile: initialProfile);

      await tester.pumpWidget(
        buildTestScope(
          child: const ProfileForm(initialProfile: initialProfile),
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      // Ubah nama
      await tester.enterText(find.byKey(const Key('profile-name-field')), 'Nadia Keisha');
      await tester.tap(find.byKey(const Key('profile-submit-button')));
      await tester.pumpAndSettle();

      expect(find.text('Profil berhasil disimpan dan diperbarui!'), findsOneWidget);
      final updated = await repo.fetchProfile();
      expect(updated.name, 'Nadia Keisha');
    });
  });
}
