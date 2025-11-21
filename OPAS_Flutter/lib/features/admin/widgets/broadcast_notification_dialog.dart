import 'package:flutter/material.dart';

class BroadcastNotificationDialog extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSend;

  const BroadcastNotificationDialog({
    Key? key,
    this.onSend,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _BroadcastNotificationDialogState createState() =>
      _BroadcastNotificationDialogState();
}

class _BroadcastNotificationDialogState
    extends State<BroadcastNotificationDialog> {
  late TextEditingController _titleController;
  late TextEditingController _messageController;
  String _recipientType = 'all'; // 'all', 'sellers', 'buyers', 'specific'
  String _templateType = 'custom'; // 'custom', 'price_warning', 'inventory_alert', 'promotion'
  final List<String> _selectedSellers = [];
  bool _isLoading = false;

  final Map<String, String> _templates = {
    'price_warning': 'Price Violation Warning - You have listings exceeding the price ceiling. Please adjust within 24 hours.',
    'inventory_alert': 'Low Inventory Alert - Your OPAS inventory is running low. Please submit new products.',
    'promotion': 'Special Promotion - New promotional period starting. Check the marketplace for details.',
    'policy_change': 'Policy Update - Important changes to our marketplace policies. Please review.',
  };

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _applyTemplate(String templateKey) {
    if (templateKey == 'custom') {
      _messageController.clear();
    } else {
      _messageController.text = _templates[templateKey] ?? '';
    }
  }

  void _sendNotification() {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate sending
    Future.delayed(const Duration(seconds: 1), () {
      if (widget.onSend != null) {
        widget.onSend!({
          'title': _titleController.text,
          'message': _messageController.text,
          'recipient_type': _recipientType,
          'template_type': _templateType,
          'selected_sellers': _selectedSellers,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification sent successfully')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Send Notification',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Recipient Type
              Text(
                'Send To',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildRecipientButton('All Users', 'all'),
                  _buildRecipientButton('Sellers', 'sellers'),
                  _buildRecipientButton('Buyers', 'buyers'),
                  _buildRecipientButton('Specific', 'specific'),
                ],
              ),
              const SizedBox(height: 20),

              // Template Selection
              Text(
                'Message Template',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButton<String>(
                  value: _templateType,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: 'custom',
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Custom Message'),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'price_warning',
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Price Violation Warning'),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'inventory_alert',
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Inventory Alert'),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'promotion',
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Promotion'),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'policy_change',
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Policy Change'),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _templateType = value;
                        _applyTemplate(value);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Title',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Notification title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 16),

              // Message
              Text(
                'Message',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Notification message',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _sendNotification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Send Notification'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipientButton(String label, String value) {
    final isSelected = _recipientType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _recipientType = value;
          if (value != 'specific') {
            _selectedSellers.clear();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2196F3) : Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF2196F3) : Colors.transparent,
            width: 1,
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
