import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bill_session.dart';
import '../providers/advanced_features_provider.dart';
import '../providers/bill_session_provider.dart';
import 'create_session_screen.dart';
import 'session_detail_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref, BillSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Sesi?'),
        content: Text('Hapus sesi "${session.title}" dari penyimpanan lokal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const Key('confirm-delete-button'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref.read(billSessionsProvider.notifier).deleteSession(session.id);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sesi "${session.title}" berhasil dihapus.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(billSessionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Sesi Tagihan')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-session-fab'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const CreateSessionScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Buat Sesi Baru'),
      ),
      body: sessions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(onRetry: () => ref.read(billSessionsProvider.notifier).retry()),
        data: (items) => items.isEmpty
            ? const Center(child: Text('Belum ada sesi tagihan.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final session = items[index];
                  return Card(
                    child: ListTile(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SessionDetailScreen(session: session),
                        ),
                      ),
                      leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
                      title: Text(session.title),
                      subtitle: Text('Host: ${session.hostName} • ${session.participantCount} orang'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Rp ${session.grandTotalAmount}'),
                          IconButton(
                            key: Key('notify-session-${session.id}'),
                            icon: const Icon(Icons.notifications_active_outlined, size: 20, color: Colors.teal),
                            tooltip: 'Kirim Pengingat',
                            onPressed: () async {
                              final res = await ref.read(notificationServiceProvider).sendBillReminder(
                                    sessionTitle: session.title,
                                    totalAmount: session.grandTotalAmount,
                                    participantCount: session.participantCount,
                                  );
                              if (context.mounted) {
                                if (res.isSuccess) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Notifikasi pengingat terkirim untuk "${session.title}".')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(res.errorMessage ?? 'Gagal mengirim notifikasi.'),
                                      backgroundColor: Theme.of(context).colorScheme.error,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          IconButton(
                            key: Key('edit-session-${session.id}'),
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            tooltip: 'Ubah Sesi',
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => CreateSessionScreen(sessionToEdit: session),
                              ),
                            ),
                          ),
                          IconButton(
                            key: Key('delete-session-${session.id}'),
                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                            tooltip: 'Hapus Sesi',
                            onPressed: () => _confirmAndDelete(context, ref, session),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Sesi tagihan gagal dimuat.'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
