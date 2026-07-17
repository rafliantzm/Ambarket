import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/error/error_mapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading_skeleton.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/models/notification_model.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedFilter = 'Semua';
  final List<String> _filters = [
    'Semua',
    'Belum Dibaca',
    'Pesanan',
    'Tawaran',
    'Chat',
    'Wallet',
  ];

  @override
  Widget build(BuildContext context) {
    final notificationsState = ref.watch(notificationsProvider);
    final actionController = ref.watch(notificationActionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifikasi'),
        actions: [
          IconButton(
            icon: Icon(Icons.done_all),
            tooltip: 'Tandai semua dibaca',
            onPressed: actionController.isLoading
                ? null
                : () {
                    ref
                        .read(notificationActionControllerProvider.notifier)
                        .markAllAsRead();
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          // Subtitle
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              'Pantau update pesanan, tawaran, chat, dan wallet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),

          // Filters
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 4,
              ),
              cacheExtent: 300,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    showCheckmark: false,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilter = filter);
                      }
                    },
                    selectedColor: context.colors.primary,
                    backgroundColor: context.colors.backgroundDarker,
                    side: BorderSide(
                      color: isSelected
                          ? context.colors.primary
                          : context.colors.border.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : context.colors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: AppSpacing.sm),

          // Notification List
          Expanded(
            child: Builder(
              builder: (context) {
                if (notificationsState.isLoading &&
                    !notificationsState.hasValue) {
                  return ListView.builder(
                    padding: EdgeInsets.all(AppSpacing.md),
                    cacheExtent: 500,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                    itemCount: 5,
                    itemBuilder: (context, index) => Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.md),
                      child: AppLoadingSkeleton(
                        height: 80,
                        width: double.infinity,
                        borderRadius: 16,
                      ),
                    ),
                  );
                }

                if (notificationsState.hasError) {
                  return Center(
                    child: AppEmptyState(
                      icon: Icons.error_outline,
                      title: 'Terjadi Kesalahan',
                      message: ErrorMapper.getFriendlyMessage(
                        notificationsState.error,
                      ),
                      buttonText: 'Coba Lagi',
                      onButtonPressed: () =>
                          ref.invalidate(notificationsProvider),
                    ),
                  );
                }

                if (notificationsState.hasValue) {
                  final notifications = notificationsState.value!;
                  final filteredList = _filterNotifications(notifications);

                  if (filteredList.isEmpty) {
                    return AppEmptyState(
                      title: 'Belum ada notifikasi',
                      message:
                          'Saat ini tidak ada notifikasi yang sesuai dengan filter Anda.',
                      icon: Icons.notifications_off_outlined,
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    cacheExtent: 800,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final notif = filteredList[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.md),
                        child: _NotificationCard(
                          notification: notif,
                          onTap: () {
                            if (!notif.isRead) {
                              ref
                                  .read(
                                    notificationActionControllerProvider
                                        .notifier,
                                  )
                                  .markAsRead(notif.id);
                            }
                            _handleNavigation(context, notif);
                          },
                        ),
                      );
                    },
                  );
                }

                return SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  List<NotificationModel> _filterNotifications(
    List<NotificationModel> notifications,
  ) {
    if (_selectedFilter == 'Semua') return notifications;
    if (_selectedFilter == 'Belum Dibaca') {
      return notifications.where((n) => !n.isRead).toList();
    }

    return notifications.where((n) {
      if (_selectedFilter == 'Pesanan') {
        return n.relatedType == 'order' ||
            n.relatedType == 'refund' ||
            n.type.startsWith('order_') ||
            n.type.startsWith('refund_') ||
            n.type == 'payment_paid';
      }
      if (_selectedFilter == 'Tawaran') {
        return n.relatedType == 'offer' || n.type.startsWith('offer_');
      }
      if (_selectedFilter == 'Chat') {
        return n.relatedType == 'chat' || n.type.startsWith('chat_');
      }
      if (_selectedFilter == 'Wallet') {
        return n.relatedType == 'withdrawal' ||
            n.type.startsWith('withdrawal_');
      }
      return false;
    }).toList();
  }

  void _handleNavigation(BuildContext context, NotificationModel notif) {
    if (notif.relatedType == 'refund') {
      final profile = ref.read(currentProfileProvider).value;
      if (profile?.role == 'admin') {
        context.push('/admin/refunds');
      } else if (notif.relatedId != null) {
        context.push('/orders/${notif.relatedId}/tracking');
      } else {
        context.push('/buyer-orders');
      }
    } else if (notif.relatedType == 'order') {
      if (notif.type == 'order_received' ||
          notif.type == 'payment_paid' ||
          (notif.type == 'order_created' && notif.title == 'Pesanan Baru')) {
        context.push('/seller/orders');
      } else if (notif.type == 'order_shipped' && notif.relatedId != null) {
        context.push('/orders/${notif.relatedId}/tracking');
      } else {
        context.push('/buyer-orders');
      }
    } else if (notif.relatedType == 'offer') {
      if (notif.type == 'offer_received') {
        context.push('/seller/offers');
      } else {
        context.push('/offers');
      }
    } else if (notif.relatedType == 'withdrawal') {
      final profile = ref.read(currentProfileProvider).value;
      context.push(
        profile?.role == 'admin' ? '/admin/withdrawals' : '/seller/wallet',
      );
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
    final iconColor = _getIconColor(context, notification.type);

    return Container(
      decoration: BoxDecoration(
        color: notification.isRead
            ? context.colors.surface
            : context.colors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: notification.isRead
              ? context.colors.border.withValues(alpha: 0.5)
              : context.colors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: context.colors.textPrimary,
                                  fontWeight: notification.isRead
                                      ? FontWeight.w600
                                      : FontWeight.bold,
                                  height: 1.2,
                                ),
                          ),
                        ),
                        if (!notification.isRead) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 5),
                            decoration: BoxDecoration(
                              color: context.colors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeago.format(notification.createdAt, locale: 'id'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notification.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: notification.isRead
                            ? context.colors.textSecondary
                            : context.colors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String type) {
    if (type.startsWith('refund_')) return Icons.gavel_outlined;
    if (type.startsWith('order_')) return Icons.local_shipping;
    if (type == 'payment_paid') return Icons.account_balance_wallet;
    if (type.startsWith('offer_')) return Icons.local_offer;
    if (type.startsWith('chat_')) return Icons.chat;
    if (type.startsWith('withdrawal_')) return Icons.money;
    return Icons.notifications;
  }

  Color _getIconColor(BuildContext context, String type) {
    if (type.startsWith('refund_')) return Colors.redAccent;
    if (type.startsWith('order_')) return Colors.orange;
    if (type == 'payment_paid') return Colors.green;
    if (type.startsWith('offer_')) return Colors.blue;
    if (type.startsWith('chat_')) return Colors.purple;
    if (type.startsWith('withdrawal_')) return context.colors.accent;
    return context.colors.textMuted;
  }
}
