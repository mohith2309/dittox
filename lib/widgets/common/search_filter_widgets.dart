import 'package:flutter/material.dart';
import '../../utils/color_pallets.dart';

class SearchBarWidget extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final TextEditingController? controller;
  final bool autofocus;

  const SearchBarWidget({
    super.key,
    this.hintText = "Search...",
    this.onChanged,
    this.onClear,
    this.controller,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller?.text.isNotEmpty == true
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller?.clear();
                    onClear?.call();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class FilterChipList extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;
  final bool scrollable;

  const FilterChipList({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final chips = options.map((option) {
      final isSelected = option == selected;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (_) => onSelected(option),
          backgroundColor: Colors.white,
          selectedColor: ColorPallets.deepBlue.withValues(alpha: 0.15),
          checkmarkColor: ColorPallets.deepBlue,
          labelStyle: TextStyle(
            color: isSelected ? ColorPallets.deepBlue : ColorPallets.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? ColorPallets.deepBlue : Colors.grey.shade300,
            ),
          ),
        ),
      );
    }).toList();

    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: chips),
      );
    }

    return Wrap(spacing: 8, children: chips);
  }
}

class FilterBottomSheet extends StatefulWidget {
  final List<FilterOption> filters;
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onApply;

  const FilterBottomSheet({
    super.key,
    required this.filters,
    required this.currentFilters,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late Map<String, dynamic> _selectedFilters;

  @override
  void initState() {
    super.initState();
    _selectedFilters = Map.from(widget.currentFilters);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedFilters.clear();
                  });
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.filters.map((filter) {
                  return _buildFilterSection(filter);
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_selectedFilters);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPallets.deepBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(FilterOption filter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          filter.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        if (filter.type == FilterType.range)
          _buildRangeFilter(filter)
        else if (filter.type == FilterType.checkbox)
          _buildCheckboxFilter(filter)
        else if (filter.type == FilterType.radio)
          _buildRadioFilter(filter),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRangeFilter(FilterOption filter) {
    final range = _selectedFilters[filter.key] as List<double>? ?? [0, 1000];
    return RangeSlider(
      values: RangeValues(range[0], range[1]),
      min: filter.min ?? 0,
      max: filter.max ?? 1000,
      divisions: filter.divisions ?? 10,
      labels: RangeLabels(
        range[0].toInt().toString(),
        range[1].toInt().toString(),
      ),
      onChanged: (values) {
        setState(() {
          _selectedFilters[filter.key] = [values.start, values.end];
        });
      },
    );
  }

  Widget _buildCheckboxFilter(FilterOption filter) {
    final selected = _selectedFilters[filter.key] as List<String>? ?? [];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filter.options!.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (value) {
            setState(() {
              if (value) {
                selected.add(option);
              } else {
                selected.remove(option);
              }
              _selectedFilters[filter.key] = selected;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildRadioFilter(FilterOption filter) {
    return RadioGroup<String>(
      groupValue: _selectedFilters[filter.key] as String?,
      onChanged: (value) {
        setState(() {
          _selectedFilters[filter.key] = value;
        });
      },
      child: Column(
        children: filter.options!.map((option) {
          return RadioListTile<String>(
            title: Text(option),
            value: option,
            contentPadding: EdgeInsets.zero,
            dense: true,
          );
        }).toList(),
      ),
    );
  }
}

enum FilterType { range, checkbox, radio }

class FilterOption {
  final String key;
  final String title;
  final FilterType type;
  final List<String>? options;
  final double? min;
  final double? max;
  final int? divisions;

  FilterOption({
    required this.key,
    required this.title,
    required this.type,
    this.options,
    this.min,
    this.max,
    this.divisions,
  });
}

class SortDropdown extends StatelessWidget {
  final List<SortOption> options;
  final String? selected;
  final ValueChanged<String> onChanged;

  const SortDropdown({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: selected,
      onSelected: onChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort, size: 18),
            const SizedBox(width: 8),
            Text(
              options.firstWhere((o) => o.value == selected).label,
              style: const TextStyle(fontSize: 14),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
      itemBuilder: (context) => options
          .map((option) => PopupMenuItem<String>(
                value: option.value,
                child: Row(
                  children: [
                    if (option.value == selected)
                      const Icon(Icons.check, size: 18)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    Text(option.label),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class SortOption {
  final String value;
  final String label;

  SortOption({required this.value, required this.label});
}