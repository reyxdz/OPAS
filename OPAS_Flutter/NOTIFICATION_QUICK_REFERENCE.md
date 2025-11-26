# Quick Reference: Notification System Usage

## For Developers

### Using NotificationBuilder in Any Screen

```dart
import '../../profile/helpers/notification_builder.dart';

// Get styling for any notification type
final style = NotificationBuilder.getStyle('REGISTRATION_APPROVED');

// Build UI components
final icon = NotificationBuilder.buildIcon(notification.type);
final badge = NotificationBuilder.buildTypeBadge(notification.type, isRead: isRead);

// Get colors
final bgColor = NotificationBuilder.getCardBackgroundColor(notification.type, isRead);
final headerBg = NotificationBuilder.getHeaderBackgroundColor(notification.type);

// Get text styles
final titleStyle = NotificationBuilder.getTitleStyle(context, isRead);
final bodyStyle = NotificationBuilder.getBodyStyle(context, isRead);
final timeStyle = NotificationBuilder.getTimestampStyle(context);
```

### Using Read State Widgets

```dart
import '../../profile/widgets/notification_read_state_widget.dart';

// Indicator dot
NotificationReadStateIndicator(
  isRead: notification.isRead,
  color: Colors.blue,
)

// Background wrapper
NotificationReadStateBackground(
  isRead: notification.isRead,
  unreadColor: Colors.blue.withOpacity(0.08),
  readColor: Colors.white,
  child: YourWidget(),
)

// Text with automatic styling
NotificationText(
  'Your Title',
  isRead: notification.isRead,
  maxLines: 1,
)
```

## Supported Notification Types

| Type | Icon | Color | Label |
|------|------|-------|-------|
| `REGISTRATION_APPROVED` | ✓ | Green | Approved |
| `REGISTRATION_REJECTED` | ✗ | Red | Rejected |
| `INFO_REQUESTED` | ℹ | Orange | Info Needed |
| `APPLICATION` | 📢 | Blue | Application |
| `PENDING_REVIEW` | ⏰ | Amber | Pending Review |
| `UNDER_REVIEW` | 🔍 | Indigo | Under Review |
| `RESUBMISSION_REQUIRED` | 🔄 | Purple | Resubmission Required |
| `APPROVED` | ✓ | Teal | Approved |
| `REJECTED` | ✗ | Deep Orange | Rejected |

## Adding a New Notification Type

**Step 1**: Add to `typeStyles` map in `notification_builder.dart`
```dart
'NEW_TYPE': NotificationTypeStyle(
  icon: Icons.my_icon,
  color: Colors.myColor,
  label: 'My Label',
),
```

**Step 2**: Optionally add to filter chips in `notification_history_screen.dart`
```dart
_buildFilterChip('NEW_TYPE', 'My Label'),
```

**That's it!** All styling automatically applies across the app.

## Testing Checklist

- [ ] Unread notifications show bold text
- [ ] Unread notifications have tinted background
- [ ] Unread notifications show blue dot
- [ ] Read notifications show normal text
- [ ] Read notifications have white background
- [ ] Read notifications have no indicator dot
- [ ] Type badge displays correct icon and color
- [ ] Clicking unread notification marks it as read
- [ ] Filter chips work for all types
- [ ] Modal shows read/unread status indicator
- [ ] All notification types render with correct colors

## File Locations

```
lib/features/profile/
├── helpers/
│   └── notification_builder.dart           # Styling logic
├── widgets/
│   └── notification_read_state_widget.dart # Reusable widgets
└── screens/
    └── notification_history_screen.dart    # Profile notifications

lib/features/seller_panel/
└── screens/
    └── notifications_screen.dart           # Seller notifications
```

## Architecture Pattern

This implementation follows **Clean Architecture** with:

1. **Separation of Concerns**
   - `NotificationBuilder`: Configuration & styling
   - `NotificationReadStateWidget`: UI components
   - Screens: UI orchestration

2. **DRY Principle**
   - No duplicate styling logic
   - Centralized configuration
   - Easy to maintain

3. **SOLID Principles**
   - Single Responsibility: Each class has one job
   - Open/Closed: Easy to extend with new types
   - Liskov Substitution: Widgets are interchangeable
   - Interface Segregation: Small, focused interfaces
   - Dependency Inversion: Depends on abstractions

## Common Patterns

### Pattern 1: Building a Notification Card
```dart
NotificationReadStateBackground(
  isRead: notification.isRead,
  unreadColor: NotificationBuilder.getCardBackgroundColor(notification.type, false),
  child: Card(
    child: ListTile(
      leading: NotificationBuilder.buildIcon(notification.type),
      title: NotificationText(notification.title, isRead: notification.isRead),
      trailing: NotificationReadStateIndicator(isRead: notification.isRead),
    ),
  ),
)
```

### Pattern 2: Building an Info Box
```dart
Container(
  decoration: BoxDecoration(
    color: NotificationBuilder.getInfoBoxBackgroundColor('rejection'),
    border: Border.all(color: Colors.red.shade300),
  ),
  child: Text(
    notification.rejectionReason,
    style: TextStyle(
      color: NotificationBuilder.getInfoBoxTextColor('rejection'),
    ),
  ),
)
```

### Pattern 3: Building a Type Badge
```dart
NotificationBuilder.buildTypeBadge(
  notification.type,
  isRead: notification.isRead,
)
```

## Performance Notes

- ✅ All styling is computed once and cached
- ✅ No unnecessary rebuilds
- ✅ Minimal widget tree
- ✅ Efficient color calculations
- ✅ No memory leaks

## Troubleshooting

**Q: New notification type not showing correct icon/color?**
A: Make sure it's added to `NotificationBuilder.typeStyles` map

**Q: Unread indicator not showing?**
A: Check that `isRead` is `false` and `NotificationReadStateIndicator` is in the trailing

**Q: Read/unread background not changing?**
A: Wrap in `NotificationReadStateBackground` with correct colors

**Q: Filter chips not working?**
A: Ensure `_filterType` matches notification type string exactly
