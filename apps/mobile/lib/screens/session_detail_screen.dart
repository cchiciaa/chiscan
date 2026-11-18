import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bill_session.dart';
import '../widgets/adaptive_container.dart';

class SessionDetailScreen extends ConsumerStatefulWidget {
  const SessionDetailScreen({super.key, required this.session});

  final BillSession session;

  @override
  ConsumerState<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  List<BillParticipant> get _participants => widget.session.participants;
  List<BillItem> get _items => widget.session.items;
  int get _grandTotal => widget.session.calculatedGrandTotal;
  List<BillShare> get _shares => widget.session.calculateShares();

  Future<void> _sendNotification() async {
    await Clipboard.setData(ClipboardData(text: _buildReminderText()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pengingat tagihan berhasil disalin. Tempelkan ke WhatsApp atau aplikasi pesan.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _buildReminderText() {
    final shares = _shares;
    final breakdown = shares.isEmpty
        ? 'Peserta: belum ada data'
        : shares.map((share) => '- ${share.participant.name}: Rp ${share.amount}').join('\n');
    return '''
🧾 *Ringkasan Tagihan: ${widget.session.title}*
Host: ${widget.session.hostName}
Total: Rp $_grandTotal
$breakdown

Silakan transfer ke rekening host. Terima kasih!
''';
  }

  void _copySummary() {
    Clipboard.setData(ClipboardData(text: _buildReminderText()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.assignment_turned_in, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text('Ringkasan tagihan disalin ke clipboard!')),
          ],
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shares = _shares;
    final perPerson = _participants.isEmpty
        ? 0
        : (_grandTotal / _participants.length).round();

    return Scaffold(
      appBar: AppBar(title: Text(widget.session.title)),
      body: SafeArea(
        child: AdaptiveContainer(
          maxWidth: 720,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              Card(
                elevation: 2,
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Semantics(
                    label: 'Total tagihan Rp $_grandTotal, estimasi Rp $perPerson per orang, host ${widget.session.hostName}',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Tagihan', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(
                          'Rp $_grandTotal',
                          key: const Key('session-detail-total-amount'),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                        ),
                        const Divider(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Host: ${widget.session.hostName}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Estimasi: Rp $perPerson / orang',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        key: const Key('send-detail-notification-button'),
                        onPressed: _sendNotification,
                        icon: const Icon(Icons.notifications_active),
                        label: const Text('Kirim Pengingat'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        key: const Key('copy-summary-button'),
                        onPressed: _copySummary,
                        icon: const Icon(Icons.copy),
                        label: const Text('Salin WA'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text('Peserta Tagihan (${_participants.length})', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_participants.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.group_add_outlined),
                    title: Text('Belum ada peserta'),
                    subtitle: Text('Tambahkan nama peserta saat membuat atau mengubah sesi.'),
                  ),
                )
              else
                ...shares.map(
                  (share) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      dense: true,
                      leading: const CircleAvatar(
                        radius: 16,
                        child: Icon(Icons.person_outline, size: 18),
                      ),
                      title: Text(
                        share.participant.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text('Bagian: Rp ${share.amount}'),
                      trailing: Chip(
                        label: const Text('PENDING'),
                        backgroundColor: Colors.orange.shade100,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Text('Item Pesanan', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_items.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.receipt_long_outlined),
                    title: Text('Belum ada item pesanan'),
                    subtitle: Text('Tambahkan item untuk menghitung pembagian yang akurat.'),
                  ),
                )
              else
                ..._items.map(
                  (item) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.restaurant_menu),
                      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text('${item.quantity}x @ Rp ${item.price}'),
                      trailing: Text(
                        'Rp ${item.totalPrice}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
