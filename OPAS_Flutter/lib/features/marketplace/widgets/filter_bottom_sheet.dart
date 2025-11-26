import 'package:flutter/material.dart';

class FilterBottomSheet extends StatefulWidget {
  final String? selectedCategory;
  final double? minPrice;
  final double? maxPrice;
  final int? minRating; // 3, 4, or 5
  final bool inStockOnly;
  final String sortOrder;
  final Function({
    String? category,
    double? minPrice,
    double? maxPrice,
    int? minRating,
    bool? inStockOnly,
    String? sortOrder,
  }) onApply;
  final VoidCallback onClear;

  const FilterBottomSheet({
    super.key,
    this.selectedCategory,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.inStockOnly = false,
    this.sortOrder = 'newest',
    required this.onApply,
    required this.onClear,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String? _selectedCategory;
  late double? _minPrice;
  late double? _maxPrice;
  late int? _minRating;
  late bool _inStockOnly;
  late String _sortOrder;
  late TextEditingController _minController;
  late TextEditingController _maxController;

  final List<String> _categories = [
    'VEGETABLE',
    'FRUIT',
    'GRAIN',
    'DAIRY',
    'POULTRY',
  ];


  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
    _minPrice = widget.minPrice;
    _maxPrice = widget.maxPrice;
    _minRating = widget.minRating;
    _inStockOnly = widget.inStockOnly;
    _sortOrder = widget.sortOrder;
    _minController = TextEditingController(
      text: _minPrice?.toStringAsFixed(0) ?? '',
    );
    _maxController = TextEditingController(
      text: _maxPrice?.toStringAsFixed(0) ?? '',
    );
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
      child: SingleChildScrollView(
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
            const SizedBox(height: 20),

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
                      isDense: true,
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
                      isDense: true,
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

            // Seller Rating Filter
            Text(
              'Seller Rating',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [3, 4, 5].map((rating) {
                final isSelected = _minRating == rating;
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 14,
                        color: isSelected ? Colors.white : Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text('$rating+'),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _minRating = selected ? rating : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Availability Filter
            Text(
              'Availability',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('In Stock Only'),
              value: _inStockOnly,
              onChanged: (value) {
                setState(() {
                  _inStockOnly = value ?? false;
                });
              },
            ),
            const SizedBox(height: 24),

            // Sort Order
            Text(
              'Sort By',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            DropdownButton<String>(
              value: _sortOrder,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: 'newest',
                  child: Text('Newest'),
                ),
                DropdownMenuItem(
                  value: 'price_asc',
                  child: Text('Price: Low to High'),
                ),
                DropdownMenuItem(
                  value: 'price_desc',
                  child: Text('Price: High to Low'),
                ),
                DropdownMenuItem(
                  value: 'rating',
                  child: Text('Top Rated'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _sortOrder = value;
                  });
                }
              },
            ),
            const SizedBox(height: 32),

            // Apply and Reset Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onClear();
                      Navigator.pop(context);
                    },
                    child: const Text('Clear All'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(
                        category: _selectedCategory,
                        minPrice: _minPrice,
                        maxPrice: _maxPrice,
                        minRating: _minRating,
                        inStockOnly: _inStockOnly,
                        sortOrder: _sortOrder,
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
