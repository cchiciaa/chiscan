import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bill_session.dart';
import '../providers/advanced_features_provider.dart';

class SessionDetailScreen extends ConsumerStatefulWidget {
  const SessionDetailScreen({super.key, required this.session});

  final BillSession session;

  @override
  ConsumerState<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  late final List<String> _participants;
  late final List<Map<String, dynamic>> _items;
  late int _grandTotal;

  @override
  void initState() {
    super.initState();
    _participants = ['Host (${widget.session.hostName})', 'Andi', 'Siti'];
    _items = [
      {'name': 'Menu Utama', 'price': 75000, 'qty': 2},
      {'name': 'Minuman Segar', 'price': 15000, 'qty': 3},
    ];
    _grandTotal = widget.session.grandTotalAmount > 0 ? widget.session.grandTotalAmount : 195000;
  }

  Future<void> _sendNotification() async {
    final result = await ref.read(notificationServiceProvider).sendBillReminder(
          sessionTitle: widget.session.title,
          totalAmount: _grandTotal,
          participantCount: _participants.length,
        );

    if (!mounted) return;

    if (result.isSuccess && result.notification != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notifikasi berhasil dikirim: ${result.notification!.title}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Gagal mengirim notifikasi.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _copySummary() {
    final perPerson = (_grandTotal / _participants.length).round();
    final summary = '''
🧾 *Ringkasan Tagihan: ${widget.session.title}*
Host: ${widget.session.hostName}
Total: Rp $_grandTotal
Peserta (${_participants.length}): ${_participants.join(', ')}
Tagihan per orang: Rp $perPerson

Silakan transfer ke rekening host. Terima kasih!
''';

    Clipboard.setData(ClipboardData(text: summary));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ringkasan tagihan disalin ke clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final perPerson = (_grandTotal / _participants.length).round();

    return Scaffold(
      appBar: AppBar(title: Text(widget.session.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Tagihan', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Rp $_grandTotal',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Host: ${widget.session.hostName}'),
                      Text('Estimasi: Rp $perPerson / orang', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const Key('send-detail-notification-button'),
                  onPressed: _sendNotification,
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Kirim Pengingat'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                key: const Key('copy-summary-button'),
                onPressed: _copySummary,
                icon: const Icon(Icons.copy),
                label: const Text('Salin WA'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Peserta Tagihan (${_participants.length})', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._participants.map(
            (p) => ListTile(
              dense: true,
              leading: const Icon(Icons.person_outline),
              title: Text(p),
              trailing: Chip(
                label: Text(p.contains('Host') ? 'PAID' : 'PENDING'),
                backgroundColor: p.contains('Host') ? Colors.green.shade100 : Colors.orange.shade100,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Item Pesanan', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._items.map(
            (item) => ListTile(
              dense: true,
              leading: const Icon(Icons.restaurant_menu),
              title: Text(item['name'] as String),
              subtitle: Text('${item['qty']}x @ Rp ${item['price']}'),
              trailing: Text('Rp ${(item['qty'] as int) * (item['price'] as int)}'),
            ),
          ),
        ],
      ),
    );
  }
}
