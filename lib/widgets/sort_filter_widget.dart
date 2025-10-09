import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum SortOption {
  priceLowToHigh,
  priceHighToLow,
  popularity,
  rating,
  newest,
  name,
}

class FilterOptions {
  final List<String> categories;
  final List<String> sizes;
  final List<String> colors;
  final List<String> brands;
  final RangeValues priceRange;
  final double minRating;
  final bool inStock;
  final String businessType; // 'All', 'Boutique', 'Rental', 'Tailor', 'Fabric'

  FilterOptions({
    this.categories = const [],
    this.sizes = const [],
    this.colors = const [],
    this.brands = const [],
    this.priceRange = const RangeValues(0, 10000),
    this.minRating = 0,
    this.inStock = false,
    this.businessType = 'All',
  });

  FilterOptions copyWith({
    List<String>? categories,
    List<String>? sizes,
    List<String>? colors,
    List<String>? brands,
    RangeValues? priceRange,
    double? minRating,
    bool? inStock,
    String? businessType,
  }) {
    return FilterOptions(
      categories: categories ?? this.categories,
      sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors,
      brands: brands ?? this.brands,
      priceRange: priceRange ?? this.priceRange,
      minRating: minRating ?? this.minRating,
      inStock: inStock ?? this.inStock,
      businessType: businessType ?? this.businessType,
    );
  }
}

class SortFilterWidget extends StatefulWidget {
  final Function(SortOption) onSortChanged;
  final Function(FilterOptions) onFilterChanged;
  final SortOption currentSort;
  final FilterOptions currentFilter;

  const SortFilterWidget({
    Key? key,
    required this.onSortChanged,
    required this.onFilterChanged,
    required this.currentSort,
    required this.currentFilter,
  }) : super(key: key);

  @override
  State<SortFilterWidget> createState() => _SortFilterWidgetState();
}

class _SortFilterWidgetState extends State<SortFilterWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FilterOptions _tempFilter;

  final List<String> _availableCategories = [
    'Men\'s Wear',
    'Women\'s Wear',
    'Kids Wear',
    'Traditional',
    'Western',
    'Ethnic',
    'Casual',
    'Formal',
    'Party Wear',
    'Wedding Collection',
  ];

  final List<String> _availableSizes = [
    'XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL', 
    '28', '30', '32', '34', '36', '38', '40', '42'
  ];

  final List<String> _availableColors = [
    'Black', 'White', 'Red', 'Blue', 'Green', 'Yellow', 
    'Pink', 'Purple', 'Orange', 'Brown', 'Gray', 'Navy',
    'Maroon', 'Beige', 'Cream', 'Gold', 'Silver'
  ];

  final List<String> _availableBrands = [
    'Generic', 'Local Brand', 'Designer', 'Premium', 'Luxury', 'Custom'
  ];

  final List<String> _businessTypes = [
    'All', 'Boutique', 'Rental', 'Tailor', 'Fabric'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tempFilter = widget.currentFilter;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sort & Filter',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: _resetFilters,
                  child: Text(
                    'Reset',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF1976D2),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            labelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Sort'),
              Tab(text: 'Filter'),
            ],
          ),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSortTab(),
                _buildFilterTab(),
              ],
            ),
          ),

          // Apply Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _applyChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Apply Changes',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSortOption(SortOption.popularity, 'Popularity', Icons.trending_up),
          _buildSortOption(SortOption.priceLowToHigh, 'Price: Low to High', Icons.arrow_upward),
          _buildSortOption(SortOption.priceHighToLow, 'Price: High to Low', Icons.arrow_downward),
          _buildSortOption(SortOption.rating, 'Customer Rating', Icons.star),
          _buildSortOption(SortOption.newest, 'Newest First', Icons.fiber_new),
          _buildSortOption(SortOption.name, 'Name: A to Z', Icons.sort_by_alpha),
        ],
      ),
    );
  }

  Widget _buildSortOption(SortOption option, String title, IconData icon) {
    final isSelected = widget.currentSort == option;
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            widget.onSortChanged(option);
            // Add small delay before closing to show selection
            Future.delayed(Duration(milliseconds: 150), () {
              Navigator.pop(context);
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.black : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              color: isSelected ? Colors.black.withOpacity(0.05) : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.black : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.black : Colors.grey.shade700,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Colors.black,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBusinessTypeFilter(),
          const SizedBox(height: 20),
          _buildPriceRangeFilter(),
          const SizedBox(height: 20),
          _buildRatingFilter(),
          const SizedBox(height: 20),
          _buildMultiSelectFilter('Categories', _availableCategories, _tempFilter.categories),
          const SizedBox(height: 20),
          _buildMultiSelectFilter('Sizes', _availableSizes, _tempFilter.sizes),
          const SizedBox(height: 20),
          _buildMultiSelectFilter('Colors', _availableColors, _tempFilter.colors),
          const SizedBox(height: 20),
          _buildMultiSelectFilter('Brands', _availableBrands, _tempFilter.brands),
          const SizedBox(height: 20),
          _buildStockFilter(),
        ],
      ),
    );
  }

  Widget _buildBusinessTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Store Type',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _businessTypes.map((type) {
            final isSelected = _tempFilter.businessType == type;
            return FilterChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _tempFilter = _tempFilter.copyWith(businessType: type);
                });
              },
              selectedColor: const Color.fromRGBO(0, 0, 0, 0.1),
              checkmarkColor: Colors.black,
              labelStyle: GoogleFonts.montserrat(
                color: isSelected ? Colors.black : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: _tempFilter.priceRange,
          min: 0,
          max: 50000,
          divisions: 100,
          labels: RangeLabels(
            '₹${_tempFilter.priceRange.start.round()}',
            '₹${_tempFilter.priceRange.end.round()}',
          ),
          activeColor: Colors.black,
          onChanged: (RangeValues values) {
            setState(() {
              _tempFilter = _tempFilter.copyWith(priceRange: values);
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '₹${_tempFilter.priceRange.start.round()}',
              style: GoogleFonts.montserrat(fontSize: 12),
            ),
            Text(
              '₹${_tempFilter.priceRange.end.round()}',
              style: GoogleFonts.montserrat(fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minimum Rating',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Slider(
          value: _tempFilter.minRating,
          min: 0,
          max: 5,
          divisions: 5,
          label: '${_tempFilter.minRating.round()} Stars',
          activeColor: Colors.black,
          onChanged: (double value) {
            setState(() {
              _tempFilter = _tempFilter.copyWith(minRating: value);
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0 Stars', style: GoogleFonts.montserrat(fontSize: 12)),
            Text('5 Stars', style: GoogleFonts.montserrat(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildMultiSelectFilter(String title, List<String> options, List<String> selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (bool selectedValue) {
                setState(() {
                  List<String> newSelected = List.from(selected);
                  if (selectedValue) {
                    newSelected.add(option);
                  } else {
                    newSelected.remove(option);
                  }
                  
                  if (title == 'Categories') {
                    _tempFilter = _tempFilter.copyWith(categories: newSelected);
                  } else if (title == 'Sizes') {
                    _tempFilter = _tempFilter.copyWith(sizes: newSelected);
                  } else if (title == 'Colors') {
                    _tempFilter = _tempFilter.copyWith(colors: newSelected);
                  } else if (title == 'Brands') {
                    _tempFilter = _tempFilter.copyWith(brands: newSelected);
                  }
                });
              },
              selectedColor: const Color.fromRGBO(0, 0, 0, 0.1),
              checkmarkColor: Colors.black,
              labelStyle: GoogleFonts.montserrat(
                fontSize: 12,
                color: isSelected ? Colors.black : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStockFilter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Only In Stock Items',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Switch(
          value: _tempFilter.inStock,
          activeColor: Colors.black,
          onChanged: (bool value) {
            setState(() {
              _tempFilter = _tempFilter.copyWith(inStock: value);
            });
          },
        ),
      ],
    );
  }

  void _resetFilters() {
    setState(() {
      _tempFilter = FilterOptions();
    });
    widget.onSortChanged(SortOption.popularity);
  }

  void _applyChanges() {
    widget.onFilterChanged(_tempFilter);
    Navigator.pop(context);
  }

  List<String> _getSelectedForTitle(String title) {
    switch (title) {
      case 'Categories':
        return _tempFilter.categories;
      case 'Sizes':
        return _tempFilter.sizes;
      case 'Colors':
        return _tempFilter.colors;
      case 'Brands':
        return _tempFilter.brands;
      default:
        return [];
    }
  }
}

// Helper function to show sort/filter bottom sheet
void showSortFilterSheet({
  required BuildContext context,
  required Function(SortOption) onSortChanged,
  required Function(FilterOptions) onFilterChanged,
  required SortOption currentSort,
  required FilterOptions currentFilter,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SortFilterWidget(
      onSortChanged: onSortChanged,
      onFilterChanged: onFilterChanged,
      currentSort: currentSort,
      currentFilter: currentFilter,
    ),
  );
}