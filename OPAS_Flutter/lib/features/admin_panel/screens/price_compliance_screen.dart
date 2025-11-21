import 'package:flutter/material.dart';
import '../../../core/models/price_compliance_model.dart';
import '../../../core/services/admin_service.dart';
import '../widgets/compliance_violation_card.dart';

class PriceComplianceScreen extends StatefulWidget {
  const PriceComplianceScreen({Key? key}) : super(key: key);

  @override
  State<PriceComplianceScreen> createState() => _PriceComplianceScreenState();
}

class _PriceComplianceScreenState extends State<PriceComplianceScreen> {
  late TextEditingController _searchController;

  // Data state
  List<PriceComplianceModel> _violations = [];
  List<PriceComplianceModel> _filteredViolations = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filter state
  String _selectedStatus = 'ALL'; // ALL, NEW, WARNED, ADJUSTED, SUSPENDED
  String _sortBy = 'overage'; // overage, date, seller

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadViolations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load all price violations from API
  Future<void> _loadViolations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<PriceComplianceModel> violations =
          (await AdminService.getNonCompliantListings())
              .cast<PriceComplianceModel>();
      setState(() {
        _violations = violations;
        _applyFiltersAndSort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load violations: $e';
        _isLoading = false;
      });
    }
  }

  /// Apply filters and sorting
  void _applyFiltersAndSort() {
    _filteredViolations = _violations.where((violation) {
      // Status filter
      if (_selectedStatus != 'ALL') {
        if (violation.status.toUpperCase() != _selectedStatus.toUpperCase()) {
          return false;
        }
      }

      // Search filter
      final query = _searchController.text.toLowerCase();
      if (query.isNotEmpty) {
        return violation.sellerName.toLowerCase().contains(query) ||
            violation.productName.toLowerCase().contains(query);
      }

      return true;
    }).toList();

    // Apply sorting
    _filteredViolations.sort((a, b) {
      int comparison = 0;

      switch (_sortBy) {
        case 'overage':
          comparison = b.overagePercentage.compareTo(a.overagePercentage);
          break;
        case 'date':
          comparison = b.createdAt.compareTo(a.createdAt);
          break;
        case 'seller':
          comparison = a.sellerName.compareTo(b.sellerName);
          break;
      }

      return comparison;
    });
  }

  /// Issue warning to seller
  void _issueWarning(PriceComplianceModel violation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Issue Price Warning'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seller: ${violation.sellerName}'),
            const SizedBox(height: 8),
            Text('Product: ${violation.productName}'),
            const SizedBox(height: 8),
            Text('Overage: ${violation.formatOverage()}'),
            const SizedBox(height: 16),
            const Text(
              'The seller will have 24 hours to adjust the price to the ceiling.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadViolations();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Warning issued to seller'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Issue Warning'),
          ),
        ],
      ),
    );
  }

  /// Force price adjustment
  void _forceAdjustment(PriceComplianceModel violation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Force Price Adjustment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seller: ${violation.sellerName}'),
            const SizedBox(height: 8),
            Text('Product: ${violation.productName}'),
            const SizedBox(height: 8),
            Text('Current Price: ${violation.formatPrice()}'),
            const SizedBox(height: 8),
            Text('Ceiling: ${violation.formatCeiling()}'),
            const SizedBox(height: 16),
            const Text(
              'The seller\'s listing will be automatically adjusted to the ceiling price.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blue),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadViolations();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Price adjusted to ceiling'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Force Adjustment'),
          ),
        ],
      ),
    );
  }

  /// Suspend seller account
  void _suspendSeller(PriceComplianceModel violation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend Seller'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seller: ${violation.sellerName}'),
            const SizedBox(height: 16),
            const Text(
              'This seller will be suspended for price manipulation.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.red),
            ),
            const SizedBox(height: 8),
            const Text(
              'All their listings will be removed from the marketplace.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadViolations();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Seller suspended'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Compliance'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadViolations,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : Column(
                  children: [
                    _buildSearchBar(),
                    _buildStatusFilter(),
                    _buildSortOptions(),
                    _buildStatsSummary(),
                    Expanded(
                      child: _filteredViolations.isEmpty
                          ? _buildEmptyState()
                          : _buildViolationsList(),
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
          hintText: 'Search by seller or product...',
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

  /// Build status filter
  Widget _buildStatusFilter() {
    final statuses = ['ALL', 'NEW', 'WARNED', 'ADJUSTED', 'SUSPENDED'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
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
            selectedColor: Colors.red.withOpacity(0.3),
          );
        }).toList(),
      ),
    );
  }

  /// Build sort options
  Widget _buildSortOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButton<String>(
        isExpanded: true,
        value: _sortBy,
        items: const [
          DropdownMenuItem(
            value: 'overage',
            child: Text('Sort by Overage %'),
          ),
          DropdownMenuItem(
            value: 'date',
            child: Text('Sort by Date'),
          ),
          DropdownMenuItem(
            value: 'seller',
            child: Text('Sort by Seller'),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() => _sortBy = value);
            _applyFiltersAndSort();
          }
        },
      ),
    );
  }

  /// Build statistics summary
  Widget _buildStatsSummary() {
    final critical =
        _filteredViolations.where((v) => v.getSeverityLevel() == 3).length;
    final high =
        _filteredViolations.where((v) => v.getSeverityLevel() == 2).length;
    final moderate =
        _filteredViolations.where((v) => v.getSeverityLevel() == 1).length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Critical',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    critical.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'High',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    high.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Moderate',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    moderate.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
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
            onPressed: _loadViolations,
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
            Icons.check_circle,
            size: 64,
            color: Colors.green.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'All prices compliant!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No price violations detected',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build violations list
  Widget _buildViolationsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredViolations.length,
      itemBuilder: (context, index) {
        final violation = _filteredViolations[index];
        return ComplianceViolationCard(
          violation: violation,
          onIssueWarning: () => _issueWarning(violation),
          onForceAdjust: () => _forceAdjustment(violation),
          onSuspend: () => _suspendSeller(violation),
          onViewDetails: () {
            // Show details dialog
          },
        );
      },
    );
  }
}
