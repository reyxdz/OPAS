import 'package:flutter/material.dart';

class FilterBottomSheet extends StatefulWidget {
  final String? selectedCategory;
  final double? minPrice;
  final double? maxPrice;
  final Function(String?, double?, double?) onApply;

  const FilterBottomSheet({
    super.key,
    this.selectedCategory,
    this.minPrice,
    this.maxPrice,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String? _selectedCategory;
  late double? _minPrice;
  late double? _maxPrice;
  final _minController = TextEditingController();
  final _maxController = TextEditingController();

  final List<String> _categories = [
    'Vegetables',
    'Fruits',
    'Grains',
    'Dairy',
    'Poultry',
    'Meat',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
    _minPrice = widget.minPrice;
    _maxPrice = widget.maxPrice;
    _minController.text = _minPrice?.toStringAsFixed(2) ?? '';
    _maxController.text = _maxPrice?.toStringAsFixed(2) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Category Filter
          Text(
            'Category',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((category) {
              final isSelected = _selectedCategory == category;
              return FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? category : null;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Price Range Filter
          Text(
            'Price Range (₱)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Min',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: (value) {
                    _minPrice =
                        value.isEmpty ? null : double.tryParse(value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maxController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Max',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: (value) {
                    _maxPrice =
                        value.isEmpty ? null : double.tryParse(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Apply and Reset Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = null;
                      _minPrice = null;
                      _maxPrice = null;
                      _minController.clear();
                      _maxController.clear();
                    });
                    widget.onApply(null, null, null);
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_selectedCategory, _minPrice, _maxPrice);
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

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }
}
