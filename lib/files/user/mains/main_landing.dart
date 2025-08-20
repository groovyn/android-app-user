import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:groovyn/files/user/boutique/boutique_page.dart';
import 'package:groovyn/files/user/fabrics/fabrics_page.dart';
import 'package:groovyn/files/user/mains/listing_page.dart';
import 'package:groovyn/files/user/profile/profile_page.dart';
import 'package:groovyn/files/user/product/product_page.dart';
import 'package:groovyn/files/user/mains/rental_page.dart';
import 'package:groovyn/files/user/profile/wish_list.dart';
import 'package:groovyn/files/user/tailors/tailors_listing.dart';
import 'package:groovyn/files/user/tailors/tailors_page.dart';
import 'package:groovyn/main.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../boutique/boutique_product.dart';
import '../cart/cart_page.dart';

class HomePage extends StatefulWidget{
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {

  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  List<Map<String, dynamic>> rentals = [];
  List<Map<String, dynamic>> tailors = [];
  List<DocumentSnapshot> reviews = [];
  List<Map<String, dynamic>> boutiques = [];

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
    fetchRentals();
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
    List<Map<String, dynamic>> fetchedRentals = [];

    for (var doc in querySnapshot.docs) {
      var productData = doc.data() as Map<String, dynamic>;
      productData['documentID'] = doc.id;
      Map<String, String> map = await fetchReviews(doc.id);
      productData['total'] =  map['total'];
      productData['rating'] =  map['rating'];
      DocumentSnapshot storeDoc = await FirebaseFirestore.instance.collection('stores').doc(productData['productStoreID']).get();
      if (storeDoc.exists && storeDoc['businessField'] == 'Rental') {
        fetchedRentals.add(productData);
      }
    }

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
                  if (!isLoading)
                    Column(
                      children: [
                        SingleChildScrollView(
                          child: Column(
                            children: [
                              SizedBox(
                                height: 300,
                                width: MediaQuery.of(context).size.width,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _advertisements.length,
                                  itemBuilder:  (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 12.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          _advertisements[index],
                                          fit: BoxFit.cover,
                                          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            } else {
                                              return Center(
                                                child: Image.asset(
                                                  'assets/images/image.gif',
                                                  fit: BoxFit.fitWidth,
                                                  width: 120,
                                                  height: 100,
                                                ),
                                              );
                                            }
                                          },
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
                                    SizedBox(height: height * 0.02,),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Category',
                                        style: GoogleFonts.montserrat(
                                          textStyle: TextStyle(
                                            color: Colors.black,
                                            fontSize: 20,
                                            fontFamily: 'Manrope',
                                            fontWeight: FontWeight.bold,
                                          )
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: height * 0.02,),
                                    SizedBox(
                                      height: MediaQuery.of(context).size.height * 0.45,
                                      child: GridView.count(
                                        physics: const NeverScrollableScrollPhysics(),
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 20,
                                        crossAxisSpacing: 20,
                                        childAspectRatio: 1.2,
                                        children: [
                                          GestureDetector(
                                            onTap: (){
                                              Navigator.push(context, MaterialPageRoute(builder: (context)=> const TailorsPage()));
                                            },
                                            child: _buildGridItem('assets/svgs/img.png'),
                                          ),
                                          GestureDetector(
                                            onTap: (){
                                              Navigator.push(context, MaterialPageRoute(builder: (context)=> const BoutiquePage()));
                                            },
                                            child: _buildGridItem('assets/svgs/img_1.png'),
                                          ),
                                          GestureDetector(
                                            onTap: (){
                                              Navigator.push(context, MaterialPageRoute(builder: (context)=> const FabricsPage()));
                                            },
                                            child: _buildGridItem('assets/svgs/img_2.png'),
                                          ),
                                          GestureDetector(
                                            onTap: (){
                                              Navigator.push(context, MaterialPageRoute(builder: (context)=> const RentalPage()));
                                            },
                                            child: _buildGridItem('assets/svgs/img_3.png'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: height * 0.04,),
                                    GestureDetector(
                                      onTap: (){
                                        Navigator.push(context, MaterialPageRoute(builder: (context)=> const TailorsListing()));
                                      },
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Trending Tailors',
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
                                            'More',
                                            style: GoogleFonts.montserrat(
                                              textStyle: TextStyle(
                                                color: Color(0xFF3F738B),
                                                fontSize: 13,
                                                fontFamily: 'Manrope',
                                                fontWeight: FontWeight.w500,
                                              )
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: height * 0.02,),
                              Padding(
                                padding: const EdgeInsets.only(left: 20.0),
                                child: SizedBox(
                                  height: 300,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: tailors.length,
                                    itemBuilder: (context, index) {
                                      var tailor = tailors[index];
                                      return Padding(
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
                                                SizedBox(
                                                  width: MediaQuery.of(context).size.width,
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: Image.network(
                                                      tailor['businessImages'][0],
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
                                                const SizedBox(height: 12,),
                                                Expanded(
                                                  flex: 1,
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text(
                                                            tailor['businessName'] ?? '',
                                                            style: GoogleFonts.roboto(
                                                              textStyle: const TextStyle(
                                                                color: Colors.black,
                                                                fontFamily: 'Manrope',
                                                                fontSize: 18,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 1),
                                                      Text(
                                                        tailor['businessLocation'] ?? '',
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
                                                            '${tailor['businessOpeningTime'] ?? '0'} - ${tailor['businessClosingTime'] ?? '0'}',
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
                                                  )
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
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Trending Boutiques',
                                        style: GoogleFonts.montserrat(
                                          textStyle: TextStyle(
                                            color: Colors.black,
                                            fontSize: 20,
                                            fontFamily: 'Manrope',
                                            fontWeight: FontWeight.bold,
                                          )
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: height * 0.02,),
                                    SizedBox(
                                      height: 400,
                                      width: MediaQuery.of(context).size.width,
                                      child: boutiques.isNotEmpty
                                          ? CardSwiper(
                                        cardsCount: boutiques.length,
                                        numberOfCardsDisplayed: 2,
                                        maxAngle: 250,
                                        backCardOffset: Offset(30, -30),
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
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                      ) : null,
                                    ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
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
                                    ),
                                    SizedBox(height: height * 0.02,),
                                    SizedBox(
                                      height: MediaQuery.of(context).size.height * 0.6,
                                      child: rentals.isNotEmpty
                                          ? MasonryGridView.count(
                                        physics: const NeverScrollableScrollPhysics(),
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 10,
                                        crossAxisSpacing: 12,
                                        itemCount: rentals.length,
                                        itemBuilder: (context, index) {
                                          var rental = rentals[index];
                                          bool isFavorite = favoriteProductIds.contains(rental['documentID']);
                        
                                          return GestureDetector(
                                            onTap: (){
                                              Navigator.push(context, MaterialPageRoute(builder: (context)=> ProductPage(productID: rental['documentID'])));
                                            },
                                            child: Container(
                                              width: (MediaQuery.of(context).size.width / 2) - 44,
                                              height: (index % 2 == 0) ? 240 : 200,
                                              decoration: ShapeDecoration(
                                                color: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                shadows: [
                                                  BoxShadow(
                                                    color: Color(0x3F000000),
                                                    blurRadius: 2,
                                                    offset: Offset(2, 2),
                                                    spreadRadius: 0,
                                                  )
                                                ],
                        
                                              ),
                                              child: Column(
                                                children: [
                                                  Expanded(
                                                    flex: 3,
                                                    child: Container(
                                                      width: MediaQuery.of(context).size.width,
                                                      decoration: ShapeDecoration(
                                                        color: Color(0xFFD9D9D9),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.only(
                                                            topLeft: Radius.circular(10),
                                                            topRight: Radius.circular(10),
                                                          ),
                                                        ),
                                                      ),
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(0.0),
                                                        child: ClipRRect(
                                                          borderRadius: BorderRadius.only(
                                                            topLeft: Radius.circular(10),
                                                            topRight: Radius.circular(10),
                                                          ),
                                                          child: Image.network(
                                                            rental['productImages'][0],
                                                            fit: BoxFit.cover,
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
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Container(
                                                      decoration: ShapeDecoration(
                                                        color: Colors.white,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                      ),
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
                                                                  rental['productName'] ?? '',
                                                                  style: GoogleFonts.roboto(
                                                                    textStyle: TextStyle(
                                                                      color: Colors.black,
                                                                      fontFamily: 'Manrope',
                                                                      fontSize: 16,
                                                                      fontWeight: FontWeight.w600,
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
                                                            const SizedBox(height: 2,),
                                                            Text(
                                                              rental['productDescription'] ?? '0',
                                                              style: GoogleFonts.poppins(
                                                                textStyle: TextStyle(
                                                                  color: Color(0xFF848080),
                                                                  fontWeight: FontWeight.w300,
                                                                  fontSize: 12
                                                                ),
                                                              ),
                                                            ),
                                                            Row(
                                                              mainAxisAlignment: MainAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  '₹${rental['productPrice'] ?? '0'}',
                                                                  style: GoogleFonts.poppins(
                                                                    textStyle: TextStyle(
                                                                      color: Colors.black,
                                                                      fontSize: 16,
                                                                      fontFamily: 'Manrope',
                                                                      fontWeight: FontWeight.w500,
                                                                    )
                                                                  ),
                                                                ),
                                                                const SizedBox(width: 8,),
                                                                Text(
                                                                  '30% OFF',
                                                                  style: GoogleFonts.poppins(
                                                                    textStyle: TextStyle(
                                                                      color: Color(0xFF949090),
                                                                      fontSize: 8,
                                                                      fontFamily: 'Manrope',
                                                                      fontWeight: FontWeight.w500,
                                                                    )
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                          : Center(child: CircularProgressIndicator()),
                                    ),
                                    // SizedBox(height: height * 0.02,),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Center(
                      child: CircularProgressIndicator()
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
        // color: Color(0xFFACDDDE),
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
          child: Image.asset(
            imagePath,
            fit: BoxFit.fitHeight,
          ),
        ),
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
}

Widget returnBottomBar(BuildContext context) {
  return Container(
    width: MediaQuery.of(context).size.width,
    height: 70,
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(width: 1.0, color: Colors.grey),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        bottomBarItem(context, 1, 'assets/icons/img_1.png', 'Home'),
        bottomBarItem(context, 2, 'assets/icons/img_2.png', 'Boutiques'),
        bottomBarItem(context, 3, 'assets/icons/img_3.png', 'Rental'),
        bottomBarItem(context, 4, 'assets/icons/img_4.png', 'Fabric'),
      ],
    ),
  );
}

Widget bottomBarItem(BuildContext context, int pageIndex, String imagePath, String title) {
  return GestureDetector(
    onTap: (){
      if (pageIndex == 1) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=> HomePage()), (route)=>false);
      } else if (pageIndex == 2) {
        Navigator.push(context, MaterialPageRoute(builder: (context)=> BoutiquePage()));
      } else if (pageIndex == 3) {
        Navigator.push(context, MaterialPageRoute(builder: (context)=> RentalPage()));
      } else if (pageIndex == 4) {
        Navigator.push(context, MaterialPageRoute(builder: (context)=> FabricsPage()));
      }
    },
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Image.asset(
          imagePath,
          width: 20,
          height: 20,
          color: theSelectedPageID == pageIndex
              ? Colors.black
              : Colors.grey,
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theSelectedPageID == pageIndex
                ? Colors.black
                : Color(0xFF080000),
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            height: 0.22,
          ),
        ),
      ],
    ),
  );
}

