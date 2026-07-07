import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_glass_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading_skeleton.dart';
import '../../domain/models/notification_model.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Belum Dibaca', 'Pesanan', 'Tawaran', 'Chat', 'Wallet'];

  @override
  Widget build(BuildContext context) {
    final notificationsState = ref.watch(notificationsProvider);
    final actionController = ref.watch(notificationActionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Tandai semua dibaca',
            onPressed: actionController.isLoading
                ? null
                : () {
                    ref.read(notificationActionControllerProvider.notifier).markAllAsRead();
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Text(
              'Pantau update pesanan, tawaran, chat, dan wallet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
          ),
          
          // Filters
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilter = filter);
                      }
                    },
                    selectedColor: AppColors.accent.withValues(alpha: 0.3),
                    checkmarkColor: AppColors.accent,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.accent : Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Notification List
          Expanded(
            child: notificationsState.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: 5,
                itemBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: AppLoadingSkeleton(height: 80, width: double.infinity),
                ),
              ),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (notifications) {
                final filteredList = _filterNotifications(notifications);

                if (filteredList.isEmpty) {
                  return const AppEmptyState(
                    title: 'Belum ada notifikasi',
                    message: 'Saat ini tidak ada notifikasi yang sesuai dengan filter Anda.',
                    icon: Icons.notifications_off_outlined,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final notif = filteredList[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _NotificationCard(
                        notification: notif,
                        onTap: () {
                          if (!notif.isRead) {
                            ref.read(notificationActionControllerProvider.notifier).markAsRead(notif.id);
                          }
                          _handleNavigation(context, notif);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<NotificationModel> _filterNotifications(List<NotificationModel> notifications) {
    if (_selectedFilter == 'Semua') return notifications;
    if (_selectedFilter == 'Belum Dibaca') return notifications.where((n) => !n.isRead).toList();
    
    return notifications.where((n) {
      if (_selectedFilter == 'Pesanan') return n.type.startsWith('order_') || n.type == 'payment_paid';
      if (_selectedFilter == 'Tawaran') return n.type.startsWith('offer_');
      if (_selectedFilter == 'Chat') return n.type.startsWith('chat_');
      if (_selectedFilter == 'Wallet') return n.type.startsWith('withdrawal_');
      return false;
    }).toList();
  }

  void _handleNavigation(BuildContext context, NotificationModel notif) {
    if (notif.relatedType == 'order' && notif.relatedId != null) {
      // Typically goes to BuyerOrdersScreen or SellerOrdersScreen, let's just go to order tracking if buyer, or orders list for now
      // To simplify, if it's order_shipped we go to tracking.
      if (notif.type == 'order_shipped') {
        context.push('/orders/${notif.relatedId}/tracking');
      } else {
        context.push('/buyer-orders');
      }
    } else if (notif.relatedType == 'offer' && notif.relatedId != null) {
      if (notif.type == 'offer_received') {
        context.push('/seller/offers');
      } else {
        context.push('/offers');
      }
    } else if (notif.relatedType == 'withdrawal') {
      context.push('/seller/wallet');
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final iconData = _getIconData(notification.type);
    final iconColor = _getIconColor(notification.type);

    return AppGlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: iconColor),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              timeago.format(notification.createdAt, locale: 'id'),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: notification.isRead ? Colors.white70 : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String type) {
    if (type.startsWith('order_')) return Icons.local_shipping;
    if (type == 'payment_paid') return Icons.account_balance_wallet;
    if (type.startsWith('offer_')) return Icons.local_offer;
    if (type.startsWith('chat_')) return Icons.chat;
    if (type.startsWith('withdrawal_')) return Icons.money;
    return Icons.notifications;
  }

  Color _getIconColor(String type) {
    if (type.startsWith('order_')) return Colors.orange;
    if (type == 'payment_paid') return Colors.green;
    if (type.startsWith('offer_')) return Colors.blue;
    if (type.startsWith('chat_')) return Colors.purple;
    if (type.startsWith('withdrawal_')) return AppColors.accent;
    return Colors.white;
  }
}
