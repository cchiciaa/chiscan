import 'package:flutter_test/flutter_test.dart';
import 'package:chiscan_mobile/validators/profile_validator.dart';

void main() {
  group('Pemisahan Tanggung Jawab - Profile Validation Rules', () {
    test('1. Validasi Nama - memeriksa nama kosong, nama terlalu pendek, dan nama valid', () {
      expect(validateProfileName(''), 'Nama lengkap wajib diisi.');
      expect(validateProfileName('   '), 'Nama lengkap wajib diisi.');
      expect(validateProfileName('Al'), 'Nama minimal terdiri dari 3 karakter.');
      expect(validateProfileName('Budi Santoso'), isNull);
    });

    test('2. Validasi Email - memeriksa format email wajib dan regex domain', () {
      expect(validateProfileEmail(''), 'Alamat email wajib diisi.');
      expect(validateProfileEmail('bukan-email'), 'Format alamat email tidak valid.');
      expect(validateProfileEmail('user@domain'), 'Format alamat email tidak valid.');
      expect(validateProfileEmail('nadia@chiscan.app'), isNull);
    });

    test('3. Validasi Nomor HP - memastikan format angka murni dan minimal 10 digit', () {
      expect(validateProfilePhone(''), 'Nomor HP/WhatsApp wajib diisi.');
      expect(validateProfilePhone('0812abc345'), 'Nomor HP hanya boleh berisi angka.');
      expect(validateProfilePhone('08123'), 'Nomor HP minimal 10 digit angka.');
      expect(validateProfilePhone('081234567890'), isNull);
    });

    test('4. Validasi Nomor Rekening - memastikan angka numerik dan minimal 5 digit', () {
      expect(validateProfileAccountNumber(''), 'Nomor rekening atau e-wallet wajib diisi untuk transfer.');
      expect(validateProfileAccountNumber('rekening123'), 'Nomor rekening hanya boleh berisi angka.');
      expect(validateProfileAccountNumber('123'), 'Nomor rekening minimal 5 digit.');
      expect(validateProfileAccountNumber('8830123456'), isNull);
    });

    test('5. Evaluasi Komposit - validateUserProfile mengembalikan isValid true saat semua valid', () {
      final valid = validateUserProfile(
        name: 'Ahmad Dahlan',
        email: 'ahmad@example.com',
        phoneNumber: '081298765432',
        accountNumber: '123456789',
      );
      expect(valid.isValid, isTrue);
      expect(valid.nameError, isNull);
      expect(valid.emailError, isNull);
      expect(valid.phoneError, isNull);
      expect(valid.accountError, isNull);

      final invalid = validateUserProfile(
        name: 'A',
        email: 'invalid-email',
        phoneNumber: '123',
        accountNumber: 'abc',
      );
      expect(invalid.isValid, isFalse);
      expect(invalid.nameError, isNotNull);
      expect(invalid.emailError, isNotNull);
      expect(invalid.phoneError, isNotNull);
      expect(invalid.accountError, isNotNull);
    });
  });
}
