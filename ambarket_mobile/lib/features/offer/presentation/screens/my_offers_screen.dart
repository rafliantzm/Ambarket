import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/offer_provider.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../domain/models/offer_model.dart';
import 'package:intl/intl.dart';

class MyOffersScreen extends ConsumerWidget {
  const MyOffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tawaran Saya'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Terkirim'),
              Tab(text: 'Diterima'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _SentOffersTab(),
            _ReceivedOffersTab(),
          ],
        ),
      ),
    );
  }
}

class _SentOffersTab extends ConsumerWidget {
  const _SentOffersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(mySentOffersProvider);

    return offersAsync.when(
      data: (offers) {
        if (offers.isEmpty) {
          return const Center(child: Text('Belum ada tawaran terkirim.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: offers.length,
          itemBuilder: (context, index) => _OfferCard(offer: offers[index], isSent: true),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

class _ReceivedOffersTab extends ConsumerWidget {
  const _ReceivedOffersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(myReceivedOffersProvider);

    return offersAsync.when(
      data: (offers) {
        if (offers.isEmpty) {
          return const Center(child: Text('Belum ada tawaran diterima.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: offers.length,
          itemBuilder: (context, index) => _OfferCard(offer: offers[index], isSent: false),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

class _OfferCard extends ConsumerWidget {
  final OfferModel offer;
  final bool isSent;

  const _OfferCard({required this.offer, required this.isSent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final theme = Theme.of(context);

    Color statusColor;
    String statusText;
    switch (offer.status) {
      case 'accepted':
        statusColor = Colors.green;
        statusText = 'Diterima';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Ditolak';
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        statusText = 'Dibatalkan';
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'Menunggu';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    offer.product?.title ?? 'Produk tidak diketahui',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Harga Asli: ${currencyFormat.format(offer.product?.price ?? 0)}', style: const TextStyle(color: Colors.grey)),
            Text('Ditawar: ${currencyFormat.format(offer.offerPrice)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (offer.message != null && offer.message!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('Pesan: "${offer.message}"', style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text('Oleh: ${isSent ? "Anda" : (offer.buyer?.name ?? "User")}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            
            if (offer.status == 'pending') ...[
              const Divider(height: 24),
              if (isSent)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _confirmAction(context, ref, 'Batalkan tawaran?', () => ref.read(offerActionControllerProvider.notifier).cancelOffer(offer.id)),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Batalkan Tawaran'),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => _confirmAction(context, ref, 'Tolak tawaran ini?', () => ref.read(offerActionControllerProvider.notifier).rejectOffer(offer.id)),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Tolak'),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    ElevatedButton(
                      onPressed: () => _confirmAction(context, ref, 'Terima tawaran ini?', () => ref.read(offerActionControllerProvider.notifier).acceptOffer(offer.id)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      child: const Text('Terima'),
                    ),
                  ],
                ),
            ],
            if (offer.status == 'accepted') ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final chat = await ref.read(chatActionControllerProvider.notifier).createOrGetConversationFromOffer(offer.id);
                        if (context.mounted) {
                          context.push('/chats/${chat.id}');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuka chat: $e')));
                        }
                      }
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      foregroundColor: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (isSent) ...[
                    const SizedBox(width: AppSpacing.sm),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.push('/checkout', extra: offer);
                      },
                      icon: const Icon(Icons.shopping_cart_checkout),
                      label: const Text('Buat Pesanan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmAction(BuildContext context, WidgetRef ref, String title, Future<void> Function() action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text(title),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await action();
            },
            child: const Text('Ya'),
          ),
        ],
      ),
    );
  }
}
