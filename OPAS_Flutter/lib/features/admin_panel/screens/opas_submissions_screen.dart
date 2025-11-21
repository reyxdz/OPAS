// OPAS Submissions Screen - Admin review of seller "Sell to OPAS" offers
// List submissions with filtering, sorting, and approval workflow

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/opas_submission_model.dart';
import '../../../core/services/admin_service.dart';
import '../widgets/opas_submission_card.dart';
import '../dialogs/opas_submission_review_dialog.dart';

class OPASSubmissionsScreen extends StatefulWidget {
  const OPASSubmissionsScreen({Key? key}) : super(key: key);

  @override
  State<OPASSubmissionsScreen> createState() => _OPASSubmissionsScreenState();
}

class _OPASSubmissionsScreenState extends State<OPASSubmissionsScreen> {
  late TextEditingController _searchController;

  // Filter & Sort State
  String _selectedStatus = 'ALL'; // ALL, PENDING, APPROVED, REJECTED
  String _sortBy = 'date'; // date, seller, quantity
  bool _sortAscending = false; // Newest first
  DateTimeRange? _dateRange;

  // Data State
  List<OPASSubmissionModel> _submissions = [];
  List<OPASSubmissionModel> _filteredSubmissions = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadSubmissions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load all OPAS submissions from API
  Future<void> _loadSubmissions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final submissions = await AdminService.getOPASSubmissions();
      setState(() {
        _submissions = (submissions as List)
            .map((item) =>
                OPASSubmissionModel.fromJson(item as Map<String, dynamic>))
            .toList();
        _applyFiltersAndSort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load submissions: $e';
        _isLoading = false;
      });
    }
  }

  /// Apply filters and sorting
  void _applyFiltersAndSort() {
    _filteredSubmissions = _submissions.where((submission) {
      // Status filter
      if (_selectedStatus != 'ALL') {
        if (submission.status.toUpperCase() != _selectedStatus) {
          return false;
        }
      }

      // Date range filter
      if (_dateRange != null) {
        if (submission.submittedAt.isBefore(_dateRange!.start) ||
            submission.submittedAt.isAfter(_dateRange!.end)) {
          return false;
        }
      }

      // Search filter
      final query = _searchController.text.toLowerCase();
      if (query.isNotEmpty) {
        return submission.sellerName.toLowerCase().contains(query) ||
            submission.productName.toLowerCase().contains(query);
      }

      return true;
    }).toList();

    // Apply sorting
    _filteredSubmissions.sort((a, b) {
      int comparison = 0;

      switch (_sortBy) {
        case 'date':
          comparison = a.submittedAt.compareTo(b.submittedAt);
          break;
        case 'seller':
          comparison = a.sellerName.compareTo(b.sellerName);
          break;
        case 'quantity':
          comparison = a.quantity.compareTo(b.quantity);
          break;
      }

      return _sortAscending ? comparison : -comparison;
    });
  }

  /// Show submission review dialog
  void _showReviewDialog(OPASSubmissionModel submission) {
    showDialog(
      context: context,
      builder: (dialogContext) => OPASSubmissionReviewDialog(
        submission: submission,
        onDecision: (approved, quantityAccepted, finalPrice, deliveryTerms,
            notes) {
          _loadSubmissions();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(approved
                  ? 'Submission approved & PO generated'
                  : 'Submission rejected'),
              backgroundColor: approved ? Colors.green : Colors.red,
            ),
          );
        },
      ),
    );
  }

  /// Show filter bottom sheet
  void _showFilterPanel() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter & Sort',
              style: Theme.of(sheetContext).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            // Status Filter
            Text(
              'Status',
              style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['ALL', 'PENDING', 'APPROVED', 'REJECTED'].map((status) {
                final isSelected = _selectedStatus == status;
                return FilterChip(
                  label: Text(status),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedStatus = status);
                    _applyFiltersAndSort();
                    Navigator.pop(sheetContext);
                  },
                  backgroundColor: Colors.grey.shade200,
                  selectedColor: Colors.blue.withOpacity(0.3),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // Sort Options
            Text(
              'Sort By',
              style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Newest First'),
                  selected: _sortBy == 'date' && !_sortAscending,
                  onSelected: (selected) {
                    setState(() {
                      _sortBy = 'date';
                      _sortAscending = false;
                    });
                    _applyFiltersAndSort();
                    Navigator.pop(sheetContext);
                  },
                  backgroundColor: Colors.grey.shade200,
                  selectedColor: Colors.blue.withOpacity(0.3),
                ),
                FilterChip(
                  label: const Text('Seller A-Z'),
                  selected: _sortBy == 'seller',
                  onSelected: (selected) {
                    setState(() {
                      _sortBy = 'seller';
                      _sortAscending = true;
                    });
                    _applyFiltersAndSort();
                    Navigator.pop(sheetContext);
                  },
                  backgroundColor: Colors.grey.shade200,
                  selectedColor: Colors.blue.withOpacity(0.3),
                ),
                FilterChip(
                  label: const Text('Quantity High'),
                  selected: _sortBy == 'quantity' && !_sortAscending,
                  onSelected: (selected) {
                    setState(() {
                      _sortBy = 'quantity';
                      _sortAscending = false;
                    });
                    _applyFiltersAndSort();
                    Navigator.pop(sheetContext);
                  },
                  backgroundColor: Colors.grey.shade200,
                  selectedColor: Colors.blue.withOpacity(0.3),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Date Range
            Text(
              'Date Range (Optional)',
              style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final range = await showDateRangePicker(
                  context: sheetContext,
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now(),
                );
                if (range == null) return;
                setState(() => _dateRange = range);
                _applyFiltersAndSort();
                if (mounted) {
                  // ignore: use_build_context_synchronously
                  Navigator.pop(sheetContext);
                }
              },
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _dateRange != null
                    ? '${DateFormat('MMM dd').format(_dateRange!.start)} - ${DateFormat('MMM dd').format(_dateRange!.end)}'
                    : 'Select Date Range',
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() {
                  _dateRange = null;
                  _applyFiltersAndSort();
                });
                Navigator.pop(sheetContext);
              },
              child: const Text('Clear Date Range'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Count pending submissions
    final pendingCount =
        _submissions.where((s) => s.isPending()).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OPAS Submissions'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSubmissions,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFilterPanel,
            tooltip: 'Filter & Sort',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : Column(
                  children: [
                    // Search bar
                    _buildSearchBar(),
                    // Status filter chips
                    _buildStatusChips(pendingCount),
                    // Submissions list or empty state
                    Expanded(
                      child: _filteredSubmissions.isEmpty
                          ? _buildEmptyState()
                          : _buildSubmissionsList(),
                    ),
                  ],
                ),
    );
  }

  /// Search bar widget
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search seller or product...',
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

  /// Status filter chips
  Widget _buildStatusChips(int pendingCount) {
    final statuses = ['ALL', 'PENDING', 'APPROVED', 'REJECTED'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: statuses.map((status) {
          final isSelected = _selectedStatus == status;
          return FilterChip(
            label: Text(
              status == 'PENDING'
                  ? '$status ($pendingCount)'
                  : status,
            ),
            selected: isSelected,
            onSelected: (selected) {
              setState(() => _selectedStatus = status);
              _applyFiltersAndSort();
            },
            backgroundColor: Colors.grey.shade200,
            selectedColor: Colors.blue.withOpacity(0.3),
          );
        }).toList(),
      ),
    );
  }

  /// Error widget
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
            onPressed: _loadSubmissions,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No submissions found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedStatus == 'PENDING'
                ? 'All submissions have been reviewed'
                : 'Try adjusting filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// Submissions list widget
  Widget _buildSubmissionsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredSubmissions.length,
      itemBuilder: (context, index) {
        final submission = _filteredSubmissions[index];
        return OPASSubmissionCard(
          submission: submission,
          onTap: () => _showReviewDialog(submission),
          onApprove: () => _showReviewDialog(submission),
          onReject: () {
            // Quick reject without dialog
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Submission rejected')),
            );
            _loadSubmissions();
          },
          onViewDetails: () => _showReviewDialog(submission),
        );
      },
    );
  }
}
