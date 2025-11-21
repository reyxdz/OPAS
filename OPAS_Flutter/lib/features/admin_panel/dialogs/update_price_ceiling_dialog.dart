import 'package:flutter/material.dart';
import '../../../core/models/price_ceiling_model.dart';

class UpdatePriceCeilingDialog extends StatefulWidget {
  final PriceCeilingModel ceiling;
  final Function(double newCeiling, String reason, String justification,
      DateTime effectiveDate) onUpdate;

  const UpdatePriceCeilingDialog({
    Key? key,
    required this.ceiling,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<UpdatePriceCeilingDialog> createState() =>
      _UpdatePriceCeilingDialogState();
}

class _UpdatePriceCeilingDialogState extends State<UpdatePriceCeilingDialog> {
  late TextEditingController _newCeilingController;
  late TextEditingController _justificationController;
  String? _selectedReason;
  DateTime? _effectiveDate;
  bool _isLoading = false;

  static const List<String> _reasons = [
    'Market Adjustment',
    'Forecast Update',
    'Compliance Issue',
    'Seasonal Change',
    'Supply Constraint',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _newCeilingController =
        TextEditingController(text: widget.ceiling.currentCeiling.toString());
    _justificationController = TextEditingController();
    _effectiveDate = DateTime.now();
  }

  @override
  void dispose() {
    _newCeilingController.dispose();
    _justificationController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    if (_newCeilingController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter new ceiling price')),
      );
      return false;
    }

    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason for change')),
      );
      return false;
    }

    if (_justificationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide justification')),
      );
      return false;
    }

    return true;
  }

  void _handleUpdate() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final newCeiling = double.parse(_newCeilingController.text);
      widget.onUpdate(
        newCeiling,
        _selectedReason!,
        _justificationController.text,
        _effectiveDate!,
      );
      Navigator.of(context).pop();
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
              // Header
              Text(
                'Update Price Ceiling',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Product: ${widget.ceiling.productName}',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Current ceiling display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Ceiling',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          widget.ceiling.formatCeiling(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.grey.shade400,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Ceiling',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        if (_newCeilingController.text.isNotEmpty)
                          Text(
                            'PKR ${double.parse(_newCeilingController.text).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          )
                        else
                          Text(
                            'PKR 0.00',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade400,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // New ceiling input
              Text(
                'New Ceiling Price',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _newCeilingController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter new ceiling price',
                  prefix: const Text('PKR '),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Reason selection
              Text(
                'Reason for Change',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
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
                  hint: const Text('Select reason...'),
                  value: _selectedReason,
                  items: _reasons
                      .map((reason) => DropdownMenuItem<String>(
                            value: reason,
                            child: Text(reason),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedReason = value);
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Justification
              Text(
                'Justification',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _justificationController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Explain the reason for this price change...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),

              // Effective date
              Text(
                'Effective Date',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _effectiveDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (date != null) {
                    setState(() => _effectiveDate = date);
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  _effectiveDate != null
                      ? _effectiveDate.toString().split(' ')[0]
                      : 'Today',
                ),
              ),
              const SizedBox(height: 24),

              // Impact preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info,
                          size: 16,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Impact Preview',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Affected Listings: ${widget.ceiling.affectedListings}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Sellers to Notify: ${widget.ceiling.affectedSellers}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'These sellers will be notified of the price change.',
                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
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
                    onPressed: _isLoading ? null : _handleUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Update Ceiling'),
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
