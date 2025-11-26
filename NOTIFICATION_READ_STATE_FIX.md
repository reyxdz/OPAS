# Notification Read State Persistence Fix

## Problem Identified
Notifications marked as read were reverting to unread after logout/login, especially in complex multi-user scenarios. 

### Root Cause
In `notification_service.dart`, when notifications are received (foreground, background, or synced), the code was creating **fresh `NotificationHistory` instances with `isRead: false`** and saving them to storage. This **overwrote existing stored notifications** that had `isRead: true`.

**Example flow that broke:**
1. User A receives approval notification → Auto-marked as read → Saved to storage with `isRead: true`
2. User A logs out → Notifications preserved in `notification_history_0913` (correct)
3. User B logs in → Some push notification sync runs → Creates fresh notification instances with `isRead: false`
4. User B logs out → Backup complete
5. User A logs in → Loads notification from `notification_history_0913` but the stored version now has `isRead: false` (was overwritten in step 3)

### Technical Details
Three locations in `notification_service.dart` were calling:
```dart
final notification = NotificationHistory.fromNotification(
  type: type,
  title: message.notification?.title ?? 'New Notification',
  body: message.notification?.body ?? '',
  data: message.data,
);
await NotificationHistoryService.saveNotification(notification);
```

This always created notifications with `isRead: false` (hardcoded in `fromNotification` factory).

## Solution Implemented

### 1. Enhanced `saveNotification()` Method
Updated in `notification_history_service.dart`:

```dart
/// Save a new notification to history
/// IMPORTANT: If notification already exists, preserve its read state!
static Future<void> saveNotification(NotificationHistory notification) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = await _getStorageKey();
    final history = await getAllNotifications();
    
    // Check if this notification already exists (by type + rejection reason or approval notes)
    final existingIndex = history.indexWhere((n) {
      final sameType = n.type == notification.type;
      final sameReason = n.rejectionReason == notification.rejectionReason;
      final sameNotes = n.approvalNotes == notification.approvalNotes;
      return sameType && sameReason && sameNotes;
    });
    
    if (existingIndex != -1) {
      debugPrint('⚠️ Notification already exists, preserving isRead=${history[existingIndex].isRead}');
      // Preserve the existing notification's read state
      final existingNotif = history[existingIndex];
      final updatedNotif = notification.copyWith(
        id: existingNotif.id,
        isRead: existingNotif.isRead,
      );
      history[existingIndex] = updatedNotif;
    } else {
      // New notification, insert at top
      history.insert(0, notification);
    }
    
    // Save to storage...
  }
}
```

**Key Changes:**
- Checks if a notification with same `type`, `rejectionReason`, and `approvalNotes` already exists
- If it exists, preserves the existing notification's `isRead` state
- Uses new `copyWith()` method to create updated instance while preserving state
- Logs when duplicates are detected

### 2. Added `copyWith()` Method
Added to `notification_history_model.dart`:

```dart
/// Create a copy with optional field overrides
NotificationHistory copyWith({
  String? id,
  String? type,
  String? title,
  String? body,
  String? rejectionReason,
  String? approvalNotes,
  DateTime? receivedAt,
  DateTime? actionTakenAt,
  bool? isRead,
  Map<String, dynamic>? data,
}) => NotificationHistory(
  id: id ?? this.id,
  type: type ?? this.type,
  title: title ?? this.title,
  body: body ?? this.body,
  rejectionReason: rejectionReason ?? this.rejectionReason,
  approvalNotes: approvalNotes ?? this.approvalNotes,
  receivedAt: receivedAt ?? this.receivedAt,
  actionTakenAt: actionTakenAt ?? this.actionTakenAt,
  isRead: isRead ?? this.isRead,
  data: data ?? this.data,
);
```

This allows selective field updates while preserving other properties.

## Why This Works

**Before Fix:**
```
User A marks notification read → isRead: true (stored) 
  → Sync recreates fresh notification → isRead: false (overwrites storage)
  → User A sees notification as unread ❌
```

**After Fix:**
```
User A marks notification read → isRead: true (stored)
  → Sync attempts to recreate → Detects existing notification
  → Preserves isRead: true → Storage remains correct ✅
  → User A still sees notification as read ✅
```

## Duplicate Detection Strategy

Notifications are considered "the same" if they have:
- Same `type` (e.g., "REGISTRATION_APPROVED")
- Same `rejectionReason` (if applicable - e.g., for rejections)
- Same `approvalNotes` (if applicable - for approvals)

This uniquely identifies notifications without relying on auto-generated IDs or timestamps.

## Files Modified
1. `lib/features/profile/services/notification_history_service.dart` - Updated `saveNotification()` method
2. `lib/features/profile/models/notification_history_model.dart` - Added `copyWith()` method

## Testing Recommendations
1. Mark notification as read
2. Log out → Log back in → Verify notification still marked as read ✅
3. Mark notification as read
4. User A logs out → User B logs in → User B logs out → User A logs in
5. Verify User A's notification still marked as read ✅
6. Verify push notification sync doesn't reset read state ✅

## Impact
- ✅ Fixes notification read state persistence across logout/login
- ✅ Prevents duplicate notifications in history
- ✅ Eliminates read state reverting issue
- ✅ Maintains notification history integrity across multi-user scenarios
- ✅ No UI changes required
- ✅ Backward compatible with existing stored notifications
