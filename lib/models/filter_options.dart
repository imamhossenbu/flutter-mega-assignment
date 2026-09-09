import 'package:flutter/material.dart';

enum SortOption {
  featured('Featured', Icons.star_border_rounded),
  priceLowToHigh('Price: Low to High', Icons.arrow_upward_rounded),
  priceHighToLow('Price: High to Low', Icons.arrow_downward_rounded),
  ratingHighToLow('Customer Rating', Icons.thumb_up_alt_outlined),
  discountHighToLow('Biggest Discount', Icons.local_offer_outlined);

  final String label;
  final IconData icon;
  const SortOption(this.label, this.icon);
}

class FilterOptions {
  final String searchQuery;
  final String selectedCategory;
  final RangeValues priceRange;
  final double minRating;
  final bool onlyInStock;
  final SortOption sortBy;

  static const double minAvailablePrice = 0.0;
  static const double maxAvailablePrice = 2500.0;

  const FilterOptions({
    this.searchQuery = '',
    this.selectedCategory = 'All',
    this.priceRange = const RangeValues(minAvailablePrice, maxAvailablePrice),
    this.minRating = 0.0,
    this.onlyInStock = false,
    this.sortBy = SortOption.featured,
  });

  bool get hasActiveFilters {
    return selectedCategory != 'All' ||
        priceRange.start > minAvailablePrice ||
        priceRange.end < maxAvailablePrice ||
        minRating > 0.0 ||
        onlyInStock ||
        sortBy != SortOption.featured ||
        searchQuery.trim().isNotEmpty;
  }

  int get filterBadgeCount {
    int count = 0;
    if (selectedCategory != 'All') count++;
    if (priceRange.start > minAvailablePrice || priceRange.end < maxAvailablePrice) count++;
    if (minRating > 0.0) count++;
    if (onlyInStock) count++;
    if (sortBy != SortOption.featured) count++;
    return count;
  }

  FilterOptions reset() {
    return const FilterOptions();
  }

  FilterOptions copyWith({
    String? searchQuery,
    String? selectedCategory,
    RangeValues? priceRange,
    double? minRating,
    bool? onlyInStock,
    SortOption? sortBy,
  }) {
    return FilterOptions(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      priceRange: priceRange ?? this.priceRange,
      minRating: minRating ?? this.minRating,
      onlyInStock: onlyInStock ?? this.onlyInStock,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}
