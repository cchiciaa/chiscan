import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bill_session.dart';
import '../providers/advanced_features_provider.dart';
import '../providers/bill_session_provider.dart';
import '../utils/ui_feedback.dart';
import '../validators/bill_session_validator.dart';
import '../widgets/adaptive_container.dart';

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
      UiFeedback.showSuccess(context, 'Lokasi terdeteksi: ${result.location!.name}');
    } else {
      UiFeedback.showError(context, result.errorMessage ?? 'Gagal mendeteksi lokasi.');
    }
  }

  Future<void> _handleScanReceipt() async {
    setState(() => _isScanningReceipt = true);
    final result = await ref.read(cameraScanServiceProvider).captureAndScanReceipt();
    if (!mounted) return;
    setState(() => _isScanningReceipt = false);

    if (result.isSuccess && result.merchantName != null) {
      _titleController.text = result.merchantName!;
      UiFeedback.showSuccess(
        context,
        'Struk berhasil dipindai: ${result.merchantName} (Total Rp ${result.totalAmount})',
      );
    } else {
      UiFeedback.showError(context, result.errorMessage ?? 'Gagal memindai struk.');
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await ref.read(createSessionProvider.notifier).submit(
          title: _titleController.text,
          hostName: _hostController.text,
          id: widget.sessionToEdit?.id,
        );
    if (success && mounted) {
      UiFeedback.showSuccess(
        context,
        widget.sessionToEdit != null
            ? 'Sesi "${_titleController.text}" berhasil diperbarui!'
            : 'Sesi "${_titleController.text}" berhasil dibuat!',
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitting = ref.watch(createSessionProvider).isLoading;
    final submitError = ref.watch(createSessionProvider).error;
    final isEditing = widget.sessionToEdit != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Ubah Sesi Tagihan' : 'Buat Sesi Baru')),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: AdaptiveContainer(
            maxWidth: 640,
            child: Form(
              key: _formKey,
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                children: [
                  Semantics(
                    label: 'Fitur otomatisasi pendeteksian data',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Semantics(
                          button: true,
                          label: 'Pindai struk belanja dengan kamera',
                          child: ActionChip(
                            key: const Key('scan-receipt-button'),
                            avatar: _isScanningReceipt
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.camera_alt, size: 18),
                            label: const Text('Pindai Struk (Kamera)'),
                            tooltip: 'Pindai struk belanja dengan kamera perangkat',
                            onPressed: _isScanningReceipt || _isDetectingLocation || submitting ? null : _handleScanReceipt,
                          ),
                        ),
                        Semantics(
                          button: true,
                          label: 'Deteksi restoran terdekat melalui GPS',
                          child: ActionChip(
                            key: const Key('detect-location-button'),
                            avatar: _isDetectingLocation
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.my_location, size: 18),
                            label: const Text('Deteksi Lokasi (GPS)'),
                            tooltip: 'Deteksi restoran di sekitar posisi GPS Anda',
                            onPressed: _isDetectingLocation || _isScanningReceipt || submitting ? null : _handleDetectLocation,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isScanningReceipt) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Sedang membuka kamera dan menganalisis struk...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_isDetectingLocation) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Sedang menghubungkan ke GPS dan mencari nama restoran...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  TextFormField(
                    key: const Key('session-title-field'),
                    controller: _titleController,
                    scrollPadding: const EdgeInsets.only(bottom: 140),
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nama tempat atau event',
                      hintText: 'Misal: Kopi Kenangan, Sederhana Bintaro',
                      helperText: 'Wajib diisi sebagai judul sesi tagihan',
                      prefixIcon: Icon(Icons.place_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => validateBillSession(title: value ?? '', hostName: 'valid').titleError,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    key: const Key('host-name-field'),
                    controller: _hostController,
                    scrollPadding: const EdgeInsets.only(bottom: 140),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Nama host',
                      hintText: 'Misal: Nadia, Budi, Ahmad',
                      helperText: 'Nama orang yang menalangi atau bertanggung jawab',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => validateBillSession(title: 'valid', hostName: value ?? '').hostNameError,
                  ),
                  if (submitError != null) ...[
                    const SizedBox(height: 16),
                    Container(
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
                              isEditing ? 'Sesi gagal diperbarui. Coba lagi.' : 'Sesi gagal dibuat. Coba lagi.',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Semantics(
                    button: true,
                    label: isEditing ? 'Perbarui sesi tagihan' : 'Simpan sesi tagihan',
                    child: SizedBox(
                      height: 48,
                      child: FilledButton(
                        key: const Key('create-session-button'),
                        onPressed: submitting ? null : _submit,
                        child: submitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(isEditing ? 'Perbarui Sesi' : 'Simpan Sesi'),
                      ),
                    ),
                  ),
                  if (submitting) ...[
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'Menyimpan data ke backend, mohon tunggu...',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
