import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bill_session.dart';
import '../providers/advanced_features_provider.dart';
import '../widgets/adaptive_container.dart';

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
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Notifikasi berhasil dikirim: ${result.notification!.title}')),
            ],
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(result.errorMessage ?? 'Gagal mengirim notifikasi.')),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
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
    final perPerson = (_grandTotal / _participants.length).round();

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
              ..._participants.map(
                (p) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    leading: const CircleAvatar(
                      radius: 16,
                      child: Icon(Icons.person_outline, size: 18),
                    ),
                    title: Text(p, style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: Semantics(
                      label: p.contains('Host') ? 'Status pembayaran lunas' : 'Status pembayaran menunggu transfer',
                      child: Chip(
                        label: Text(p.contains('Host') ? 'PAID' : 'PENDING'),
                        backgroundColor: p.contains('Host') ? Colors.green.shade100 : Colors.orange.shade100,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Item Pesanan', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._items.map(
                (item) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.restaurant_menu),
                    title: Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text('${item['qty']}x @ Rp ${item['price']}'),
                    trailing: Text(
                      'Rp ${(item['qty'] as int) * (item['price'] as int)}',
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
