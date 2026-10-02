import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/bill_session_provider.dart';
import '../validators/bill_session_validator.dart';

class CreateSessionScreen extends ConsumerStatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  ConsumerState<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends ConsumerState<CreateSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _hostController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _hostController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final created = await ref.read(createSessionProvider.notifier).submit(
          title: _titleController.text,
          hostName: _hostController.text,
        );
    if (created && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final submitting = ref.watch(createSessionProvider).isLoading;
    final submitError = ref.watch(createSessionProvider).error;
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Sesi Baru')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              key: const Key('session-title-field'),
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Nama tempat atau event'),
              validator: (value) => validateBillSession(title: value ?? '', hostName: 'valid').titleError,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('host-name-field'),
              controller: _hostController,
              decoration: const InputDecoration(labelText: 'Nama host'),
              validator: (value) => validateBillSession(title: 'valid', hostName: value ?? '').hostNameError,
            ),
            if (submitError != null) ...[
              const SizedBox(height: 16),
              Text('Sesi gagal dibuat. Coba lagi.', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('create-session-button'),
              onPressed: submitting ? null : _submit,
              child: submitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Simpan Sesi'),
            ),
          ],
        ),
      ),
    );
  }
}
