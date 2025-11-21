// Seller approval workflow dialog
import 'package:flutter/material.dart';

class SellerApprovalDialog extends StatefulWidget {
  final Map<String, dynamic> seller;
  final Function(String action, String? notes) onDecision;

  const SellerApprovalDialog({
    Key? key,
    required this.seller,
    required this.onDecision,
  }) : super(key: key);

  @override
  State<SellerApprovalDialog> createState() => _SellerApprovalDialogState();
}

class _SellerApprovalDialogState extends State<SellerApprovalDialog> {
  String? _selectedAction;
  final _notesController = TextEditingController();
  String? _selectedReason;
  bool _isLoading = false;

  static const List<String> _rejectionReasons = [
    'Documents incomplete',
    'Business information invalid',
    'Suspicious activity detected',
    'Compliance concerns',
    'Other',
  ];

  static const List<String> _suspensionReasons = [
    'Price manipulation detected',
    'Counterfeit products',
    'Customer complaints',
    'Regulatory violation',
    'Other',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _handleDecision() async {
    if (_selectedAction == null || _selectedAction!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an action')),
      );
      return;
    }

    if (_selectedAction != 'approve' && _selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final notes = _notesController.text.isNotEmpty
          ? _notesController.text
          : (_selectedReason ?? '');

      widget.onDecision(_selectedAction!, notes);
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Seller $_selectedAction action completed',
          ),
        ),
      );
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
                'Seller Decision',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Make a decision for ${widget.seller['full_name'] ?? 'this seller'}',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Action selection
              _buildActionSection(),
              const SizedBox(height: 16),

              // Reason selection (conditional)
              if (_selectedAction != null && _selectedAction != 'approve')
                _buildReasonSection(),

              // Notes field
              const SizedBox(height: 16),
              Text(
                'Admin Notes (Optional)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Enter your notes here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),

              // Buttons
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleDecision,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getActionColor(),
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _selectedAction?.toUpperCase() ?? 'CONFIRM',
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Action',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          label: 'Approve',
          value: 'approve',
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        const SizedBox(height: 10),
        _buildActionButton(
          label: 'Reject',
          value: 'reject',
          icon: Icons.cancel,
          color: Colors.red,
        ),
        const SizedBox(height: 10),
        _buildActionButton(
          label: 'Suspend',
          value: 'suspend',
          icon: Icons.block,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedAction == value;
    return InkWell(
      onTap: () => setState(() => _selectedAction = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonSection() {
    final reasons = _selectedAction == 'reject'
        ? _rejectionReasons
        : _suspensionReasons;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Reason',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            isExpanded: true,
            underline: const SizedBox(),
            hint: const Text('Choose a reason...'),
            value: _selectedReason,
            items: reasons
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
      ],
    );
  }

  Color _getActionColor() {
    switch (_selectedAction) {
      case 'approve':
        return Colors.green;
      case 'reject':
        return Colors.red;
      case 'suspend':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}
