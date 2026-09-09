import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/filter_options.dart';
import '../../../providers/product_provider.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FilterBottomSheet(),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late FilterOptions _tempOptions;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ProductProvider>();
    _tempOptions = provider.filterOptions;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Filter & Sort',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (_tempOptions.filterBadgeCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_tempOptions.filterBadgeCount} active',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _tempOptions = _tempOptions.reset();
                      });
                    },
                    child: const Text(
                      'Reset All',
                      style: TextStyle(
                        color: AppTheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Sort By
                    _buildSectionHeader('Sort By'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: SortOption.values.map((sort) {
                        final isSelected = _tempOptions.sortBy == sort;
                        return ChoiceChip(
                          avatar: Icon(
                            sort.icon,
                            size: 16,
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                          ),
                          label: Text(sort.label),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryColor,
                          backgroundColor: Colors.grey.shade100,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textPrimary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 13,
                          ),
                          side: BorderSide(
                            color: isSelected ? AppTheme.primaryColor : AppTheme.cardBorder,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _tempOptions = _tempOptions.copyWith(sortBy: sort);
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // 2. Category
                    _buildSectionHeader('Category'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppConstants.categories.map((cat) {
                        final isSelected = _tempOptions.selectedCategory == cat.id;
                        return FilterChip(
                          avatar: Icon(
                            cat.icon,
                            size: 16,
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                          ),
                          label: Text(cat.name),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryColor,
                          backgroundColor: Colors.grey.shade100,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textPrimary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 13,
                          ),
                          side: BorderSide(
                            color: isSelected ? AppTheme.primaryColor : AppTheme.cardBorder,
                          ),
                          onSelected: (val) {
                            setState(() {
                              _tempOptions = _tempOptions.copyWith(
                                selectedCategory: val ? cat.id : 'All',
                              );
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // 3. Price Range
                    _buildSectionHeader(
                      'Price Range: \$${_tempOptions.priceRange.start.round()} - \$${_tempOptions.priceRange.end.round()}',
                    ),
                    RangeSlider(
                      values: _tempOptions.priceRange,
                      min: FilterOptions.minAvailablePrice,
                      max: FilterOptions.maxAvailablePrice,
                      divisions: 50,
                      activeColor: AppTheme.primaryColor,
                      inactiveColor: Colors.grey.shade200,
                      labels: RangeLabels(
                        '\$${_tempOptions.priceRange.start.round()}',
                        '\$${_tempOptions.priceRange.end.round()}',
                      ),
                      onChanged: (newRange) {
                        setState(() {
                          _tempOptions = _tempOptions.copyWith(priceRange: newRange);
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // 4. Minimum Rating
                    _buildSectionHeader('Minimum Customer Rating'),
                    Row(
                      children: [0.0, 3.0, 4.0, 4.5].map((rating) {
                        final isSelected = _tempOptions.minRating == rating;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                backgroundColor: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.white,
                                side: BorderSide(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : AppTheme.cardBorder,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _tempOptions = _tempOptions.copyWith(minRating: rating);
                                });
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (rating > 0) ...[
                                    Icon(
                                      Icons.star_rounded,
                                      size: 16,
                                      color: isSelected ? Colors.white : AppTheme.starGold,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$rating+',
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      'Any',
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // 5. In Stock Only Switch
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.inventory_2_outlined, color: AppTheme.primaryColor),
                              SizedBox(width: 12),
                              Text(
                                'In Stock Only',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _tempOptions.onlyInStock,
                            activeTrackColor: AppTheme.primaryColor,
                            activeThumbColor: Colors.white,
                            onChanged: (val) {
                              setState(() {
                                _tempOptions = _tempOptions.copyWith(onlyInStock: val);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<ProductProvider>().setFilterOptions(_tempOptions);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}
