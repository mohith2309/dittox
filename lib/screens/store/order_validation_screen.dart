import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/color_pallets.dart';

class OrderValidationScreen extends StatefulWidget {
  static const routeName = "/orderValidation";
  final String? initialOrderId;

  const OrderValidationScreen({super.key, this.initialOrderId});

  @override
  State<OrderValidationScreen> createState() => _OrderValidationScreenState();
}

class _OrderValidationScreenState extends State<OrderValidationScreen> {
  final _orderIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isValidating = false;
  String? _validationResult;
  bool? _isValid;

  @override
  void initState() {
    super.initState();
    if (widget.initialOrderId != null) {
      _orderIdController.text = widget.initialOrderId!;
    }
  }

  @override
  void dispose() {
    _orderIdController.dispose();
    super.dispose();
  }

  Future<void> _validateOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isValidating = true;
      _validationResult = null;
      _isValid = null;
    });

    // Simulate API call - replace with actual validation
    await Future.delayed(const Duration(seconds: 1));

    final orderId = _orderIdController.text.trim().toUpperCase();
    
    // Mock validation logic
    bool isValid = orderId.length >= 6 && orderId.startsWith('DTX');

    setState(() {
      _isValidating = false;
      _isValid = isValid;
      _validationResult = isValid
          ? 'Order #$orderId is valid!\n\nCustomer: John Doe\nItems: 5 pages\nTotal: ₹45\nStatus: Ready for pickup'
          : 'Order #$orderId not found.\nPlease check the order number and try again.';
    });
  }

  void _clearForm() {
    setState(() {
      _orderIdController.clear();
      _validationResult = null;
      _isValid = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Validation'),
        backgroundColor: ColorPallets.deepBlue,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanBarcode,
            tooltip: 'Scan QR Code',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.qr_code_2,
                        size: 64,
                        color: ColorPallets.deepBlue,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Validate Order',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Enter the order number or scan the QR code to validate',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ColorPallets.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _orderIdController,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  UpperCaseTextFormatter(),
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Order Number',
                  hintText: 'e.g., DTX123456',
                  prefixIcon: const Icon(Icons.tag),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearForm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an order number';
                  }
                  if (value.trim().length < 4) {
                    return 'Order number too short';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _validateOrder(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isValidating ? null : _validateOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPallets.deepBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isValidating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Validate Order',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
              const SizedBox(height: 24),
              if (_validationResult != null) _buildResultCard(),
              const SizedBox(height: 24),
              _buildQuickValidateSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final color = _isValid! ? ColorPallets.deepBlue : Colors.red;
    return Card(
      elevation: 2,
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              _isValid! ? Icons.check_circle : Icons.error,
              size: 48,
              color: color,
            ),
            const SizedBox(height: 16),
            Text(
              _validationResult!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: color,
                height: 1.5,
              ),
            ),
            if (_isValid!) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Confirm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPallets.deepBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _clearForm,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Next'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickValidateSection() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flash_on, color: ColorPallets.deepBlue, size: 20),
                SizedBox(width: 8),
                Text(
                  'Quick Validate',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSampleOrderChip('DTX001'),
                _buildSampleOrderChip('DTX002'),
                _buildSampleOrderChip('DTX003'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSampleOrderChip(String orderId) {
    return ActionChip(
      label: Text(orderId),
      onPressed: () {
        _orderIdController.text = orderId;
        _validateOrder();
      },
    );
  }

  void _scanBarcode() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Barcode scanner - integrate with mobile_scanner package'),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
