import 'package:flutter/material.dart';
import '../services/seller_service.dart';
import '../../profile/helpers/notification_builder.dart';
import '../../profile/widgets/notification_read_state_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<Map<String, dynamic>>> _notificationsFuture;
  List<Map<String, dynamic>> _allNotifications = [];
  List<Map<String, dynamic>> _filteredNotifications = [];
  String _filterType = 'All'; // All, Orders, Payments, System

  @override
  void initState() {
    super.initState();
    _notificationsFuture = SellerService.getNotifications();
  }

  Future<void> _refreshNotifications() async {
    setState(() {
    });
    try {
      final notifications = await SellerService.getNotifications();
      setState(() {
        _allNotifications = notifications;
        _applyFilter();
      });
    } catch (e) {
      setState(() {
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing notifications: $e')),
        );
      }
    }
  }

  void _applyFilter() {
    if (_filterType == 'All') {
      _filteredNotifications = _allNotifications;
    } else {
      _filteredNotifications = _allNotifications
          .where((n) => n['type'] == _filterType)
          .toList();
    }
  }

  void _onFilterChanged(String newFilter) {
    setState(() {
      _filterType = newFilter;
      _applyFilter();
    });
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      await SellerService.markNotificationAsRead(notificationId);
      await _refreshNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error marking notification as read: $e')),
        );
      }
    }
  }

  Color _getNotificationColor(String type) {
    return NotificationBuilder.getStyle(type).color;
  }

  IconData _getNotificationIcon(String type) {
    return NotificationBuilder.getStyle(type).icon;
  }

  String _formatTime(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return dateTime.toString().split(' ')[0];
      }
    } catch (e) {
      return 'unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshNotifications,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _allNotifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading notifications',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshNotifications,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (_allNotifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'re all caught up!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshNotifications,
            child: Column(
              children: [
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: ['All', 'Orders', 'Payments', 'System']
                        .map((type) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(type),
                            selected: _filterType == type,
                            onSelected: (selected) {
                              if (selected) _onFilterChanged(type);
                            },
                          ),
                        ))
                        .toList(),
                  ),
                ),
                // Notifications list
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredNotifications.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      final notification = _filteredNotifications[index];
                      final type = notification['type'] ?? 'System';
                      final title = notification['title'] ?? 'Notification';
                      final message = notification['message'] ?? '';
                      final isRead = notification['is_read'] ?? true;
                      final createdAt = notification['created_at'] ?? DateTime.now().toString();
                      final notificationId = notification['id'] ?? 0;

                  return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isRead ? Colors.white : NotificationBuilder.getCardBackgroundColor(type, false),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: NotificationBuilder.getStyle(type).color.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              NotificationBuilder.getStyle(type).icon,
                              color: NotificationBuilder.getStyle(type).color,
                            ),
                          ),
                          title: NotificationText(
                            title,
                            baseStyle: NotificationBuilder.getTitleStyle(context, isRead),
                            isRead: isRead,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              NotificationText(
                                message,
                                baseStyle: NotificationBuilder.getBodyStyle(context, isRead),
                                isRead: isRead,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(createdAt),
                                style: NotificationBuilder.getTimestampStyle(context),
                              ),
                            ],
                          ),
                          trailing: NotificationReadStateIndicator(
                            isRead: isRead,
                            padding: const EdgeInsets.all(0),
                            color: NotificationBuilder.getStyle(type).color,
                          ),
                          onTap: () {
                            if (!isRead) {
                              _markAsRead(notificationId);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
