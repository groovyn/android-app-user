import 'package:carousel_slider_plus/carousel_slider_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:groovyn/main.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../cart/cart_page.dart';
import '../mains/listing_page.dart';
import '../mains/main_landing.dart';
import '../product/product_page.dart';
import '../profile/profile_page.dart';
import '../profile/wish_list.dart';
import 'boutique_listing.dart';
import 'boutique_product.dart';

class BoutiquePage extends StatefulWidget{
  const BoutiquePage({super.key});

  @override
  State<BoutiquePage> createState() => BoutiquePageState();
}

class BoutiquePageState extends State<BoutiquePage> {

  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  List<Map<String, dynamic>> boutiques = [];
  List<Map<String, dynamic>> rentals = [];
  List<DocumentSnapshot> reviews = [];

  @override
  void initState() {
    theSelectedPageID = 2;
    super.initState();
    fetchBoutiques();
    fetchRentals();
  }

  Future<void> _handleRefresh() async {
    await fetchBoutiques();
    await fetchRentals();
    _refreshController.refreshCompleted();
  }

  List<Widget> imageSliders = [];

  Future<void> fetchBoutiques() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('stores').get();

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
      imageSliders = boutiques.map((item) {
        return Container(
          width: MediaQuery.of(context).size.width,
          height: 600,
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              item['businessImages'][0],
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            ),
          ),
        );
      }).toList();
    });
  }

  Future<void> fetchRentals() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('status', isEqualTo: true)
        .where('trending', isEqualTo: true)
        .get();
    List<Map<String, dynamic>> fetchedRentals = [];

    for (var doc in querySnapshot.docs) {
      var productData = doc.data() as Map<String, dynamic>;
      productData['documentID'] = doc.id;
      Map<String, String> map = await fetchReviews(doc.id);
      productData['total'] =  map['total'];
      productData['rating'] =  map['rating'];
      DocumentSnapshot storeDoc = await FirebaseFirestore.instance.collection('stores').doc(productData['productStoreID']).get();
      if (storeDoc.exists && storeDoc['businessField'] == 'Boutique') {
        fetchedRentals.add(productData);
      }
    }

    setState(() {
      rentals = fetchedRentals;
    });
  }

  Future<void> fetchFavorites() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(theID).get();
    if (userDoc.exists && userDoc.data() != null) {
      setState(() {
        favoriteStoreIds = List<String>.from(userDoc['favouriteStores'] ?? []);
      });
    }
  }

  Future<void> addToFavorites(String productId) async {
    DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(theID);

    if (favoriteStoreIds.contains(productId)) {
      setState(() {
        favoriteStoreIds.remove(productId);
      });
      await userDoc.update({
        'favouriteStores': FieldValue.arrayRemove([productId])
      });
    } else {
      setState(() {
        favoriteStoreIds.add(productId);
      });
      await userDoc.update({
        'favouriteStores': FieldValue.arrayUnion([productId])
      });
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

  @override
  Widget build(BuildContext context) {
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
              header: CustomHeader(
                builder: (context, mode) {
                  return Center(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 90.0),
                          child: Center(
                            child: Image.asset(
                              'assets/images/loading.gif',
                              height: 100,
                              width: 100,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
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
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Image.asset(
                              'assets/icons/img_8.png',
                              width: 40,
                              height: 40,
                            ),
                          ),
                          Expanded(
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
                                    hintText: 'Search',
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
                  // const SizedBox(height: 20,),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 20,),
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                            child: Container(
                              decoration: ShapeDecoration(
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(width: 1, color: Color(0xFFD9D9D9)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Column(
                                children: [
                                  if(boutiques.isNotEmpty)
                                  SizedBox(
                                    height: 400,
                                    width: MediaQuery.of(context).size.width,
                                    child: CardSwiper(
                                      cardsCount: boutiques.length,
                                      numberOfCardsDisplayed: 2,
                                      maxAngle: 250,
                                      cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                                        var boutique = boutiques[index];
                                        bool isFavorite = favoriteStoreIds.contains(boutique['documentID']);
                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(15),
                                          child: Container(
                                            decoration: ShapeDecoration(
                                              color: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                side: BorderSide(color: Colors.black.withOpacity(0.1)),
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
                                            child: GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                      BoutiqueProduct(
                                                        storeID: boutique['documentID'],
                                                      ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                width: (MediaQuery.of(context).size.width / 2) - 44,
                                                height: 400,
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
                                                      child: SizedBox(
                                                        width: MediaQuery.of(context).size.width,
                                                        child: ClipRRect(
                                                          borderRadius: const BorderRadius.only(
                                                            topLeft: Radius.circular(10),
                                                            topRight: Radius.circular(10),
                                                          ),
                                                          child: Image.network(
                                                            boutique['businessImages'][0],
                                                            fit: BoxFit.fill,
                                                            loadingBuilder: (context, child, loadingProgress) {
                                                              if (loadingProgress == null) return child;
                                                              return const Center(
                                                                child: CircularProgressIndicator(),
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 1,
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
                                                                  boutique['businessName'] ?? '',
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
                                                                  onTap: () => addToFavorites(boutique['documentID']),
                                                                  child: Icon(
                                                                    isFavorite
                                                                        ? Icons.favorite
                                                                        : Icons.favorite_border,
                                                                    color: isFavorite ? Colors.red : null,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(height: 1),
                                                            Text(
                                                              boutique['businessLocation'] ?? '',
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
                                                            const SizedBox(height: 4),
                                                            Row(
                                                              children: [
                                                                Text(
                                                                  '${boutique['businessOpeningTime'] ?? '0'} - ${boutique['businessClosingTime'] ?? '0'}',
                                                                  style: GoogleFonts.poppins(
                                                                    textStyle: const TextStyle(
                                                                      color: Colors.black,
                                                                      fontSize: 16,
                                                                      fontFamily: 'Manrope',
                                                                      fontWeight: FontWeight.w400,
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
                                            ),
                                          ),
                                        );
                                      }
                                    ),
                                  ),
                                  const SizedBox(height: 12,),
                                  Text(
                                    'Latest Designs',
                                    style: GoogleFonts.poppins(
                                      textStyle: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  ),
                                  const SizedBox(height: 4,),
                                  Text(
                                    'for you',
                                    style: GoogleFonts.poppins(
                                      textStyle: TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w400,
                                      ),
                                    )
                                  ),
                                  const SizedBox(height: 15,),
                                  GestureDetector(
                                    onTap: (){
                                      Navigator.push(context, MaterialPageRoute(builder: (context)=> const BoutiqueListing()));
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 12.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Image.asset('assets/svgs/img_10.png', height: 7,),
                                          Text(
                                            'View all',
                                            style: GoogleFonts.poppins(
                                              textStyle: TextStyle(
                                                color: Colors.black,
                                                fontSize: 10,
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w400,
                                              ),
                                            )
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 30,),
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Boutiques near you',
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
                          const SizedBox(height: 30,),
                          CarouselSlider(
                            options: CarouselOptions(
                              autoPlay: true,
                              aspectRatio: 1,
                              enlargeCenterPage: true,
                            ),
                            items: imageSliders,
                          ),
                          const SizedBox(height: 20,),
                          GestureDetector(
                            onTap: (){
                              Navigator.push(context, MaterialPageRoute(builder: (context)=> const BoutiqueListing()));
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Trending Designs',
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
                                  Text(
                                    'View all',
                                    style: GoogleFonts.poppins(
                                      textStyle: TextStyle(
                                        color: Colors.black,
                                        fontSize: 10,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w400,
                                      ),
                                    )
                                  )
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20,),
                          if(boutiques.isNotEmpty)
                          Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: SizedBox(
                        height: 320,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: rentals.length,
                          itemBuilder: (context, index) {
                            var rental = rentals[index];
                            return GestureDetector(
                              onTap: (){
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
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12.0, bottom: 12.0),
                                child: Container(
                                  width: (MediaQuery.of(context).size.width / 2),
                                  height: 300,
                                  decoration: ShapeDecoration(
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
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
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: SizedBox(
                                            width: MediaQuery.of(context).size.width,
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                rental['productImages'][0],
                                                fit: BoxFit.fill,
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) return child;
                                                  return Center(
                                                    child: CircularProgressIndicator(),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Expanded(
                                          flex: 1,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    rental['productName'] ?? '',
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
                                                      favoriteProductIds.contains(rental['documentID'])
                                                          ? Icons.favorite
                                                          : Icons.favorite_border,
                                                      color: favoriteProductIds.contains(rental['documentID'])
                                                          ? Colors.red
                                                          : null,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 1),
                                              Text(
                                                rental['productDescription'] ?? '',
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
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Text(
                                                    '₹${rental['productPrice'] ?? '0'}',
                                                    style: GoogleFonts.poppins(
                                                      textStyle: const TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 16,
                                                        fontFamily: 'Manrope',
                                                        fontWeight: FontWeight.w400,
                                                      ),
                                                    ),
                                                  ),
                                                  Spacer(),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.star,
                                                        color: Colors.yellow,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        rental['rating'] ?? '0',
                                                        style: GoogleFonts.poppins(
                                                          textStyle: const TextStyle(
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                      Text(
                                                        "(${rental['total'] ?? '0'})",
                                                        style: GoogleFonts.poppins(
                                                          textStyle: const TextStyle(
                                                            fontWeight: FontWeight.w400,
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
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                          if(boutiques.isEmpty)
                            const SizedBox(height: 20,),
                          if(boutiques.isEmpty)
                            Center(
                              child: Text('No Boutiques Found !'),
                            ),
                          if(boutiques.isEmpty)
                          const SizedBox(height: 20,),
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
}