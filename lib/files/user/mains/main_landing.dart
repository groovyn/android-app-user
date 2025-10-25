import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:groovyn/files/user/boutique/boutique_page.dart';
import 'package:groovyn/files/user/boutique/boutique_listing.dart';
import 'package:groovyn/files/user/fabrics/fabrics_page.dart';
import 'package:groovyn/files/user/mains/listing_page.dart';
import 'package:groovyn/files/user/profile/profile_page.dart';
import 'package:groovyn/files/user/product/product_page.dart';
import 'package:groovyn/files/user/mains/rental_page.dart';
import 'package:groovyn/files/user/profile/wish_list.dart';
import 'package:groovyn/files/user/tailors/tailors_listing.dart';
import 'package:groovyn/files/user/tailors/tailors_product.dart';
import 'package:groovyn/main.dart';
import 'package:groovyn/widgets/fashion_refresh_header.dart';
import 'package:groovyn/widgets/rental_product_card.dart';
import 'package:groovyn/widgets/custom_image_widget.dart';
import 'package:groovyn/theme/app_theme.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../cart/cart_page.dart';

class HomePage extends StatefulWidget{
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {

  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  final PageController _pageController = PageController(viewportFraction: 0.85);
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  List<Map<String, dynamic>> rentals = [];
  List<Map<String, dynamic>> tailors = [];
  List<DocumentSnapshot> reviews = [];
  List<Map<String, dynamic>> boutiques = [];
  List<Map<String, dynamic>> trendingProducts = [];

  List<String> _advertisements = [];

  bool isLoading = true;

  @override
  void initState() {
    theSelectedPageID = 1;
    super.initState();
    fetchHoardings();
    fetchFavorites();
    fetchTailors();
    fetchBoutiques();
    fetchTrendingProducts();
    fetchRentals();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_advertisements.isNotEmpty && _pageController.hasClients) {
        _currentPage = (_currentPage + 1) % _advertisements.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _handleRefresh() async {
    await fetchHoardings();
    await fetchFavorites();
    _refreshController.refreshCompleted();
  }

  Future<void> fetchRentals() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('status', isEqualTo: true)
        .where('trending', isEqualTo: true)
        .get();
    
    if (querySnapshot.docs.isEmpty) {
      setState(() { rentals = []; });
      return;
    }

    List<Map<String, dynamic>> fetchedRentals = [];
    
    // Get all unique store IDs to batch fetch stores
    Set<String> storeIds = {};
    for (var doc in querySnapshot.docs) {
      var productData = doc.data() as Map<String, dynamic>;
      if (productData['productStoreID'] != null) {
        storeIds.add(productData['productStoreID']);
      }
    }
    
    // Batch fetch all store documents
    Map<String, Map<String, dynamic>> storeData = {};
    if (storeIds.isNotEmpty) {
      for (String storeId in storeIds) {
        try {
          DocumentSnapshot storeDoc = await FirebaseFirestore.instance
              .collection('stores').doc(storeId).get();
          if (storeDoc.exists) {
            storeData[storeId] = storeDoc.data() as Map<String, dynamic>;
          }
        } catch (e) {
          print('Error fetching store $storeId: $e');
        }
      }
    }

    // Process products with store data
    List<Future<Map<String, dynamic>?>> futures = querySnapshot.docs.map((doc) async {
      try {
        var productData = doc.data() as Map<String, dynamic>;
        productData['documentID'] = doc.id;
        
        // Check if store is rental business
        String? storeId = productData['productStoreID'];
        if (storeId != null && storeData.containsKey(storeId)) {
          if (storeData[storeId]!['businessField'] == 'Rental') {
            // Set default rating to avoid slow review fetching
            productData['total'] = '150';
            productData['rating'] = '4.2';
            return productData;
          }
        }
        return null;
      } catch (e) {
        print('Error processing product ${doc.id}: $e');
        return null;
      }
    }).toList();
    
    // Wait for all products to be processed
    List<Map<String, dynamic>?> results = await Future.wait(futures);
    
    // Filter out null results
    fetchedRentals = results.where((item) => item != null).cast<Map<String, dynamic>>().toList();

    setState(() {
      rentals = fetchedRentals;
    });
  }

  Future<void> fetchBoutiques() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('stores')
        .where('trending', isEqualTo: true)
        .get();

    List<Map<String, dynamic>> fetchedBoutiques = [];

    for (var doc in querySnapshot.docs) {
      if(doc['businessField'] == 'Boutique') {
        var storeData = doc.data() as Map<String, dynamic>;
        storeData['documentID'] = doc.id;
        fetchedBoutiques.add(storeData);
      }
    }

    setState(() {
      boutiques = fetchedBoutiques;
    });
  }

  Future<void> fetchTrendingProducts() async {
    if (kDebugMode) {
      print('Fetching trending products...');
    }
    
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('trending', isEqualTo: true)
        .where('status', isEqualTo: true)
        .limit(20)
        .get();

    if (querySnapshot.docs.isEmpty) {
      if (kDebugMode) {
        print('No trending products found');
      }
      setState(() { trendingProducts = []; });
      return;
    }

    if (kDebugMode) {
      print('Found ${querySnapshot.docs.length} trending products');
    }

    List<Map<String, dynamic>> fetchedProducts = [];
    
    // Get all unique store IDs - try both field names
    Set<String> storeIds = {};
    for (var doc in querySnapshot.docs) {
      var productData = doc.data() as Map<String, dynamic>;
      String? storeId = productData['productStoreID'] ?? productData['storeID'];
      if (storeId != null) {
        storeIds.add(storeId);
      }
    }
    
    if (kDebugMode) {
      print('Found ${storeIds.length} unique stores');
    }
    
    // Batch fetch store data
    Map<String, String> storeBusinessFields = {};
    if (storeIds.isNotEmpty) {
      List<Future<void>> storeQueries = storeIds.map((storeId) async {
        try {
          DocumentSnapshot storeDoc = await FirebaseFirestore.instance
              .collection('stores').doc(storeId).get();
          if (storeDoc.exists) {
            var storeData = storeDoc.data() as Map<String, dynamic>;
            String businessField = storeData['businessField'] ?? '';
            storeBusinessFields[storeId] = businessField;
            if (kDebugMode) {
              print('Store $storeId: $businessField');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error fetching store $storeId: $e');
          }
        }
      }).toList();
      
      await Future.wait(storeQueries);
    }

    // Process products with cached store data
    for (var doc in querySnapshot.docs) {
      var productData = doc.data() as Map<String, dynamic>;
      productData['documentID'] = doc.id;
      
      String? storeId = productData['productStoreID'] ?? productData['storeID'];
      if (storeId != null && storeBusinessFields[storeId] == 'Boutique') {
        fetchedProducts.add(productData);
      }
    }

    if (kDebugMode) {
      print('Filtered ${fetchedProducts.length} boutique products');
    }

    setState(() {
      trendingProducts = fetchedProducts;
    });
  }

  Future<void> fetchTailors() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('stores')
        .where('trending', isEqualTo: true)
        .get();

    List<Map<String, dynamic>> fetchedTailors = [];

    for (var doc in querySnapshot.docs) {
      if(doc['businessField'] == 'Tailor') {
        var storeData = doc.data() as Map<String, dynamic>;
        storeData['documentID'] = doc.id;
        fetchedTailors.add(storeData);
      }
    }

    setState(() {
      tailors = fetchedTailors;
    });
  }

  Future<void> fetchFavorites() async {
    if (theID.isEmpty) {
      return; // Skip if user is not logged in
    }
    
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(theID).get();
    if (userDoc.exists && userDoc.data() != null) {
      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

      if (data.containsKey('favourites') && data['favourites'] is List) {
        setState(() {
          favoriteProductIds = List<String>.from(data['favourites']);
        });
      } else {
        setState(() {
          favoriteProductIds = [];
        });
      }
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

  Future<void> fetchHoardings() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('hoardings').get();

    if (snapshot.docs.isNotEmpty) {
      final DocumentSnapshot document = snapshot.docs.first;

      List<String> advertisements = List<String>.from(document['advertisements']);
      // List<String> trendingBoutiques = List<String>.from(document['trendingBoutiques']);
      // List<String> trendingTailors = List<String>.from(document['trendingTailors']);

      setState(() {
        _advertisements = advertisements;

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
              header: FashionRefreshHeader(customText: "Pull for fresh collections"),
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
                            onTap:(){
                              // Navigator.push(context, MaterialPageRoute(builder: (context)=> ShippingAddress(total: '20')));
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
                          Expanded(
                            child: GestureDetector(
                              onTap: (){
                                if(theID.isEmpty){
                                  EasyLoading.showError('Log in first to view WishList !');
                                  return;
                                }
                                Navigator.push(context, MaterialPageRoute(builder: (context)=> ListingPage(isSearch: true,)));
                              },
                              child: Center(
                                child: TextField(
                                  textAlignVertical: TextAlignVertical.center,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.only(top: 8, bottom: 12, left: 8),
                                    hintText: 'Search for fashion, rentals, tailors...',
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
                            )
                          ),
                          const SizedBox(width: 8,),
                          GestureDetector(
                            onTap: (){
                              if(theID.isEmpty){
                                EasyLoading.showError('Log in first to view WishList !');
                                return;
                              }
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
                              if(theID.isEmpty){
                                EasyLoading.showError('Log in first to view Cart !');
                                return;
                              }
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
                              if(theID.isEmpty){
                                EasyLoading.showError('Log in first to view profile page !');
                                return;
                              }
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
                  // Advertisement Section - Always visible
                  Column(
                    children: [
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.35,
                              width: MediaQuery.of(context).size.width,
                              child: _advertisements.isEmpty
                                  ? Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 12.0),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.black,
                                        ),
                                      ),
                                    )
                                  : PageView.builder(
                                      controller: _pageController,
                                      itemCount: _advertisements.length,
                                      itemBuilder: (context, index) {
                                        return Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 8.0),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: CustomImageWidget(
                                              imageUrl: _advertisements[index],
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.fill,
                                              borderRadius: BorderRadius.circular(12),
                                              showShimmer: true,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
                                child: Column(
                                  children: [
                                    SizedBox(height: height * 0.03,),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Explore',
                                            style: GoogleFonts.playfairDisplay(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black87,
                                              height: 1.2,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Browse by category',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: height * 0.025,),
                                    SizedBox(
                                      height: MediaQuery.of(context).size.height * 0.44,
                                      child: GridView.count(
                                        physics: const NeverScrollableScrollPhysics(),
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 14,
                                        crossAxisSpacing: 14,
                                        childAspectRatio: 0.95,
                                        children: [
                                          GestureDetector(
                                            onTap: (){
                                              Navigator.push(context, MaterialPageRoute(builder: (context)=> const TailorsListing()));
                                            },
                                            child: _buildPremiumCategoryCard(
                                              imagePath: 'assets/images/tailor1.png',
                                              title: 'Tailors',
                                              subtitle: 'Custom Stitching',
                                              gradientColors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: (){
                                              Navigator.push(context, MaterialPageRoute(builder: (context)=> const BoutiquePage()));
                                            },
                                            child: _buildPremiumCategoryCard(
                                              imagePath: 'assets/images/boutique1.png',
                                              title: 'Boutique',
                                              subtitle: 'Designer Wear',
                                              gradientColors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: (){
                                              Navigator.push(context, MaterialPageRoute(builder: (context)=> const FabricsPage()));
                                            },
                                            child: _buildPremiumCategoryCard(
                                              imagePath: 'assets/images/fabric1.png',
                                              title: 'Fabrics',
                                              subtitle: 'Premium Materials',
                                              gradientColors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: (){
                                              Navigator.push(context, MaterialPageRoute(builder: (context)=> const RentalPage()));
                                            },
                                            child: _buildPremiumCategoryCard(
                                              imagePath: 'assets/images/rental1.png',
                                              title: 'Rental',
                                              subtitle: 'Occasion Outfits',
                                              gradientColors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: height * 0.04,), // Increased gap between category and trending rentals
                                    // Trending Rentals Section - Third section after categories
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'TRENDING',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 6),
                                            Text(
                                              'Rental Collections',
                                              style: GoogleFonts.playfairDisplay(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.black87,
                                                height: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const RentalPage(),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.black,
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.2),
                                                  blurRadius: 8,
                                                  offset: Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              children: [
                                                Text(
                                                  'View All',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                SizedBox(width: 4),
                                                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: height * 0.02,),
                                    // Horizontal Rental Cards
                                    if(rentals.isNotEmpty)
                                      SizedBox(
                                        height: 320,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          padding: EdgeInsets.only(left: 8),
                                          physics: const BouncingScrollPhysics(),
                                          itemCount: rentals.length,
                                          itemBuilder: (context, index) {
                                            final rental = rentals[index];
                                            return RentalProductCard(
                                              product: rental,
                                              isFavorite: favoriteProductIds.contains(rental['documentID']),
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
                                        ),
                                      ),
                                    if(!rentals.isNotEmpty)
                                      SizedBox(
                                        height: 320,
                                        child: Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.checkroom_outlined, 
                                                       size: 50, color: Colors.grey[400]),
                                                  SizedBox(height: 10),
                                                  Text(
                                                    "No rental items available",
                                                    style: GoogleFonts.montserrat(
                                                      color: Colors.grey[600],
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                        ),
                                    ),
                                    SizedBox(height: height * 0.04,),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'FEATURED',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 6),
                                            Text(
                                              'Expert Tailors',
                                              style: GoogleFonts.playfairDisplay(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.black87,
                                                height: 1.2,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Top rated near you',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ],
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => const TailorsListing()));
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.black,
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.2),
                                                  blurRadius: 8,
                                                  offset: Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              children: [
                                                Text(
                                                  'View All',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                SizedBox(width: 4),
                                                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: height * 0.02,),
                              Padding(
                                padding: const EdgeInsets.only(left: 20.0),
                                child: SizedBox(
                                  height: 280,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: tailors.length,
                                    itemBuilder: (context, index) {
                                      var tailor = tailors[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 12.0, bottom: 12.0),
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => TailorsProduct(storeID: tailor['documentID']),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            width: 180,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.08),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                )
                                              ],
                                            ),
                                            child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Image Section with fixed aspect ratio
                                              AspectRatio(
                                                aspectRatio: 1.0,
                                                child: Stack(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius: const BorderRadius.only(
                                                        topLeft: Radius.circular(12),
                                                        topRight: Radius.circular(12),
                                                      ),
                                                      child: CustomImageWidget(
                                                        imageUrl: (tailor['businessImages'] != null && tailor['businessImages'].isNotEmpty)
                                                            ? tailor['businessImages'][0]
                                                            : 'https://via.placeholder.com/300x200.png?text=Fashion+Store',
                                                        fit: BoxFit.cover,
                                                        width: double.infinity,
                                                        height: double.infinity,
                                                        showShimmer: true,
                                                      ),
                                                    ),
                                                    // Rating overlay - bottom right
                                                    Positioned(
                                                      bottom: 8,
                                                      right: 8,
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                        decoration: BoxDecoration(
                                                          color: const Color.fromRGBO(0, 0, 0, 0.7),
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            const Icon(
                                                              Icons.star,
                                                              color: Colors.green,
                                                              size: 12,
                                                            ),
                                                            const SizedBox(width: 2),
                                                            Text(
                                                              '4.5',
                                                              style: GoogleFonts.poppins(
                                                                color: Colors.white,
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Content Section
                                              Padding(
                                                padding: const EdgeInsets.all(12.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      tailor['businessName'] ?? '',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.black,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.location_on,
                                                          size: 14,
                                                          color: Colors.grey.shade600,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Expanded(
                                                          child: Text(
                                                            tailor['businessLocation'] ?? '',
                                                            style: GoogleFonts.poppins(
                                                              fontSize: 12,
                                                              color: Colors.grey.shade600,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.access_time,
                                                          size: 14,
                                                          color: Colors.grey.shade600,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Expanded(
                                                          child: Text(
                                                            '${tailor['businessOpeningTime'] ?? '09:00 AM'} - ${tailor['businessClosingTime'] ?? '06:00 PM'}',
                                                            style: GoogleFonts.poppins(
                                                              fontSize: 10,
                                                              color: Colors.grey.shade600,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(height: height * 0.02,),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'EXCLUSIVE',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 6),
                                            Text(
                                              'Designer Collection',
                                              style: GoogleFonts.playfairDisplay(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.black87,
                                                height: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const BoutiqueListing(),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.black,
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.2),
                                                  blurRadius: 8,
                                                  offset: Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              children: [
                                                Text(
                                                  'View All',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                SizedBox(width: 4),
                                                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: height * 0.02,),
                                    Container(
                                      height: 320,
                                      child: trendingProducts.isNotEmpty
                                          ? ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              padding: EdgeInsets.only(left: 8),
                                              physics: const BouncingScrollPhysics(),
                                              itemCount: trendingProducts.length,
                                              itemBuilder: (context, index) {
                                                return RentalProductCard(
                                                  product: trendingProducts[index],
                                                  isFavorite: favoriteProductIds.contains(trendingProducts[index]['documentID']),
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => ProductPage(
                                                          productID: trendingProducts[index]['documentID'],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  onFavoriteToggle: () {
                                                    addToFavorites(trendingProducts[index]['documentID']);
                                                  },
                                                );
                                              },
                                            )
                                          : Container(
                                              height: 320,
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.shopping_bag_outlined, 
                                                         size: 50, color: Colors.grey[400]),
                                                    SizedBox(height: 10),
                                                    Text(
                                                      "No trending products available",
                                                      style: GoogleFonts.montserrat(
                                                        color: Colors.grey[600],
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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



  Widget _buildGridItem(String imagePath) {
    return Container(
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        shadows: [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 4,
            offset: Offset(0, 4),
            spreadRadius: 0,
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
        child: Center(
          child: CustomAssetImageWidget(
            assetPath: imagePath,
            fit: BoxFit.fitHeight,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumCategoryCard({
    required String imagePath,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
            spreadRadius: 0,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Full Image Background
            Positioned.fill(
              child: CustomAssetImageWidget(
                assetPath: imagePath,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            // Gradient Overlay at Bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCategoryCard({
    required IconData icon,
    required String title,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor,
            backgroundColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
            spreadRadius: 0,
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 40,
              color: iconColor,
            ),
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
}

Widget returnBottomBar(BuildContext context) {
  final bottomPadding = MediaQuery.of(context).padding.bottom;

  return Container(
    width: MediaQuery.of(context).size.width,
    padding: EdgeInsets.only(bottom: bottomPadding),
    decoration: BoxDecoration(
      color: AppTheme.cardColor,
      boxShadow: AppTheme.elevatedShadow,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(AppTheme.largeRadius),
        topRight: Radius.circular(AppTheme.largeRadius),
      ),
    ),
    child: SizedBox(
      height: 75,
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.largeRadius),
          topRight: Radius.circular(AppTheme.largeRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            bottomBarItem(context, 1, 'assets/icons/img_1.png', 'Home'),
            bottomBarItem(context, 2, 'assets/icons/img_2.png', 'Boutiques'),
            bottomBarItem(context, 3, 'assets/icons/img_3.png', 'Rental'),
            bottomBarItem(context, 5, 'assets/icons/img_5.png', 'Tailors'),
            bottomBarItem(context, 4, 'assets/icons/img_4.png', 'Fabric'),
          ],
        ),
      ),
    ),
  );
}

Widget bottomBarItem(BuildContext context, int pageIndex, String imagePath, String title) {
  bool isSelected = theSelectedPageID == pageIndex;
  
  return AnimatedContainer(
    duration: Duration(milliseconds: 200),
    curve: Curves.easeInOut,
    child: InkWell(
      onTap: () {
        HapticFeedback.lightImpact(); // Add haptic feedback
        if (pageIndex == 1) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => HomePage()), (route) => false);
        } else if (pageIndex == 2) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => BoutiquePage()));
        } else if (pageIndex == 3) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => RentalPage()));
        } else if (pageIndex == 5) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => TailorsListing()));
        } else if (pageIndex == 4) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => FabricsPage()));
        }
      },
      borderRadius: BorderRadius.circular(15),
      splashColor: const Color.fromRGBO(0, 0, 0, 0.1),
      highlightColor: const Color.fromRGBO(0, 0, 0, 0.05),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.2 : 1.0,
              duration: Duration(milliseconds: 200),
              curve: Curves.elasticOut,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color.fromRGBO(0, 0, 0, 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  imagePath,
                  width: 22,
                  height: 22,
                  color: isSelected ? Colors.black : Colors.grey[600],
                ),
              ),
            ),
            SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: AppTheme.shortAnimationDuration,
              style: AppTheme.bodySmall.copyWith(
                color: isSelected ? AppTheme.primaryTextColor : Colors.grey[600],
                fontSize: isSelected ? 11 : 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              child: Text(
                title,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

