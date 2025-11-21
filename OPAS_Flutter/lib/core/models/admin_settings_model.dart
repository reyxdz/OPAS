/// Admin Settings Model
/// Stores admin-specific preferences and configurations
class AdminSettingsModel {
  final String settingId;
  final bool enableEmailNotifications;
  final bool enablePushNotifications;
  final bool enableDashboardNotifications;
  final String notificationFrequency; // 'immediate', 'hourly', 'daily'
  final List<String> alertCategories; // Categories to receive alerts for
  final List<String> dashboardWidgets; // Customized dashboard widgets
  final bool showPriceTrendChart;
  final bool showSalesAnalyticsChart;
  final bool showAlertWidget;
  final bool showRecentActivityWidget;
  final String priceDisplayFormat; // 'decimal', 'currency', 'percentage'
  final String currency; // 'UGX', 'USD', etc.
  final String dateFormat; // 'MM/dd/yyyy', 'dd/MM/yyyy', etc.
  final String timeFormat; // '12h', '24h'
  final bool enableAutoExport;
  final String reportScheduleFrequency; // 'daily', 'weekly', 'monthly'
  final String reportScheduleTime; // 'HH:mm'
  final List<String> reportTypes; // Types of reports to schedule
  final DateTime lastUpdated;

  AdminSettingsModel({
    required this.settingId,
    required this.enableEmailNotifications,
    required this.enablePushNotifications,
    required this.enableDashboardNotifications,
    required this.notificationFrequency,
    required this.alertCategories,
    required this.dashboardWidgets,
    required this.showPriceTrendChart,
    required this.showSalesAnalyticsChart,
    required this.showAlertWidget,
    required this.showRecentActivityWidget,
    required this.priceDisplayFormat,
    required this.currency,
    required this.dateFormat,
    required this.timeFormat,
    required this.enableAutoExport,
    required this.reportScheduleFrequency,
    required this.reportScheduleTime,
    required this.reportTypes,
    required this.lastUpdated,
  });

  /// Convert JSON to AdminSettingsModel
  factory AdminSettingsModel.fromJson(Map<String, dynamic> json) {
    return AdminSettingsModel(
      settingId: json['setting_id'] ?? '',
      enableEmailNotifications: json['enable_email_notifications'] ?? true,
      enablePushNotifications: json['enable_push_notifications'] ?? true,
      enableDashboardNotifications: json['enable_dashboard_notifications'] ?? true,
      notificationFrequency: json['notification_frequency'] ?? 'immediate',
      alertCategories: List<String>.from(json['alert_categories'] ?? []),
      dashboardWidgets: List<String>.from(json['dashboard_widgets'] ?? []),
      showPriceTrendChart: json['show_price_trend_chart'] ?? true,
      showSalesAnalyticsChart: json['show_sales_analytics_chart'] ?? true,
      showAlertWidget: json['show_alert_widget'] ?? true,
      showRecentActivityWidget: json['show_recent_activity_widget'] ?? true,
      priceDisplayFormat: json['price_display_format'] ?? 'currency',
      currency: json['currency'] ?? 'UGX',
      dateFormat: json['date_format'] ?? 'MM/dd/yyyy',
      timeFormat: json['time_format'] ?? '24h',
      enableAutoExport: json['enable_auto_export'] ?? false,
      reportScheduleFrequency: json['report_schedule_frequency'] ?? 'daily',
      reportScheduleTime: json['report_schedule_time'] ?? '09:00',
      reportTypes: List<String>.from(json['report_types'] ?? []),
      lastUpdated: DateTime.parse(json['last_updated'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert AdminSettingsModel to JSON
  Map<String, dynamic> toJson() => {
    'setting_id': settingId,
    'enable_email_notifications': enableEmailNotifications,
    'enable_push_notifications': enablePushNotifications,
    'enable_dashboard_notifications': enableDashboardNotifications,
    'notification_frequency': notificationFrequency,
    'alert_categories': alertCategories,
    'dashboard_widgets': dashboardWidgets,
    'show_price_trend_chart': showPriceTrendChart,
    'show_sales_analytics_chart': showSalesAnalyticsChart,
    'show_alert_widget': showAlertWidget,
    'show_recent_activity_widget': showRecentActivityWidget,
    'price_display_format': priceDisplayFormat,
    'currency': currency,
    'date_format': dateFormat,
    'time_format': timeFormat,
    'enable_auto_export': enableAutoExport,
    'report_schedule_frequency': reportScheduleFrequency,
    'report_schedule_time': reportScheduleTime,
    'report_types': reportTypes,
    'last_updated': lastUpdated.toIso8601String(),
  };

  /// Create a copy with modifications
  AdminSettingsModel copyWith({
    String? settingId,
    bool? enableEmailNotifications,
    bool? enablePushNotifications,
    bool? enableDashboardNotifications,
    String? notificationFrequency,
    List<String>? alertCategories,
    List<String>? dashboardWidgets,
    bool? showPriceTrendChart,
    bool? showSalesAnalyticsChart,
    bool? showAlertWidget,
    bool? showRecentActivityWidget,
    String? priceDisplayFormat,
    String? currency,
    String? dateFormat,
    String? timeFormat,
    bool? enableAutoExport,
    String? reportScheduleFrequency,
    String? reportScheduleTime,
    List<String>? reportTypes,
    DateTime? lastUpdated,
  }) {
    return AdminSettingsModel(
      settingId: settingId ?? this.settingId,
      enableEmailNotifications: enableEmailNotifications ?? this.enableEmailNotifications,
      enablePushNotifications: enablePushNotifications ?? this.enablePushNotifications,
      enableDashboardNotifications: enableDashboardNotifications ?? this.enableDashboardNotifications,
      notificationFrequency: notificationFrequency ?? this.notificationFrequency,
      alertCategories: alertCategories ?? this.alertCategories,
      dashboardWidgets: dashboardWidgets ?? this.dashboardWidgets,
      showPriceTrendChart: showPriceTrendChart ?? this.showPriceTrendChart,
      showSalesAnalyticsChart: showSalesAnalyticsChart ?? this.showSalesAnalyticsChart,
      showAlertWidget: showAlertWidget ?? this.showAlertWidget,
      showRecentActivityWidget: showRecentActivityWidget ?? this.showRecentActivityWidget,
      priceDisplayFormat: priceDisplayFormat ?? this.priceDisplayFormat,
      currency: currency ?? this.currency,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      enableAutoExport: enableAutoExport ?? this.enableAutoExport,
      reportScheduleFrequency: reportScheduleFrequency ?? this.reportScheduleFrequency,
      reportScheduleTime: reportScheduleTime ?? this.reportScheduleTime,
      reportTypes: reportTypes ?? this.reportTypes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
