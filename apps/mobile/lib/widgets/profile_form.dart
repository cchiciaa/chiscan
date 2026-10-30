import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../validators/profile_validator.dart';

/// ProfileForm: Bertanggung jawab murni pada INPUT dan STATUS UI
/// Logika validasi didelegasikan ke profile_validator, dan API didelegasikan ke profileRepository.
class ProfileForm extends ConsumerStatefulWidget {
  const ProfileForm({
    super.key,
    required this.initialProfile,
    this.onSavedSuccessfully,
  });

  final UserProfile initialProfile;
  final VoidCallback? onSavedSuccessfully;

  @override
  ConsumerState<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<ProfileForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bankController;
  late final TextEditingController _accountController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialProfile.name);
    _emailController = TextEditingController(text: widget.initialProfile.email);
    _phoneController = TextEditingController(text: widget.initialProfile.phoneNumber);
    _bankController = TextEditingController(text: widget.initialProfile.bankName);
    _accountController = TextEditingController(text: widget.initialProfile.accountNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bankController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _handleFormSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await ref.read(profileProvider.notifier).updateProfile(
          name: _nameController.text,
          email: _emailController.text,
          phoneNumber: _phoneController.text,
          bankName: _bankController.text,
          accountNumber: _accountController.text,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          key: Key('profile-save-success-snackbar'),
          content: Text('Profil berhasil disimpan dan diperbarui!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.onSavedSuccessfully?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final isSubmitting = profileState.isLoading;
    final hasError = profileState.hasError;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAvatarHeader(widget.initialProfile.name),
          const SizedBox(height: 24),
          _buildStatusFeedback(hasError, profileState.error),
          _buildNameField(),
          const SizedBox(height: 16),
          _buildEmailField(),
          const SizedBox(height: 16),
          _buildPhoneField(),
          const SizedBox(height: 16),
          _buildBankAndAccountFields(),
          const SizedBox(height: 28),
          _buildSubmitButton(isSubmitting),
        ],
      ),
    );
  }

  // --- Fungsi-fungsi terfokus (Separation of Concerns) ---

  Widget _buildAvatarHeader(String name) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : 'U';

    return Center(
      child: Semantics(
        label: 'Foto profil pengguna $name',
        child: CircleAvatar(
          radius: 44,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            initials,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFeedback(bool hasError, Object? error) {
    if (!hasError) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Gagal menyimpan profil. Silakan coba kembali.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      key: const Key('profile-name-field'),
      controller: _nameController,
      scrollPadding: const EdgeInsets.only(bottom: 120),
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Nama Lengkap',
        hintText: 'Misal: Nadia Pratama',
        helperText: 'Nama yang ditampilkan kepada peserta split bill',
        prefixIcon: Icon(Icons.person_outline),
        border: OutlineInputBorder(),
      ),
      validator: validateProfileName,
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      key: const Key('profile-email-field'),
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      scrollPadding: const EdgeInsets.only(bottom: 120),
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Alamat Email',
        hintText: 'Misal: nadia@chiscan.app',
        prefixIcon: Icon(Icons.email_outlined),
        border: OutlineInputBorder(),
      ),
      validator: validateProfileEmail,
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      key: const Key('profile-phone-field'),
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      scrollPadding: const EdgeInsets.only(bottom: 120),
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Nomor WhatsApp / HP',
        hintText: 'Misal: 081234567890',
        helperText: 'Nomor untuk pengiriman notifikasi tagihan',
        prefixIcon: Icon(Icons.phone_outlined),
        border: OutlineInputBorder(),
      ),
      validator: validateProfilePhone,
    );
  }

  Widget _buildBankAndAccountFields() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: TextFormField(
            key: const Key('profile-bank-field'),
            controller: _bankController,
            scrollPadding: const EdgeInsets.only(bottom: 120),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Bank / e-Wallet',
              hintText: 'BCA / GoPay',
              prefixIcon: Icon(Icons.account_balance_outlined),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: TextFormField(
            key: const Key('profile-account-field'),
            controller: _accountController,
            keyboardType: TextInputType.number,
            scrollPadding: const EdgeInsets.only(bottom: 120),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleFormSubmit(),
            decoration: const InputDecoration(
              labelText: 'Nomor Rekening',
              hintText: '8830123456',
              helperText: 'Tujuan transfer iuran',
              border: OutlineInputBorder(),
            ),
            validator: validateProfileAccountNumber,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isSubmitting) {
    return Semantics(
      button: true,
      label: 'Simpan perubahan profil pengguna',
      child: SizedBox(
        height: 48,
        child: FilledButton(
          key: const Key('profile-submit-button'),
          onPressed: isSubmitting ? null : _handleFormSubmit,
          child: isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Simpan Profil'),
        ),
      ),
    );
  }
}
