import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:groovyn/files/user/product/product_page.dart';
import 'package:groovyn/main.dart';
import 'package:groovyn/widgets/custom_image_widget.dart';
import 'package:groovyn/widgets/sort_filter_widget.dart';
import 'package:groovyn/widgets/product_card.dart';
import 'package:groovyn/services/product_sort_filter_service.dart';
import 'package:groovyn/widgets/premium_loading.dart';

import 'main_landing.dart';

class ListingPage extends StatefulWidget {
  final bool isSearch;
  final String? collection;
  final String? categoryType;
  const ListingPage({super.key, required this.isSearch, this.collection, this.categoryType});

  @override
  State<ListingPage> createState() => ListingPageState();
}

class ListingPageState extends State<ListingPage> with TickerProviderStateMixin {

  List<Map<String, dynamic>> rentals = [];
  List<Map<String, dynamic>> filteredRentals = [];

  bool isSearchActive = false;
  bool isLoading = false;
  bool hasMore = true;

  final TextEditingController searchController = TextEditingController();

  DocumentSnapshot? lastDocument;

  final int pageSize = 10;

  // Sort and Filter state
  SortOption currentSort = SortOption.popularity;
  FilterOptions currentFilter = FilterOptions();
  List<Map<String, dynamic>> allProducts = []; // Store all products for filtering
  late TabController _tabController;
  Timer? _debounce;

  @override
  void initState() {
    // Set correct page ID based on category type
    if (widget.categoryType == 'boutique_trending') {
      theSelectedPageID = 2; // Boutique page
    } else if (widget.categoryType == 'tailor') {
      theSelectedPageID = 5; // Tailor page
    } else {
      theSelectedPageID = 3; // Rental page
    }

    isSearchActive = widget.isSearch;
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
    fetchFavorites();
    fetchRentals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> fetchRentals() async {
    if (isLoading || !hasMore) return;

    setState(() {
      isLoading = true;
    });

    print('ListingPage: Fetching products for categoryType: ${widget.categoryType}');

    Query query = FirebaseFirestore.instance.collection('products').where('status', isEqualTo: true).limit(pageSize);

    // If categoryType is boutique_trending, filter by trending boutique products
    if (widget.categoryType == 'boutique_trending') {
      query = query.where('trending', isEqualTo: true);
      print('ListingPage: Filtering for trending products');
    }

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument!);
    }

    QuerySnapshot querySnapshot = await query.get();
    print('ListingPage: Found ${querySnapshot.docs.length} products from Firestore');

    if (querySnapshot.docs.isNotEmpty) {
      lastDocument = querySnapshot.docs.last;

      for (var doc in querySnapshot.docs) {
        var productData = doc.data() as Map<String, dynamic>;
        productData['documentID'] = doc.id;

        // Get store document
        String? storeID = productData['productStoreID'] ?? productData['storeID'];
        if (storeID == null) continue;

        DocumentSnapshot storeDoc = await FirebaseFirestore.instance
            .collection('stores')
            .doc(storeID)
            .get();

        if (storeDoc.exists) {
          var storeData = storeDoc.data() as Map<String, dynamic>?;
          if (storeData == null) continue;

          String businessField = storeData['businessField'] ?? '';

          // For boutique_trending, only get products from boutique stores
          if (widget.categoryType == 'boutique_trending' && businessField == 'Boutique') {
            rentals.add(productData);
            print('ListingPage: Added boutique product: ${productData['productName']}');
          }
          // For tailor, only get products from tailor stores
          else if (widget.categoryType == 'tailor' && businessField == 'Tailor') {
            rentals.add(productData);
            print('ListingPage: Added tailor product: ${productData['productName']}');
          }
          // For regular listings, get rental products
          else if (widget.categoryType != 'boutique_trending' && widget.categoryType != 'tailor' && businessField == 'Rental') {
            if(widget.collection != null) {
              // Check if product category matches the selected collection
              String productCategory = productData['productCategory']?.toString() ?? '';
              if (productCategory.toLowerCase() == widget.collection.toString().toLowerCase()) {
                rentals.add(productData);
                print('ListingPage: Added rental product with category: ${productData['productName']} (Category: $productCategory)');
              }
            }
            else{
              rentals.add(productData);
              print('ListingPage: Added rental product: ${productData['productName']}');
            }
          }
        }
      }

      print('ListingPage: Total products in rentals list: ${rentals.length}');

      setState(() {
        allProducts = rentals; // Store all products for filtering
        _applySortAndFilter(); // Apply current sort and filter
        hasMore = querySnapshot.docs.length == pageSize;
        print('ListingPage: After filter - filteredRentals: ${filteredRentals.length}');
      });
    } else {
      setState(() {
        hasMore = false;
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  void filterSearchResults(String query) {
    setState(() {
      _applySortAndFilter(); // This will now handle search + sort + filter together
    });
  }

  Future<void> fetchFavorites() async {
    if (theID.isEmpty) {
      setState(() {
        favoriteProductIds = [];
      });
      return;
    }
    
    try {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(theID).get();
      if (userDoc.exists && userDoc.data() != null) {
        setState(() {
          favoriteProductIds = List<String>.from(userDoc['favourites'] ?? []);
        });
      }
    } catch (e) {
      print('Error fetching favorites: $e');
      setState(() {
        favoriteProductIds = [];
      });
    }
  }

  Future<void> addToFavorites(String productId) async {
    DocumentReference userDoc =
    FirebaseFirestore.instance.collection('users').doc(theID);

    if (favoriteProductIds.contains(productId)) {
      setState(() {
        favoriteProductIds.remove(productId);
      });
      await userDoc.update({
        'favourites': FieldValue.arrayRemove([productId])
      });
    } else {
      setState(() {
        favoriteProductIds.add(productId);
      });
      await userDoc.update({
        'favourites': FieldValue.arrayUnion([productId])
      });
    }
  }

  void _applySort(SortOption sortOption) {
    setState(() {
      currentSort = sortOption;
      _applySortAndFilter();
    });
  }

  void _applyFilter(FilterOptions filterOptions) {
    setState(() {
      currentFilter = filterOptions;
      _applySortAndFilter();
    });
  }

  void _applySortAndFilter() {
    List<Map<String, dynamic>> productsToFilter = searchController.text.isEmpty 
        ? allProducts 
        : allProducts.where((product) =>
            product['productName']
                .toString()
                .toLowerCase()
                .contains(searchController.text.toLowerCase())
          ).toList();

    filteredRentals = ProductSortFilterService.applySortAndFilter(
      products: productsToFilter,
      sortOption: currentSort,
      filterOptions: currentFilter,
    );
  }

  void _applyPriceFilter() {
    FilterOptions newFilter = FilterOptions(
      businessType: currentFilter.businessType,
      categories: currentFilter.categories,
      sizes: currentFilter.sizes,
      colors: currentFilter.colors,
      brands: currentFilter.brands,
      priceRange: const RangeValues(0, 5000), // Example price range
      minRating: currentFilter.minRating,
      inStock: currentFilter.inStock,
    );
    _applyFilter(newFilter);
  }

  void _applyBrandFilter() {
    FilterOptions newFilter = FilterOptions(
      businessType: currentFilter.businessType,
      categories: currentFilter.categories,
      sizes: currentFilter.sizes,
      colors: currentFilter.colors,
      brands: ['Nike', 'Adidas'], // Example brands
      priceRange: currentFilter.priceRange,
      minRating: currentFilter.minRating,
      inStock: currentFilter.inStock,
    );
    _applyFilter(newFilter);
  }

  void _applySizeFilter() {
    FilterOptions newFilter = FilterOptions(
      businessType: currentFilter.businessType,
      categories: currentFilter.categories,
      sizes: ['M', 'L', 'XL'], // Example sizes
      colors: currentFilter.colors,
      brands: currentFilter.brands,
      priceRange: currentFilter.priceRange,
      minRating: currentFilter.minRating,
      inStock: currentFilter.inStock,
    );
    _applyFilter(newFilter);
  }

  void _applyColorFilter() {
    FilterOptions newFilter = FilterOptions(
      businessType: currentFilter.businessType,
      categories: currentFilter.categories,
      sizes: currentFilter.sizes,
      colors: ['Black', 'White', 'Blue'], // Example colors
      brands: currentFilter.brands,
      priceRange: currentFilter.priceRange,
      minRating: currentFilter.minRating,
      inStock: currentFilter.inStock,
    );
    _applyFilter(newFilter);
  }

  void _applyRatingFilter() {
    FilterOptions newFilter = FilterOptions(
      businessType: currentFilter.businessType,
      categories: currentFilter.categories,
      sizes: currentFilter.sizes,
      colors: currentFilter.colors,
      brands: currentFilter.brands,
      priceRange: currentFilter.priceRange,
      minRating: 4.0, // Example minimum rating
      inStock: currentFilter.inStock,
    );
    _applyFilter(newFilter);
  }

  void _showPriceRangeDialog() {
    RangeValues tempPriceRange = currentFilter.priceRange;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Price Range',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₹${tempPriceRange.start.round()} - ₹${tempPriceRange.end.round()}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(height: 20),
                  RangeSlider(
                    values: tempPriceRange,
                    min: 0,
                    max: 10000,
                    divisions: 100,
                    activeColor: const Color(0xFF6366F1),
                    onChanged: (values) {
                      setState(() {
                        tempPriceRange = values;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.poppins()),
                ),
                ElevatedButton(
                  onPressed: () {
                    FilterOptions newFilter = FilterOptions(
                      businessType: currentFilter.businessType,
                      categories: currentFilter.categories,
                      sizes: currentFilter.sizes,
                      colors: currentFilter.colors,
                      brands: currentFilter.brands,
                      priceRange: tempPriceRange,
                      minRating: currentFilter.minRating,
                      inStock: currentFilter.inStock,
                    );
                    _applyFilter(newFilter);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                  ),
                  child: Text('Apply', style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBrandFilterDialog() {
    List<String> availableBrands = ['Nike', 'Adidas', 'Puma', 'Reebok', 'Under Armour'];
    List<String> selectedBrands = List.from(currentFilter.brands);
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Select Brands', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: availableBrands.map((brand) {
                    return CheckboxListTile(
                      title: Text(brand, style: GoogleFonts.poppins()),
                      value: selectedBrands.contains(brand),
                      activeColor: const Color(0xFF6366F1),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedBrands.add(brand);
                          } else {
                            selectedBrands.remove(brand);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.poppins()),
                ),
                ElevatedButton(
                  onPressed: () {
                    FilterOptions newFilter = FilterOptions(
                      businessType: currentFilter.businessType,
                      categories: currentFilter.categories,
                      sizes: currentFilter.sizes,
                      colors: currentFilter.colors,
                      brands: selectedBrands,
                      priceRange: currentFilter.priceRange,
                      minRating: currentFilter.minRating,
                      inStock: currentFilter.inStock,
                    );
                    _applyFilter(newFilter);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                  ),
                  child: Text('Apply', style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSizeFilterDialog() {
    List<String> availableSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
    List<String> selectedSizes = List.from(currentFilter.sizes);
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Select Sizes', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: availableSizes.map((size) {
                    return CheckboxListTile(
                      title: Text(size, style: GoogleFonts.poppins()),
                      value: selectedSizes.contains(size),
                      activeColor: const Color(0xFF6366F1),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedSizes.add(size);
                          } else {
                            selectedSizes.remove(size);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.poppins()),
                ),
                ElevatedButton(
                  onPressed: () {
                    FilterOptions newFilter = FilterOptions(
                      businessType: currentFilter.businessType,
                      categories: currentFilter.categories,
                      sizes: selectedSizes,
                      colors: currentFilter.colors,
                      brands: currentFilter.brands,
                      priceRange: currentFilter.priceRange,
                      minRating: currentFilter.minRating,
                      inStock: currentFilter.inStock,
                    );
                    _applyFilter(newFilter);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                  ),
                  child: Text('Apply', style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showColorFilterDialog() {
    List<String> availableColors = ['Black', 'White', 'Red', 'Blue', 'Green', 'Yellow', 'Pink'];
    List<String> selectedColors = List.from(currentFilter.colors);
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Select Colors', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: availableColors.map((color) {
                    return CheckboxListTile(
                      title: Text(color, style: GoogleFonts.poppins()),
                      value: selectedColors.contains(color),
                      activeColor: const Color(0xFF6366F1),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedColors.add(color);
                          } else {
                            selectedColors.remove(color);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.poppins()),
                ),
                ElevatedButton(
                  onPressed: () {
                    FilterOptions newFilter = FilterOptions(
                      businessType: currentFilter.businessType,
                      categories: currentFilter.categories,
                      sizes: currentFilter.sizes,
                      colors: selectedColors,
                      brands: currentFilter.brands,
                      priceRange: currentFilter.priceRange,
                      minRating: currentFilter.minRating,
                      inStock: currentFilter.inStock,
                    );
                    _applyFilter(newFilter);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                  ),
                  child: Text('Apply', style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRatingFilterDialog() {
    double tempRating = currentFilter.minRating;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Minimum Rating', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${tempRating.toStringAsFixed(1)} stars and above',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Slider(
                    value: tempRating,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    activeColor: const Color(0xFF6366F1),
                    onChanged: (value) {
                      setState(() {
                        tempRating = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.poppins()),
                ),
                ElevatedButton(
                  onPressed: () {
                    FilterOptions newFilter = FilterOptions(
                      businessType: currentFilter.businessType,
                      categories: currentFilter.categories,
                      sizes: currentFilter.sizes,
                      colors: currentFilter.colors,
                      brands: currentFilter.brands,
                      priceRange: currentFilter.priceRange,
                      minRating: tempRating,
                      inStock: currentFilter.inStock,
                    );
                    _applyFilter(newFilter);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                  ),
                  child: Text('Apply', style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSortFilterSheet() {
    showSortFilterSheet(
      context: context,
      onSortChanged: _applySort,
      onFilterChanged: _applyFilter,
      currentSort: currentSort,
      currentFilter: currentFilter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color.fromRGBO(250, 250, 250, 1),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildSearchBar(),
            const SizedBox(height: 20),
            _buildRentalsList(),
          ],
        ),
      ),
      floatingActionButton: _buildBottomSortFilter(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: returnBottomBar(context),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isSearchActive ? const Color(0xFF6366F1) : Colors.grey.shade300, 
          width: isSearchActive ? 2 : 1
        ),
        boxShadow: [
          BoxShadow(
            color: isSearchActive 
                ? const Color(0xFF6366F1).withOpacity(0.1)
                : const Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: isSearchActive ? 20 : 8,
            offset: const Offset(0, 2),
            spreadRadius: isSearchActive ? 1 : 0,
          )
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              if (!isSearchActive) {
                Navigator.pop(context);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: !isSearchActive ? Colors.grey.shade100 : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                !isSearchActive ? Icons.arrow_back_ios : Icons.search,
                color: !isSearchActive ? Colors.grey.shade700 : const Color(0xFF6366F1),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (!isSearchActive)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    isSearchActive = true;
                  });
                },
                child: Container(
                  height: 40,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_outlined,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.categoryType == 'tailor' ? 'Search tailors...' : 
                        widget.categoryType == 'boutique_trending' ? 'Search boutiques...' : 'Search rentals...',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade500,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (isSearchActive)
            Expanded(
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  // Add debounce for smoother search
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () {
                    filterSearchResults(value);
                  });
                },
                autofocus: true,
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
                decoration: InputDecoration(
                  hintText: 'Search products, brands...',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey.shade400,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          if (isSearchActive && searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                searchController.clear();
                _applySortAndFilter();
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.clear,
                  color: Colors.grey.shade600,
                  size: 16,
                ),
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                isSearchActive = !isSearchActive;
                if (!isSearchActive) {
                  searchController.clear();
                  _applySortAndFilter();
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSearchActive ? const Color(0xFF6366F1) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isSearchActive ? Icons.keyboard_arrow_up : Icons.search,
                color: isSearchActive ? Colors.white : Colors.grey.shade600,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Products (${filteredRentals.length})',
      style: GoogleFonts.montserrat(
        textStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontFamily: 'Manrope',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return currentFilter.businessType != 'All' ||
           currentFilter.categories.isNotEmpty ||
           currentFilter.sizes.isNotEmpty ||
           currentFilter.colors.isNotEmpty ||
           currentFilter.brands.isNotEmpty ||
           currentFilter.priceRange.start > 0 ||
           currentFilter.priceRange.end < 10000 ||
           currentFilter.minRating > 0 ||
           currentFilter.inStock;
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Sort By',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                _buildSortOption('Popularity', Icons.trending_up),
                _buildSortOption('Latest', Icons.access_time),
                _buildSortOption('Discount', Icons.local_offer),
                _buildSortOption('Price: High to Low', Icons.arrow_downward),
                _buildSortOption('Price: Low to High', Icons.arrow_upward),
                _buildSortOption('Customer Rating', Icons.star),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Options',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          currentFilter = FilterOptions();
                          _applySortAndFilter();
                        });
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Reset',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFFF3F6C),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildFilterOption('Price Range', Icons.attach_money),
                _buildFilterOption('Brand', Icons.business),
                _buildFilterOption('Size', Icons.straighten),
                _buildFilterOption('Color', Icons.palette),
                _buildFilterOption('Customer Rating', Icons.star),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        // Handle sort selection - you can integrate with existing sort logic
        if (title == 'Popularity') {
          _applySort(SortOption.popularity);
        } else if (title == 'Latest') {
          _applySort(SortOption.newest);
        } else if (title == 'Price: High to Low') {
          _applySort(SortOption.priceHighToLow);
        } else if (title == 'Price: Low to High') {
          _applySort(SortOption.priceLowToHigh);
        } else if (title == 'Customer Rating') {
          _applySort(SortOption.rating);
        }
      },
    );
  }

  Widget _buildFilterOption(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
      onTap: () {
        Navigator.pop(context);
        // Show specific filter dialog based on selection
        if (title == 'Price Range') {
          _showPriceRangeDialog();
        } else if (title == 'Brand') {
          _showBrandFilterDialog();
        } else if (title == 'Size') {
          _showSizeFilterDialog();
        } else if (title == 'Color') {
          _showColorFilterDialog();
        } else if (title == 'Customer Rating') {
          _showRatingFilterDialog();
        }
      },
    );
  }
  
  Widget _buildBottomSortFilter() {
    return Container(
      width: MediaQuery.of(context).size.width - 32,
      margin: const EdgeInsets.only(bottom: 80), // Position above bottom navigation
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 4),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            // Sort button
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(25),
                  onTap: () {
                    _showSortOptions();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.sort,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sort',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Filter button
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(25),
                  onTap: () {
                    _showFilterOptions();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _hasActiveFilters() ? const Color(0xFFFF3F6C) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.tune,
                          size: 18,
                          color: _hasActiveFilters() ? Colors.white : Colors.grey.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Filter',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _hasActiveFilters() ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                        if (_hasActiveFilters()) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
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

  Widget _buildRentalsList() {
    return Expanded(
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
              !isLoading &&
              hasMore) {
            fetchRentals();
          }
          return false;
        },
        child: isLoading ?
        Center(child: PremiumLoadingWidget(message: "Loading products...")) : filteredRentals.isNotEmpty
            ? GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.7,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: filteredRentals.length,
          itemBuilder: (context, index) {
            final product = filteredRentals[index];
            return ProductCard(
              imageUrl: _getImageUrl(product),
              name: product['productBrand']?.toString() ?? 'Fashion Brand',
              description: product['productName']?.toString() ?? 'Stylish Fashion Item',
              price: _getPrice(product),
              originalPrice: _getOriginalPrice(product),
              isFavorite: favoriteProductIds.contains(product['documentID']),
              rating: _getRating(product),
              totalRatings: _getTotalRatings(product),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductPage(
                      productID: product['documentID'],
                    ),
                  ),
                );
              },
              onFavoriteToggle: () {
                addToFavorites(product['documentID']);
              },
            );
          },
        ) : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 50, color: Colors.grey[400]),
                SizedBox(height: 10),
                Text(
                  'No products found',
                  style: GoogleFonts.montserrat(
                    color: Colors.grey[600],
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildRentalItem(Map<String, dynamic> rental, bool isFavorite) {
    return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProductPage(
                    productID: rental['documentID'],
                  ),
            ),
          );
        },
        child: Container(
            width: (MediaQuery
                .of(context)
                .size
                .width / 2) - 44,
            height: 200,
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              shadows: [
                const BoxShadow(
                  color: Color(0x3F000000),
                  blurRadius: 2,
                  offset: Offset(2, 2),
                )
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: CustomImageWidget(
                    imageUrl: rental['productImages'][0],
                    fit: BoxFit.cover,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              rental['productName'].toString().length > 7 ? '${rental['productName'].toString().substring(0,7)}...' : rental['productName'].toString(),
                              style: GoogleFonts.roboto(
                                textStyle: const TextStyle(
                                  color: Colors.black,
                                  fontFamily: 'Manrope',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => addToFavorites(rental['documentID']),
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite ? Colors.red : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rental['productDescription'].toString().length > 7 ? '${rental['productDescription'].toString().substring(0,7)}...' : rental['productDescription'].toString(),
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                '₹${rental['productPrice'] ?? '0'}',
                                style: GoogleFonts.poppins(
                                  textStyle: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '30% OFF',
                              style: GoogleFonts.poppins(
                                textStyle: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 10,
                                  fontFamily: 'Manrope',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              ],
            )
        )
    );
  }

  String _getImageUrl(Map<String, dynamic> product) {
    if (product['productImages'] != null) {
      final images = product['productImages'];
      if (images is List && images.isNotEmpty) {
        String url = images[0]?.toString() ?? '';
        if (!url.contains('placeholder') && url.isNotEmpty) {
          return url;
        }
      } else if (images is String && images.isNotEmpty) {
        String url = images;
        if (!url.contains('placeholder') && url.isNotEmpty) {
          return url;
        }
      }
    }
    return 'https://via.placeholder.com/300';
  }

  int _getPrice(Map<String, dynamic> product) {
    // Check if there's a dynamic discount to apply
    final originalPrice = _getOriginalPriceRaw(product);
    if (originalPrice != null) {
      final discount = _getDiscountPercentage(product);
      if (discount > 0) {
        return (originalPrice * (1 - discount / 100)).round();
      }
    }
    
    final price = product['productPrice'];
    if (price == null) return 349;
    
    String priceStr = price.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    if (priceStr.isEmpty) return 349;
    
    try {
      double priceValue = double.parse(priceStr);
      return priceValue.toInt();
    } catch (e) {
      return 349;
    }
  }

  int? _getOriginalPriceRaw(Map<String, dynamic> product) {
    // Get raw original price without discount calculation
    final originalPrice = product['originalPrice'] ?? 
                         product['mrp'] ?? 
                         product['productOriginalPrice'] ?? 
                         product['productMRP'];
    if (originalPrice == null) return null;
    
    String priceStr = originalPrice.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    if (priceStr.isEmpty) return null;
    
    try {
      return double.parse(priceStr).toInt();
    } catch (e) {
      return null;
    }
  }

  int? _getOriginalPrice(Map<String, dynamic> product) {
    // First check for explicit original price fields
    final originalPrice = _getOriginalPriceRaw(product);
    if (originalPrice != null) {
      int currentPrice = _getPrice(product);
      // Only show original price if it's higher than current price
      return originalPrice > currentPrice ? originalPrice : null;
    }
    
    // Fallback: calculate from current price if discount exists
    final discount = _getDiscountPercentage(product);
    if (discount > 0) {
      final currentPriceRaw = product['productPrice'];
      if (currentPriceRaw != null) {
        String priceStr = currentPriceRaw.toString().replaceAll(RegExp(r'[^0-9.]'), '');
        if (priceStr.isNotEmpty) {
          try {
            double price = double.parse(priceStr);
            // Calculate original price from discounted price
            return (price / (1 - discount / 100)).round();
          } catch (e) {
            // Continue to return null
          }
        }
      }
    }
    
    return null;
  }
  
  double _getDiscountPercentage(Map<String, dynamic> product) {
    final discount = product['discount'] ?? 
                    product['productDiscount'] ?? 
                    product['discountPercentage'] ??
                    product['discountPercent'];
    if (discount == null) return 0.0;
    
    try {
      if (discount is num) {
        return discount.toDouble();
      } else if (discount is String) {
        // Remove % symbol if present
        String discountStr = discount.replaceAll('%', '').replaceAll(RegExp(r'[^0-9.]'), '');
        if (discountStr.isNotEmpty) {
          return double.parse(discountStr);
        }
      }
    } catch (e) {
      // Return 0 if parsing fails
    }
    
    return 0.0;
  }

  double _getRating(Map<String, dynamic> product) {
    final rating = product['rating'];
    if (rating == null) return 4.5;
    
    try {
      return double.parse(rating.toString());
    } catch (e) {
      return 4.5;
    }
  }

  int _getTotalRatings(Map<String, dynamic> product) {
    final total = product['total'] ?? product['totalRatings'] ?? product['reviewCount'];
    if (total == null) return 0;
    
    try {
      return int.parse(total.toString());
    } catch (e) {
      return 0;
    }
  }
}
