# 📋 Deployment Checklist - Seller Product Listings Fix

## Pre-Deployment Verification

### Backend (Django)
- [ ] Pull latest code changes
- [ ] Verify `seller_views.py` has `select_related('seller')` in list() method
- [ ] Verify `seller_serializers.py` has image fields removed from SellerProductListSerializer
- [ ] Run migrations (new migration added: `apps/users/migrations/0023_add_previous_status_field.py`).
	- Verify with `python manage.py showmigrations users` and apply with `python manage.py migrate users`.
	- If tests or the test DB fail when creating the test database, remove stale test DB or fix conflicting local schema before running tests (see notes below).
- [ ] Test locally: `python verify_product_listing_fix.py`

### Frontend (Flutter)
- [ ] Pull latest code changes
- [ ] Verify `seller_service.dart` has timeout increased to 30 seconds
- [ ] Build locally: `flutter build apk` (for Android) or `flutter build ios` (for iOS)
- [ ] Test on emulator with seller account

## Deployment Steps

### 1. Backend Deployment
```bash
# Production server
git pull origin main
python manage.py collectstatic --noinput
# Restart Django/Gunicorn
systemctl restart opas-django  # or your service name
# Verify
curl -H "Authorization: Bearer <token>" http://api.example.com/api/users/seller/products/
```

### 2. Frontend Deployment
```bash
# Local development
flutter clean
flutter pub get
flutter build apk --release  # Android
flutter build ios --release   # iOS

# Upload to stores or distribute APK
```

## Post-Deployment Testing

### 1. Functional Testing
- [ ] Login as seller with products
- [ ] Navigate to Products screen
- [ ] Verify products load without "TimeoutException" error
- [ ] Verify product list is not empty
- [ ] Test filtering (ACTIVE, EXPIRED, PENDING)
- [ ] Test search functionality
- [ ] Test refresh button

### 2. Performance Testing
- [ ] Monitor API response time (should be < 1 second)
- [ ] Check database query count (should be 2-3 queries)
- [ ] Test with seller having 50+ products
- [ ] Test on 3G throttle simulation
- [ ] Check memory usage on device

### 3. Error Handling
- [ ] Test with seller having no products
- [ ] Test with invalid token
- [ ] Test with expired token
- [ ] Check error messages are user-friendly

## Rollback Plan

If issues occur:

### Backend Rollback
```bash
git revert <commit_hash>
systemctl restart opas-django
```

## Notes about migrations & local test DB issues

- If `manage.py test` fails while creating the test database (example error: "column \"email\" of relation \"users\" already exists"), this indicates your local schema and migrations are out of sync. Common fixes:
	1. Drop the leftover `test_*` database used by the test runner and re-run tests.
 2. Ensure your local dev DB is in a clean state (optionally run `python manage.py migrate --fake <app> <migration>` only with understanding).
 3. If you intentionally reset, run `python manage.py flush` (destructive) or re-create the dev DB.

- Recommended CI step: run `python manage.py migrate --noinput` during CI setup before running tests to keep the test environment consistent.

### Frontend Rollback
- Distribute previous APK version
- Update links in app stores

## Monitoring

### Check These Logs
- Django server logs for errors
- API response times from monitoring tools
- Database query performance
- Flutter app crashes

### Expected Metrics After Fix
| Metric | Expected Value |
|--------|-----------------|
| 90th percentile response time | < 500ms |
| 99th percentile response time | < 1s |
| Database queries per request | 2-3 |
| Cache hit rate | N/A (not using cache yet) |
| Error rate | 0% |

## Success Criteria

✅ **Fix is successful when:**
1. Sellers can view product listings without timeout errors
2. Response time is under 1 second (typically 200-500ms)
3. All sellers can access their products (APPROVED status)
4. Filtering functionality works correctly
5. No increase in server resource usage
6. No database errors in logs

❌ **Issues to investigate if:**
1. Timeout still occurs (> 15 seconds)
2. Products don't display
3. Database queries are > 10
4. Memory usage spikes
5. 500 errors in logs

## Contacts & Escalation

- **Django Issues**: Backend team
- **Flutter Issues**: Mobile team
- **Database Issues**: DBA
- **Deployment Issues**: DevOps

## Sign-off

- [ ] Backend deployment approved
- [ ] Frontend deployment approved
- [ ] Testing completed successfully
- [ ] Monitoring confirmed active

**Deployment Date**: _______________  
**Deployed By**: _______________  
**Verified By**: _______________
