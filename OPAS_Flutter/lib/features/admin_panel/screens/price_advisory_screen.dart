import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/price_advisory_model.dart';
import '../../../core/services/admin_service.dart';
import '../widgets/advisory_card.dart';

class PriceAdvisoryScreen extends StatefulWidget {
  final String? initialProductName;
  final double? initialCeiling;

  const PriceAdvisoryScreen({
    Key? key,
    this.initialProductName,
    this.initialCeiling,
  }) : super(key: key);

  @override
  State<PriceAdvisoryScreen> createState() => _PriceAdvisoryScreenState();
}

class _PriceAdvisoryScreenState extends State<PriceAdvisoryScreen> {
  late TextEditingController _searchController;

  // Data state
  List<PriceAdvisoryModel> _advisories = [];
  List<PriceAdvisoryModel> _filteredAdvisories = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filter state
  String _selectedType = 'ALL'; // ALL, Price Update, Shortage Alert, Promotion, Market Trend
  String _selectedStatus = 'ALL'; // ALL, Active, Scheduled, Expired, Inactive

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadAdvisories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load all price advisories from API
  Future<void> _loadAdvisories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final advisories = await AdminService.getPriceAdvisories();
      setState(() {
        _advisories = (advisories)
            .map((item) => PriceAdvisoryModel.fromJson(item as Map<String, dynamic>))
            .toList();
        _applyFiltersAndSort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load advisories: $e';
        _isLoading = false;
      });
    }
  }

  /// Apply filters
  void _applyFiltersAndSort() {
    _filteredAdvisories = _advisories.where((advisory) {
      // Type filter
      if (_selectedType != 'ALL') {
        if (advisory.type != _selectedType) {
          return false;
        }
      }

      // Status filter
      if (_selectedStatus != 'ALL') {
        if (advisory.getStatus() != _selectedStatus) {
          return false;
        }
      }

      // Search filter
      final query = _searchController.text.toLowerCase();
      if (query.isNotEmpty) {
        return advisory.title.toLowerCase().contains(query) ||
            advisory.content.toLowerCase().contains(query);
      }

      return true;
    }).toList();

    // Sort by effective date (newest first)
    _filteredAdvisories.sort(
      (a, b) => b.effectiveDate.compareTo(a.effectiveDate),
    );
  }

  /// Show create/edit advisory dialog
  void _showAdvisoryDialog({PriceAdvisoryModel? advisory}) {
    showDialog(
      context: context,
      builder: (context) => CreateAdvisoryDialog(
        advisory: advisory,
        initialProductName: widget.initialProductName,
        initialCeiling: widget.initialCeiling,
        onSave: (title, content, type, targetAudience, effectiveDate,
            expiryDate) {
          _loadAdvisories();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                advisory != null ? 'Advisory updated' : 'Advisory created',
              ),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  /// Delete advisory
  void _deleteAdvisory(PriceAdvisoryModel advisory) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Advisory'),
        content: Text('Are you sure you want to delete "${advisory.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadAdvisories();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Advisory deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Advisories'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAdvisories,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAdvisoryDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : Column(
                  children: [
                    _buildSearchBar(),
                    _buildFilterChips(),
                    Expanded(
                      child: _filteredAdvisories.isEmpty
                          ? _buildEmptyState()
                          : _buildAdvisoriesList(),
                    ),
                  ],
                ),
    );
  }

  /// Build search bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search advisories...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _applyFiltersAndSort();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (_) {
          setState(() => _applyFiltersAndSort());
        },
      ),
    );
  }

  /// Build filter chips
  Widget _buildFilterChips() {
    final types = ['ALL', 'Price Update', 'Shortage Alert', 'Promotion', 'Market Trend'];
    final statuses = ['ALL', 'Active', 'Scheduled', 'Expired', 'Inactive'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: types.map((type) {
              final isSelected = _selectedType == type;
              return FilterChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedType = type);
                  _applyFiltersAndSort();
                },
                backgroundColor: Colors.grey.shade200,
                selectedColor: Colors.blue.withOpacity(0.3),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: statuses.map((status) {
              final isSelected = _selectedStatus == status;
              return FilterChip(
                label: Text(status),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedStatus = status);
                  _applyFiltersAndSort();
                },
                backgroundColor: Colors.grey.shade200,
                selectedColor: Colors.green.withOpacity(0.3),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Build error widget
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadAdvisories,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No advisories found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first price advisory',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAdvisoryDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Create Advisory'),
          ),
        ],
      ),
    );
  }

  /// Build advisories list
  Widget _buildAdvisoriesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredAdvisories.length,
      itemBuilder: (context, index) {
        final advisory = _filteredAdvisories[index];
        return AdvisoryCard(
          advisory: advisory,
          onTap: () {
            // Show full details
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(advisory.title),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(advisory.content),
                      const SizedBox(height: 16),
                      Text(
                        'Type: ${advisory.type}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Target: ${advisory.targetAudience}'),
                      Text(
                        'Status: ${advisory.getStatus()}',
                      ),
                      Text(
                        'Views: ${advisory.viewsCount}',
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
          onEdit: () => _showAdvisoryDialog(advisory: advisory),
          onDelete: () => _deleteAdvisory(advisory),
        );
      },
    );
  }
}

/// Dialog for creating/editing price advisory
class CreateAdvisoryDialog extends StatefulWidget {
  final PriceAdvisoryModel? advisory;
  final String? initialProductName;
  final double? initialCeiling;
  final Function(String title, String content, String type,
      String targetAudience, DateTime effectiveDate, DateTime? expiryDate) onSave;

  const CreateAdvisoryDialog({
    Key? key,
    this.advisory,
    this.initialProductName,
    this.initialCeiling,
    required this.onSave,
  }) : super(key: key);

  @override
  State<CreateAdvisoryDialog> createState() => _CreateAdvisoryDialogState();
}

class _CreateAdvisoryDialogState extends State<CreateAdvisoryDialog> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  String? _selectedType;
  String _targetAudience = 'ALL';
  DateTime? _effectiveDate;
  DateTime? _expiryDate;
  bool _isLoading = false;

  static const List<String> _types = [
    'Price Update',
    'Shortage Alert',
    'Promotion',
    'Market Trend',
  ];

  static const List<String> _audiences = ['ALL', 'BUYERS', 'SELLERS', 'SPECIFIC'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.advisory?.title ?? (widget.initialProductName != null
          ? '${widget.initialProductName} - Price Update'
          : ''),
    );
    _contentController = TextEditingController(
      text: widget.advisory?.content ?? (widget.initialCeiling != null
          ? 'Price ceiling updated to PKR ${widget.initialCeiling!.toStringAsFixed(2)}'
          : ''),
    );
    _selectedType = widget.advisory?.type ?? 'Price Update';
    _targetAudience = widget.advisory?.targetAudience ?? 'ALL';
    _effectiveDate = widget.advisory?.effectiveDate ?? DateTime.now();
    _expiryDate = widget.advisory?.expiryDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter title')),
      );
      return;
    }

    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter content')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      widget.onSave(
        _titleController.text,
        _contentController.text,
        _selectedType!,
        _targetAudience,
        _effectiveDate!,
        _expiryDate,
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.advisory != null ? 'Edit Advisory' : 'Create Advisory',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              // Title
              Text('Title', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Enter advisory title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),
              // Content
              Text('Content', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _contentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Enter advisory content',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),
              // Type
              Text('Type', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  isExpanded: true,
                  underline: const SizedBox(),
                  value: _selectedType,
                  items: _types.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                  onChanged: (value) => setState(() => _selectedType = value),
                ),
              ),
              const SizedBox(height: 16),
              // Target Audience
              Text('Target Audience', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  isExpanded: true,
                  underline: const SizedBox(),
                  value: _targetAudience,
                  items: _audiences.map((aud) => DropdownMenuItem(value: aud, child: Text(aud))).toList(),
                  onChanged: (value) => setState(() => _targetAudience = value ?? 'ALL'),
                ),
              ),
              const SizedBox(height: 16),
              // Dates
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Effective Date', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _effectiveDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) setState(() => _effectiveDate = date);
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(_effectiveDate != null ? DateFormat('MMM dd, yyyy').format(_effectiveDate!) : 'Select'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Expiry Date (Optional)', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) setState(() => _expiryDate = date);
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(_expiryDate != null ? DateFormat('MMM dd, yyyy').format(_expiryDate!) : 'Select'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSave,
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(widget.advisory != null ? 'Update' : 'Create'),
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
