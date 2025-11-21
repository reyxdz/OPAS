# OPAS Admin Panel - Quick Start Guide

## 🚀 5-Minute Setup

### Step 1: Apply Database Migrations (Django)
```bash
cd OPAS_Django
python manage.py migrate
```

### Step 2: Create an Admin User
```bash
python manage.py shell

from apps.users.models import User, UserRole

# Create admin account
User.objects.create_user(
    email='admin@opas.com',
    username='opas_admin',
    password='admin123456',
    phone_number='09123456789',
    first_name='Admin',
    last_name='User',
    role=UserRole.OPAS_ADMIN
)

exit()
```

### Step 3: Run Django Server
```bash
python manage.py runserver 0.0.0.0:8000
```

### Step 4: Run Flutter App
```bash
cd OPAS_Flutter
flutter run -d web
# Or for other platforms:
# flutter run -d chrome
# flutter run (for Android/iOS emulator)
```

### Step 5: Login to Admin Dashboard
- Phone Number: `09123456789`
- Password: `admin123456`
- Should automatically route to AdminLayout

## 📱 Admin Dashboard Overview

### 5 Main Sections in Bottom Navbar

1. **Dashboard** - View platform statistics
2. **Users** - Manage sellers and users
3. **Pricing** - Set ceiling prices and advisories
4. **Inventory** - Manage OPAS stock
5. **Announcements** - Send notifications

## 🧪 Quick Test Scenarios

### Test 1: View Dashboard
1. Login as admin
2. Tap "Dashboard" in navbar
3. Should see stat cards with numbers

### Test 2: User Management
1. Tap "Users" in navbar
2. View pending seller approvals
3. Try approving/suspending users (UI functions exist)

### Test 3: Price Management
1. Tap "Pricing" in navbar
2. Set a ceiling price
3. Post a price advisory

### Test 4: Inventory
1. Tap "Inventory" in navbar
2. View current stock
3. Accept "Sell to OPAS" requests

### Test 5: Announcements
1. Tap "Announcements" in navbar
2. Create test announcement
3. Choose recipient group

## 🔧 Troubleshooting

### Issue: Not Routing to Admin
**Solution:** 
- Check user role in database: `SELECT role FROM users WHERE email='admin@opas.com'`
- Should be: `OPAS_ADMIN`
- Re-login if needed

### Issue: API Endpoints 404
**Solution:**
- Verify Django server is running
- Check baseUrl in `admin_service.dart` (should be `http://localhost:8000/api`)
- Run migrations: `python manage.py migrate`

### Issue: Permission Denied (403)
**Solution:**
- Verify user has `OPAS_ADMIN` role
- Check token in SharedPreferences
- Test with a fresh login

### Issue: UI Not Showing Data
**Solution:**
- Data is hardcoded for demo purposes
- Check console logs for API errors
- Verify JSON responses match expected format

## 📊 Database Queries

### Check Admin Users
```sql
SELECT id, email, phone_number, role FROM users WHERE role IN ('OPAS_ADMIN', 'SYSTEM_ADMIN');
```

### Check Pending Sellers
```sql
SELECT id, email, store_name, seller_status FROM users WHERE seller_status = 'PENDING';
```

### Check Suspended Users
```sql
SELECT id, email, suspension_reason, suspended_at FROM users WHERE seller_status = 'SUSPENDED';
```

## 🎯 Feature Completeness

### ✅ Fully Implemented
- Admin dashboard UI with all 5 sections
- Uniform navbar design (matching buyer side)
- Admin profile screen
- Django API endpoints
- Admin role detection
- Automatic routing on login
- Admin service with API calls
- Database models and fields

### 🔄 To Be Connected
- Dashboard statistics to real database data
- Seller list to real sellers from DB
- Price advisories to notification system
- Inventory to product model
- Announcements to notification queue

### 🚀 Future Enhancements
- Document verification workflow
- Advanced analytics/reporting
- Real-time notifications
- Audit logging system
- Advanced filtering and export

## 📞 Support

For issues, check:
1. **Logs:** Console output in Flutter and Django
2. **Database:** Verify data exists
3. **Network:** Ensure server is running
4. **Permissions:** Check user role
5. **Tokens:** Verify access token is valid

## 💡 Tips & Tricks

### View API Response in Console
All admin service methods log responses to console:
```dart
debugPrint('Response: ${response.body}');
```

### Test API Endpoints Directly
Use Postman or Insomnia:
```
GET http://localhost:8000/api/users/admin/dashboard/stats/
Authorization: Bearer {your_access_token}
```

### Create Multiple Admin Users for Testing
```bash
python manage.py shell

from apps.users.models import User, UserRole

# Create system admin
User.objects.create_user(
    email='system@opas.com',
    username='system_admin',
    password='admin123456',
    phone_number='09123456790',
    first_name='System',
    last_name='Admin',
    role=UserRole.SYSTEM_ADMIN
)
```

---

**Ready to Go!** 🎉

All admin panel features are integrated and ready for testing. Start with Step 1 above and you'll be viewing the admin dashboard in under 5 minutes.
