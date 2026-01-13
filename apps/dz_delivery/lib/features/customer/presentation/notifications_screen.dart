import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await NotificationService.getNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllAsRead() async {
    await NotificationService.markAllAsRead();
    _loadNotifications();
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'order_status': return Icons.shopping_bag;
      case 'new_order': return Icons.notifications_active;
      case 'promotion': return Icons.local_offer;
      case 'bonus': return Icons.card_giftcard;
      case 'tier_change': return Icons.emoji_events;
      default: return Icons.notifications;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'order_status': return Colors.blue;
      case 'new_order': return Colors.green;
      case 'promotion': return Colors.orange;
      case 'bonus': return Colors.purple;
      case 'tier_change': return Colors.amber;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.any((n) => n['is_read'] == false))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Tout lire'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Aucune notification', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      final isRead = notif['is_read'] == true;
                      final type = notif['notification_type'] as String? ?? 'system';
                      final sentAt = DateTime.tryParse(notif['sent_at'] ?? '');
                      
                      return Container(
                        color: isRead ? null : AppTheme.primaryColor.withValues(alpha: 0.05),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getColor(type).withValues(alpha: 0.1),
                            child: Icon(_getIcon(type), color: _getColor(type)),
                          ),
                          title: Text(
                            notif['title'] ?? '',
                            style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(notif['body'] ?? ''),
                              if (sentAt != null)
                                Text(
                                  _formatTime(sentAt),
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                            ],
                          ),
                          onTap: () async {
                            if (!isRead) {
                              await NotificationService.markAsRead(notif['id']);
                              _loadNotifications();
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jour(s)';
    return '${date.day}/${date.month}/${date.year}';
  }
}
