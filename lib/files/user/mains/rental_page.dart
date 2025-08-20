import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:groovyn/files/user/mains/listing_page.dart';
import 'package:groovyn/files/user/product/product_page.dart';
import 'package:groovyn/main.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

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

  Future<void> _handleRefresh() async {
    await fetchRentals();
    await fetchAllStoresData();
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
                                              child: Image.network(
                                                rental['businessImage'],
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
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 20,),
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
                                        fontSize: 10,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.02,),
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                            child: SizedBox(
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
                                          Flexible(
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
                                          Flexible(
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
                                                                fontSize: 18,
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
                                                    const SizedBox(height: 2,),
                                                    Flexible(
                                                      child: Center(
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons.star,
                                                              color: Colors.yellow,
                                                            ),
                                                            const SizedBox(width: 8,),
                                                            Text(
                                                              rental['rating'] ?? '0',
                                                              style: GoogleFonts.poppins(
                                                                textStyle: TextStyle(
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                              ),
                                                            ),
                                                            Text(
                                                              "(${rental['total'] ?? '0'})",
                                                              style: GoogleFonts.poppins(
                                                                textStyle: TextStyle(
                                                                  fontWeight: FontWeight.w400,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
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
                                                                fontWeight: FontWeight.w600,
                                                              )
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8,),
                                                        Text(
                                                          '30% OFF',
                                                          style: GoogleFonts.poppins(
                                                              textStyle: TextStyle(
                                                                color: Colors.black,
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