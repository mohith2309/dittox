import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/notification_item.dart';
import '../../providers/app_notifications.dart';
import '../../utils/color_pallets.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/pill_appbar_title.dart';

class NotificationsScreen extends StatelessWidget {
  static const routeName = "/notifications";

  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 10,
        title: const PillAppBarTitle(
          title: 'Notifications',
          icon: Icons.notifications_active_rounded,
        ),
        backgroundColor: ColorPallets.deepBlue,
        actions: [
          Consumer<AppNotifications>(
            builder: (context, notifs, _) {
              if (notifs.all.isEmpty) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded),
                onSelected: (value) {
                  switch (value) {
                    case 'mark_all_read':
                      notifs.markAllAsRead();
                      break;
                    case 'clear_all':
                      notifs.dismissAll();
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'mark_all_read',
                    child: Text('Mark all as read'),
                  ),
                  PopupMenuItem(
                    value: 'clear_all',
                    child: Text('Clear all'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ColorPallets.deepBlue.withValues(alpha: 0.08),
              ColorPallets.surface,
              ColorPallets.surface,
            ],
          ),
        ),
        child: Consumer<AppNotifications>(
          builder: (context, notifs, _) {
            final notifications = notifs.all;
            if (notifications.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              itemCount: notifications.length,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
              itemBuilder: (context, index) {
                final each = notifications[index];
                return _NotificationCard(
                  notification: each,
                  onTap: () => notifs.markAsRead(each.id),
                  onDelete: () => notifs.dismiss(each.id),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorPallets.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "You're all caught up!",
            style: TextStyle(color: ColorPallets.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = notification.status != 'read';
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: isUnread
                  ? ColorPallets.lightBlue.withValues(alpha: 0.14)
                  : Colors.white.withValues(alpha: 0.75),
              child: InkWell(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isUnread
                          ? ColorPallets.deepBlue.withValues(alpha: 0.35)
                          : ColorPallets.cardBorder.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _typeColor(notification.type).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _typeIcon(notification.type),
                          color: _typeColor(notification.type),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: ColorPallets.textPrimary,
                                      fontWeight: isUnread
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (isUnread)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: ColorPallets.deepBlue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              notification.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: ColorPallets.textSecondary,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              DateFormatter.formatRelative(notification.timestamp),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case AppNotification.typeOrderUpdate:
        return Colors.blue;
      case AppNotification.typeStoreAlert:
        return Colors.orange;
      case AppNotification.typeOffer:
        return Colors.pink;
      case AppNotification.typeError:
        return Colors.red;
      case AppNotification.typeSuccess:
        return ColorPallets.deepBlue;
      case AppNotification.typeWarning:
        return Colors.amber.shade800;
      default:
        return Colors.teal;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case AppNotification.typeOrderUpdate:
        return Icons.receipt_long_rounded;
      case AppNotification.typeStoreAlert:
        return Icons.store_mall_directory_rounded;
      case AppNotification.typeOffer:
        return Icons.local_offer_rounded;
      case AppNotification.typeError:
        return Icons.error_rounded;
      case AppNotification.typeSuccess:
        return Icons.check_circle_rounded;
      case AppNotification.typeWarning:
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_rounded;
    }
  }
}
