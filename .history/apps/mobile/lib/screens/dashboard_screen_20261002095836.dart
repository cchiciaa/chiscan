import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/bill_session_provider.dart';
import 'create_session_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(billSessionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Sesi Tagihan')),
      floatingActionButton: FloatingActionButton.extended(
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
                      leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
                      title: Text(session.title),
                      subtitle: Text('Host: ${session.hostName} • ${session.participantCount} orang'),
                      trailing: Text('Rp ${session.grandTotalAmount}'),
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
