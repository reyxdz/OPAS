/// Reusable Admin Note Components for Phase 4.4: Admin Collaboration
/// Components for displaying, creating, and managing admin notes
/// 
/// Architecture: Composable widgets with separation of concerns
/// - admin_note_card: Individual note display
/// - note_input_dialog: Create/edit notes
/// - admin_notes_section: List with filtering and pagination

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opas_flutter/core/services/logger_service.dart';
import 'package:opas_flutter/features/admin_panel/services/admin_note_service.dart';

/// Individual note card widget
class AdminNoteCard extends StatefulWidget {
  final AdminNote note;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleLike;
  final bool canEdit;
  final bool showActions;

  const AdminNoteCard({
    Key? key,
    required this.note,
    this.onEdit,
    this.onDelete,
    this.onTogglePin,
    this.onToggleLike,
    this.canEdit = false,
    this.showActions = true,
  }) : super(key: key);

  @override
  State<AdminNoteCard> createState() => _AdminNoteCardState();
}

class _AdminNoteCardState extends State<AdminNoteCard> {
  late AdminNote _note;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
  }

  @override
  void didUpdateWidget(AdminNoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.noteId != widget.note.noteId) {
      _note = widget.note;
    }
  }

  Color _getVisibilityColor() {
    switch (_note.visibility) {
      case NoteVisibility.PRIVATE:
        return Colors.orange;
      case NoteVisibility.TEAM:
        return Colors.blue;
      case NoteVisibility.PUBLIC:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final isPinned = _note.isPinned;
    final likeCount = _note.likeCount ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          border: isPinned ? const Border(left: BorderSide(color: Colors.amber, width: 4)) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Admin name, timestamp, visibility
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              child: Text(
                                _note.adminName.isNotEmpty
                                    ? _note.adminName[0].toUpperCase()
                                    : 'A',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _note.adminName,
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  Text(
                                    dateFormat.format(_note.createdAt),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  if (_note.updatedAt != null)
                                    Text(
                                      '(edited ${dateFormat.format(_note.updatedAt!)})',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(fontStyle: FontStyle.italic),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Visibility badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getVisibilityColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _note.visibility.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getVisibilityColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Content
              Text(
                _note.content,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),

              // Mentions
              if (_note.mentionedAdminIds.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: _note.mentionedAdminIds
                      .map(
                        (adminId) => Chip(
                          label: Text('@$adminId'),
                          backgroundColor: Colors.blue.withOpacity(0.2),
                          labelStyle: const TextStyle(fontSize: 12),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),

              if (_note.mentionedAdminIds.isNotEmpty) const SizedBox(height: 12),

              // Actions: Like, Pin, Edit, Delete
              if (widget.showActions)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Like button
                        InkWell(
                          onTap: widget.onToggleLike,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.favorite,
                                  size: 16,
                                  color: likeCount > 0 ? Colors.red : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  likeCount > 0 ? '$likeCount' : '0',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Pin button
                        InkWell(
                          onTap: widget.onTogglePin,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Icon(
                              isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                              size: 16,
                              color: isPinned ? Colors.amber : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Edit/Delete buttons
                    if (widget.canEdit)
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: widget.onEdit,
                            tooltip: 'Edit note',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18),
                            onPressed: widget.onDelete,
                            tooltip: 'Delete note',
                          ),
                        ],
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Note input dialog for creating/editing notes
class NoteInputDialog extends StatefulWidget {
  final AdminNote? existingNote;
  final String adminId;
  final String adminName;
  final NoteEntityType entityType;
  final String entityId;
  final bool isEditing;

  const NoteInputDialog({
    Key? key,
    this.existingNote,
    required this.adminId,
    required this.adminName,
    required this.entityType,
    required this.entityId,
    this.isEditing = false,
  }) : super(key: key);

  @override
  State<NoteInputDialog> createState() => _NoteInputDialogState();
}

class _NoteInputDialogState extends State<NoteInputDialog> {
  late TextEditingController _contentController;
  late NoteVisibility _visibility;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _contentController =
        TextEditingController(text: widget.existingNote?.content ?? '');
    _visibility = widget.existingNote?.visibility ?? NoteVisibility.TEAM;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note content cannot be empty')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final mentions = AdminNoteService.extractMentions(_contentController.text);

      if (widget.isEditing && widget.existingNote != null) {
        await AdminNoteService.updateNote(
          noteId: widget.existingNote!.noteId,
          updatingAdminId: widget.adminId,
          updatingAdminName: widget.adminName,
          content: _contentController.text,
          visibility: _visibility,
          mentionedAdminIds: mentions,
        );
        LoggerService.info('Note updated successfully');
      } else {
        await AdminNoteService.createNote(
          adminId: widget.adminId,
          adminName: widget.adminName,
          entityType: widget.entityType,
          entityId: widget.entityId,
          content: _contentController.text,
          visibility: _visibility,
          mentionedAdminIds: mentions,
        );
        LoggerService.info('Note created successfully');
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      LoggerService.error('Failed to save note: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving note: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit Note' : 'Add Note'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content input
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter your note (use @adminId to mention)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Visibility selector
            Text(
              'Visibility',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            SegmentedButton<NoteVisibility>(
              segments: const [
                ButtonSegment(
                  value: NoteVisibility.PRIVATE,
                  label: Text('Private'),
                  icon: Icon(Icons.lock),
                ),
                ButtonSegment(
                  value: NoteVisibility.TEAM,
                  label: Text('Team'),
                  icon: Icon(Icons.people),
                ),
                ButtonSegment(
                  value: NoteVisibility.PUBLIC,
                  label: Text('Public'),
                  icon: Icon(Icons.public),
                ),
              ],
              selected: {_visibility},
              onSelectionChanged: (Set<NoteVisibility> newSelection) {
                setState(() => _visibility = newSelection.first);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveNote,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.isEditing ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}

/// Notes section widget for displaying notes with filters
class AdminNotesSection extends StatefulWidget {
  final NoteEntityType entityType;
  final String entityId;
  final String? currentAdminId;
  final bool showCreateButton;
  final TextEditingController? searchController;

  const AdminNotesSection({
    Key? key,
    required this.entityType,
    required this.entityId,
    this.currentAdminId,
    this.showCreateButton = true,
    this.searchController,
  }) : super(key: key);

  @override
  State<AdminNotesSection> createState() => _AdminNotesSectionState();
}

class _AdminNotesSectionState extends State<AdminNotesSection> {
  late Future<List<AdminNote>> _notesFuture;
  bool _showPinnedOnly = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    _notesFuture = AdminNoteService.getEntityNotes(
      entityType: widget.entityType,
      entityId: widget.entityId,
      viewingAdminId: widget.currentAdminId,
      isPinned: _showPinnedOnly ? true : null,
    );
  }

  Future<void> _showNoteDialog({AdminNote? noteToEdit}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => NoteInputDialog(
        existingNote: noteToEdit,
        adminId: widget.currentAdminId ?? 'admin_000',
        adminName: 'Current Admin',
        entityType: widget.entityType,
        entityId: widget.entityId,
        isEditing: noteToEdit != null,
      ),
    );

    if (result == true && mounted) {
      setState(() => _loadNotes());
    }
  }

  Future<void> _deleteNote(AdminNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminNoteService.deleteNote(
          noteId: note.noteId,
          deletingAdminId: widget.currentAdminId ?? 'admin_000',
        );
        if (mounted) {
          setState(() => _loadNotes());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title and action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Notes & Comments',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (widget.showCreateButton)
              ElevatedButton.icon(
                onPressed: () => _showNoteDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Note'),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Filter buttons
        Row(
          children: [
            FilterChip(
              label: const Text('Pinned Only'),
              selected: _showPinnedOnly,
              onSelected: (selected) {
                setState(() {
                  _showPinnedOnly = selected;
                  _loadNotes();
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Notes list
        FutureBuilder<List<AdminNote>>(
          future: _notesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading notes: ${snapshot.error}'),
              );
            }

            final notes = snapshot.data ?? [];

            if (notes.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    _showPinnedOnly
                        ? 'No pinned notes'
                        : 'No notes yet. Create one to get started!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                final isOwner = note.adminId == widget.currentAdminId;

                return AdminNoteCard(
                  note: note,
                  canEdit: isOwner,
                  onEdit: isOwner ? () => _showNoteDialog(noteToEdit: note) : null,
                  onDelete: isOwner ? () => _deleteNote(note) : null,
                  onTogglePin: isOwner
                      ? () async {
                          await AdminNoteService.togglePinNote(
                            noteId: note.noteId,
                            adminId: widget.currentAdminId ?? 'admin_000',
                          );
                          if (mounted) {
                            setState(() => _loadNotes());
                          }
                        }
                      : null,
                  onToggleLike: () async {
                    await AdminNoteService.toggleLikeNote(
                      noteId: note.noteId,
                      adminId: widget.currentAdminId ?? 'admin_000',
                    );
                    if (mounted) {
                      setState(() => _loadNotes());
                    }
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}
