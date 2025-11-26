import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_service.dart';
import '../models/notification_history_model.dart';
import '../services/notification_history_service.dart';

/// Notification History Screen
/// Displays all past notifications with rejection reasons, approvals, and info requests
class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  List<NotificationHistory> _notifications = [];
  bool _isLoading = true;
  String _filterType = 'ALL'; // ALL, APPLICATION

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      // First, check if there's a pending rejection from the server
      await _syncPendingRejections();
      
      List<NotificationHistory> notifications;
      if (_filterType == 'ALL') {
        notifications =
            await NotificationHistoryService.getAllNotifications();
      } else {
        notifications =
            await NotificationHistoryService.getRejectionNotifications();
      }

      debugPrint('📋 Loaded ${notifications.length} notifications');
      for (var n in notifications) {
        debugPrint('  - ${n.type}: ${n.title}');
      }

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading notifications: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notifications: $e')),
        );
      }
    }
  }

  /// Check server for pending rejections and sync to local history
  Future<void> _syncPendingRejections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access') ?? '';
      
      if (accessToken.isEmpty) {
        debugPrint('⚠️ No access token available for sync');
        return;
      }
      
      final response = await ApiService.getUserStatus(accessToken: accessToken);
      
      if (response != null && response['rejection_reason'] != null) {
        final rejectionReason = response['rejection_reason'];
        final status = response['application_status'];
        
        if (status == 'REJECTED' && rejectionReason.isNotEmpty) {
          debugPrint('🔄 Found pending rejection from server: $rejectionReason');
          
          // Check if we already have this rejection in history
          final existing = await NotificationHistoryService.getAllNotifications();
          final hasRejection = existing.any((n) => 
            n.type == 'REGISTRATION_REJECTED' && 
            n.rejectionReason == rejectionReason
          );
          
          if (!hasRejection) {
            debugPrint('➕ Adding rejection to history');
            final notification = NotificationHistory(
              id: 'REJECTION_${DateTime.now().millisecondsSinceEpoch}',
              type: 'REGISTRATION_REJECTED',
              title: 'Registration Rejected ❌',
              body: rejectionReason,
              rejectionReason: rejectionReason,
              receivedAt: DateTime.now(),
              isRead: false,
              data: {
                'action': 'REGISTRATION_REJECTED',
                'rejection_reason': rejectionReason,
              },
            );
            await NotificationHistoryService.saveNotification(notification);
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error syncing rejections: $e');
      // Don't throw - this is a background sync
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    await NotificationHistoryService.markAsRead(notificationId);
    _loadNotifications();
  }

  Future<void> _deleteNotification(String notificationId) async {
    await NotificationHistoryService.deleteNotification(notificationId);
    _loadNotifications();
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications?'),
        content: const Text(
            'This will delete all notification history. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      await NotificationHistoryService.clearAll();
      _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications cleared')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notification History'),
        centerTitle: true,
        actions: [
          if (_notifications.isNotEmpty)
            PopupMenuButton(
              onSelected: (value) {
                if (value == 'clear') {
                  _clearAll();
                } else if (value == 'mark_all_read') {
                  NotificationHistoryService.markAllAsRead()
                      .then((_) => _loadNotifications());
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'mark_all_read',
                  child: Text('Mark all as read'),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Text('Clear all', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildFilterChip('ALL', 'All'),
                const SizedBox(width: 8),
                _buildFilterChip('APPLICATION', 'Application'),
              ],
            ),
          ),
          // Notifications list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF00B464),
                    ),
                  )
                : _notifications.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: _notifications.length,
                        padding: const EdgeInsets.all(8),
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          return _buildNotificationCard(notification);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filterType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _filterType = value);
        _loadNotifications();
      },
      backgroundColor: Colors.grey[100],
      selectedColor: const Color(0xFF00B464),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[800],
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Your notification history is empty',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationHistory notification) {
    final color = Color(notification.getColorValue());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getIcon(notification.getIcon()),
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: notification.isRead ? Colors.grey[600] : Colors.black,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // Main body
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            // Rejection reason if available
            if (notification.rejectionReason != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Reason: ${notification.rejectionReason}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade700,
                        ),
                  ),
                ),
              ),
            const SizedBox(height: 4),
            // Time
            Text(
              notification.getDetailedDateTime(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          onSelected: (value) {
            if (value == 'read') {
              _markAsRead(notification.id);
            } else if (value == 'delete') {
              _deleteNotification(notification.id);
            }
          },
          itemBuilder: (context) => [
            if (!notification.isRead)
              const PopupMenuItem(
                value: 'read',
                child: Text('Mark as read'),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        isThreeLine: true,
        onTap: () {
          if (!notification.isRead) {
            _markAsRead(notification.id);
          }
          _showNotificationDetail(context, notification);
        },
      ),
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'check_circle':
        return Icons.check_circle;
      case 'cancel':
        return Icons.cancel;
      case 'help':
        return Icons.help;
      default:
        return Icons.notifications;
    }
  }

  void _showNotificationDetail(
      BuildContext context, NotificationHistory notification) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(notification.getColorValue())
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIcon(notification.getIcon()),
                      color: Color(notification.getColorValue()),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.getDetailedDateTime(),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Body
              Text(
                'Message',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  notification.body,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              // Rejection reason
              if (notification.rejectionReason != null &&
                  notification.rejectionReason!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Rejection Reason',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    notification.rejectionReason!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.red.shade700,
                        ),
                  ),
                ),
              ],
              // Approval notes
              if (notification.approvalNotes != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Approval Notes',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    notification.approvalNotes!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.green.shade700,
                        ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Action buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B464),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
