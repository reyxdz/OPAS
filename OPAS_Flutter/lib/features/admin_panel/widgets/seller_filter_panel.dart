// Filter panel widget for sellers list
import 'package:flutter/material.dart';

class SellerFilterPanel extends StatefulWidget {
  final String selectedStatus;
  final String selectedSort;
  final bool sortAscending;
  final DateTimeRange? dateRange;
  final Function(String) onStatusChanged;
  final Function(String, bool) onSortChanged;
  final Function(DateTimeRange?) onDateRangeChanged;
  final VoidCallback onReset;

  const SellerFilterPanel({
    Key? key,
    required this.selectedStatus,
    required this.selectedSort,
    required this.sortAscending,
    this.dateRange,
    required this.onStatusChanged,
    required this.onSortChanged,
    required this.onDateRangeChanged,
    required this.onReset,
  }) : super(key: key);

  @override
  State<SellerFilterPanel> createState() => _SellerFilterPanelState();
}

class _SellerFilterPanelState extends State<SellerFilterPanel> {
  late String _status;
  late String _sort;
  late bool _ascending;
  late DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _status = widget.selectedStatus;
    _sort = widget.selectedSort;
    _ascending = widget.sortAscending;
    _dateRange = widget.dateRange;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter & Sort',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),

          // Status Filter
          const Text(
            'Status',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._buildStatusOptions(),
          const SizedBox(height: 24),

          // Sort By
          const Text(
            'Sort By',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._buildSortOptions(),
          const SizedBox(height: 24),

          // Date Range
          const Text(
            'Date Range',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildDateRangePicker(),
          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onReset();
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onStatusChanged(_status);
                    widget.onSortChanged(_sort, _ascending);
                    widget.onDateRangeChanged(_dateRange);
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStatusOptions() {
    final statuses = ['ALL', 'PENDING', 'APPROVED', 'SUSPENDED'];
    return statuses.map((status) {
      return RadioListTile<String>(
        title: Text(status),
        value: status,
        groupValue: _status,
        onChanged: (value) {
          setState(() => _status = value!);
        },
      );
    }).toList();
  }

  List<Widget> _buildSortOptions() {
    return [
      RadioListTile<String>(
        title: const Text('Alphabetical'),
        value: 'name',
        groupValue: _sort,
        onChanged: (value) {
          setState(() => _sort = value!);
        },
      ),
      RadioListTile<String>(
        title: const Text('Registration Date'),
        value: 'date',
        groupValue: _sort,
        onChanged: (value) {
          setState(() => _sort = value!);
        },
      ),
      RadioListTile<String>(
        title: const Text('Status'),
        value: 'status',
        groupValue: _sort,
        onChanged: (value) {
          setState(() => _sort = value!);
        },
      ),
      CheckboxListTile(
        title: const Text('Ascending'),
        value: _ascending,
        onChanged: (value) {
          setState(() => _ascending = value ?? true);
        },
      ),
    ];
  }

  Widget _buildDateRangePicker() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDateRange: _dateRange,
        );
        if (picked != null) {
          setState(() => _dateRange = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _dateRange == null
                  ? 'Select date range'
                  : '${_dateRange!.start.toString().split(' ')[0]} - ${_dateRange!.end.toString().split(' ')[0]}',
              style: TextStyle(
                color: _dateRange == null ? Colors.grey : Colors.black,
              ),
            ),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }
}
