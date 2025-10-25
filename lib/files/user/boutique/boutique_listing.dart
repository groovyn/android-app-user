import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:groovyn/files/user/product/product_page.dart';
import 'package:groovyn/main.dart';
import 'package:groovyn/widgets/premium_loading.dart';
import 'package:groovyn/widgets/product_card.dart';

import '../mains/main_landing.dart';

class BoutiqueListing extends StatefulWidget {
  const BoutiqueListing({super.key});

  @override
  State<BoutiqueListing> createState() => BoutiqueListingState();
}

class BoutiqueListingState extends State<BoutiqueListing> {
  List<Map<String, dynamic>> rentals = [];
  List<Map<String, dynamic>> filteredRentals = [];

  bool isSearchActive = false;
  bool isLoading = false;
  bool hasMore = true;

  String currentSort = 'Popularity'; // Track current sort option

  // Category filter
  String? selectedCategory;
  final List<String> categories = [
    "All",
    "Suit Men",
    "Kurta Men",
    "Saree",
    "Lehenga",
    "Sherwani",
    "Gown",
    "Kurtis"
  ];

  // Filter options
  RangeValues priceRange = const RangeValues(0, 10000);
  List<String> selectedBrands = [];
  List<String> selectedSizes = [];
  List<String> selectedColors = [];
  double minRating = 0;
  bool inStockOnly = false;

  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    theSelectedPageID = 2;
    super.initState();
    fetchFavorites();
    fetchRentals();
  }

  @override
  void dispose() {
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> fetchRentals() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      // First, get all boutique store IDs
      QuerySnapshot storesSnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .where('businessField', isEqualTo: 'Boutique')
          .get();

      if (storesSnapshot.docs.isEmpty) {
        print('No boutique stores found');
        setState(() {
          rentals = [];
          filteredRentals = [];
          hasMore = false;
        });
        return;
      }

      // Get store IDs
      List<String> boutiqueStoreIds = storesSnapshot.docs.map((doc) => doc.id).toList();
      print('Found ${boutiqueStoreIds.length} boutique stores: $boutiqueStoreIds');

      // Firestore has a limit of 10 items for whereIn, so we need to chunk the store IDs
      List<Map<String, dynamic>> allProducts = [];

      // Process store IDs in chunks of 10
      for (int i = 0; i < boutiqueStoreIds.length; i += 10) {
        List<String> chunk = boutiqueStoreIds.sublist(
          i,
          (i + 10 > boutiqueStoreIds.length) ? boutiqueStoreIds.length : i + 10
        );

        QuerySnapshot productsSnapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('status', isEqualTo: true)
            .where('productStoreID', whereIn: chunk)
            .limit(50)
            .get();

        print('Found ${productsSnapshot.docs.length} products for chunk: $chunk');

        for (var doc in productsSnapshot.docs) {
          var productData = doc.data() as Map<String, dynamic>;
          productData['documentID'] = doc.id;
          allProducts.add(productData);
        }
      }

      print('Total boutique products found: ${allProducts.length}');

      setState(() {
        rentals = allProducts;
        filteredRentals = allProducts;
        hasMore = false; // Simplified for now
      });

    } catch (e) {
      print('Error fetching boutique products: $e');
      setState(() {
        rentals = [];
        filteredRentals = [];
        hasMore = false;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterSearchResults(String query) {
    setState(() {
      filteredRentals = rentals.where((rental) {
        // Search filter
        if (query.isNotEmpty) {
          final productName = rental['productName']?.toString().toLowerCase() ?? '';
          final productBrand = rental['productBrand']?.toString().toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();
          if (!productName.contains(searchQuery) && !productBrand.contains(searchQuery)) {
            return false;
          }
        }

        // Category filter
        if (selectedCategory != null && selectedCategory != "All") {
          final productName = rental['productName']?.toString().toLowerCase() ?? '';
          if (!productName.contains(selectedCategory!.toLowerCase())) {
            return false;
          }
        }

        // Apply all other filters
        return _applyFilters(rental);
      }).toList();
      _applySorting(); // Apply current sort after filtering
    });
  }

  bool _applyFilters(Map<String, dynamic> product) {
    // Category filter
    if (selectedCategory != null && selectedCategory != "All") {
      final productName = product['productName']?.toString().toLowerCase() ?? '';
      if (!productName.contains(selectedCategory!.toLowerCase())) {
        return false;
      }
    }

    // Price range filter
    int price = _getPrice(product);
    if (price < priceRange.start || price > priceRange.end) {
      return false;
    }

    // Brand filter
    if (selectedBrands.isNotEmpty) {
      String brand = product['productBrand']?.toString() ?? '';
      if (!selectedBrands.contains(brand)) {
        return false;
      }
    }

    // Size filter
    if (selectedSizes.isNotEmpty) {
      List<dynamic> sizes = product['productSizes'] ?? [];
      bool hasMatchingSize = false;
      for (var size in selectedSizes) {
        if (sizes.contains(size)) {
          hasMatchingSize = true;
          break;
        }
      }
      if (!hasMatchingSize) {
        return false;
      }
    }

    // Rating filter
    if (minRating > 0) {
      double rating = _getRating(product);
      if (rating < minRating) {
        return false;
      }
    }

    // In stock filter
    if (inStockOnly) {
      String stockStatus = product['productStock']?.toString() ?? 'Out of Stock';
      if (stockStatus == 'Out of Stock') {
        return false;
      }
    }

    return true;
  }

  void _applyAllFilters() {
    setState(() {
      filteredRentals = rentals.where((rental) => _applyFilters(rental)).toList();
      _applySorting();
    });
  }

  void _applySorting() {
    switch (currentSort) {
      case 'Price: High to Low':
        filteredRentals.sort((a, b) {
          int priceA = _getPrice(a);
          int priceB = _getPrice(b);
          return priceB.compareTo(priceA);
        });
        break;
      case 'Price: Low to High':
        filteredRentals.sort((a, b) {
          int priceA = _getPrice(a);
          int priceB = _getPrice(b);
          return priceA.compareTo(priceB);
        });
        break;
      case 'Customer Rating':
        filteredRentals.sort((a, b) {
          double ratingA = _getRating(a);
          double ratingB = _getRating(b);
          return ratingB.compareTo(ratingA);
        });
        break;
      case 'Discount':
        filteredRentals.sort((a, b) {
          int discountA = _getDiscountPercentage(a);
          int discountB = _getDiscountPercentage(b);
          return discountB.compareTo(discountA);
        });
        break;
      case 'Latest':
        filteredRentals.sort((a, b) {
          String timeA = a['productTime']?.toString() ?? '';
          String timeB = b['productTime']?.toString() ?? '';
          return timeB.compareTo(timeA);
        });
        break;
      case 'Popularity':
      default:
        filteredRentals.sort((a, b) {
          int ratingsA = _getTotalRatings(a);
          int ratingsB = _getTotalRatings(b);
          return ratingsB.compareTo(ratingsA);
        });
        break;
    }
  }

  int _getDiscountPercentage(Map<String, dynamic> product) {
    final originalPrice = _getOriginalPrice(product);
    if (originalPrice == null) return 0;

    final currentPrice = _getPrice(product);
    if (currentPrice >= originalPrice) return 0;

    return (((originalPrice - currentPrice) / originalPrice) * 100).round();
  }

  Future<void> fetchFavorites() async {
    if (theID.isEmpty) {
      setState(() {
        favoriteProductIds = [];
      });
      return;
    }

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(theID).get();
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
    DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(theID);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(250, 250, 250, 1),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildSearchBar(),
            const SizedBox(height: 16),
            _buildCategoryScroller(),
            const SizedBox(height: 16),
            Expanded(
              child: _buildRentalsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildBottomSortFilter(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: returnBottomBar(context),
    );
  }

  Widget _buildCategoryScroller() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category || (selectedCategory == null && category == "All");

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = category;
                filterSearchResults(searchController.text);
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  category,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.black87,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          );
        },
      ),
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
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.arrow_back,
                color: Colors.grey.shade700,
                size: 22,
              ),
            ),
          ),
          if (!isSearchActive)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Boutique Products',
                      style: GoogleFonts.poppins(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (filteredRentals.isNotEmpty)
                      Text(
                        '${filteredRentals.length} items',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.2,
                        ),
                      ),
                  ],
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
                filterSearchResults('');
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
                  filterSearchResults('');
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

  Widget _buildRentalsList() {
    if (isLoading) {
      return Center(
        child: PremiumLoadingWidget(
          message: 'Loading boutique products...',
          size: 70,
        ),
      );
    }

    if (filteredRentals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No boutique products found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new arrivals',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.65, // Increased card height for better appearance
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredRentals.length,
      itemBuilder: (context, index) {
        final product = filteredRentals[index];
        return ProductCard(
          imageUrl: _getImageUrl(product),
          name: product['productName']?.toString() ?? 'Fashion Item',
          description: product['productBrand']?.toString() ?? 'Brand',
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

  int? _getOriginalPrice(Map<String, dynamic> product) {
    final originalPrice = product['originalPrice'] ?? product['mrp'];
    if (originalPrice == null) return null;

    String priceStr = originalPrice.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    if (priceStr.isEmpty) return null;

    try {
      double priceValue = double.parse(priceStr);
      int originalPriceInt = priceValue.toInt();
      int currentPrice = _getPrice(product);
      // Only show original price if it's higher than current price
      return originalPriceInt > currentPrice ? originalPriceInt : null;
    } catch (e) {
      return null;
    }
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.swap_vert,
                          color: Colors.grey.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sort',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Divider
            Container(
              height: 30,
              width: 1,
              color: Colors.grey.shade300,
            ),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.tune,
                          color: Colors.grey.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Filter',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                            letterSpacing: 0.3,
                          ),
                        ),
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

  Widget _buildSortOption(String title, IconData icon) {
    bool isSelected = currentSort == title;
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade600),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? const Color(0xFF6366F1) : Colors.black87,
        ),
      ),
      trailing: isSelected
        ? Icon(Icons.check, size: 20, color: const Color(0xFF6366F1))
        : Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
      onTap: () {
        setState(() {
          currentSort = title;
          _applySorting();
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sorted by: $title'),
            duration: const Duration(seconds: 1),
            backgroundColor: const Color(0xFF6366F1),
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
                          priceRange = const RangeValues(0, 10000);
                          selectedCategory = null;
                          selectedBrands = [];
                          selectedSizes = [];
                          selectedColors = [];
                          minRating = 0;
                          inStockOnly = false;
                          _applyAllFilters();
                        });
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Clear All',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildFilterOption('Price Range', Icons.attach_money),
                _buildFilterOption('Category', Icons.category),
                _buildFilterOption('Brand', Icons.local_offer),
                _buildFilterOption('Size', Icons.straighten),
                _buildFilterOption('Color', Icons.palette),
                _buildFilterOption('Customer Rating', Icons.star),
                _buildFilterOption('In Stock', Icons.inventory),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
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
        } else if (title == 'Category') {
          _showCategoryFilterDialog();
        } else if (title == 'Brand') {
          _showBrandFilterDialog();
        } else if (title == 'Size') {
          _showSizeFilterDialog();
        } else if (title == 'Color') {
          _showColorFilterDialog();
        } else if (title == 'Customer Rating') {
          _showRatingFilterDialog();
        } else if (title == 'In Stock') {
          _showInStockFilterDialog();
        }
      },
    );
  }

  void _showCategoryFilterDialog() {
    String? tempSelectedCategory = selectedCategory;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Select Category', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: categories.map((category) {
                    return RadioListTile<String>(
                      title: Text(category, style: GoogleFonts.poppins()),
                      value: category,
                      groupValue: tempSelectedCategory ?? "All",
                      activeColor: const Color(0xFF6366F1),
                      onChanged: (String? value) {
                        setDialogState(() {
                          tempSelectedCategory = value;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedCategory = tempSelectedCategory;
                      _applyAllFilters();
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                  child: Text('Apply', style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPriceRangeDialog() {
    RangeValues tempRange = priceRange;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Price Range', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₹${tempRange.start.round()} - ₹${tempRange.end.round()}',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  RangeSlider(
                    values: tempRange,
                    min: 0,
                    max: 10000,
                    divisions: 100,
                    activeColor: const Color(0xFF6366F1),
                    labels: RangeLabels(
                      '₹${tempRange.start.round()}',
                      '₹${tempRange.end.round()}',
                    ),
                    onChanged: (RangeValues values) {
                      setDialogState(() {
                        tempRange = values;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      priceRange = tempRange;
                      _applyAllFilters();
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
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
    // Get unique brands from products
    Set<String> brands = rentals
        .map((p) => p['productBrand']?.toString() ?? '')
        .where((b) => b.isNotEmpty)
        .toSet();

    List<String> tempSelectedBrands = List.from(selectedBrands);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Select Brands', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: brands.map((brand) {
                    return CheckboxListTile(
                      title: Text(brand, style: GoogleFonts.poppins()),
                      value: tempSelectedBrands.contains(brand),
                      activeColor: const Color(0xFF6366F1),
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            tempSelectedBrands.add(brand);
                          } else {
                            tempSelectedBrands.remove(brand);
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
                  child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedBrands = tempSelectedBrands;
                      _applyAllFilters();
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
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
    List<String> commonSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', '28', '30', '32', '34', '36', '38', '40'];
    List<String> tempSelectedSizes = List.from(selectedSizes);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Select Sizes', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              content: SizedBox(
                width: double.maxFinite,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: commonSizes.map((size) {
                    bool isSelected = tempSelectedSizes.contains(size);
                    return FilterChip(
                      label: Text(size),
                      selected: isSelected,
                      selectedColor: const Color(0xFF6366F1),
                      labelStyle: GoogleFonts.poppins(
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                      onSelected: (bool selected) {
                        setDialogState(() {
                          if (selected) {
                            tempSelectedSizes.add(size);
                          } else {
                            tempSelectedSizes.remove(size);
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
                  child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedSizes = tempSelectedSizes;
                      _applyAllFilters();
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
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
    List<Map<String, dynamic>> colors = [
      {'name': 'Red', 'color': Colors.red},
      {'name': 'Blue', 'color': Colors.blue},
      {'name': 'Green', 'color': Colors.green},
      {'name': 'Black', 'color': Colors.black},
      {'name': 'White', 'color': Colors.white},
      {'name': 'Yellow', 'color': Colors.yellow},
      {'name': 'Pink', 'color': Colors.pink},
      {'name': 'Purple', 'color': Colors.purple},
    ];
    List<String> tempSelectedColors = List.from(selectedColors);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Select Colors', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              content: SizedBox(
                width: double.maxFinite,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: colors.map((colorData) {
                    bool isSelected = tempSelectedColors.contains(colorData['name']);
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          if (isSelected) {
                            tempSelectedColors.remove(colorData['name']);
                          } else {
                            tempSelectedColors.add(colorData['name']);
                          }
                        });
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: colorData['color'],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade300,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedColors = tempSelectedColors;
                      _applyAllFilters();
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
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
    double tempRating = minRating;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Minimum Rating', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${tempRating.toStringAsFixed(1)} ★ and above',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Slider(
                    value: tempRating,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    activeColor: const Color(0xFF6366F1),
                    label: tempRating.toStringAsFixed(1),
                    onChanged: (double value) {
                      setDialogState(() {
                        tempRating = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      minRating = tempRating;
                      _applyAllFilters();
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                  child: Text('Apply', style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showInStockFilterDialog() {
    bool tempInStock = inStockOnly;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Stock Filter', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              content: SwitchListTile(
                title: Text('Show only in-stock items', style: GoogleFonts.poppins()),
                value: tempInStock,
                activeColor: const Color(0xFF6366F1),
                onChanged: (bool value) {
                  setDialogState(() {
                    tempInStock = value;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      inStockOnly = tempInStock;
                      _applyAllFilters();
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                  child: Text('Apply', style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
