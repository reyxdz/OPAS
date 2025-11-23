import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/seller_registration_model.dart';
import '../services/seller_registration_service.dart';
import '../../../services/seller_registration_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// CORE PRINCIPLE: Resource Management - Lazy initialization of services
final sellerRegistrationServiceProvider =
    Provider((ref) => SellerRegistrationService());

final cacheServiceProvider =
    Provider((ref) => SellerRegistrationCacheService());

/// Fetch current user's registration with caching
/// CORE PRINCIPLE: Caching - Return cached data if available
/// CORE PRINCIPLE: Offline-First - Show cached data while fetching fresh
final AutoDisposeFutureProvider<SellerRegistration?>
    myRegistrationProvider =
    FutureProvider.autoDispose<SellerRegistration?>((ref) async {
  final cacheService = ref.watch(cacheServiceProvider);

  try {
    // Get access token from shared preferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access') ?? '';

    // Try to get cached data first
    // CORE PRINCIPLE: Offline-First - Display immediately from cache
    final cachedData = await cacheService.getFilterState('my_registration');
    if (cachedData != null) {
      final cached = SellerRegistration.fromJson(cachedData);
      // Refresh in background (optimistic UI)
      unawaited(
        SellerRegistrationService.getMyRegistration(token).then((fresh) async {
          if (fresh != null) {
            await cacheService.cacheFilterState(
              'my_registration',
              fresh.toJson(),
            );
          }
        }),
      );
      return cached;
    }

    // If no cache, fetch from network
    final registration =
        await SellerRegistrationService.getMyRegistration(token);
    if (registration != null) {
      await cacheService.cacheFilterState(
        'my_registration',
        registration.toJson(),
      );
    }
    return registration;
  } catch (e) {
    // On error, return cached data if available
    final cachedData = await cacheService.getFilterState('my_registration');
    if (cachedData != null) {
      return SellerRegistration.fromJson(cachedData);
    }
    rethrow;
  }
});

/// Form state notifier for managing registration form input
/// CORE PRINCIPLE: State Preservation - Restore form state when app resumes
class RegistrationFormNotifier
    extends StateNotifier<Map<String, dynamic>?> {
  final SellerRegistrationCacheService _cacheService;

  RegistrationFormNotifier(this._cacheService) : super(null);

  /// Initialize form with cached data or empty state
  Future<void> initializeForm() async {
    final cached = await _cacheService.getFilterState('registration_draft');
    if (cached != null) {
      state = cached;
    }
  }

  /// Update form field and persist to cache
  /// CORE PRINCIPLE: State Preservation - Save form state immediately
  Future<void> updateField(String field, dynamic value) async {
    if (state == null) return;

    // Update in-memory state
    final updatedData = <String, dynamic>{...state!};
    _setNestedValue(updatedData, field, value);
    state = updatedData;

    // Persist to cache immediately for offline support
    // CORE PRINCIPLE: Crash Recovery - Form data survives app crash
    await _cacheService.cacheFilterState('registration_draft', updatedData);
  }

  /// Helper to set nested JSON values
  void _setNestedValue(Map<String, dynamic> map, String path, dynamic value) {
    final parts = path.split('.');
    for (int i = 0; i < parts.length - 1; i++) {
      map[parts[i]] ??= {};
      map = map[parts[i]] as Map<String, dynamic>;
    }
    map[parts.last] = value;
  }

  /// Clear draft form
  Future<void> clearDraft() async {
    state = null;
    await _cacheService.clearAllCache();
  }

  /// Reset form to initial state
  void resetForm() {
    state = null;
  }
}

/// Provider for registration form state
/// CORE PRINCIPLE: State Management - Preserve form across navigation
final registrationFormProvider =
    StateNotifierProvider<RegistrationFormNotifier, Map<String, dynamic>?>(
  (ref) {
    final cacheService = ref.watch(cacheServiceProvider);
    return RegistrationFormNotifier(cacheService);
  },
);

/// Track registration submission status
/// CORE PRINCIPLE: UX - Show loading state during submission
class SubmissionStatusNotifier extends StateNotifier<AsyncValue<void>> {
  final SellerRegistrationCacheService _cacheService;

  SubmissionStatusNotifier(this._cacheService)
      : super(const AsyncValue.data(null));

  /// Submit registration form
  /// CORE PRINCIPLE: Resource Management - Efficient API call
  /// CORE PRINCIPLE: Input Validation - Server-side enforcement
  Future<void> submitRegistration(Map<String, dynamic> formData) async {
    state = const AsyncValue.loading();

    try {
      // Get access token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';

      await SellerRegistrationService.submitRegistration(
        farmName: formData['farm_name'] as String? ?? '',
        farmLocation: formData['farm_location'] as String? ?? '',
        farmSize: formData['farm_size'] as String? ?? '',
        productsGrown:
            List<String>.from(formData['products_grown'] as List? ?? []),
        storeName: formData['store_name'] as String? ?? '',
        storeDescription: formData['store_description'] as String? ?? '',
        accessToken: token,
      );

      // Clear draft on successful submission
      await _cacheService.clearAllCache();

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider for registration submission
final registrationSubmissionProvider =
    StateNotifierProvider<SubmissionStatusNotifier, AsyncValue<void>>((ref) {
  final cacheService = ref.watch(cacheServiceProvider);
  return SubmissionStatusNotifier(cacheService);
});

/// Watch loading state of my registration
/// CORE PRINCIPLE: UX - Show loading indicator
final isRegistrationLoadingProvider = Provider<bool>((ref) {
  final asyncValue = ref.watch(myRegistrationProvider);
  return asyncValue.isLoading;
});

/// Get current registration error if any
/// CORE PRINCIPLE: Error Handling - Show error messages
final registrationErrorProvider = Provider<String?>((ref) {
  final asyncValue = ref.watch(myRegistrationProvider);
  return asyncValue.maybeWhen(
    error: (err, st) => err.toString(),
    orElse: () => null,
  );
});

/// Initialize cache on app startup
/// CORE PRINCIPLE: Resource Management - Setup before first use
final cacheInitializationProvider = FutureProvider<void>((ref) async {
  final cacheService = ref.watch(cacheServiceProvider);
  await cacheService.initialize();
  // Periodically clear expired cache
  // CORE PRINCIPLE: Memory Management - Cleanup expired data
  await cacheService.clearExpiredCache();
});
