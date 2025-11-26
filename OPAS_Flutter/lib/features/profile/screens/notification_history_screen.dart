import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_service.dart';
import '../models/notification_history_model.dart';
import '../services/notification_history_service.dart';
import '../helpers/notification_builder.dart';
import '../widgets/notification_read_state_widget.dart';

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
      // First, check if there's a pending rejection or approval from the server
      await _syncPendingRejections();
      await _syncPendingApprovals();
      
      // Get all notifications first
      List<NotificationHistory> allNotifications =
          await NotificationHistoryService.getAllNotifications();
      
      // Filter based on selected type
      List<NotificationHistory> notifications;
      if (_filterType == 'ALL') {
        notifications = allNotifications;
      } else {
        notifications = allNotifications
            .where((n) => n.type == _filterType)
            .toList();
      }

      debugPrint('📋 Loaded ${notifications.length} notifications (filtered by $_filterType)');
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
  /// This acts as a fallback when push notifications weren't received
  Future<void> _syncPendingRejections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access') ?? '';
      
      if (accessToken.isEmpty) {
        debugPrint('⚠️ No access token available for sync');
        return;
      }
      
      final response = await ApiService.getUserStatus(accessToken: accessToken);
      
      if (response == null) {
        debugPrint('⚠️ No response from getUserStatus');
        return;
      }
      
      final rejectionReason = response['rejection_reason'];
      final status = response['application_status'];
      
      debugPrint('🔄 Sync check - Status: $status, rejection_reason type: ${rejectionReason.runtimeType}, value: "$rejectionReason"');
      
      // Check if there's a rejection reason (even if status is PENDING, user might have resubmitted)
      if (rejectionReason != null) {
        final reasonStr = rejectionReason.toString().trim();
        
        if (reasonStr.isNotEmpty && reasonStr != 'null') {
          debugPrint('🔄 Found rejection reason from server: "$reasonStr"');
          
          // Check if we already have this rejection in history
          final existing = await NotificationHistoryService.getAllNotifications();
          final hasRejection = existing.any((n) => 
            n.type == 'REGISTRATION_REJECTED' && 
            n.rejectionReason != null &&
            n.rejectionReason == reasonStr
          );
          
          if (!hasRejection) {
            debugPrint('➕ Adding rejection to history (fallback sync)');
            final notification = NotificationHistory(
              id: 'REJECTION_SYNC_${DateTime.now().millisecondsSinceEpoch}',
              type: 'REGISTRATION_REJECTED',
              title: 'Registration Rejected ❌',
              body: reasonStr,
              rejectionReason: reasonStr,
              receivedAt: DateTime.now(),
              isRead: false,
              data: {
                'action': 'REGISTRATION_REJECTED',
                'rejection_reason': reasonStr,
              },
            );
            await NotificationHistoryService.saveNotification(notification);
            debugPrint('✅ Rejection notification added via fallback sync');
          } else {
            debugPrint('ℹ️ Rejection already in history');
          }
        } else {
          debugPrint('⚠️ Rejection reason is empty or null: "$reasonStr"');
        }
      } else {
        debugPrint('ℹ️ No rejection reason in response');
      }
    } catch (e, stackTrace) {
      debugPrint('⚠️ Error syncing rejections: $e');
      debugPrint('Stack trace: $stackTrace');
      // Don't throw - this is a background sync
    }
  }

  Future<void> _syncPendingApprovals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access') ?? '';
      
      if (accessToken.isEmpty) {
        debugPrint('⚠️ No access token available for approval sync');
        return;
      }
      
      final response = await ApiService.getUserStatus(accessToken: accessToken);
      
      if (response == null) {
        debugPrint('⚠️ No response from getUserStatus for approval sync');
        return;
      }
      
      final sellerStatus = response['seller_status'];
      final applicationStatus = response['application_status'];
      
      debugPrint('🔄 Approval sync check - seller_status: $sellerStatus, application_status: $applicationStatus');
      
      // Check if the seller status is APPROVED
      if (sellerStatus == 'APPROVED' && applicationStatus == 'APPROVED') {
        debugPrint('🔄 Found APPROVED status from server');
        
        // Check if we already have this approval in history
        final existing = await NotificationHistoryService.getAllNotifications();
        final hasApproval = existing.any((n) => 
          n.type == 'REGISTRATION_APPROVED'
        );
        
        if (!hasApproval) {
          debugPrint('➕ Adding approval to history (fallback sync)');
          final notification = NotificationHistory(
            id: 'APPROVAL_SYNC_${DateTime.now().millisecondsSinceEpoch}',
            type: 'REGISTRATION_APPROVED',
            title: 'Registration Approved ✅',
            body: 'Congratulations! Your seller registration has been approved. You can now access your seller dashboard.',
            receivedAt: DateTime.now(),
            isRead: false,
            data: {
              'action': 'REGISTRATION_APPROVED',
            },
          );
          await NotificationHistoryService.saveNotification(notification);
          debugPrint('✅ Approval notification added via fallback sync');
        } else {
          debugPrint('ℹ️ Approval already in history');
        }
      } else {
        debugPrint('ℹ️ Not APPROVED status: seller_status=$sellerStatus, application_status=$applicationStatus');
      }
    } catch (e, stackTrace) {
      debugPrint('⚠️ Error syncing approvals: $e');
      debugPrint('Stack trace: $stackTrace');
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
                _buildFilterChip('REGISTRATION_APPROVED', 'Approved'),
                const SizedBox(width: 8),
                _buildFilterChip('REGISTRATION_REJECTED', 'Rejected'),
                const SizedBox(width: 8),
                _buildFilterChip('INFO_REQUESTED', 'Info Needed'),
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
    return NotificationReadStateBackground(
      isRead: notification.isRead,
      unreadColor: NotificationBuilder.getCardBackgroundColor(notification.type, false),
      readColor: Colors.white,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          leading: NotificationBuilder.buildIcon(notification.type, isRead: notification.isRead),
          title: NotificationText(
            notification.title,
            baseStyle: NotificationBuilder.getTitleStyle(context, notification.isRead),
            isRead: notification.isRead,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              // Main body
              NotificationText(
                notification.body,
                baseStyle: NotificationBuilder.getBodyStyle(context, notification.isRead),
                isRead: notification.isRead,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // Notification type badge
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: NotificationBuilder.buildTypeBadge(
                  notification.type,
                  isRead: notification.isRead,
                ),
              ),
              // Rejection reason if available
              if (notification.rejectionReason != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: NotificationBuilder.buildInfoBoxDecoration('rejection'),
                    color: NotificationBuilder.getInfoBoxBackgroundColor('rejection'),
                    child: Text(
                      'Reason: ${notification.rejectionReason}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: NotificationBuilder.getInfoBoxTextColor('rejection'),
                          ),
                    ),
                  ),
                ),
              // Approval notes if available
              if (notification.approvalNotes != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: NotificationBuilder.buildInfoBoxDecoration('approval'),
                    color: NotificationBuilder.getInfoBoxBackgroundColor('approval'),
                    child: Text(
                      'Approval Notes: ${notification.approvalNotes}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: NotificationBuilder.getInfoBoxTextColor('approval'),
                          ),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              // Time
              NotificationText(
                notification.getDetailedDateTime(),
                baseStyle: NotificationBuilder.getTimestampStyle(context),
                isRead: notification.isRead,
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Unread indicator dot
              NotificationReadStateIndicator(
                isRead: notification.isRead,
                padding: const EdgeInsets.only(right: 8),
                color: NotificationBuilder.getStyle(notification.type).color,
              ),
              // Actions menu
              PopupMenuButton(
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
      ),
    );
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
                  NotificationBuilder.buildIcon(notification.type),
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
                          style: NotificationBuilder.getTimestampStyle(context),
                        ),
                        const SizedBox(height: 8),
                        NotificationBuilder.buildTypeBadge(notification.type, isRead: notification.isRead),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Main body
              Text(
                'Details',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border.all(color: Colors.grey[300]!),
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
                    color: NotificationBuilder.getInfoBoxBackgroundColor('rejection'),
                    border: Border.all(color: NotificationBuilder.getStyle(notification.type).color),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    notification.rejectionReason!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: NotificationBuilder.getInfoBoxTextColor('rejection'),
                        ),
                  ),
                ),
              ],
              // Approval notes
              if (notification.approvalNotes != null &&
                  notification.approvalNotes!.isNotEmpty) ...[
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
                    color: NotificationBuilder.getInfoBoxBackgroundColor('approval'),
                    border: Border.all(color: NotificationBuilder.getStyle(notification.type).color),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    notification.approvalNotes!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: NotificationBuilder.getInfoBoxTextColor('approval'),
                        ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Read status indicator
              if (!notification.isRead)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This is an unread notification',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.blue[700],
                              ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You have already read this notification',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
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
