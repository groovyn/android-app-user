import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flexi_productimage_slider/flexi_productimage_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:groovyn/main.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../cart/cart_page.dart';
import '../mains/listing_page.dart';
import '../mains/main_landing.dart';
import '../profile/profile_page.dart';
import '../profile/wish_list.dart';
import 'tailors_listing.dart';
import 'tailors_product.dart';

class TailorsPage extends StatefulWidget{
  const TailorsPage({super.key});

  @override
  State<TailorsPage> createState() => TailorsPageState();
}

class TailorsPageState extends State<TailorsPage> {

  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  List<String> tailorImages = [];
  List<Map<String, dynamic>> tailors = [];
  List<Map<String, dynamic>> rentals = [];
  List<DocumentSnapshot> reviews = [];

  @override
  void initState() {
    theSelectedPageID = 2;
    super.initState();
    fetchTailors();
    fetchRentals();
  }

  Future<void> _handleRefresh() async {
    await fetchTailors();
    await fetchRentals();
    _refreshController.refreshCompleted();
  }

  List<Widget> imageSliders = [];

  Future<void> fetchTailors() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('stores').get();

    List<Map<String, dynamic>> fetchedTailors = [];
    List<String> fetchedImages = [];

    for (var doc in querySnapshot.docs) {
      if(doc['businessField'] == 'Tailor') {
        var storeData = doc.data() as Map<String, dynamic>;
        if(storeData['businessImages'] != null && storeData['businessImages'] is List && (storeData['businessImages'] as List).isNotEmpty) {
          storeData['documentID'] = doc.id;
          fetchedTailors.add(storeData);
          fetchedImages.add(storeData['businessImages'][0]);
        }
      }
    }

    setState(() {
      tailors = fetchedTailors;
      tailorImages = fetchedImages;
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
      if (storeDoc.exists && storeDoc['businessField'] == 'Tailor') {
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
                          flexiProductimageSlider(
                            arrayImages: tailorImages,
                            sliderStyle: SliderStyle.nextToSlider,
                            aspectRatio: 0.8,
                            boxFit: BoxFit.cover,
                            selectedImagePosition: 0,
                            thumbnailAlignment: ThumbnailAlignment.bottom,
                            thumbnailWidth: 0,
                            thumbnailHeight: 0,
                          ),
                          const SizedBox(height: 6,),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.8,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2), // Shadow color with transparency
                                  offset: Offset(-4, 4), // Left (-4) and bottom (4) shadow
                                  blurRadius: 10, // Softness of the shadow
                                  spreadRadius: 2, // How much the shadow spreads
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Image.asset('assets/svgs/img_11.png', fit: BoxFit.fitWidth,),
                                    ),
                                    const SizedBox(width: 16,),
                                    Expanded(
                                      child: Image.asset('assets/svgs/img_12.png', fit: BoxFit.fitWidth,),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16,),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Image.asset('assets/svgs/img_13.png', fit: BoxFit.fitWidth,),
                                    ),
                                    const SizedBox(width: 16,),
                                    Expanded(
                                      child: Image.asset('assets/svgs/img_14.png', fit: BoxFit.fitWidth,),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 35,),
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Latest Designs',
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
                          const SizedBox(height: 40,),
                          if(tailors.isNotEmpty)
                            SizedBox(
                              height: 400,
                              width: MediaQuery.of(context).size.width,
                              child: CardSwiper(
                                  cardsCount: tailors.length,
                                  numberOfCardsDisplayed: 2,
                                  maxAngle: 250,
                                  cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                                    var tailor = tailors[index];
                                    bool isFavorite = favoriteStoreIds.contains(tailor['documentID']);
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
                                                      TailorsProduct(
                                                        storeID: tailor['documentID'],
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
                                                            tailor['businessImages'][0],
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
                                                  ],
                                                )
                                            )
                                        ),
                                      ),
                                    );
                                  }
                              ),
                            ),
                          const SizedBox(height: 30,),
                          GestureDetector(
                            onTap: (){
                              Navigator.push(context, MaterialPageRoute(builder: (context)=> const TailorsListing()));
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Tailors Near By',
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
                          if(tailors.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 12.0,),
                              child: SizedBox(
                                height: MediaQuery.of(context).size.height * 0.4,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: tailors.length,
                                  itemBuilder: (context, index) {
                                    var rental = tailors[index];
                                    bool isFavorite = favoriteProductIds.contains(rental['documentID']);
                                    return GestureDetector(
                                      onTap: (){
                                        Navigator.push(context, MaterialPageRoute(builder: (context)=> TailorsProduct(storeID: rental['documentID'])));
                                      },
                                      child: Container(
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
                                                  child: Image.network(
                                                    rental['businessImages'][0],
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
                                            SizedBox(
                                              child: Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          rental['businessName'] ?? '',
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
                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          '${rental['businessLocation'] ?? '0'}',
                                                          style: GoogleFonts.poppins(
                                                              textStyle: TextStyle(
                                                                color: Colors.black,
                                                                fontSize: 18,
                                                                fontFamily: 'Manrope',
                                                                fontWeight: FontWeight.w400,
                                                              )
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8,),
                                                        Center(
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons.star,
                                                                color: Colors.yellow,
                                                              ),
                                                              const SizedBox(width: 8,),
                                                              Text(
                                                                "${rental['businessOpeningTime']}-${rental['businessClosingTime']}",
                                                                style: GoogleFonts.poppins(
                                                                  textStyle: TextStyle(
                                                                    fontWeight: FontWeight.w600,
                                                                  ),
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
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          if(tailors.isEmpty)
                            const SizedBox(height: 20,),
                          if(tailors.isEmpty)
                            Center(
                              child: Text('No Tailors Found !'),
                            ),
                          if(tailors.isEmpty)
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