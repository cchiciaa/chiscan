import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bill_session.dart';
import '../providers/advanced_features_provider.dart';
import '../providers/bill_session_provider.dart';
import '../widgets/adaptive_container.dart';
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
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              const SizedBox(width: 12),
              Text('Menghapus sesi "${session.title}"...'),
            ],
          ),
          duration: const Duration(milliseconds: 700),
          behavior: SnackBarBehavior.floating,
        ),
      );

      final success = await ref.read(billSessionsProvider.notifier).deleteSession(session.id);
      if (success && context.mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Sesi "${session.title}" berhasil dihapus.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(billSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sesi Tagihan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang data',
            onPressed: () => ref.read(billSessionsProvider.notifier).retry(),
          ),
        ],
      ),
      floatingActionButton: Semantics(
        button: true,
        label: 'Buat sesi tagihan baru',
        child: FloatingActionButton.extended(
          key: const Key('add-session-fab'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const CreateSessionScreen()),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Buat Sesi Baru'),
        ),
      ),
      body: SafeArea(
        child: AdaptiveContainer(
          maxWidth: 800,
          child: sessions.when(
            loading: () => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat sesi tagihan dari backend...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            error: (error, _) => _ErrorState(onRetry: () => ref.read(billSessionsProvider.notifier).retry()),
            data: (items) => items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'Belum ada sesi tagihan.',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tekan tombol "Buat Sesi Baru" di bawah untuk memulai split bill bersama teman.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => ref.read(billSessionsProvider.notifier).retry(),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final session = items[index];
                        return Card(
                          elevation: 1,
                          clipBehavior: Clip.antiAlias,
                          child: Semantics(
                            label: 'Kartu sesi ${session.title}, dipimpin host ${session.hostName}, total Rp ${session.grandTotalAmount}',
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => SessionDetailScreen(session: session),
                                ),
                              ),
                              leading: const CircleAvatar(
                                child: Icon(Icons.receipt_long),
                              ),
                              title: Text(
                                session.title,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Host: ${session.hostName} • ${session.participantCount} orang',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      'Rp ${session.grandTotalAmount}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
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
                                            SnackBar(
                                              content: Text('Notifikasi pengingat terkirim untuk "${session.title}".'),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(res.errorMessage ?? 'Gagal mengirim notifikasi.'),
                                              backgroundColor: Theme.of(context).colorScheme.error,
                                              behavior: SnackBarBehavior.floating,
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
                          ),
                        );
                      },
                    ),
                  ),
          ),
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            const Text(
              'Sesi tagihan gagal dimuat.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Terjadi kendala saat menghubungkan ke backend atau memuat data lokal.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
