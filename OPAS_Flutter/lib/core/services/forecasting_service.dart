/// ForecastingService - Provider-based state management for forecasting data (Phase 5.3)
/// 
/// Manages forecasting data state using Provider pattern:
/// - Fetches forecasts from API
/// - Caches forecast data
/// - Handles errors and loading states
/// - Provides convenient access for UI widgets

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opas_flutter/core/services/forecasting_api_client.dart';
import 'package:opas_flutter/core/models/forecast_model.dart';
import 'package:opas_flutter/core/models/forecast_detail_model.dart';
import 'package:opas_flutter/core/models/forecast_dto.dart';

/// State class for forecast list
class ForecastListState {
  final List<ForecastModel> forecasts;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  ForecastListState({
    this.forecasts = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  ForecastListState copyWith({
    List<ForecastModel>? forecasts,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return ForecastListState(
      forecasts: forecasts ?? this.forecasts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// State class for forecast detail
class ForecastDetailState {
  final ForecastDetailModel? detail;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  ForecastDetailState({
    this.detail,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  ForecastDetailState copyWith({
    ForecastDetailModel? detail,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return ForecastDetailState(
      detail: detail ?? this.detail,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// State class for forecast metadata
class ForecastMetadataState {
  final ForecastMetadataDto? metadata;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  ForecastMetadataState({
    this.metadata,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  ForecastMetadataState copyWith({
    ForecastMetadataDto? metadata,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return ForecastMetadataState(
      metadata: metadata ?? this.metadata,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Notifier for forecast list
class ForecastListNotifier extends StateNotifier<ForecastListState> {
  final ForecastingApiClient _apiClient;

  ForecastListNotifier(this._apiClient) : super(ForecastListState());

  /// Load all forecasts from API
  Future<void> loadForecasts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dtos = await _apiClient.getAllForecasts();
      final models = dtos.map((dto) => dto.toModel()).toList();
      state = state.copyWith(
        forecasts: models,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh forecasts (same as load but indicates user-initiated refresh)
  Future<void> refreshForecasts() async {
    return loadForecasts();
  }

  /// Filter forecasts by model type
  List<ForecastModel> getByModelType(String modelType) {
    return state.forecasts
        .where((f) => f.modelType == modelType)
        .toList();
  }

  /// Filter forecasts by confidence level
  List<ForecastModel> getByConfidenceLevel(String confidence) {
    return state.forecasts
        .where((f) => f.confidenceLevel == confidence)
        .toList();
  }

  /// Find forecast by product ID
  ForecastModel? getForecastByProductId(int productId) {
    try {
      return state.forecasts.firstWhere(
        (f) => f.productId == productId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Clear forecasts
  void clear() {
    state = ForecastListState();
  }
}

/// Notifier for forecast detail
class ForecastDetailNotifier extends StateNotifier<ForecastDetailState> {
  final ForecastingApiClient _apiClient;

  ForecastDetailNotifier(this._apiClient) : super(ForecastDetailState());

  /// Load detail for a specific product
  Future<void> loadDetail(int productId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dto = await _apiClient.getForecastDetail(productId);
      final model = dto.toModel();
      state = state.copyWith(
        detail: model,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh detail for current product
  Future<void> refreshDetail() async {
    if (state.detail == null || state.detail!.productId == null) return;
    return loadDetail(state.detail!.productId!);
  }

  /// Clear detail
  void clear() {
    state = ForecastDetailState();
  }
}

/// Notifier for forecast metadata
class ForecastMetadataNotifier extends StateNotifier<ForecastMetadataState> {
  final ForecastingApiClient _apiClient;

  ForecastMetadataNotifier(this._apiClient)
      : super(ForecastMetadataState());

  /// Load metadata
  Future<void> loadMetadata() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final metadata = await _apiClient.getMetadata();
      state = state.copyWith(
        metadata: metadata,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh metadata
  Future<void> refreshMetadata() async {
    return loadMetadata();
  }

  /// Clear metadata
  void clear() {
    state = ForecastMetadataState();
  }
}

/// Singleton instance of API client
final forecastingApiClientProvider = Provider<ForecastingApiClient>((ref) {
  return ForecastingApiClient();
});

/// Provider for forecast list state
final forecastListProvider =
    StateNotifierProvider<ForecastListNotifier, ForecastListState>((ref) {
  final apiClient = ref.watch(forecastingApiClientProvider);
  return ForecastListNotifier(apiClient);
});

/// Provider for forecast detail state
final forecastDetailProvider = StateNotifierProvider<ForecastDetailNotifier,
    ForecastDetailState>((ref) {
  final apiClient = ref.watch(forecastingApiClientProvider);
  return ForecastDetailNotifier(apiClient);
});

/// Provider for forecast metadata state
final forecastMetadataProvider = StateNotifierProvider<ForecastMetadataNotifier,
    ForecastMetadataState>((ref) {
  final apiClient = ref.watch(forecastingApiClientProvider);
  return ForecastMetadataNotifier(apiClient);
});

/// Convenience provider to get forecasts by model type
final forecastsByModelTypeProvider = FutureProvider.family<
    List<ForecastModel>,
    String>((ref, modelType) async {
  final state = ref.watch(forecastListProvider);
  return state.forecasts
      .where((f) => f.modelType == modelType)
      .toList();
});

/// Convenience provider to get forecasts by confidence level
final forecastsByConfidenceProvider = FutureProvider.family<
    List<ForecastModel>,
    String>((ref, confidence) async {
  final state = ref.watch(forecastListProvider);
  return state.forecasts
      .where((f) => f.confidenceLevel == confidence)
      .toList();
});

/// Convenience provider to get a single forecast by product ID
final forecastByProductProvider =
    FutureProvider.family<ForecastModel?, int>((ref, productId) async {
  final state = ref.watch(forecastListProvider);
  try {
    return state.forecasts.firstWhere(
      (f) => f.productId == productId,
    );
  } catch (e) {
    return null;
  }
});

/// Provider for forecast alerts
final forecastAlertsProvider = FutureProvider<List<ForecastAlertItemDto>>((ref) async {
  final apiClient = ref.watch(forecastingApiClientProvider);
  return apiClient.getAlerts();
});

/// Extension methods for convenient API calls
extension ForecastingExt on WidgetRef {
  /// Load all forecasts
  Future<void> loadForecasts() async {
    await read(forecastListProvider.notifier).loadForecasts();
  }

  /// Load forecast detail for product
  Future<void> loadForecastDetail(int productId) async {
    await read(forecastDetailProvider.notifier).loadDetail(productId);
  }

  /// Load metadata
  Future<void> loadForecastMetadata() async {
    await read(forecastMetadataProvider.notifier).loadMetadata();
  }

  /// Refresh all forecasting data
  Future<void> refreshAllForecasts() async {
    await Future.wait([
      read(forecastListProvider.notifier).refreshForecasts(),
      read(forecastMetadataProvider.notifier).refreshMetadata(),
    ]);
  }
}
