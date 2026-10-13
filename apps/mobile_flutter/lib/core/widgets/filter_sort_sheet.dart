import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Single selectable option inside a filter category
class FilterItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final int? count;

  const FilterItem({
    required this.value,
    required this.label,
    this.icon,
    this.count,
  });
}

/// A filter category configuration (e.g., Batch, Subject, Status)
class FilterConfig<T> {
  final String id;
  final String title;
  final List<FilterItem<T>> options;
  final T initialValue;
  final T defaultValue;

  const FilterConfig({
    required this.id,
    required this.title,
    required this.options,
    required this.initialValue,
    required this.defaultValue,
  });
}

/// A sort option item (e.g., Newest, Oldest, Due Date soonest)
class SortOptionItem<T> {
  final T value;
  final String label;
  final IconData? icon;

  const SortOptionItem({
    required this.value,
    required this.label,
    this.icon,
  });
}

/// Sort section configuration
class SortConfig<S> {
  final List<SortOptionItem<S>> options;
  final S initialValue;
  final S defaultValue;
  final String title;

  const SortConfig({
    required this.options,
    required this.initialValue,
    required this.defaultValue,
    this.title = 'Sort By',
  });
}

/// Result returned from the filter & sort bottom sheet
class FilterSortSelection<S> {
  final Map<String, dynamic> filterValues;
  final S? sortValue;

  const FilterSortSelection({
    required this.filterValues,
    this.sortValue,
  });

  T getFilter<T>(String id, T fallback) {
    if (filterValues.containsKey(id) && filterValues[id] is T) {
      return filterValues[id] as T;
    }
    return fallback;
  }
}

/// Reusable Filter & Sort Bottom Sheet Modal conforming to DESIGN.md
class FilterSortSheet<S> extends StatefulWidget {
  final String title;
  final List<FilterConfig<dynamic>> filters;
  final SortConfig<S>? sort;

  const FilterSortSheet({
    super.key,
    this.title = 'Filters & Sort',
    required this.filters,
    this.sort,
  });

  @override
  State<FilterSortSheet<S>> createState() => _FilterSortSheetState<S>();
}

class _FilterSortSheetState<S> extends State<FilterSortSheet<S>> {
  late Map<String, dynamic> _currentFilterValues;
  late S? _currentSortValue;

  @override
  void initState() {
    super.initState();
    _currentFilterValues = {
      for (final f in widget.filters) f.id: f.initialValue,
    };
    _currentSortValue = widget.sort?.initialValue;
  }

  void _resetAll() {
    setState(() {
      _currentFilterValues = {
        for (final f in widget.filters) f.id: f.defaultValue,
      };
      _currentSortValue = widget.sort?.defaultValue;
    });
  }

  int get _activeCount {
    var count = 0;
    for (final f in widget.filters) {
      if (_currentFilterValues[f.id] != f.defaultValue) {
        count++;
      }
    }
    if (widget.sort != null && _currentSortValue != widget.sort!.defaultValue) {
      count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Drag Handle
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.slate300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 2. Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              widget.title,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textLight,
                              ),
                            ),
                          ),
                          if (_activeCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.skyBlueLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.skyBlue.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                '$_activeCount active',
                                style: const TextStyle(
                                  color: AppColors.skyBlue,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _resetAll,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        foregroundColor: AppColors.slate500,
                      ),
                      child: const Text('Reset All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.slate500, size: 20),
                      tooltip: 'Close',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.borderLight),

              // 3. Scrollable Filter Sections & Sort
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filter Categories
                      for (final filter in widget.filters) ...[
                        _buildSectionHeader(filter.title),
                        const SizedBox(height: 10),
                        _buildFilterChips(filter),
                        const SizedBox(height: 20),
                      ],

                      // Sort Options
                      if (widget.sort != null) ...[
                        _buildSectionHeader(widget.sort!.title),
                        const SizedBox(height: 10),
                        _buildSortOptions(widget.sort!),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),

              // 4. Action Buttons Footer
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: AppColors.borderLight, width: 1),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final result = FilterSortSelection<S>(
                        filterValues: Map<String, dynamic>.from(_currentFilterValues),
                        sortValue: _currentSortValue,
                      );
                      Navigator.of(context).pop(result);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.skyBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.slate500,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildFilterChips(FilterConfig<dynamic> filter) {
    final selectedVal = _currentFilterValues[filter.id];
    final maxChipWidth = MediaQuery.of(context).size.width - 56;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filter.options.map((option) {
        final isSelected = selectedVal == option.value;

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxChipWidth),
          child: InkWell(
            onTap: () {
              setState(() {
                _currentFilterValues[filter.id] = option.value;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.skyBlueLight : AppColors.slate100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.skyBlue : AppColors.borderLight,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (option.icon != null) ...[
                    Icon(
                      option.icon,
                      size: 16,
                      color: isSelected ? AppColors.skyBlue : AppColors.slate500,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      option.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppColors.skyBlue : AppColors.textLight,
                      ),
                    ),
                  ),
                  if (option.count != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.skyBlue : AppColors.slate300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${option.count}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected ? Colors.white : AppColors.slate700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSortOptions(SortConfig<S> sortConfig) {
    return Column(
      children: sortConfig.options.map((opt) {
        final isSelected = _currentSortValue == opt.value;

        return InkWell(
          onTap: () {
            setState(() {
              _currentSortValue = opt.value;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.skyBlueLight.withValues(alpha: 0.5) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.skyBlue.withValues(alpha: 0.4) : AppColors.borderLight,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                if (opt.icon != null) ...[
                  Icon(
                    opt.icon,
                    size: 18,
                    color: isSelected ? AppColors.skyBlue : AppColors.slate400,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    opt.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.skyBlue : AppColors.textLight,
                    ),
                  ),
                ),
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? AppColors.skyBlue : AppColors.slate400,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Helper function to display the Filter & Sort bottom sheet
Future<FilterSortSelection<S>?> showFilterSortSheet<S>({
  required BuildContext context,
  String title = 'Filters & Sort',
  required List<FilterConfig<dynamic>> filters,
  SortConfig<S>? sort,
}) {
  return showModalBottomSheet<FilterSortSelection<S>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => FilterSortSheet<S>(
      title: title,
      filters: filters,
      sort: sort,
    ),
  );
}

/// Badge Icon Button to show filter status in AppBars
class FilterBadgeButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onPressed;
  final String tooltip;

  const FilterBadgeButton({
    super.key,
    required this.activeCount,
    required this.onPressed,
    this.tooltip = 'Filters & Sort',
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.tune_rounded,
            color: activeCount > 0 ? AppColors.skyBlue : null,
          ),
          if (activeCount > 0)
            Positioned(
              top: -3,
              right: -5,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.skyBlue,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  '$activeCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Data container for a single active filter badge chip
class ActiveFilterChipData {
  final String label;
  final VoidCallback onRemoved;

  const ActiveFilterChipData({
    required this.label,
    required this.onRemoved,
  });
}

/// Clean horizontal strip displaying active filter chips with tap-to-remove and Clear All
class ActiveFiltersBar extends StatelessWidget {
  final List<ActiveFilterChipData> chips;
  final VoidCallback onClearAll;

  const ActiveFiltersBar({
    super.key,
    required this.chips,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final chip in chips)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Container(
                  padding: const EdgeInsets.only(left: 10, right: 4, top: 2, bottom: 2),
                  decoration: BoxDecoration(
                    color: AppColors.skyBlueLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.skyBlue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        chip.label,
                        style: const TextStyle(
                          color: AppColors.skyBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      InkWell(
                        onTap: chip.onRemoved,
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close, size: 14, color: AppColors.skyBlue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            TextButton(
              onPressed: onClearAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(50, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Clear all',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

