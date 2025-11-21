/// AdminNote Service for Phase 4.4: Admin Collaboration
/// Centralized management of admin notes across sellers, violations, OPAS submissions
/// 
/// Architecture: Entity-based note system with filtering and timestamps
/// Supports rich text (mentions), visibility control, and audit trail

import 'package:opas_flutter/core/services/logger_service.dart';

// ignore_for_file: constant_identifier_names

/// Entity types that can have admin notes
enum NoteEntityType {
  SELLER,
  SELLER_VIOLATION,
  OPAS_SUBMISSION,
  MARKETPLACE_LISTING,
  PRICE_VIOLATION,
  ESCALATION,
}

/// Note visibility levels
enum NoteVisibility {
  PRIVATE, // Only note creator can see
  TEAM, // All admins can see
  PUBLIC, // Visible to relevant stakeholders
}

/// Represents an admin note/comment on an entity
class AdminNote {
  final String noteId;
  final String adminId;
  final String adminName;
  final NoteEntityType entityType;
  final String entityId;
  final String content;
  final NoteVisibility visibility;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? updatedByAdminId;
  final List<String> mentionedAdminIds; // For @mentions
  final bool isPinned;
  final int? likeCount;
  final List<String> likedByAdminIds;

  AdminNote({
    required this.noteId,
    required this.adminId,
    required this.adminName,
    required this.entityType,
    required this.entityId,
    required this.content,
    required this.visibility,
    required this.createdAt,
    this.updatedAt,
    this.updatedByAdminId,
    this.mentionedAdminIds = const [],
    this.isPinned = false,
    this.likeCount = 0,
    this.likedByAdminIds = const [],
  });

  /// Create a copy with updated fields
  AdminNote copyWith({
    String? noteId,
    String? adminId,
    String? adminName,
    NoteEntityType? entityType,
    String? entityId,
    String? content,
    NoteVisibility? visibility,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedByAdminId,
    List<String>? mentionedAdminIds,
    bool? isPinned,
    int? likeCount,
    List<String>? likedByAdminIds,
  }) {
    return AdminNote(
      noteId: noteId ?? this.noteId,
      adminId: adminId ?? this.adminId,
      adminName: adminName ?? this.adminName,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      content: content ?? this.content,
      visibility: visibility ?? this.visibility,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByAdminId: updatedByAdminId ?? this.updatedByAdminId,
      mentionedAdminIds: mentionedAdminIds ?? this.mentionedAdminIds,
      isPinned: isPinned ?? this.isPinned,
      likeCount: likeCount ?? this.likeCount,
      likedByAdminIds: likedByAdminIds ?? this.likedByAdminIds,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'noteId': noteId,
    'adminId': adminId,
    'adminName': adminName,
    'entityType': entityType.name,
    'entityId': entityId,
    'content': content,
    'visibility': visibility.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'updatedByAdminId': updatedByAdminId,
    'mentionedAdminIds': mentionedAdminIds,
    'isPinned': isPinned,
    'likeCount': likeCount,
    'likedByAdminIds': likedByAdminIds,
  };

  /// Create from JSON
  factory AdminNote.fromJson(Map<String, dynamic> json) {
    return AdminNote(
      noteId: json['noteId'] as String,
      adminId: json['adminId'] as String,
      adminName: json['adminName'] as String,
      entityType: NoteEntityType.values.firstWhere(
        (type) => type.name == json['entityType'],
        orElse: () => NoteEntityType.SELLER,
      ),
      entityId: json['entityId'] as String,
      content: json['content'] as String,
      visibility: NoteVisibility.values.firstWhere(
        (vis) => vis.name == json['visibility'],
        orElse: () => NoteVisibility.TEAM,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      updatedByAdminId: json['updatedByAdminId'] as String?,
      mentionedAdminIds:
          List<String>.from(json['mentionedAdminIds'] as List? ?? []),
      isPinned: json['isPinned'] as bool? ?? false,
      likeCount: json['likeCount'] as int? ?? 0,
      likedByAdminIds:
          List<String>.from(json['likedByAdminIds'] as List? ?? []),
    );
  }
}

/// Service for managing admin notes with CRUD operations
class AdminNoteService {
  // In-memory storage (would be replaced with backend API)
  static final List<AdminNote> _notes = [];
  static int _noteIdCounter = 1000;

  /// Create a new note
  static Future<AdminNote> createNote({
    required String adminId,
    required String adminName,
    required NoteEntityType entityType,
    required String entityId,
    required String content,
    NoteVisibility visibility = NoteVisibility.TEAM,
    List<String> mentionedAdminIds = const [],
  }) async {
    try {
      LoggerService.info('Creating admin note for $entityType:$entityId');

      final noteId = 'note_${_noteIdCounter++}';
      final note = AdminNote(
        noteId: noteId,
        adminId: adminId,
        adminName: adminName,
        entityType: entityType,
        entityId: entityId,
        content: content,
        visibility: visibility,
        createdAt: DateTime.now(),
        mentionedAdminIds: mentionedAdminIds,
      );

      _notes.add(note);

      LoggerService.info('Admin note created: $noteId');
      return note;
    } catch (e) {
      LoggerService.error('Failed to create note: $e');
      rethrow;
    }
  }

  /// Update an existing note (only by original creator)
  static Future<AdminNote> updateNote({
    required String noteId,
    required String updatingAdminId,
    required String updatingAdminName,
    String? content,
    NoteVisibility? visibility,
    List<String>? mentionedAdminIds,
  }) async {
    try {
      LoggerService.info('Updating note: $noteId');

      final noteIndex = _notes.indexWhere((n) => n.noteId == noteId);
      if (noteIndex == -1) {
        throw Exception('Note not found');
      }

      final note = _notes[noteIndex];
      if (note.adminId != updatingAdminId) {
        throw Exception('Only the note creator can update this note');
      }

      final updatedNote = note.copyWith(
        content: content ?? note.content,
        visibility: visibility ?? note.visibility,
        mentionedAdminIds: mentionedAdminIds ?? note.mentionedAdminIds,
        updatedAt: DateTime.now(),
        updatedByAdminId: updatingAdminId,
      );

      _notes[noteIndex] = updatedNote;

      LoggerService.info('Note updated: $noteId');
      return updatedNote;
    } catch (e) {
      LoggerService.error('Failed to update note: $e');
      rethrow;
    }
  }

  /// Delete a note (only by creator or super admin)
  static Future<void> deleteNote({
    required String noteId,
    required String deletingAdminId,
    bool isSuperAdmin = false,
  }) async {
    try {
      LoggerService.info('Deleting note: $noteId');

      final note = _notes.firstWhere(
        (n) => n.noteId == noteId,
        orElse: () => throw Exception('Note not found'),
      );

      if (!isSuperAdmin && note.adminId != deletingAdminId) {
        throw Exception('Only the note creator or super admin can delete this');
      }

      _notes.removeWhere((n) => n.noteId == noteId);

      LoggerService.info('Note deleted: $noteId');
    } catch (e) {
      LoggerService.error('Failed to delete note: $e');
      rethrow;
    }
  }

  /// Get notes for a specific entity
  static Future<List<AdminNote>> getEntityNotes({
    required NoteEntityType entityType,
    required String entityId,
    String? viewingAdminId,
    bool? isPinned,
  }) async {
    try {
      var notes = _notes
          .where((n) => n.entityType == entityType && n.entityId == entityId)
          .toList();

      // Filter by visibility
      if (viewingAdminId != null) {
        notes = notes.where((n) {
          if (n.visibility == NoteVisibility.PRIVATE) {
            return n.adminId == viewingAdminId;
          } else if (n.visibility == NoteVisibility.TEAM) {
            return true; // All admins can see team notes
          } else {
            return true; // Public notes visible to all
          }
        }).toList();
      }

      // Filter by pinned status
      if (isPinned != null) {
        notes = notes.where((n) => n.isPinned == isPinned).toList();
      }

      // Sort: pinned first, then by date descending
      notes.sort((a, b) {
        if (a.isPinned != b.isPinned) {
          return a.isPinned ? -1 : 1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });

      LoggerService.info('Retrieved ${notes.length} notes for $entityType:$entityId');
      return notes;
    } catch (e) {
      LoggerService.error('Failed to get entity notes: $e');
      rethrow;
    }
  }

  /// Get notes by admin
  static Future<List<AdminNote>> getAdminNotes({
    required String adminId,
    DateTime? fromDate,
    DateTime? toDate,
    NoteEntityType? entityType,
  }) async {
    try {
      var notes = _notes.where((n) => n.adminId == adminId).toList();

      if (fromDate != null) {
        notes = notes.where((n) => n.createdAt.isAfter(fromDate)).toList();
      }

      if (toDate != null) {
        notes = notes.where((n) => n.createdAt.isBefore(toDate)).toList();
      }

      if (entityType != null) {
        notes = notes.where((n) => n.entityType == entityType).toList();
      }

      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      LoggerService.info('Retrieved ${notes.length} notes for admin: $adminId');
      return notes;
    } catch (e) {
      LoggerService.error('Failed to get admin notes: $e');
      rethrow;
    }
  }

  /// Pin/unpin a note (team visible)
  static Future<AdminNote> togglePinNote({
    required String noteId,
    required String adminId,
  }) async {
    try {
      LoggerService.info('Toggling pin status for note: $noteId');

      final noteIndex = _notes.indexWhere((n) => n.noteId == noteId);
      if (noteIndex == -1) {
        throw Exception('Note not found');
      }

      final note = _notes[noteIndex];
      final updatedNote = note.copyWith(isPinned: !note.isPinned);
      _notes[noteIndex] = updatedNote;

      LoggerService.info('Note pin toggled: $noteId');
      return updatedNote;
    } catch (e) {
      LoggerService.error('Failed to toggle pin: $e');
      rethrow;
    }
  }

  /// Like/unlike a note
  static Future<AdminNote> toggleLikeNote({
    required String noteId,
    required String adminId,
  }) async {
    try {
      LoggerService.info('Toggling like for note: $noteId');

      final noteIndex = _notes.indexWhere((n) => n.noteId == noteId);
      if (noteIndex == -1) {
        throw Exception('Note not found');
      }

      final note = _notes[noteIndex];
      final likedByAdminIds = List<String>.from(note.likedByAdminIds);

      if (likedByAdminIds.contains(adminId)) {
        likedByAdminIds.remove(adminId);
      } else {
        likedByAdminIds.add(adminId);
      }

      final updatedNote = note.copyWith(
        likeCount: likedByAdminIds.length,
        likedByAdminIds: likedByAdminIds,
      );
      _notes[noteIndex] = updatedNote;

      LoggerService.info('Note like toggled: $noteId');
      return updatedNote;
    } catch (e) {
      LoggerService.error('Failed to toggle like: $e');
      rethrow;
    }
  }

  /// Get mentioned admins from note content
  static List<String> extractMentions(String content) {
    final regex = RegExp(r'@(\w+)');
    final matches = regex.allMatches(content);
    return matches.map((m) => m.group(1) ?? '').where((s) => s.isNotEmpty).toList();
  }

  /// Search notes
  static Future<List<AdminNote>> searchNotes({
    required String query,
    NoteEntityType? entityType,
    String? adminId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var notes = _notes
          .where((n) => n.content.toLowerCase().contains(query.toLowerCase()))
          .toList();

      if (entityType != null) {
        notes = notes.where((n) => n.entityType == entityType).toList();
      }

      if (adminId != null) {
        notes = notes.where((n) => n.adminId == adminId).toList();
      }

      if (fromDate != null) {
        notes = notes.where((n) => n.createdAt.isAfter(fromDate)).toList();
      }

      if (toDate != null) {
        notes = notes.where((n) => n.createdAt.isBefore(toDate)).toList();
      }

      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      LoggerService.info('Found ${notes.length} notes matching query: $query');
      return notes;
    } catch (e) {
      LoggerService.error('Failed to search notes: $e');
      rethrow;
    }
  }

  /// Get statistics on notes
  static Future<Map<String, dynamic>> getNotesStatistics({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var notes = _notes;

      if (fromDate != null) {
        notes = notes.where((n) => n.createdAt.isAfter(fromDate)).toList();
      }

      if (toDate != null) {
        notes = notes.where((n) => n.createdAt.isBefore(toDate)).toList();
      }

      final adminNoteCount = <String, int>{};
      for (final note in notes) {
        adminNoteCount[note.adminId] = (adminNoteCount[note.adminId] ?? 0) + 1;
      }

      final stats = {
        'totalNotes': notes.length,
        'notesByAdmin': adminNoteCount,
        'notesByEntityType': {
          for (final type in NoteEntityType.values)
            type.name: notes.where((n) => n.entityType == type).length,
        },
        'pinnedNotes': notes.where((n) => n.isPinned).length,
        'mentionedNotesCount': notes.where((n) => n.mentionedAdminIds.isNotEmpty).length,
      };

      LoggerService.info('Note statistics: ${stats['totalNotes']} total notes');
      return stats;
    } catch (e) {
      LoggerService.error('Failed to get notes statistics: $e');
      rethrow;
    }
  }
}
