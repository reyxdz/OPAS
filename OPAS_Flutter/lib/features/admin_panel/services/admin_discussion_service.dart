/// Admin Discussion Service for Phase 4.4: Admin Collaboration
/// Manages discussion threads with comments, mentions, and real-time notifications
/// 
/// Architecture: Thread-based discussion system with mention detection and user engagement
/// Supports hierarchical comments, emoji reactions, and file attachments

import 'package:opas_flutter/core/services/logger_service.dart';

// ignore_for_file: constant_identifier_names

/// Discussion thread topic
enum DiscussionTopic {
  ESCALATION,
  PRICE_POLICY,
  SELLER_ISSUE,
  OPAS_DECISION,
  GENERAL_DISCUSSION,
  COMPLIANCE_REVIEW,
  SYSTEM_ISSUE,
}

/// Comment reaction type
enum ReactionType {
  LIKE,
  HELPFUL,
  DISAGREE,
  NEEDS_DISCUSSION,
}

/// Represents a comment in a discussion thread
class DiscussionComment {
  final String commentId;
  final String adminId;
  final String adminName;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? parentCommentId; // For reply threading
  final List<String> mentionedAdminIds;
  final Map<ReactionType, List<String>> reactions; // reaction -> [adminIds]
  final List<String> attachmentUrls;
  final bool isEdited;

  DiscussionComment({
    required this.commentId,
    required this.adminId,
    required this.adminName,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.parentCommentId,
    this.mentionedAdminIds = const [],
    Map<ReactionType, List<String>>? reactions,
    this.attachmentUrls = const [],
    this.isEdited = false,
  }) : reactions = reactions ?? {};

  /// Add reaction from admin
  DiscussionComment addReaction(ReactionType type, String adminId) {
    final newReactions = Map<ReactionType, List<String>>.from(reactions);
    final reactionList = List<String>.from(newReactions[type] ?? []);

    if (!reactionList.contains(adminId)) {
      reactionList.add(adminId);
      newReactions[type] = reactionList;
    }

    return copyWith(reactions: newReactions);
  }

  /// Remove reaction from admin
  DiscussionComment removeReaction(ReactionType type, String adminId) {
    final newReactions = Map<ReactionType, List<String>>.from(reactions);
    final reactionList = List<String>.from(newReactions[type] ?? []);
    reactionList.remove(adminId);

    if (reactionList.isEmpty) {
      newReactions.remove(type);
    } else {
      newReactions[type] = reactionList;
    }

    return copyWith(reactions: newReactions);
  }

  /// Create copy with updates
  DiscussionComment copyWith({
    String? commentId,
    String? adminId,
    String? adminName,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? parentCommentId,
    List<String>? mentionedAdminIds,
    Map<ReactionType, List<String>>? reactions,
    List<String>? attachmentUrls,
    bool? isEdited,
  }) {
    return DiscussionComment(
      commentId: commentId ?? this.commentId,
      adminId: adminId ?? this.adminId,
      adminName: adminName ?? this.adminName,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      mentionedAdminIds: mentionedAdminIds ?? this.mentionedAdminIds,
      reactions: reactions ?? this.reactions,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      isEdited: isEdited ?? this.isEdited,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'commentId': commentId,
    'adminId': adminId,
    'adminName': adminName,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'parentCommentId': parentCommentId,
    'mentionedAdminIds': mentionedAdminIds,
    'reactions': {
      for (final entry in reactions.entries)
        entry.key.name: entry.value,
    },
    'attachmentUrls': attachmentUrls,
    'isEdited': isEdited,
  };

  /// Create from JSON
  factory DiscussionComment.fromJson(Map<String, dynamic> json) {
    final reactionsMap = <ReactionType, List<String>>{};
    final reactionsJson = json['reactions'] as Map<String, dynamic>? ?? {};
    for (final entry in reactionsJson.entries) {
      final type = ReactionType.values.firstWhere(
        (t) => t.name == entry.key,
        orElse: () => ReactionType.LIKE,
      );
      reactionsMap[type] = List<String>.from(entry.value as List? ?? []);
    }

    return DiscussionComment(
      commentId: json['commentId'] as String,
      adminId: json['adminId'] as String,
      adminName: json['adminName'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      parentCommentId: json['parentCommentId'] as String?,
      mentionedAdminIds:
          List<String>.from(json['mentionedAdminIds'] as List? ?? []),
      reactions: reactionsMap,
      attachmentUrls:
          List<String>.from(json['attachmentUrls'] as List? ?? []),
      isEdited: json['isEdited'] as bool? ?? false,
    );
  }
}

/// Represents a discussion thread
class DiscussionThread {
  final String threadId;
  final String title;
  final String description;
  final String createdByAdminId;
  final String createdByAdminName;
  final DiscussionTopic topic;
  final DateTime createdAt;
  final DateTime? closedAt;
  final String? closedByAdminId;
  final String? relatedEntityType; // 'escalation', 'seller', etc.
  final String? relatedEntityId;
  final List<DiscussionComment> comments;
  final List<String> participantAdminIds;
  final List<String> watcherAdminIds;
  final bool isClosed;
  final int? priority; // 1-5, higher = more important

  DiscussionThread({
    required this.threadId,
    required this.title,
    required this.description,
    required this.createdByAdminId,
    required this.createdByAdminName,
    required this.topic,
    required this.createdAt,
    this.closedAt,
    this.closedByAdminId,
    this.relatedEntityType,
    this.relatedEntityId,
    this.comments = const [],
    this.participantAdminIds = const [],
    this.watcherAdminIds = const [],
    this.isClosed = false,
    this.priority,
  });

  /// Get thread summary (first comment + count)
  String getSummary() {
    final commentCount = comments.length;
    final participantCount = participantAdminIds.length;
    return '$commentCount comments • $participantCount participants';
  }

  /// Create copy with updates
  DiscussionThread copyWith({
    String? threadId,
    String? title,
    String? description,
    String? createdByAdminId,
    String? createdByAdminName,
    DiscussionTopic? topic,
    DateTime? createdAt,
    DateTime? closedAt,
    String? closedByAdminId,
    String? relatedEntityType,
    String? relatedEntityId,
    List<DiscussionComment>? comments,
    List<String>? participantAdminIds,
    List<String>? watcherAdminIds,
    bool? isClosed,
    int? priority,
  }) {
    return DiscussionThread(
      threadId: threadId ?? this.threadId,
      title: title ?? this.title,
      description: description ?? this.description,
      createdByAdminId: createdByAdminId ?? this.createdByAdminId,
      createdByAdminName: createdByAdminName ?? this.createdByAdminName,
      topic: topic ?? this.topic,
      createdAt: createdAt ?? this.createdAt,
      closedAt: closedAt ?? this.closedAt,
      closedByAdminId: closedByAdminId ?? this.closedByAdminId,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      comments: comments ?? this.comments,
      participantAdminIds: participantAdminIds ?? this.participantAdminIds,
      watcherAdminIds: watcherAdminIds ?? this.watcherAdminIds,
      isClosed: isClosed ?? this.isClosed,
      priority: priority ?? this.priority,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'threadId': threadId,
    'title': title,
    'description': description,
    'createdByAdminId': createdByAdminId,
    'createdByAdminName': createdByAdminName,
    'topic': topic.name,
    'createdAt': createdAt.toIso8601String(),
    'closedAt': closedAt?.toIso8601String(),
    'closedByAdminId': closedByAdminId,
    'relatedEntityType': relatedEntityType,
    'relatedEntityId': relatedEntityId,
    'comments': comments.map((c) => c.toJson()).toList(),
    'participantAdminIds': participantAdminIds,
    'watcherAdminIds': watcherAdminIds,
    'isClosed': isClosed,
    'priority': priority,
  };

  /// Create from JSON
  factory DiscussionThread.fromJson(Map<String, dynamic> json) {
    return DiscussionThread(
      threadId: json['threadId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      createdByAdminId: json['createdByAdminId'] as String,
      createdByAdminName: json['createdByAdminName'] as String,
      topic: DiscussionTopic.values.firstWhere(
        (t) => t.name == json['topic'],
        orElse: () => DiscussionTopic.GENERAL_DISCUSSION,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      closedAt: json['closedAt'] != null
          ? DateTime.parse(json['closedAt'] as String)
          : null,
      closedByAdminId: json['closedByAdminId'] as String?,
      relatedEntityType: json['relatedEntityType'] as String?,
      relatedEntityId: json['relatedEntityId'] as String?,
      comments: (json['comments'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map((c) => DiscussionComment.fromJson(c))
          .toList(),
      participantAdminIds:
          List<String>.from(json['participantAdminIds'] as List? ?? []),
      watcherAdminIds:
          List<String>.from(json['watcherAdminIds'] as List? ?? []),
      isClosed: json['isClosed'] as bool? ?? false,
      priority: json['priority'] as int?,
    );
  }
}

/// Service for managing discussion threads
class AdminDiscussionService {
  static final List<DiscussionThread> _threads = [];
  static int _threadIdCounter = 3000;
  static int _commentIdCounter = 10000;

  /// Create new discussion thread
  static Future<DiscussionThread> createThread({
    required String title,
    required String description,
    required String createdByAdminId,
    required String createdByAdminName,
    required DiscussionTopic topic,
    String? relatedEntityType,
    String? relatedEntityId,
    List<String> initialWatchers = const [],
  }) async {
    try {
      LoggerService.info('Creating discussion thread: $title');

      final threadId = 'thread_${_threadIdCounter++}';
      final thread = DiscussionThread(
        threadId: threadId,
        title: title,
        description: description,
        createdByAdminId: createdByAdminId,
        createdByAdminName: createdByAdminName,
        topic: topic,
        createdAt: DateTime.now(),
        relatedEntityType: relatedEntityType,
        relatedEntityId: relatedEntityId,
        participantAdminIds: [createdByAdminId],
        watcherAdminIds: [createdByAdminId, ...initialWatchers],
      );

      _threads.add(thread);

      LoggerService.info('Discussion thread created: $threadId');
      return thread;
    } catch (e) {
      LoggerService.error('Failed to create thread: $e');
      rethrow;
    }
  }

  /// Add comment to thread
  static Future<DiscussionThread> addComment({
    required String threadId,
    required String adminId,
    required String adminName,
    required String content,
    String? parentCommentId,
    List<String> attachmentUrls = const [],
  }) async {
    try {
      LoggerService.info('Adding comment to thread: $threadId');

      final threadIndex = _threads.indexWhere((t) => t.threadId == threadId);
      if (threadIndex == -1) throw Exception('Thread not found');

      final thread = _threads[threadIndex];
      if (thread.isClosed) {
        throw Exception('Cannot comment on closed thread');
      }

      // Extract mentions
      final mentionedAdmins = _extractMentions(content);

      final comment = DiscussionComment(
        commentId: 'comment_${_commentIdCounter++}',
        adminId: adminId,
        adminName: adminName,
        content: content,
        createdAt: DateTime.now(),
        parentCommentId: parentCommentId,
        mentionedAdminIds: mentionedAdmins,
        attachmentUrls: attachmentUrls,
      );

      // Update thread
      final comments = List<DiscussionComment>.from(thread.comments);
      comments.add(comment);

      final participants = {
        ...thread.participantAdminIds,
        adminId,
        ...mentionedAdmins,
      }.toList();

      final watchers = {
        ...thread.watcherAdminIds,
        adminId,
        ...mentionedAdmins,
      }.toList();

      final updated = thread.copyWith(
        comments: comments,
        participantAdminIds: participants,
        watcherAdminIds: watchers,
      );

      _threads[threadIndex] = updated;

      LoggerService.info('Comment added to thread: $threadId');
      return updated;
    } catch (e) {
      LoggerService.error('Failed to add comment: $e');
      rethrow;
    }
  }

  /// Edit comment
  static Future<DiscussionThread> editComment({
    required String threadId,
    required String commentId,
    required String newContent,
    required String editingAdminId,
  }) async {
    try {
      LoggerService.info('Editing comment: $commentId');

      final threadIndex = _threads.indexWhere((t) => t.threadId == threadId);
      if (threadIndex == -1) throw Exception('Thread not found');

      final thread = _threads[threadIndex];
      final commentIndex =
          thread.comments.indexWhere((c) => c.commentId == commentId);
      if (commentIndex == -1) throw Exception('Comment not found');

      final comment = thread.comments[commentIndex];
      if (comment.adminId != editingAdminId) {
        throw Exception('Only comment creator can edit');
      }

      // Extract new mentions
      final mentionedAdmins = _extractMentions(newContent);

      final updatedComment = comment.copyWith(
        content: newContent,
        updatedAt: DateTime.now(),
        mentionedAdminIds: mentionedAdmins,
        isEdited: true,
      );

      final comments = List<DiscussionComment>.from(thread.comments);
      comments[commentIndex] = updatedComment;

      final updated = thread.copyWith(comments: comments);
      _threads[threadIndex] = updated;

      LoggerService.info('Comment edited: $commentId');
      return updated;
    } catch (e) {
      LoggerService.error('Failed to edit comment: $e');
      rethrow;
    }
  }

  /// Delete comment
  static Future<DiscussionThread> deleteComment({
    required String threadId,
    required String commentId,
    required String deletingAdminId,
    bool isSuperAdmin = false,
  }) async {
    try {
      LoggerService.info('Deleting comment: $commentId');

      final threadIndex = _threads.indexWhere((t) => t.threadId == threadId);
      if (threadIndex == -1) throw Exception('Thread not found');

      final thread = _threads[threadIndex];
      final commentIndex =
          thread.comments.indexWhere((c) => c.commentId == commentId);
      if (commentIndex == -1) throw Exception('Comment not found');

      final comment = thread.comments[commentIndex];
      if (!isSuperAdmin && comment.adminId != deletingAdminId) {
        throw Exception('Only comment creator or super admin can delete');
      }

      final comments = List<DiscussionComment>.from(thread.comments);
      comments.removeAt(commentIndex);

      final updated = thread.copyWith(comments: comments);
      _threads[threadIndex] = updated;

      LoggerService.info('Comment deleted: $commentId');
      return updated;
    } catch (e) {
      LoggerService.error('Failed to delete comment: $e');
      rethrow;
    }
  }

  /// Add reaction to comment
  static Future<DiscussionThread> addReaction({
    required String threadId,
    required String commentId,
    required ReactionType reactionType,
    required String adminId,
  }) async {
    try {
      LoggerService.info('Adding reaction to comment: $commentId');

      final threadIndex = _threads.indexWhere((t) => t.threadId == threadId);
      if (threadIndex == -1) throw Exception('Thread not found');

      final thread = _threads[threadIndex];
      final commentIndex =
          thread.comments.indexWhere((c) => c.commentId == commentId);
      if (commentIndex == -1) throw Exception('Comment not found');

      final comment = thread.comments[commentIndex];
      final updatedComment = comment.addReaction(reactionType, adminId);

      final comments = List<DiscussionComment>.from(thread.comments);
      comments[commentIndex] = updatedComment;

      final updated = thread.copyWith(comments: comments);
      _threads[threadIndex] = updated;

      LoggerService.info('Reaction added: $commentId');
      return updated;
    } catch (e) {
      LoggerService.error('Failed to add reaction: $e');
      rethrow;
    }
  }

  /// Get thread
  static Future<DiscussionThread> getThread(String threadId) async {
    try {
      final thread = _threads.firstWhere(
        (t) => t.threadId == threadId,
        orElse: () => throw Exception('Thread not found'),
      );

      LoggerService.info('Retrieved thread: $threadId');
      return thread;
    } catch (e) {
      LoggerService.error('Failed to get thread: $e');
      rethrow;
    }
  }

  /// Get active threads
  static Future<List<DiscussionThread>> getActiveThreads({
    DiscussionTopic? topic,
    String? adminId,
  }) async {
    try {
      var threads = _threads.where((t) => !t.isClosed).toList();

      if (topic != null) {
        threads = threads.where((t) => t.topic == topic).toList();
      }

      if (adminId != null) {
        threads = threads
            .where((t) =>
                t.participantAdminIds.contains(adminId) ||
                t.watcherAdminIds.contains(adminId))
            .toList();
      }

      // Sort by priority and date
      threads.sort((a, b) {
        final aPriority = a.priority ?? 0;
        final bPriority = b.priority ?? 0;
        if (aPriority != bPriority) {
          return bPriority.compareTo(aPriority);
        }
        return b.createdAt.compareTo(a.createdAt);
      });

      LoggerService.info('Retrieved ${threads.length} active threads');
      return threads;
    } catch (e) {
      LoggerService.error('Failed to get active threads: $e');
      rethrow;
    }
  }

  /// Close thread
  static Future<DiscussionThread> closeThread({
    required String threadId,
    required String closedByAdminId,
  }) async {
    try {
      LoggerService.info('Closing thread: $threadId');

      final threadIndex = _threads.indexWhere((t) => t.threadId == threadId);
      if (threadIndex == -1) throw Exception('Thread not found');

      final thread = _threads[threadIndex];
      final updated = thread.copyWith(
        isClosed: true,
        closedAt: DateTime.now(),
        closedByAdminId: closedByAdminId,
      );

      _threads[threadIndex] = updated;

      LoggerService.info('Thread closed: $threadId');
      return updated;
    } catch (e) {
      LoggerService.error('Failed to close thread: $e');
      rethrow;
    }
  }

  /// Get threads for entity
  static Future<List<DiscussionThread>> getEntityThreads({
    required String entityType,
    required String entityId,
  }) async {
    try {
      final threads = _threads
          .where((t) =>
              t.relatedEntityType == entityType &&
              t.relatedEntityId == entityId)
          .toList();

      LoggerService.info(
        'Retrieved ${threads.length} threads for $entityType:$entityId',
      );
      return threads;
    } catch (e) {
      LoggerService.error('Failed to get entity threads: $e');
      rethrow;
    }
  }

  /// Helper: Extract @mentions from content
  static List<String> _extractMentions(String content) {
    final regex = RegExp(r'@(\w+)');
    final matches = regex.allMatches(content);
    return matches
        .map((m) => m.group(1) ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Get statistics
  static Future<Map<String, dynamic>> getDiscussionStatistics() async {
    try {
      final stats = {
        'totalThreads': _threads.length,
        'activeThreads': _threads.where((t) => !t.isClosed).length,
        'closedThreads': _threads.where((t) => t.isClosed).length,
        'totalComments': _threads.fold<int>(
          0,
          (sum, t) => sum + t.comments.length,
        ),
        'threadsByTopic': {
          for (final topic in DiscussionTopic.values)
            topic.name: _threads.where((t) => t.topic == topic).length,
        },
      };

      LoggerService.info('Discussion statistics: ${stats['totalThreads']} threads');
      return stats;
    } catch (e) {
      LoggerService.error('Failed to get discussion statistics: $e');
      rethrow;
    }
  }
}
