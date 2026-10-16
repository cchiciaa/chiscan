import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bill_session.dart';
import '../providers/advanced_features_provider.dart';
import '../providers/bill_session_provider.dart';
import '../validators/bill_session_validator.dart';

class CreateSessionScreen extends ConsumerStatefulWidget {
  const CreateSessionScreen({super.key, this.sessionToEdit});

  final BillSession? sessionToEdit;

  @override
  ConsumerState<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends ConsumerState<CreateSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _hostController;
  bool _isDetectingLocation = false;
  bool _isScanningReceipt = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.sessionToEdit?.title ?? '');
    _hostController = TextEditingController(text: widget.sessionToEdit?.hostName ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _hostController.dispose();
    super.dispose();
  }

  Future<void> _handleDetectLocation() async {
    setState(() => _isDetectingLocation = true);
    final result = await ref.read(locationServiceProvider).detectCurrentRestaurantLocation();
    if (!mounted) return;
    setState(() => _isDetectingLocation = false);

    if (result.isSuccess && result.location != null) {
      _titleController.text = result.location!.name;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lokasi terdeteksi: ${result.location!.name}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Gagal mendeteksi lokasi.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _handleScanReceipt() async {
    setState(() => _isScanningReceipt = true);
    final result = await ref.read(cameraScanServiceProvider).captureAndScanReceipt();
    if (!mounted) return;
    setState(() => _isScanningReceipt = false);

    if (result.isSuccess && result.merchantName != null) {
      _titleController.text = result.merchantName!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Struk berhasil dipindai: ${result.merchantName} (Total Rp ${result.totalAmount})'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Gagal memindai struk.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await ref.read(createSessionProvider.notifier).submit(
          title: _titleController.text,
          hostName: _hostController.text,
          id: widget.sessionToEdit?.id,
        );
    if (success && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final submitting = ref.watch(createSessionProvider).isLoading;
    final submitError = ref.watch(createSessionProvider).error;
    final isEditing = widget.sessionToEdit != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Ubah Sesi Tagihan' : 'Buat Sesi Baru')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  key: const Key('scan-receipt-button'),
                  avatar: _isScanningReceipt
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Pindai Struk (Kamera)'),
                  onPressed: _isScanningReceipt ? null : _handleScanReceipt,
                ),
                ActionChip(
                  key: const Key('detect-location-button'),
                  avatar: _isDetectingLocation
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location, size: 18),
                  label: const Text('Deteksi Lokasi (GPS)'),
                  onPressed: _isDetectingLocation ? null : _handleDetectLocation,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('session-title-field'),
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Nama tempat atau event',
                border: OutlineInputBorder(),
              ),
              validator: (value) => validateBillSession(title: value ?? '', hostName: 'valid').titleError,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('host-name-field'),
              controller: _hostController,
              decoration: const InputDecoration(
                labelText: 'Nama host',
                border: OutlineInputBorder(),
              ),
              validator: (value) => validateBillSession(title: 'valid', hostName: value ?? '').hostNameError,
            ),
            if (submitError != null) ...[
              const SizedBox(height: 16),
              Text(
                isEditing ? 'Sesi gagal diperbarui. Coba lagi.' : 'Sesi gagal dibuat. Coba lagi.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('create-session-button'),
              onPressed: submitting ? null : _submit,
              child: submitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isEditing ? 'Perbarui Sesi' : 'Simpan Sesi'),
            ),
          ],
        ),
      ),
    );
  }
}
