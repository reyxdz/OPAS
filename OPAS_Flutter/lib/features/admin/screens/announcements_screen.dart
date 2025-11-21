import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opas_flutter/core/models/announcement_model.dart';
import 'package:opas_flutter/core/services/admin_service.dart';
import 'package:opas_flutter/features/admin/widgets/announcement_card.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({Key? key}) : super(key: key);

  @override
  AnnouncementsScreenState createState() => AnnouncementsScreenState();
}

class AnnouncementsScreenState extends State<AnnouncementsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _typeFilter = 'all';
  List<AnnouncementModel> _activeAnnouncements = [];
  List<AnnouncementModel> _allAnnouncements = [];
  bool _isLoadingActive = false;
  bool _isLoadingAll = false;
  String? _errorActive;
  String? _errorAll;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAnnouncements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnnouncements() async {
    _loadActiveAnnouncements();
    _loadAllAnnouncements();
  }

  Future<void> _loadActiveAnnouncements() async {
    setState(() => _isLoadingActive = true);
    try {
      final response = await AdminService.getAnnouncements(
        status: 'published',
        type: _typeFilter != 'all' ? _typeFilter : null,
      );

      List<AnnouncementModel> announcements = response
          .map((item) =>
              AnnouncementModel.fromJson(item as Map<String, dynamic>))
          .toList();

      setState(() {
        _activeAnnouncements = announcements;
        _errorActive = null;
      });
    } catch (e) {
      setState(() => _errorActive = 'Failed to load announcements: $e');
    } finally {
      setState(() => _isLoadingActive = false);
    }
  }

  Future<void> _loadAllAnnouncements() async {
    setState(() => _isLoadingAll = true);
    try {
      final response = await AdminService.getAnnouncements(
        type: _typeFilter != 'all' ? _typeFilter : null,
      );

      List<AnnouncementModel> announcements = response
          .map((item) =>
              AnnouncementModel.fromJson(item as Map<String, dynamic>))
          .toList();

      setState(() {
        _allAnnouncements = announcements;
        _errorAll = null;
      });
    } catch (e) {
      setState(() => _errorAll = 'Failed to load announcements: $e');
    } finally {
      setState(() => _isLoadingAll = false);
    }
  }

  Future<void> _createAnnouncement(Map<String, dynamic> data) async {
    try {
      await AdminService.createAnnouncementV2(data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement created successfully')),
      );
      _loadAnnouncements();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _editAnnouncement(AnnouncementModel announcement) async {
    final titleController = TextEditingController(text: announcement.title);
    final contentController = TextEditingController(text: announcement.content);
    String selectedType = announcement.type;
    String selectedAudience = announcement.targetAudience;
    DateTime? scheduledDate = announcement.scheduledFor;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Announcement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Title'),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(8),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Content'),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(8),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                const Text('Type'),
                DropdownButton<String>(
                  value: selectedType,
                  isExpanded: true,
                  items: ['price_update', 'shortage_alert', 'policy_change', 'promotion']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.replaceAll('_', ' ')),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                const Text('Target Audience'),
                DropdownButton<String>(
                  value: selectedAudience,
                  isExpanded: true,
                  items: ['all', 'buyers', 'sellers']
                      .map((audience) => DropdownMenuItem(
                            value: audience,
                            child: Text(audience),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedAudience = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                const Text('Schedule (Optional)'),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: scheduledDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      if (!context.mounted) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() {
                          scheduledDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      scheduledDate != null
                          ? DateFormat('MMM dd, yyyy HH:mm')
                              .format(scheduledDate!)
                          : 'Select date and time',
                      style: TextStyle(
                        color: scheduledDate != null
                            ? Colors.black87
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isEmpty ||
                    contentController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields')),
                  );
                  return;
                }

                _updateAnnouncement(announcement.announcementId, {
                  'title': titleController.text,
                  'content': contentController.text,
                  'type': selectedType,
                  'target_audience': selectedAudience,
                  'scheduled_for': scheduledDate?.toIso8601String(),
                });
                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateAnnouncement(String id, Map<String, dynamic> data) async {
    try {
      await AdminService.updateAnnouncement(id, data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement updated successfully')),
      );
      _loadAnnouncements();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deleteAnnouncement(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: const Text('Are you sure you want to delete this announcement?'),
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
        await AdminService.deleteAnnouncement(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement deleted successfully')),
        );
        _loadAnnouncements();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showCreateDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedType = 'promotion';
    String selectedAudience = 'all';
    DateTime? scheduledDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Announcement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Title'),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(8),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Content'),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(8),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                const Text('Type'),
                DropdownButton<String>(
                  value: selectedType,
                  isExpanded: true,
                  items: ['price_update', 'shortage_alert', 'policy_change', 'promotion']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.replaceAll('_', ' ')),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                const Text('Target Audience'),
                DropdownButton<String>(
                  value: selectedAudience,
                  isExpanded: true,
                  items: ['all', 'buyers', 'sellers']
                      .map((audience) => DropdownMenuItem(
                            value: audience,
                            child: Text(audience),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedAudience = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                const Text('Schedule (Optional)'),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      if (!context.mounted) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() {
                          scheduledDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      scheduledDate != null
                          ? DateFormat('MMM dd, yyyy HH:mm')
                              .format(scheduledDate!)
                          : 'Select date and time',
                      style: TextStyle(
                        color: scheduledDate != null
                            ? Colors.black87
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isEmpty ||
                    contentController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields')),
                  );
                  return;
                }

                _createAnnouncement({
                  'title': titleController.text,
                  'content': contentController.text,
                  'type': selectedType,
                  'target_audience': selectedAudience,
                  'scheduled_for':
                      scheduledDate?.toIso8601String(),
                });
                Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2196F3),
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: const Color(0xFF2196F3),
          tabs: [
            Tab(text: 'Active (${_activeAnnouncements.length})'),
            const Tab(text: 'All'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveTab(),
          _buildAllTab(),
        ],
      ),
    );
  }

  Widget _buildActiveTab() {
    return Column(
      children: [
        // Type Filter
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey[50],
          child: Row(
            children: [
              const Text('Type: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTypeChip('all', 'All'),
                      const SizedBox(width: 6),
                      _buildTypeChip(
                          'price_update', 'Price Update'),
                      const SizedBox(width: 6),
                      _buildTypeChip('shortage_alert', 'Shortage'),
                      const SizedBox(width: 6),
                      _buildTypeChip('policy_change', 'Policy'),
                      const SizedBox(width: 6),
                      _buildTypeChip('promotion', 'Promotion'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Announcements List
        Expanded(
          child: _isLoadingActive
              ? const Center(child: CircularProgressIndicator())
              : _errorActive != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(_errorActive!),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadActiveAnnouncements,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _activeAnnouncements.isEmpty
                      ? const Center(
                          child: Text('No active announcements'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _activeAnnouncements.length,
                          itemBuilder: (context, index) {
                            final announcement = _activeAnnouncements[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: AnnouncementCard(
                                title: announcement.title,
                                type: announcement.type,
                                status: announcement.status,
                                targetAudience: announcement.targetAudience,
                                createdAt: announcement.createdAt,
                                scheduledFor: announcement.scheduledFor,
                                viewCount: announcement.viewCount,
                                onEdit: () {
                                  _editAnnouncement(announcement);
                                },
                                onDelete: () {
                                  _deleteAnnouncement(announcement.announcementId);
                                },
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildAllTab() {
    return _isLoadingAll
        ? const Center(child: CircularProgressIndicator())
        : _errorAll != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(_errorAll!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadAllAnnouncements,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _allAnnouncements.isEmpty
                ? const Center(
                    child: Text('No announcements found'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _allAnnouncements.length,
                    itemBuilder: (context, index) {
                      final announcement = _allAnnouncements[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AnnouncementCard(
                          title: announcement.title,
                          type: announcement.type,
                          status: announcement.status,
                          targetAudience: announcement.targetAudience,
                          createdAt: announcement.createdAt,
                          scheduledFor: announcement.scheduledFor,
                          viewCount: announcement.viewCount,
                          onEdit: () {
                            _editAnnouncement(announcement);
                          },
                          onDelete: () {
                            _deleteAnnouncement(announcement.announcementId);
                          },
                        ),
                      );
                    },
                  );
  }

  Widget _buildTypeChip(String value, String label) {
    final isSelected = _typeFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _typeFilter = value;
          _loadAnnouncements();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2196F3) : Colors.grey[100],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? const Color(0xFF2196F3) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}
