# Notification System - Clean Architecture Implementation

## Overview

This document outlines the clean architecture and code reusability improvements made to the notification system in OPAS Flutter. The system now distinguishes between read and unread notifications across **all application statuses**, not just "APPLICATION" status.

## Architecture Principles Applied

### 1. **Single Responsibility Principle (SRP)**
Each component has one clear responsibility:
- `NotificationBuilder`: Centralized styling logic for all notification types
- `NotificationReadStateWidget`: Handles read/unread state visualization
- `NotificationText`: Manages text styling consistency
- `NotificationReadStateBackground`: Manages background color based on read state

### 2. **Don't Repeat Yourself (DRY)**
All styling logic is centralized in `NotificationBuilder`, eliminating duplication across screens:
- Seller notifications screen
- Profile notification history screen
- Both now use the same styling rules

### 3. **Configuration as Data**
`NotificationTypeStyle` class and `typeStyles` map decouple styling from logic:
```dart
static final Map<String, NotificationTypeStyle> typeStyles = {
  'REGISTRATION_APPROVED': NotificationTypeStyle(...),
  'REGISTRATION_REJECTED': NotificationTypeStyle(...),
  'INFO_REQUESTED': NotificationTypeStyle(...),
  // ... more types
};
```

Easy to add new notification types without modifying code logic.

### 4. **Composition Over Inheritance**
Used composition to build complex UI:
```dart
NotificationReadStateBackground(
  isRead: notification.isRead,
  child: Card(...)  // Card wrapped with background
)
```

## Components

### File Structure

```
lib/features/profile/
├── helpers/
│   └── notification_builder.dart      (Centralized styling logic)
├── widgets/
│   └── notification_read_state_widget.dart  (Reusable read/unread widgets)
├── screens/
│   └── notification_history_screen.dart     (Updated to use builder)
└── models/
    └── notification_history_model.dart

lib/features/seller_panel/screens/
└── notifications_screen.dart              (Updated to use builder)
```

### Core Components

#### 1. NotificationBuilder (notification_builder.dart)
**Purpose**: Centralized styling configuration and UI building

**Key Methods**:
- `getStyle(String type)` - Get styling for notification type
- `buildIcon(String type)` - Build styled icon
- `buildTypeBadge(String type)` - Build type badge
- `getCardBackgroundColor(String type, bool isRead)` - Background based on read state
- `getTitleStyle()`, `getBodyStyle()`, `getTimestampStyle()` - Text styling
- `buildInfoBoxDecoration()` - Consistent info box styling

**Supported Notification Types**:
- `REGISTRATION_APPROVED` ✅ (Green)
- `REGISTRATION_REJECTED` ❌ (Red)
- `INFO_REQUESTED` ℹ️ (Orange)
- `APPLICATION` 📢 (Blue)
- `PENDING_REVIEW` ⏰ (Amber)
- `UNDER_REVIEW` 🔍 (Indigo)
- `RESUBMISSION_REQUIRED` 🔄 (Purple)
- `APPROVED` ✓ (Teal)
- `REJECTED` ✗ (Deep Orange)

#### 2. NotificationReadStateWidget (notification_read_state_widget.dart)
**Purpose**: Reusable widgets for read/unread state visualization

**Widgets**:
1. **NotificationReadStateIndicator**
   - Shows blue dot for unread notifications
   - Hidden for read notifications
   ```dart
   NotificationReadStateIndicator(
     isRead: notification.isRead,
     color: Colors.blue,
   )
   ```

2. **NotificationReadStateBackground**
   - Wraps children with appropriate background color
   - Unread: light-tinted background
   - Read: white background
   ```dart
   NotificationReadStateBackground(
     isRead: notification.isRead,
     unreadColor: Colors.blue.withOpacity(0.08),
     readColor: Colors.white,
     child: Card(...),
   )
   ```

3. **NotificationText**
   - Applies consistent text styling
   - Bold for unread, normal for read
   ```dart
   NotificationText(
     notification.title,
     isRead: notification.isRead,
     maxLines: 1,
   )
   ```

## Visual Distinctions

### Read vs Unread Notifications

**Unread Notifications**:
- ✅ Bold title text
- ✅ Light-tinted background (notification color @ 0.08 opacity)
- ✅ Blue dot indicator in trailing
- ✅ Type badge more prominent (0.7 opacity)
- ✅ Darker text color

**Read Notifications**:
- ✅ Normal title text
- ✅ White background
- ✅ No indicator dot
- ✅ Type badge muted (0.3 opacity)
- ✅ Grayed-out text color (Colors.grey[700])

### Example Visual Flow

```
UNREAD NOTIFICATION (Blue "Approved" type):
┌─────────────────────────────────────────┐
│ [✓] "Registration Approved"    [• • •]  │  ← Bold title, blue dot
│                                          │
│ "Your application was approved"  ◀─ Bold │
│ ┌──────────────────────────────────────┐ │
│ │ ✓ APPROVED   ◀─ Prominent badge      │ │
│ └──────────────────────────────────────┘ │
│ "2 hours ago"                             │
└─ Light blue background ──────────────────┘

READ NOTIFICATION (Green "Rejected" type):
┌─────────────────────────────────────────┐
│ [✗] "Registration Rejected"             │  ← Normal text, no dot
│                                          │
│ "Your application was rejected"          │
│ ┌──────────────────────────────────────┐ │
│ │ ✗ REJECTED   ◀─ Muted badge         │ │
│ └──────────────────────────────────────┘ │
│ "5 days ago"                              │
└─ White background ───────────────────────┘
```

## Updated Screens

### 1. Notification History Screen
**Path**: `lib/features/profile/screens/notification_history_screen.dart`

**Changes**:
- Uses `NotificationBuilder` for all styling
- Uses `NotificationReadStateWidget` for read/unread indicators
- Extended filters to show all notification types:
  - All
  - Approved
  - Rejected
  - Info Needed
  - Application
- Enhanced modal detail view with read state indicator
- Better visual distinction between read/unread

**Filter Types** (not just "APPLICATION"):
```dart
_buildFilterChip('ALL', 'All'),
_buildFilterChip('REGISTRATION_APPROVED', 'Approved'),
_buildFilterChip('REGISTRATION_REJECTED', 'Rejected'),
_buildFilterChip('INFO_REQUESTED', 'Info Needed'),
_buildFilterChip('APPLICATION', 'Application'),
```

### 2. Seller Notifications Screen
**Path**: `lib/features/seller_panel/screens/notifications_screen.dart`

**Changes**:
- Uses `NotificationBuilder` instead of local color/icon methods
- Uses `NotificationReadStateWidget` for consistency
- Maintains existing filter functionality
- Improved visual consistency with profile screen

## Code Reusability Examples

### Before (Without Clean Architecture)
```dart
// In notification_history_screen.dart
color: Colors.blue.withOpacity(0.05)

// In notifications_screen.dart
Color _getNotificationColor(String type) {
  switch (type) {
    case 'Orders': return Colors.blue;
    // ... more cases
  }
}
```

### After (With Clean Architecture)
```dart
// Both screens use the same centralized logic
NotificationBuilder.getCardBackgroundColor(notification.type, isRead)

// Add new notification type in ONE place
NotificationBuilder.typeStyles['MY_NEW_TYPE'] = NotificationTypeStyle(...)
```

## Adding New Notification Types

### To add a new notification type:

1. **Update `NotificationBuilder.typeStyles` map**:
```dart
static final Map<String, NotificationTypeStyle> typeStyles = {
  // ... existing types
  'MY_NEW_TYPE': NotificationTypeStyle(
    icon: Icons.my_icon,
    color: Colors.myColor,
    label: 'My Label',
  ),
};
```

2. **Update filter chips** (if UI needs it):
```dart
_buildFilterChip('MY_NEW_TYPE', 'My Label'),
```

3. **That's it!** The styling automatically applies everywhere:
   - List cards
   - Modal details
   - Type badges
   - Background colors

## Testing Scenarios

### Test Read/Unread Distinction
1. Load notification history
2. Verify unread notifications have:
   - Bold text
   - Light tinted background
   - Blue dot indicator
   - More prominent badge
3. Click to mark as read
4. Verify changes to:
   - Normal text
   - White background
   - No indicator dot
   - Muted badge

### Test All Notification Types
1. Create notifications of each type
2. Verify each has correct:
   - Icon
   - Color scheme
   - Badge label
   - Background tint

### Test Filter Chips
1. Select "All" → shows all notifications
2. Select "Approved" → shows only REGISTRATION_APPROVED
3. Select "Rejected" → shows only REGISTRATION_REJECTED
4. Select "Info Needed" → shows only INFO_REQUESTED
5. Select "Application" → shows only APPLICATION

## Benefits

✅ **Code Reusability**: Same styling logic across all screens
✅ **Maintainability**: Change styling in one place, applies everywhere
✅ **Extensibility**: Add new notification types without code duplication
✅ **Consistency**: All notifications styled identically
✅ **Clean Code**: Follows SOLID principles
✅ **User Experience**: Clear visual distinction between read/unread
✅ **Scalability**: Easy to support new notification types

## Future Enhancements

1. **Animations**: Add subtle animations when marking as read
2. **Grouping**: Group notifications by type/date
3. **Search**: Search notifications by title/content
4. **Archiving**: Archive old notifications
5. **Preferences**: User-configurable notification visibility
6. **Sound/Vibration**: Different sounds for different types
