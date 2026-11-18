import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bill_session.dart';
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
  late final TextEditingController _participantsController;
  late final TextEditingController _itemNameController;
  late final TextEditingController _itemPriceController;
  late final TextEditingController _itemQuantityController;
  late List<BillItem> _items;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.sessionToEdit?.title ?? '');
    _hostController = TextEditingController(text: widget.sessionToEdit?.hostName ?? '');
    _participantsController = TextEditingController(
      text: widget.sessionToEdit?.participants
              .map((participant) => participant.name)
              .join(', ') ??
          '',
    );
    _itemNameController = TextEditingController();
    _itemPriceController = TextEditingController();
    _itemQuantityController = TextEditingController(text: '1');
    _items = List<BillItem>.from(widget.sessionToEdit?.items ?? const []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _hostController.dispose();
    _participantsController.dispose();
    _itemNameController.dispose();
    _itemPriceController.dispose();
    _itemQuantityController.dispose();
    super.dispose();
  }

  void _addItem() {
    final name = _itemNameController.text.trim();
    final price = int.tryParse(_itemPriceController.text.trim()) ?? 0;
    final quantity = int.tryParse(_itemQuantityController.text.trim()) ?? 0;
    if (name.isEmpty || price <= 0 || quantity <= 0) {
      UiFeedback.showError(context, 'Nama item, harga, dan jumlah harus valid.');
      return;
    }
    setState(() {
      _items = [
        ..._items,
        BillItem(
          id: 'item-${DateTime.now().microsecondsSinceEpoch}',
          name: name,
          price: price,
          quantity: quantity,
        ),
      ];
      _itemNameController.clear();
      _itemPriceController.clear();
      _itemQuantityController.text = '1';
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final names = _participantsController.text
        .split(',')
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    if (!names.contains(_hostController.text.trim()) && _hostController.text.trim().isNotEmpty) {
      names.insert(0, _hostController.text.trim());
    }
    final participants = List<BillParticipant>.generate(
      names.length,
      (index) => BillParticipant(id: 'p-$index', name: names[index]),
    );
    final success = await ref.read(createSessionProvider.notifier).submit(
          title: _titleController.text,
          hostName: _hostController.text,
          id: widget.sessionToEdit?.id,
          participants: participants,
          items: _items,
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
                    label: 'Input data dilakukan secara manual',
                    child: const Card(
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Input manual'),
                        subtitle: Text('Scan kamera dan GPS belum diaktifkan; nama, peserta, dan item harus dimasukkan manual.'),
                      ),
                    ),
                  ),
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
                  const SizedBox(height: 18),
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
                  const SizedBox(height: 18),
                  TextFormField(
                    key: const Key('session-participants-field'),
                    controller: _participantsController,
                    decoration: const InputDecoration(
                      labelText: 'Nama peserta (dipisahkan koma)',
                      hintText: 'Contoh: Ahmad, Siti, Budi',
                      prefixIcon: Icon(Icons.group_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Item Pesanan', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _itemNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama item',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _itemPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Harga satuan',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 110,
                        child: TextField(
                          controller: _itemQuantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Jumlah',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Item'),
                  ),
                  if (_items.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ..._items.map(
                      (item) => ListTile(
                        dense: true,
                        title: Text(item.name),
                        subtitle: Text('${item.quantity}x @ Rp ${item.price}'),
                        trailing: IconButton(
                          tooltip: 'Hapus item',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => setState(
                            () => _items = _items.where((current) => current.id != item.id).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
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
