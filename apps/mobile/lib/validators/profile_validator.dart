/// Aturan validasi profil pengguna (Single Responsibility Functions)
/// Setiap fungsi berfokus pada satu aturan input spesifik tanpa duplikasi logika.

class ProfileValidationResult {
  const ProfileValidationResult({
    this.nameError,
    this.emailError,
    this.phoneError,
    this.accountError,
  });

  final String? nameError;
  final String? emailError;
  final String? phoneError;
  final String? accountError;

  bool get isValid =>
      nameError == null &&
      emailError == null &&
      phoneError == null &&
      accountError == null;
}

/// Validasi nama pengguna: wajib diisi dan minimal 3 karakter
String? validateProfileName(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return 'Nama lengkap wajib diisi.';
  }
  if (trimmed.length < 3) {
    return 'Nama minimal terdiri dari 3 karakter.';
  }
  return null;
}

/// Validasi email pengguna: format harus mengandung @ dan domain yang valid
String? validateProfileEmail(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return 'Alamat email wajib diisi.';
  }
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(trimmed)) {
    return 'Format alamat email tidak valid.';
  }
  return null;
}

/// Validasi nomor HP/WhatsApp: wajib diisi, format numerik, dan minimal 10 digit
String? validateProfilePhone(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return 'Nomor HP/WhatsApp wajib diisi.';
  }
  final numericRegex = RegExp(r'^[0-9]+$');
  if (!numericRegex.hasMatch(trimmed)) {
    return 'Nomor HP hanya boleh berisi angka.';
  }
  if (trimmed.length < 10) {
    return 'Nomor HP minimal 10 digit angka.';
  }
  return null;
}

/// Validasi nomor rekening bank / nomor e-wallet: minimal 5 digit angka jika diisi
String? validateProfileAccountNumber(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return 'Nomor rekening atau e-wallet wajib diisi untuk transfer.';
  }
  final numericRegex = RegExp(r'^[0-9]+$');
  if (!numericRegex.hasMatch(trimmed)) {
    return 'Nomor rekening hanya boleh berisi angka.';
  }
  if (trimmed.length < 5) {
    return 'Nomor rekening minimal 5 digit.';
  }
  return null;
}

/// Menggabungkan seluruh aturan input profil menjadi satu evaluasi menyeluruh
ProfileValidationResult validateUserProfile({
  required String name,
  required String email,
  required String phoneNumber,
  required String accountNumber,
}) {
  return ProfileValidationResult(
    nameError: validateProfileName(name),
    emailError: validateProfileEmail(email),
    phoneError: validateProfilePhone(phoneNumber),
    accountError: validateProfileAccountNumber(accountNumber),
  );
}
