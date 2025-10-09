import 'package:groovyn/widgets/sort_filter_widget.dart';

class ProductSortFilterService {
  static List<Map<String, dynamic>> applySortAndFilter({
    required List<Map<String, dynamic>> products,
    required SortOption sortOption,
    required FilterOptions filterOptions,
  }) {
    List<Map<String, dynamic>> filteredProducts = List.from(products);

    // Apply filters first
    filteredProducts = _applyFilters(filteredProducts, filterOptions);

    // Then apply sorting
    filteredProducts = _applySort(filteredProducts, sortOption);

    return filteredProducts;
  }

  static List<Map<String, dynamic>> _applyFilters(
    List<Map<String, dynamic>> products,
    FilterOptions filterOptions,
  ) {
    return products.where((product) {
      // Business type filter
      if (filterOptions.businessType != 'All') {
        final businessField = product['businessField']?.toString() ?? 'All';
        if (businessField != filterOptions.businessType) {
          return false;
        }
      }

      // Price range filter
      final price = double.tryParse(product['productPrice']?.toString() ?? '0') ?? 0;
      if (price < filterOptions.priceRange.start || price > filterOptions.priceRange.end) {
        return false;
      }

      // Rating filter
      final rating = double.tryParse(product['rating']?.toString() ?? '0') ?? 0;
      if (rating < filterOptions.minRating) {
        return false;
      }

      // Stock filter
      if (filterOptions.inStock) {
        final stock = _getTotalStock(product);
        if (stock <= 0) {
          return false;
        }
      }

      // Category filter
      if (filterOptions.categories.isNotEmpty) {
        final productCategory = product['productCategory']?.toString() ?? '';
        final productHashtags = product['productHashtags']?.toString() ?? '';
        
        bool categoryMatch = filterOptions.categories.any((category) =>
          productCategory.toLowerCase().contains(category.toLowerCase()) ||
          productHashtags.toLowerCase().contains(category.toLowerCase())
        );
        
        if (!categoryMatch) {
          return false;
        }
      }

      // Size filter
      if (filterOptions.sizes.isNotEmpty) {
        final availableSizes = _getAvailableSizes(product);
        bool sizeMatch = filterOptions.sizes.any((size) =>
          availableSizes.contains(size)
        );
        
        if (!sizeMatch) {
          return false;
        }
      }

      // Color filter
      if (filterOptions.colors.isNotEmpty) {
        final availableColors = _getAvailableColors(product);
        bool colorMatch = filterOptions.colors.any((color) =>
          availableColors.contains(color)
        );
        
        if (!colorMatch) {
          return false;
        }
      }

      // Brand filter
      if (filterOptions.brands.isNotEmpty) {
        final productBrand = product['productBrand']?.toString() ?? 'Generic';
        bool brandMatch = filterOptions.brands.any((brand) =>
          productBrand.toLowerCase().contains(brand.toLowerCase())
        );
        
        if (!brandMatch) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  static List<Map<String, dynamic>> _applySort(
    List<Map<String, dynamic>> products,
    SortOption sortOption,
  ) {
    List<Map<String, dynamic>> sortedProducts = List.from(products);

    switch (sortOption) {
      case SortOption.priceLowToHigh:
        sortedProducts.sort((a, b) {
          final priceA = double.tryParse(a['productPrice']?.toString() ?? '0') ?? 0;
          final priceB = double.tryParse(b['productPrice']?.toString() ?? '0') ?? 0;
          return priceA.compareTo(priceB);
        });
        break;

      case SortOption.priceHighToLow:
        sortedProducts.sort((a, b) {
          final priceA = double.tryParse(a['productPrice']?.toString() ?? '0') ?? 0;
          final priceB = double.tryParse(b['productPrice']?.toString() ?? '0') ?? 0;
          return priceB.compareTo(priceA);
        });
        break;

      case SortOption.popularity:
        sortedProducts.sort((a, b) {
          // Sort by trending first, then by total reviews
          final trendingA = a['trending'] == true ? 1 : 0;
          final trendingB = b['trending'] == true ? 1 : 0;
          
          if (trendingA != trendingB) {
            return trendingB.compareTo(trendingA);
          }
          
          final totalA = int.tryParse(a['total']?.toString() ?? '0') ?? 0;
          final totalB = int.tryParse(b['total']?.toString() ?? '0') ?? 0;
          return totalB.compareTo(totalA);
        });
        break;

      case SortOption.rating:
        sortedProducts.sort((a, b) {
          final ratingA = double.tryParse(a['rating']?.toString() ?? '0') ?? 0;
          final ratingB = double.tryParse(b['rating']?.toString() ?? '0') ?? 0;
          return ratingB.compareTo(ratingA);
        });
        break;

      case SortOption.newest:
        sortedProducts.sort((a, b) {
          // Assuming there's a createdAt timestamp
          final dateA = a['createdAt'] ?? DateTime.now();
          final dateB = b['createdAt'] ?? DateTime.now();
          
          if (dateA is String && dateB is String) {
            return dateB.compareTo(dateA);
          } else if (dateA is DateTime && dateB is DateTime) {
            return dateB.compareTo(dateA);
          }
          
          return 0;
        });
        break;

      case SortOption.name:
        sortedProducts.sort((a, b) {
          final nameA = a['productName']?.toString() ?? '';
          final nameB = b['productName']?.toString() ?? '';
          return nameA.compareTo(nameB);
        });
        break;
    }

    return sortedProducts;
  }

  static int _getTotalStock(Map<String, dynamic> product) {
    final sizesAndStock = product['productSizesAndStock'] as List<dynamic>? ?? [];
    int totalStock = 0;
    
    for (var item in sizesAndStock) {
      if (item is Map<String, dynamic>) {
        final stock = int.tryParse(item['stock']?.toString() ?? '0') ?? 0;
        totalStock += stock;
      }
    }
    
    return totalStock;
  }

  static List<String> _getAvailableSizes(Map<String, dynamic> product) {
    final sizesAndStock = product['productSizesAndStock'] as List<dynamic>? ?? [];
    List<String> sizes = [];
    
    for (var item in sizesAndStock) {
      if (item is Map<String, dynamic>) {
        final stock = int.tryParse(item['stock']?.toString() ?? '0') ?? 0;
        if (stock > 0) {
          final size = item['size']?.toString() ?? '';
          if (size.isNotEmpty && !sizes.contains(size)) {
            sizes.add(size);
          }
        }
      }
    }
    
    return sizes;
  }

  static List<String> _getAvailableColors(Map<String, dynamic> product) {
    final sizesAndStock = product['productSizesAndStock'] as List<dynamic>? ?? [];
    List<String> colors = [];
    
    for (var item in sizesAndStock) {
      if (item is Map<String, dynamic>) {
        final stock = int.tryParse(item['stock']?.toString() ?? '0') ?? 0;
        if (stock > 0) {
          final color = item['color']?.toString() ?? '';
          if (color.isNotEmpty && !colors.contains(color)) {
            colors.add(color);
          }
        }
      }
    }
    
    return colors;
  }

  static Map<String, int> getFilterCounts(List<Map<String, dynamic>> allProducts) {
    int boutiques = 0, rentals = 0, tailors = 0, fabrics = 0;
    int inStock = 0;
    Set<String> categories = {};
    Set<String> sizes = {};
    Set<String> colors = {};
    Set<String> brands = {};
    
    for (var product in allProducts) {
      // Business type counts
      final businessField = product['businessField']?.toString() ?? 'Rental';
      switch (businessField) {
        case 'Boutique':
          boutiques++;
          break;
        case 'Rental':
          rentals++;
          break;
        case 'Tailor':
          tailors++;
          break;
        case 'Fabric':
          fabrics++;
          break;
      }
      
      // Stock count
      if (_getTotalStock(product) > 0) {
        inStock++;
      }
      
      // Categories
      final category = product['productCategory']?.toString() ?? '';
      if (category.isNotEmpty) {
        categories.add(category);
      }
      
      // Sizes and colors
      sizes.addAll(_getAvailableSizes(product));
      colors.addAll(_getAvailableColors(product));
      
      // Brands
      final brand = product['productBrand']?.toString() ?? 'Generic';
      if (brand.isNotEmpty) {
        brands.add(brand);
      }
    }
    
    return {
      'boutiques': boutiques,
      'rentals': rentals,
      'tailors': tailors,
      'fabrics': fabrics,
      'inStock': inStock,
      'categories': categories.length,
      'sizes': sizes.length,
      'colors': colors.length,
      'brands': brands.length,
    };
  }
}