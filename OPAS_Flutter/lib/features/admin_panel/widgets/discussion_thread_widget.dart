/// Discussion Thread Widgets for Phase 4.4: Admin Collaboration
/// UI components for displaying and managing discussion threads
/// 
/// Architecture: Composable widgets for thread display, commenting, and collaboration
/// Features: Thread view, comment rendering, mention system, reactions

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opas_flutter/core/services/logger_service.dart';
import 'package:opas_flutter/features/admin_panel/services/admin_discussion_service.dart';

/// Widget for a single discussion comment
class DiscussionCommentCard extends StatefulWidget {
  final DiscussionComment comment;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAddReaction;
  final bool canEdit;
  final int? depth; // For reply threading

  const DiscussionCommentCard({
    Key? key,
    required this.comment,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onAddReaction,
    this.canEdit = false,
    this.depth = 0,
  }) : super(key: key);

  @override
  State<DiscussionCommentCard> createState() => _DiscussionCommentCardState();
}

class _DiscussionCommentCardState extends State<DiscussionCommentCard> {
  final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

  @override
  Widget build(BuildContext context) {
    final depth = widget.depth ?? 0;
    final leftPadding = (depth * 16.0).clamp(0.0, 48.0);

    return Padding(
      padding: EdgeInsets.only(left: leftPadding),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Admin info and timestamp
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        child: Text(
                          widget.comment.adminName.isNotEmpty
                              ? widget.comment.adminName[0].toUpperCase()
                              : 'A',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.comment.adminName,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            dateFormat.format(widget.comment.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (widget.comment.isEdited)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Chip(
                        label: const Text('Edited'),
                        backgroundColor: Colors.amber.withOpacity(0.2),
                        labelStyle: const TextStyle(fontSize: 11),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Comment content
              Text(
                widget.comment.content,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),

              // Mentions as tags
              if (widget.comment.mentionedAdminIds.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: widget.comment.mentionedAdminIds
                      .map(
                        (adminId) => Chip(
                          label: Text('@$adminId'),
                          backgroundColor: Colors.blue.withOpacity(0.2),
                          labelStyle: const TextStyle(fontSize: 11),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),

              const SizedBox(height: 12),

              // Reactions
              if (widget.comment.reactions.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: widget.comment.reactions.entries
                      .map(
                        (entry) => Chip(
                          label: Text(
                            '${_getReactionEmoji(entry.key)} ${entry.value.length}',
                          ),
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          labelStyle: const TextStyle(fontSize: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),

              const SizedBox(height: 12),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (widget.onAddReaction != null)
                        InkWell(
                          onTap: widget.onAddReaction,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.add_reaction,
                              size: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      if (widget.onReply != null)
                        InkWell(
                          onTap: widget.onReply,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.reply,
                              size: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (widget.canEdit)
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: widget.onEdit,
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18),
                          onPressed: widget.onDelete,
                          tooltip: 'Delete',
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

  String _getReactionEmoji(ReactionType type) {
    switch (type) {
      case ReactionType.LIKE:
        return '👍';
      case ReactionType.HELPFUL:
        return '✅';
      case ReactionType.DISAGREE:
        return '👎';
      case ReactionType.NEEDS_DISCUSSION:
        return '💬';
    }
  }
}

/// Widget for displaying a discussion thread
class DiscussionThreadWidget extends StatefulWidget {
  final DiscussionThread thread;
  final String? currentAdminId;
  final VoidCallback? onAddComment;
  final bool showHeader;

  const DiscussionThreadWidget({
    Key? key,
    required this.thread,
    this.currentAdminId,
    this.onAddComment,
    this.showHeader = true,
  }) : super(key: key);

  @override
  State<DiscussionThreadWidget> createState() =>
      _DiscussionThreadWidgetState();
}

class _DiscussionThreadWidgetState extends State<DiscussionThreadWidget> {
  late DiscussionThread _thread;

  @override
  void initState() {
    super.initState();
    _thread = widget.thread;
  }

  @override
  void didUpdateWidget(DiscussionThreadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.thread.threadId != widget.thread.threadId) {
      _thread = widget.thread;
    }
  }

  Color _getTopicColor() {
    switch (_thread.topic) {
      case DiscussionTopic.ESCALATION:
        return Colors.red;
      case DiscussionTopic.PRICE_POLICY:
        return Colors.orange;
      case DiscussionTopic.SELLER_ISSUE:
        return Colors.blue;
      case DiscussionTopic.OPAS_DECISION:
        return Colors.purple;
      case DiscussionTopic.GENERAL_DISCUSSION:
        return Colors.teal;
      case DiscussionTopic.COMPLIANCE_REVIEW:
        return Colors.green;
      case DiscussionTopic.SYSTEM_ISSUE:
        return Colors.brown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getTopicColor().withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _thread.topic.name.replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getTopicColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_thread.isClosed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'CLOSED',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _thread.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Started by ${_thread.createdByAdminName} on ${dateFormat.format(_thread.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),

        // Description box
        if (widget.showHeader)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _thread.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),

        if (widget.showHeader) const SizedBox(height: 24),

        // Comments section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Comments (${_thread.comments.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (widget.onAddComment != null && !_thread.isClosed)
              ElevatedButton.icon(
                onPressed: widget.onAddComment,
                icon: const Icon(Icons.comment, size: 16),
                label: const Text('Add Comment'),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Comments list
        if (_thread.comments.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No comments yet. Be the first to share your thoughts!',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _thread.comments.length,
            itemBuilder: (context, index) {
              final comment = _thread.comments[index];
              final isOwner = comment.adminId == widget.currentAdminId;

              return DiscussionCommentCard(
                comment: comment,
                canEdit: isOwner,
                depth: comment.parentCommentId != null ? 1 : 0,
              );
            },
          ),
      ],
    );
  }
}

/// Full screen discussion thread view
class DiscussionThreadScreen extends StatefulWidget {
  final String threadId;
  final String? currentAdminId;
  final String? currentAdminName;

  const DiscussionThreadScreen({
    Key? key,
    required this.threadId,
    this.currentAdminId,
    this.currentAdminName,
  }) : super(key: key);

  @override
  State<DiscussionThreadScreen> createState() =>
      _DiscussionThreadScreenState();
}

class _DiscussionThreadScreenState extends State<DiscussionThreadScreen> {
  late Future<DiscussionThread> _threadFuture;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadThread();
  }

  void _loadThread() {
    _threadFuture = AdminDiscussionService.getThread(widget.threadId);
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment cannot be empty')),
      );
      return;
    }

    try {
      await AdminDiscussionService.addComment(
        threadId: widget.threadId,
        adminId: widget.currentAdminId ?? 'admin_000',
        adminName: widget.currentAdminName ?? 'Admin',
        content: _commentController.text,
      );

      _commentController.clear();
      _loadThread();
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment added')),
        );
      }
    } catch (e) {
      LoggerService.error('Failed to add comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discussion Thread'),
        elevation: 0,
      ),
      body: FutureBuilder<DiscussionThread>(
        future: _threadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final thread = snapshot.data;
          if (thread == null) {
            return const Center(
              child: Text('Thread not found'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DiscussionThreadWidget(
                  thread: thread,
                  currentAdminId: widget.currentAdminId,
                  showHeader: true,
                ),
                const SizedBox(height: 24),

                // Comment input
                if (!thread.isClosed)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            controller: _commentController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText:
                                  'Share your thoughts (use @adminId to mention)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: _addComment,
                                child: const Text('Post Comment'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
