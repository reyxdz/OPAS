// Announcement Model - Marketplace announcements and notifications
class AnnouncementModel {
  final String announcementId;
  final String title;
  final String content;
  final String type; // 'price_update', 'shortage_alert', 'policy_change', 'promotion'
  final String targetAudience; // 'all', 'buyers', 'sellers', 'specific'
  final List<String>? targetSellerIds;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final DateTime? sentAt;
  final String status; // 'draft', 'scheduled', 'published', 'archived'
  final int? viewCount;
  final String createdBy;

  AnnouncementModel({
    required this.announcementId,
    required this.title,
    required this.content,
    required this.type,
    required this.targetAudience,
    this.targetSellerIds,
    required this.createdAt,
    this.scheduledFor,
    this.sentAt,
    required this.status,
    this.viewCount,
    required this.createdBy,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      announcementId: json['announcement_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Announcement',
      content: json['content'] as String? ?? '',
      type: json['type'] as String? ?? 'promotion',
      targetAudience: json['target_audience'] as String? ?? 'all',
      targetSellerIds: json['target_seller_ids'] != null
          ? List<String>.from(json['target_seller_ids'] as List)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      scheduledFor: json['scheduled_for'] != null
          ? DateTime.parse(json['scheduled_for'] as String)
          : null,
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'] as String)
          : null,
      status: json['status'] as String? ?? 'draft',
      viewCount: json['view_count'] as int?,
      createdBy: json['created_by'] as String? ?? 'admin',
    );
  }

  String getTypeColor() {
    switch (type) {
      case 'price_update':
        return '#FF9800';
      case 'shortage_alert':
        return '#F44336';
      case 'policy_change':
        return '#2196F3';
      case 'promotion':
      default:
        return '#4CAF50';
    }
  }

  String getTypeIcon() {
    switch (type) {
      case 'price_update':
        return '💰';
      case 'shortage_alert':
        return '⚠️';
      case 'policy_change':
        return '📋';
      case 'promotion':
      default:
        return '🎉';
    }
  }

  String getTypeLabel() {
    switch (type) {
      case 'price_update':
        return 'Price Update';
      case 'shortage_alert':
        return 'Shortage Alert';
      case 'policy_change':
        return 'Policy Change';
      case 'promotion':
      default:
        return 'Promotion';
    }
  }

  String getTargetAudienceLabel() {
    switch (targetAudience) {
      case 'buyers':
        return 'Buyers Only';
      case 'sellers':
        return 'Sellers Only';
      case 'specific':
        return 'Specific Sellers';
      case 'all':
      default:
        return 'All Users';
    }
  }

  bool isDraft() => status == 'draft';
  bool isScheduled() => status == 'scheduled';
  bool isPublished() => status == 'published';
  bool canEdit() => isDraft() || isScheduled();
}
