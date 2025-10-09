import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:groovyn/files/user/mains/listing_page.dart';
import 'package:groovyn/files/user/product/product_page.dart';
import 'package:groovyn/main.dart';
import 'package:groovyn/widgets/custom_image_widget.dart';
import 'package:groovyn/widgets/product_card.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:groovyn/widgets/fashion_refresh_header.dart';

import '../cart/cart_page.dart';
import '../profile/profile_page.dart';
import '../profile/wish_list.dart';
import 'main_landing.dart';

class RentalPage extends StatefulWidget{
  const RentalPage({super.key});

  @override
  State<RentalPage> createState() => RentalPageState();
}

class RentalPageState extends State<RentalPage> {

  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  List<Map<String, dynamic>> rentals = [];
  List<Map<String, dynamic>> allStores = [];

  List<DocumentSnapshot> reviews = [];

  bool isLoading = true;

  @override
  void initState() {
    theSelectedPageID = 3;
    super.initState();
    fetchRentals();
    fetchAllStoresData();
  }


  // Helper methods for ProductCard data extraction
  String _getImageUrl(Map<String, dynamic> product) {
    if (product['productImages'] != null && product['productImages'].isNotEmpty) {
      return product['productImages'][0] ?? '';
    }
    return '';
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
    
    if (product['productPrice'] != null) {
      if (product['productPrice'] is int) {
        return product['productPrice'];
      } else if (product['productPrice'] is String) {
        return int.tryParse(product['productPrice']) ?? 0;
      }
    }
    return 0;
  }

  int? _getOriginalPrice(Map<String, dynamic> product) {
    // First check for explicit original price fields
    final originalPriceRaw = _getOriginalPriceRaw(product);
    if (originalPriceRaw != null && originalPriceRaw > 0) {
      return originalPriceRaw;
    }
    
    // Check for dedicated originalPrice field
    if (product['productOriginalPrice'] != null) {
      if (product['productOriginalPrice'] is int) {
        return product['productOriginalPrice'];
      } else if (product['productOriginalPrice'] is String) {
        final parsed = int.tryParse(product['productOriginalPrice']);
        if (parsed != null && parsed > 0) return parsed;
      }
    }
    
    // Only show original price if there's a discount percentage or we have explicit original price
    final currentPrice = _getPrice(product);
    final discountPercentage = _getDiscountPercentage(product);
    
    if (discountPercentage > 0 && currentPrice > 0) {
      return (currentPrice / (1 - discountPercentage / 100)).round();
    }
    
    return null; // Don't show original price if no discount exists
  }

  double? _getRating(Map<String, dynamic> product) {
    if (product['rating'] != null && product['rating'].toString() != '0') {
      if (product['rating'] is double) {
        return product['rating'];
      } else if (product['rating'] is String) {
        return double.tryParse(product['rating']);
      }
    }
    return 4.5;
  }

  int? _getTotalRatings(Map<String, dynamic> product) {
    if (product['total'] != null && product['total'].toString() != '0') {
      if (product['total'] is int) {
        return product['total'];
      } else if (product['total'] is String) {
        return int.tryParse(product['total']);
      }
    }
    return 0;
  }

  int? _getOriginalPriceRaw(Map<String, dynamic> product) {
    // Get raw original price without discount calculation
    final originalPrice = product['originalPrice'] ?? 
                         product['mrp'] ?? 
                         product['productOriginalPrice'] ?? 
                         product['productMRP'];
    if (originalPrice == null) return null;
    
    if (originalPrice is int) {
      return originalPrice;
    } else if (originalPrice is String) {
      return int.tryParse(originalPrice);
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

  Future<void> _handleRefresh() async {
    await fetchRentals();
    await fetchAllStoresData();
    _refreshController.refreshCompleted();
  }

  Future<void> fetchRentals() async {
    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('status', isEqualTo: true)
          .where('trending', isEqualTo: true)
          .limit(15)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          rentals = [];
          isLoading = false;
        });
        return;
      }

      // Get all unique store IDs
      Set<String> storeIds = {};
      Map<String, Map<String, dynamic>> productDataMap = {};
      
      for (var doc in querySnapshot.docs) {
        var productData = doc.data() as Map<String, dynamic>;
        productData['documentID'] = doc.id;
        productDataMap[doc.id] = productData;
        
        String? storeId = productData['productStoreID'];
        if (storeId != null) {
          storeIds.add(storeId);
        }
      }

      // Batch fetch store data using whereIn for better performance
      Map<String, String> storeBusinessFields = {};
      if (storeIds.isNotEmpty) {
        try {
          // Convert to list and split into chunks if needed (Firestore has 10-item limit for whereIn)
          List<String> storeIdsList = storeIds.toList();
          List<List<String>> chunks = [];
          for (int i = 0; i < storeIdsList.length; i += 10) {
            chunks.add(storeIdsList.sublist(i, 
                i + 10 > storeIdsList.length ? storeIdsList.length : i + 10));
          }
          
          List<Future<QuerySnapshot>> queries = chunks.map((chunk) {
            return FirebaseFirestore.instance
                .collection('stores')
                .where(FieldPath.documentId, whereIn: chunk)
                .get();
          }).toList();
          
          List<QuerySnapshot> results = await Future.wait(queries);
          for (QuerySnapshot snapshot in results) {
            for (DocumentSnapshot storeDoc in snapshot.docs) {
              var storeData = storeDoc.data() as Map<String, dynamic>;
              storeBusinessFields[storeDoc.id] = storeData['businessField'] ?? '';
            }
          }
        } catch (e) {
          print('Error batch fetching stores: $e');
          // Fallback to individual queries if batch fails
          for (String storeId in storeIds) {
            try {
              DocumentSnapshot storeDoc = await FirebaseFirestore.instance
                  .collection('stores').doc(storeId).get();
              if (storeDoc.exists) {
                var storeData = storeDoc.data() as Map<String, dynamic>;
                storeBusinessFields[storeId] = storeData['businessField'] ?? '';
              }
            } catch (e) {
              print('Error fetching store $storeId: $e');
            }
          }
        }
      }

      // Filter rental products and add default ratings
      List<Map<String, dynamic>> fetchedRentals = [];
      for (var productData in productDataMap.values) {
        String? storeId = productData['productStoreID'];
        if (storeId != null && storeBusinessFields[storeId] == 'Rental') {
          // Add default rating data (we'll load reviews asynchronously later)
          productData['total'] = '0';
          productData['rating'] = '4.5';
          fetchedRentals.add(productData);
        }
      }

      setState(() {
        rentals = fetchedRentals;
        isLoading = false;
      });

      // Load reviews asynchronously in background
      _loadReviewsInBackground(fetchedRentals);

    } catch (e) {
      print('Error fetching rentals: $e');
      setState(() {
        rentals = [];
        isLoading = false;
      });
    }
  }

  void _loadReviewsInBackground(List<Map<String, dynamic>> products) async {
    // Load reviews for each product in background
    for (int i = 0; i < products.length; i++) {
      try {
        var product = products[i];
        Map<String, String> reviewData = await fetchReviews(product['documentID']);
        
        // Update the product data
        setState(() {
          if (i < rentals.length) {
            rentals[i]['total'] = reviewData['total'] ?? '0';
            rentals[i]['rating'] = reviewData['rating'] ?? '4.5';
          }
        });
        
        // Small delay to avoid overwhelming the UI
        if (i < products.length - 1) {
          await Future.delayed(Duration(milliseconds: 100));
        }
      } catch (e) {
        print('Error loading reviews for product: $e');
      }
    }
  }

  Future<Map<String, String>> fetchReviews(String productID) async {
    double averageRating = 0;
    int totalRatings = 0;
    Map<String, String> map = {};
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('reviews').where('productID', isEqualTo: productID).get();
    reviews = snapshot.docs;
    totalRatings = reviews.length;
    if (totalRatings > 0) {
      double total = 0;
      for (var review in reviews) {
        if(review['productID'] == productID) {
          total += int.parse(review['rating'].toString());
        }
      }
      averageRating = total / totalRatings;
      map.addAll({'total': totalRatings.toString(), 'rating': averageRating.toString(),});
      return map;
    }
    return {};
  }

  Future<void> fetchFavorites() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(theID).get();
    if (userDoc.exists && userDoc.data() != null) {
      setState(() {
        favoriteProductIds = List<String>.from(userDoc['favourites'] ?? []);
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

  Future<void> fetchAllStoresData() async {
    try {
      QuerySnapshot<Map<String, dynamic>> storesSnapshot =
      await FirebaseFirestore.instance.collection('stores').get();


      if (storesSnapshot.docs.isNotEmpty) {
        final List<Map<String, dynamic>> storesList = [];

        for (var doc in storesSnapshot.docs) {
          final storeData = doc.data();
          if(storeData['businessField'] == 'Rental') {
            storesList.add({
              'documentID': doc.id,
              'businessName': storeData['businessName'] ?? '',
              'businessLocation': storeData['businessLocation'] ?? '',
              'businessOpeningTime': storeData['businessOpeningTime'] ?? '',
              'businessClosingTime': storeData['businessClosingTime'] ?? '',
              'businessImage': (storeData['businessImages'] as List<dynamic>?)?.first ?? '',
            });
          }
        }

        setState(() {
          allStores = storesList;
        });
      } else {
        debugPrint('No stores found');
      }
    } catch (e) {
      debugPrint('Error fetching stores data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Color.fromRGBO(250, 250, 250, 1),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
            child: SmartRefresher(
              controller: _refreshController,
              enablePullDown: true,
              onRefresh: _handleRefresh,
              header: FashionRefreshHeader(customText: "Pull for rental updates"),
              child: ListView(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 20.0, bottom: 20.0, left: 12.0, right: 12.0),
                    child: Container(
                      height: 40,
                      width: MediaQuery.of(context).size.width,
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        shadows: [
                          BoxShadow(
                            color: Color(0x3F000000),
                            blurRadius: 4,
                            offset: Offset(2, 2),
                            spreadRadius: 0,
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const HomePage()),
                                (route) => false,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Image.asset(
                                'assets/icons/img_8.png',
                                width: 40,
                                height: 40,
                              ),
                            ),
                          ),
                          Flexible(
                            child: GestureDetector(
                              onTap: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context)=> ListingPage(isSearch: true,)));
                              },
                              child: Center(
                                child: TextField(
                                  textAlignVertical: TextAlignVertical.center,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.only(top: 8, bottom: 12, left: 8),
                                    hintText: 'Search rental items, brands...',
                                    enabled: false,
                                    hintStyle: GoogleFonts.montserrat(
                                      textStyle: GoogleFonts.poppins(
                                        textStyle: TextStyle(
                                          color: Colors.black,
                                          fontSize: 18,
                                          fontFamily: 'Manrope',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8,),
                          GestureDetector(
                            onTap: (){
                              Navigator.push(context, MaterialPageRoute(builder: (context)=> const WishList()));
                            },
                            child: Icon(
                              Icons.favorite_outline_rounded,
                              color: Colors.black,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 8,),
                          GestureDetector(
                            onTap: (){
                              Navigator.push(context, MaterialPageRoute(builder: (context)=> const CartPage()));
                            },
                            child: Stack(
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(right: cartProductIDs.isNotEmpty ? 8.0 : 0.0),
                                  child: Icon(
                                    Icons.shopping_cart_outlined,
                                    color: Colors.black,
                                    size: 22,
                                  ),
                                ),
                                if(cartProductIDs.isNotEmpty)
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      width: 15,
                                      height: 15,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.red,
                                      ),
                                      child: Center(
                                        child: Text(
                                          cartProductIDs.length.toString(),
                                          style: GoogleFonts.poppins(
                                            textStyle: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8,),
                          GestureDetector(
                            onTap: (){
                              Navigator.push(context, MaterialPageRoute(builder: (context)=> const ProfilePage()));
                            },
                            child: Icon(
                              Icons.person_outline,
                              color: Colors.black,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 8,),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: (){
                              Navigator.push(context, MaterialPageRoute(builder: (context)=> const ListingPage(isSearch: false)));
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                              child: Image.asset(
                                'assets/images/img_3.png',
                                width: MediaQuery.of(context).size.width,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20,),
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Collections',
                                style: GoogleFonts.poppins(
                                  textStyle: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                    height: 0.03,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20,),
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: GridView.count(
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                mainAxisSpacing: 6,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1,
                                children: [
                                  _buildGridItem('Wedding', 'assets/svgs/img_4.png'),
                                  _buildGridItem('Festival', 'assets/svgs/img_5.png'),
                                  _buildGridItem('Office', 'assets/svgs/img_6.png'),
                                  _buildGridItem('Party', 'assets/svgs/img_7.png'),
                                  _buildGridItem('Travel', 'assets/svgs/img_8.png'),
                                  _buildGridItem('Winter', 'assets/svgs/img_9.png'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20,),
                          // Trending Rentals Section - Moved up before Rental Houses
                          GestureDetector(
                            onTap: (){
                              Navigator.push(context, MaterialPageRoute(builder: (context)=> const ListingPage(isSearch: false)));
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Trending Rentals',
                                    style: GoogleFonts.montserrat(
                                      textStyle: TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontFamily: 'Manrope',
                                        fontWeight: FontWeight.bold,
                                      )
                                    ),
                                  ),
                                  Text(
                                    'View all',
                                    style: GoogleFonts.poppins(
                                      textStyle: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.02,),
                          // Modern Grid Layout with ProductCard
                          Container(
                            height: MediaQuery.of(context).size.height * 0.5,
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: rentals.isNotEmpty
                                ? GridView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(left: 4, right: 4, bottom: 20),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.7,
                              ),
                              itemCount: rentals.length,
                              itemBuilder: (context, index) {
                                final rental = rentals[index];
                                return ProductCard(
                                  imageUrl: _getImageUrl(rental),
                                  name: rental['productBrand']?.toString() ?? 'Fashion Brand',
                                  description: rental['productName']?.toString() ?? 'Stylish Fashion Item',
                                  price: _getPrice(rental),
                                  originalPrice: _getOriginalPrice(rental),
                                  isFavorite: favoriteProductIds.contains(rental['documentID']),
                                  rating: _getRating(rental),
                                  totalRatings: _getTotalRatings(rental),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProductPage(
                                          productID: rental['documentID'],
                                        ),
                                      ),
                                    );
                                  },
                                  onFavoriteToggle: () {
                                    addToFavorites(rental['documentID']);
                                  },
                                );
                              },
                            )
                                : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 80,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No trending rentals found',
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
                            ),
                          ),
                          // TODO: Uncomment Rental Houses section when ready
                          /*
                          SizedBox(height: height * 0.02,),
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Rental Houses',
                                style: GoogleFonts.poppins(
                                  textStyle: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                    height: 0.03,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20,),
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0,),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.4,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: allStores.length,
                                itemBuilder: (context, index) {
                                  var rental = allStores[index];
                                  bool isFavorite = favoriteProductIds.contains(rental['documentID']);
                                  return Container(
                                    height: 100,
                                    width: 277,
                                    margin: EdgeInsets.all(10),
                                    decoration: ShapeDecoration(
                                      color: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      shadows: [
                                        BoxShadow(
                                          color: Color(0x3F000000),
                                          blurRadius: 4,
                                          offset: Offset(0, 4),
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Flexible(
                                          child: Container(
                                            width: 277,
                                            height: MediaQuery.of(context).size.height * 0.4,
                                            decoration: BoxDecoration(
                                              color: Colors.black,
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(10),
                                                topRight: Radius.circular(10),
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(10),
                                                topRight: Radius.circular(10),
                                              ),
                                              child: CustomImageWidget(
                                                imageUrl: _getProductImage(rental),
                                                fit: BoxFit.fill,
                                                borderRadius: const BorderRadius.only(
                                                  topLeft: Radius.circular(10),
                                                  topRight: Radius.circular(10),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      rental['productName'] ?? '',
                                                      style: GoogleFonts.roboto(
                                                        textStyle: TextStyle(
                                                          color: Colors.black,
                                                          fontFamily: 'Manrope',
                                                          fontSize: 20,
                                                          fontWeight: FontWeight.bold,
                                                        )
                                                      ),
                                                    ),
                                                    GestureDetector(
                                                      onTap: () => addToFavorites(rental['documentID']),
                                                      child: Icon(
                                                        isFavorite ? Icons.favorite : Icons.favorite_border,
                                                        color: isFavorite ? Colors.red : null,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        '₹${_getProductPrice(rental)}',
                                                        style: GoogleFonts.poppins(
                                                          textStyle: TextStyle(
                                                            color: Colors.black,
                                                            fontSize: 16,
                                                            fontFamily: 'Manrope',
                                                            fontWeight: FontWeight.w600,
                                                          )
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8,),
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.star,
                                                          color: Colors.yellow,
                                                          size: 16,
                                                        ),
                                                        const SizedBox(width: 4,),
                                                        Text(
                                                          "${rental['productRating'] ?? '4.2'}",
                                                          style: GoogleFonts.poppins(
                                                            textStyle: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          */
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: returnBottomBar(context),
    );
  }
  Widget _buildGridItem(String collection, String imagePath) {
    return GestureDetector(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (context)=> ListingPage(isSearch: false, collection: collection,)));
      },
      child: Container(
        decoration: ShapeDecoration(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              imagePath,
              fit: BoxFit.fill,
            ),
          ),
        ),
      ),
    );
  }
}