import 'package:flutter/material.dart';
import '../../utils/color_pallets.dart';
import '../../utils/formatters.dart';

class PriceCalculator extends StatefulWidget {
  static const routeName = "/priceCalculator";
  final Map<String, String>? shopPricing;

  const PriceCalculator({super.key, this.shopPricing});

  @override
  State<PriceCalculator> createState() => _PriceCalculatorState();
}

class _PriceCalculatorState extends State<PriceCalculator> {
  int _pages = 1;
  int _copies = 1;
  String _side = 'single';
  String _color = 'black';
  String _quality = '80gsm';
  String _size = 'A4';
  String _binding = 'none';
  int _colorPages = 0;

  double get _totalCost {
    double cost = 0;
    final pricing = widget.shopPricing ?? _defaultPricing;
    
    // Base cost per page
    double pageCost = 0;
    if (_color == 'color') {
      pageCost = double.tryParse(pricing['color'] ?? '5') ?? 5;
    } else {
      pageCost = double.tryParse(pricing['black'] ?? '2') ?? 2;
    }
    
    // Single vs double side discount
    if (_side == 'double') {
      pageCost *= 0.85; // 15% discount for double-sided
    }
    
    // Calculate total pages (color + black and single/double sided)
    int totalPageSets = ((_pages - _colorPages) + _colorPages);
    if (_side == 'double') {
      totalPageSets = (totalPageSets / 2).ceil();
    }
    
    cost = totalPageSets * pageCost * _copies;
    
    // Quality add-on
    if (_quality == '100gsm') {
      cost += (_pages * _copies * 0.5);
    } else if (_quality == 'bond') {
      cost += (_pages * _copies * 1.0);
    }
    
    // Size add-on
    if (_size == 'A3') {
      cost *= 1.5;
    } else if (_size == 'legal') {
      cost *= 1.2;
    } else if (_size == 'letter') {
      cost *= 1.1;
    }
    
    // Binding
    if (_binding == 'spiral') {
      cost += 15;
    } else if (_binding == 'staple') {
      cost += 5;
    }
    
    return cost;
  }

  Map<String, String> get _defaultPricing => {
    'black': '2',
    'color': '5',
    'a4': '2',
    'a3': '3',
    'spiral': '15',
    'staple': '5',
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calculate, color: ColorPallets.deepBlue),
                SizedBox(width: 8),
                Text(
                  'Price Calculator',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildNumberInput('Pages', _pages, (v) => setState(() => _pages = v)),
            _buildNumberInput('Copies', _copies, (v) => setState(() => _copies = v)),
            _buildDropdown('Side', _side, ['single', 'double'], 
              (v) => setState(() => _side = v!)),
            _buildDropdown('Color', _color, ['black', 'color'], 
              (v) => setState(() => _color = v!)),
            if (_color == 'color')
              _buildNumberInput('Color Pages', _colorPages, 
                (v) => setState(() => _colorPages = v.clamp(0, _pages))),
            _buildDropdown('Quality', _quality, ['80gsm', '100gsm', 'bond'], 
              (v) => setState(() => _quality = v!)),
            _buildDropdown('Size', _size, ['A4', 'A3', 'legal', 'letter'], 
              (v) => setState(() => _size = v!)),
            _buildDropdown('Binding', _binding, ['none', 'staple', 'spiral'], 
              (v) => setState(() => _binding = v!)),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estimated Cost:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(_totalCost),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: ColorPallets.deepBlue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberInput(String label, int value, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            // UX Improvement: Add tooltip for accessibility and hover context
            tooltip: 'Decrease $label',
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 50,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            // UX Improvement: Add tooltip for accessibility and hover context
            tooltip: 'Increase $label',
            onPressed: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> options, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          DropdownButton<String>(
            value: value,
            items: options.map((o) => DropdownMenuItem(
              value: o,
              child: Text(o.toUpperCase()),
            )).toList(),
            onChanged: onChanged,
            underline: const SizedBox(),
          ),
        ],
      ),
    );
  }
}

class PriceCalculatorBottomSheet extends StatelessWidget {
  const PriceCalculatorBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const PriceCalculator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
