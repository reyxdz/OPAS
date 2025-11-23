import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_registration_list_model.dart';
import '../services/seller_registration_admin_service.dart';
import '../../services/seller_registration_cache_service.dart';

// CORE PRINCIPLE: Resource Management - Lazy initialization
final adminServiceProvider = Provider((ref) => SellerRegistrationAdminService());

final adminCacheServiceProvider =
    Provider((ref) => SellerRegistrationCacheService());

/// Admin filter state notifier
/// CORE PRINCIPLE: State Preservation - Remember filter selections
class AdminFiltersNotifier extends StateNotifier<AdminFilters> {
  final SellerRegistrationCacheService _cacheService;

  AdminFiltersNotifier(this._cacheService)
      : super(AdminFilters(
          status: null,
          page: 1,
          searchQuery: '',
          sortBy: 'submitted_at',
          sortOrder: 'desc',
        )) {
    _loadCachedFilters();
  }

  /// Load cached filter state from previous session
  /// CORE PRINCIPLE: State Preservation - Restore user's previous selections
  Future<void> _loadCachedFilters() async {
    final cached = await _cacheService.getFilterState('admin_filters');
    if (cached != null) {
      state = AdminFilters.fromJson(cached);
    }
  }

  /// Update filters and persist to cache
  /// CORE PRINCIPLE: Cache Invalidation - Clear list cache when filters change
  Future<void> updateFilters(AdminFilters filters) async {
    state = filters;
    // Save to cache for restoration on app restart
    await _cacheService.cacheFilterState('admin_filters', filters.toJson());
    // Invalidate list cache since filters changed
    await _cacheService.clearAllAdminRegistrations();
  }

  /// Update status filter
  Future<void> setStatus(String? status) async {
    final updated = state.copyWith(status: status, page: 1);
    await updateFilters(updated);
  }

  /// Update search query
  Future<void> setSearchQuery(String query) async {
    final updated = state.copyWith(searchQuery: query, page: 1);
    await updateFilters(updated);
  }

  /// Update sort field
  Future<void> setSortBy(String sortBy) async {
    final updated = state.copyWith(sortBy: sortBy, page: 1);
    await updateFilters(updated);
  }

  /// Toggle sort order
  Future<void> toggleSortOrder() async {
    final newOrder = state.sortOrder == 'asc' ? 'desc' : 'asc';
    final updated = state.copyWith(sortOrder: newOrder);
    await updateFilters(updated);
  }

  /// Update page
  Future<void> setPage(int page) async {
    final updated = state.copyWith(page: page);
    state = updated;
  }

  /// Reset filters to default
  Future<void> resetFilters() async {
    final defaults = AdminFilters(
      status: null,
      page: 1,
      searchQuery: '',
      sortBy: 'submitted_at',
      sortOrder: 'desc',
    );
    await updateFilters(defaults);
  }

  /// Get cache key for current filters
  String _getCacheKey() {
    return 'admin_registrations_${state.status}_${state.searchQuery}_${state.sortBy}_${state.sortOrder}';
  }
}

/// Admin filters state model
class AdminFilters {
  final String? status;
  final int page;
  final String searchQuery;
  final String sortBy;
  final String sortOrder;

  AdminFilters({
    required this.status,
    required this.page,
    required this.searchQuery,
    required this.sortBy,
    required this.sortOrder,
  });

  AdminFilters copyWith({
    String? status,
    int? page,
    String? searchQuery,
    String? sortBy,
    String? sortOrder,
  }) {
    return AdminFilters(
      status: status ?? this.status,
      page: page ?? this.page,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'page': page,
        'searchQuery': searchQuery,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };

  factory AdminFilters.fromJson(Map<String, dynamic> json) {
    return AdminFilters(
      status: json['status'],
      page: json['page'] ?? 1,
      searchQuery: json['searchQuery'] ?? '',
      sortBy: json['sortBy'] ?? 'submitted_at',
      sortOrder: json['sortOrder'] ?? 'desc',
    );
  }
}

/// Provider for admin filters
final adminFiltersProvider =
    StateNotifierProvider<AdminFiltersNotifier, AdminFilters>((ref) {
  final cacheService = ref.watch(adminCacheServiceProvider);
  return AdminFiltersNotifier(cacheService);
});

/// Fetch admin registrations list with caching and pagination
/// CORE PRINCIPLE: Caching - Cache pages as loaded
/// CORE PRINCIPLE: Pagination - Efficient data loading
final adminRegistrationsListProvider =
    FutureProvider.family<List<AdminRegistrationListItem>, AdminFilters>(
  (ref, filters) async {
    final service = ref.watch(adminServiceProvider);
    final cacheService = ref.watch(adminCacheServiceProvider);

    final cacheKey =
        'admin_regs_${filters.status}_${filters.searchQuery}_${filters.sortBy}_${filters.sortOrder}';

    try {
      // Try cache first
      // CORE PRINCIPLE: Offline-First - Show cached data while fetching
      final cached = await cacheService.getAdminRegistrationsList(cacheKey, filters.page);
      if (cached != null) {
        final items = cached
            .map((json) => AdminRegistrationListItem.fromJson(json))
            .toList();

        // Refresh in background (optimistic UI)
        service
            .getRegistrationsList(
              status: filters.status,
              page: filters.page,
              searchQuery: filters.searchQuery,
              sortBy: filters.sortBy,
              sortOrder: filters.sortOrder,
            )
            .then((fresh) async {
          final jsonData = fresh.map((item) => item.toJson()).toList();
          await cacheService.cacheAdminRegistrationsList(
            cacheKey,
            filters.page,
            jsonData,
          );
          ref.refresh(adminRegistrationsListProvider(filters));
        });

        return items;
      }

      // Fetch from network
      final items = await service.getRegistrationsList(
        status: filters.status,
        page: filters.page,
        searchQuery: filters.searchQuery,
        sortBy: filters.sortBy,
        sortOrder: filters.sortOrder,
      );

      // Cache the result
      final jsonData = items.map((item) => item.toJson()).toList();
      await cacheService.cacheAdminRegistrationsList(
        cacheKey,
        filters.page,
        jsonData,
      );

      return items;
    } catch (e) {
      // On error, return cached data if available
      final cached = await cacheService.getAdminRegistrationsList(cacheKey, filters.page);
      if (cached != null) {
        return cached
            .map((json) => AdminRegistrationListItem.fromJson(json))
            .toList();
      }
      rethrow;
    }
  },
);

/// Fetch single registration details with caching
/// CORE PRINCIPLE: Caching - Cache detail views separately
final adminRegistrationDetailProvider =
    FutureProvider.family<AdminRegistrationDetail, int>((ref, registrationId) async {
  final service = ref.watch(adminServiceProvider);
  final cacheService = ref.watch(adminCacheServiceProvider);

  try {
    // Try cache first
    final cacheKey = 'admin_registration_detail_$registrationId';
    final cached =
        await cacheService.getBuyerRegistration(cacheKey);
    if (cached != null) {
      final detail = AdminRegistrationDetail.fromJson(cached);

      // Refresh in background
      service.getRegistrationDetails(registrationId).then((fresh) async {
        await cacheService.cacheBuyerRegistration(cacheKey, fresh.toJson());
        ref.refresh(adminRegistrationDetailProvider(registrationId));
      });

      return detail;
    }

    // Fetch from network
    final detail = await service.getRegistrationDetails(registrationId);

    // Cache the result
    await cacheService.cacheBuyerRegistration(cacheKey, detail.toJson());

    return detail;
  } catch (e) {
    // On error, return cached data if available
    final cacheKey = 'admin_registration_detail_$registrationId';
    final cached =
        await cacheService.getBuyerRegistration(cacheKey);
    if (cached != null) {
      return AdminRegistrationDetail.fromJson(cached);
    }
    rethrow;
  }
});

/// Track approval/rejection action status
/// CORE PRINCIPLE: UX - Show loading state during operations
class AdminActionNotifier extends StateNotifier<AsyncValue<void>> {
  final SellerRegistrationAdminService _service;
  final SellerRegistrationCacheService _cacheService;

  AdminActionNotifier(this._service, this._cacheService)
      : super(const AsyncValue.data(null));

  /// Approve registration
  /// CORE PRINCIPLE: API Idempotency - Backend prevents duplicate approvals
  Future<void> approveRegistration(
    int registrationId, {
    String? adminNotes,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _service.approveRegistration(
        registrationId,
        adminNotes: adminNotes,
      );

      // Invalidate cache for this registration and list
      // CORE PRINCIPLE: Cache Invalidation - Clear affected caches
      await _cacheService.clearBuyerRegistration(
        'admin_registration_detail_$registrationId',
      );
      await _cacheService.clearAllAdminRegistrations();

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Reject registration
  Future<void> rejectRegistration(
    int registrationId, {
    required String rejectionReason,
    String? adminNotes,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _service.rejectRegistration(
        registrationId,
        rejectionReason: rejectionReason,
        adminNotes: adminNotes,
      );

      // Clear caches
      await _cacheService.clearBuyerRegistration(
        'admin_registration_detail_$registrationId',
      );
      await _cacheService.clearAllAdminRegistrations();

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Request more information
  Future<void> requestMoreInfo(
    int registrationId, {
    required String requiredInfo,
    int? deadlineInDays,
    String? adminNotes,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _service.requestMoreInfo(
        registrationId,
        requiredInfo: requiredInfo,
        deadlineInDays: deadlineInDays,
        adminNotes: adminNotes,
      );

      // Clear caches
      await _cacheService.clearBuyerRegistration(
        'admin_registration_detail_$registrationId',
      );
      await _cacheService.clearAllAdminRegistrations();

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Reset action status
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for admin actions
final adminActionProvider =
    StateNotifierProvider<AdminActionNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(adminServiceProvider);
  final cacheService = ref.watch(adminCacheServiceProvider);
  return AdminActionNotifier(service, cacheService);
});

/// Check if admin action is loading
final isAdminActionLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(adminActionProvider);
  return state.isLoading;
});

/// Get admin action error if any
final adminActionErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(adminActionProvider);
  return state.maybeWhen(
    error: (err, st) => err.toString(),
    orElse: () => null,
  );
});

/// Check if registrations list is loading
final isAdminListLoadingProvider = Provider<bool>((ref) {
  final filters = ref.watch(adminFiltersProvider);
  final asyncValue = ref.watch(adminRegistrationsListProvider(filters));
  return asyncValue.isLoading;
});

/// Get registrations list error if any
final adminListErrorProvider = Provider<String?>((ref) {
  final filters = ref.watch(adminFiltersProvider);
  final asyncValue = ref.watch(adminRegistrationsListProvider(filters));
  return asyncValue.maybeWhen(
    error: (err, st) => err.toString(),
    orElse: () => null,
  );
});

/// Initialize admin cache on app startup
final adminCacheInitializationProvider = FutureProvider<void>((ref) async {
  final cacheService = ref.watch(adminCacheServiceProvider);
  await cacheService.initialize();
  await cacheService.clearExpiredCache();
});
