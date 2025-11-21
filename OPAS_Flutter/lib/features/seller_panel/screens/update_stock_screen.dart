import 'package:flutter/material.dart';
import '../services/seller_service.dart';

class UpdateStockScreen extends StatefulWidget {
  final int productId;
  final String productName;
  final int currentStock;
  final int minimumStock;
  final String unit;

  const UpdateStockScreen({
    Key? key,
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.minimumStock,
    required this.unit,
  }) : super(key: key);

  @override
  State<UpdateStockScreen> createState() => _UpdateStockScreenState();
}

class _UpdateStockScreenState extends State<UpdateStockScreen> {
  late TextEditingController _stockController;
  late TextEditingController _minimumStockController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _stockController =
        TextEditingController(text: widget.currentStock.toString());
    _minimumStockController =
        TextEditingController(text: widget.minimumStock.toString());
  }

  @override
  void dispose() {
    _stockController.dispose();
    _minimumStockController.dispose();
    super.dispose();
  }

  Future<void> _updateStock() async {
    // Validation
    if (_stockController.text.isEmpty || _minimumStockController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields';
      });
      return;
    }

    final newStock = int.tryParse(_stockController.text);
    final newMinimum = int.tryParse(_minimumStockController.text);

    if (newStock == null || newMinimum == null) {
      setState(() {
        _errorMessage = 'Please enter valid numbers';
      });
      return;
    }

    if (newStock < 0 || newMinimum < 0) {
      setState(() {
        _errorMessage = 'Stock levels cannot be negative';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call API to update stock
      await SellerService.updateProductStock(
        widget.productId,
        newStock,
        newMinimum,
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock updated successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate back
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update stock: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  int get _difference {
    final newStock = int.tryParse(_stockController.text) ?? widget.currentStock;
    return newStock - widget.currentStock;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Stock'),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Information Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Product Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Product Name:'),
                        Expanded(
                          child: Text(
                            widget.productName,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Unit:'),
                        Text(
                          widget.unit,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Current Stock:'),
                        Text(
                          '${widget.currentStock} ${widget.unit}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Error Message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            if (_errorMessage != null) const SizedBox(height: 16),

            // Stock Input Fields
            const Text(
              'Update Stock Levels',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Current Stock Field
            TextField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Current Stock',
                hintText: 'Enter current stock quantity',
                suffixText: widget.unit,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {}); // Update difference display
              },
            ),
            const SizedBox(height: 16),

            // Stock Change Indicator
            if (_difference != 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_difference > 0
                          ? Colors.green
                          : Colors.red)
                      .withOpacity(0.1),
                  border: Border.all(
                    color: _difference > 0 ? Colors.green : Colors.red,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _difference > 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: _difference > 0 ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Change: ${_difference > 0 ? '+' : ''}$_difference ${widget.unit}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _difference > 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Minimum Stock Field
            TextField(
              controller: _minimumStockController,
              keyboardType: TextInputType.number,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Minimum Stock Required',
                hintText: 'Enter minimum stock level',
                suffixText: widget.unit,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'When stock falls below this level, you\'ll receive low stock alerts.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            // Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ensure stock levels are accurate to prevent overselling.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            _stockController.text =
                                widget.currentStock.toString();
                            _minimumStockController.text =
                                widget.minimumStock.toString();
                            setState(() {
                              _errorMessage = null;
                            });
                          },
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateStock,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Update Stock'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
