import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:groovyn/files/user/mains/main_landing.dart';
import 'package:groovyn/main.dart';
import 'package:groovyn/widgets/custom_image_widget.dart';

import '../cart/cart_page.dart';
import '../product/product_page.dart';

class BoutiqueProduct extends StatefulWidget{
  final String storeID;
  const BoutiqueProduct({super.key, required this.storeID});

  @override
  State<BoutiqueProduct> createState() => BoutiqueProductState();
}

class BoutiqueProductState extends State<BoutiqueProduct> {

  List<Map<String, dynamic>> rentals = [];
  List<DocumentSnapshot> reviews = [];
  List<String> pictures = ['assets/images/img_3.png'];
  final List<String> _tabs = ["Styles", "Reviews"];
  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  String productStoreName = '';
  String productStoreLocation = '';
  String productOpeningTime = '';
  String productClosingTime = '';

  bool isLoading = true;

  bool isFavorite = false;

  @override
  void initState() {
    theSelectedPageID = 2;
    isFavorite = favoriteStoreIds.contains(widget.storeID);
    super.initState();
    fetchProductData();
    fetchRentals();
    fetchFavorites();
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
        isFavorite = favoriteStoreIds.contains(widget.storeID);
      });
      await userDoc.update({
        'favouriteStores': FieldValue.arrayRemove([productId])
      });
    } else {
      setState(() {
        favoriteStoreIds.add(productId);
        isFavorite = favoriteStoreIds.contains(widget.storeID);
      });
      await userDoc.update({
        'favouriteStores': FieldValue.arrayUnion([productId])
      });
    }
  }

  Future<void> fetchProductData() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> storeSnapshot = await FirebaseFirestore.instance.collection('stores').doc(widget.storeID).get();

      if (storeSnapshot.exists) {
        final storeData = storeSnapshot.data()!;

        setState(() {
          productStoreName = storeData['businessName'] ?? productStoreName;
          productStoreLocation = storeData['businessLocation'] ?? productStoreLocation;
          productOpeningTime = storeData['businessOpeningTime'] ?? productOpeningTime;
          productClosingTime = storeData['businessClosingTime'] ?? productClosingTime;
          pictures = List<String>.from(storeData['businessImages'] ?? pictures);
        });

      } else {
        debugPrint('Product document does not exist');
      }
    } catch (e) {
      debugPrint('Error fetching product or store data: $e');
    }
    finally{
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchRentals() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('products').where('productStoreID', isEqualTo: widget.storeID).where('status', isEqualTo: true).get();
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
      backgroundColor: Colors.white,
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20,),
                Container(
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
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 15,),
                      Image.asset(
                        'assets/icons/img_8.png',
                        width: 30,
                        height: 30,
                      ),
                      Expanded(child: SizedBox(width: 12,)),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.search,
                                color: Colors.black,
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8,),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.favorite_outline_rounded,
                                color: Colors.black,
                                size: 16,
                              ),
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
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12.0, right: 12.0),
                    child: isLoading ? Center(child: SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        strokeWidth: 8,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    ))
                    : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20,),
                          Container(
                            width: (MediaQuery.of(context).size.width),
                            height: 450,
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(width: 1, color: Color(0xFFD9D9D9)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                        topRight: Radius.circular(10),
                                      ),
                                      child: CardSwiper(
                                        cardsCount: pictures.length,
                                        numberOfCardsDisplayed: pictures.length > 1 ? 2 : 1,
                                        maxAngle: 250,
                                        cardBuilder: (context, index, percentThresholdX, percentThresholdY) =>
                                          CustomImageWidget(
                                            imageUrl: pictures[index],
                                            width: MediaQuery.of(context).size.width - 40,
                                            fit: BoxFit.fill,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
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
                                              productStoreName,
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
                                              onTap: () => addToFavorites(widget.storeID),
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
                                          productStoreLocation,
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
                                              '$productOpeningTime - $productClosingTime',
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
                          ),
                          const SizedBox(height: 20,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(
                              _tabs.length,
                                  (index) => GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedIndex = index;
                                    _pageController.animateToPage(
                                      index,
                                      duration: Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  });
                                },
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                                      child: Text(
                                        _tabs[index],
                                        style: GoogleFonts.montserrat(
                                          textStyle:  TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: _selectedIndex == index ? Colors.black : Colors.grey,
                                          ),
                                        )
                                      ),
                                    ),
                                    // Underline for the selected tab
                                    Container(
                                      height: 2,
                                      width: 60,
                                      color: _selectedIndex == index ? Colors.black : Colors.transparent,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20,),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: PageView(
                              controller: _pageController,
                              onPageChanged: (index) {
                                setState(() {
                                  _selectedIndex = index;
                                });
                              },
                              children: [
                                _buildProductsTab(),
                                _buildReviewsTab(),
                              ],
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
        ),
      ),
      bottomNavigationBar: returnBottomBar(context),
    );
  }
  Widget _buildProductsTab(){
    return SizedBox(
      child: GridView.builder(
        padding: const EdgeInsets.all(0.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 6.0,
          mainAxisSpacing: 10.0,
          childAspectRatio: 0.55,
        ),
        itemCount: rentals.length,
        itemBuilder: (context, index) {
          var rental = rentals[index];
          return GestureDetector(
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
            child: Container(
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8.0),
                    ),
                    child: Stack(
                      children: [
                        CustomImageWidget(
                          imageUrl: rental['productImages'][0],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8.0),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4.0, right: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '4.5',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      textStyle: TextStyle(
                                        color: Colors.black,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 2,),
                                  Icon(
                                    Icons.star_outline,
                                    size: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rental['productName'],
                        style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600
                          ),
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        rental['productDescription'],
                        style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                            color: Color(0xFF848080),
                            fontSize: 12,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${rental['productPrice']}',
                            style: GoogleFonts.roboto(
                              textStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500
                              ),
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
        );
        },
      ),
    );
  }
  Widget _buildReviewsTab(){
    return Container();
  }
}