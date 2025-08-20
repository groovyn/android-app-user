import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flexi_productimage_slider/flexi_productimage_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:groovyn/files/user/mains/main_landing.dart';
import 'package:groovyn/main.dart';

import '../../auth/login_path/sign_in.dart';
import '../cart/cart_page.dart';

class TailorsProduct extends StatefulWidget{
  final String storeID;
  const TailorsProduct({super.key, required this.storeID});

  @override
  State<TailorsProduct> createState() => TailorsProductState();
}

class TailorsProductState extends State<TailorsProduct> {

  List<Map<String, dynamic>> rentals = [];
  List<DocumentSnapshot> reviews = [];
  List<String> pictures = ['assets/images/img_3.png'];
  final List<String> _tabs = ["Services", "Gallery", "Review"];
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

                const SizedBox(height: 16,),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      Text(
                        'Tailor',
                        style: GoogleFonts.roboto(
                          textStyle: const TextStyle(
                            color: Colors.black,
                            fontFamily: 'Manrope',
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
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
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Column(
                              children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      topRight: Radius.circular(10),
                                    ),
                                    child: flexiProductimageSlider(
                                      arrayImages: pictures,
                                      sliderStyle: SliderStyle.nextToSlider,
                                      aspectRatio: 0.8,
                                      boxFit: BoxFit.cover,
                                      selectedImagePosition: 0,
                                      thumbnailAlignment: ThumbnailAlignment.bottom,
                                      thumbnailBorderType: ThumbnailBorderType.all,
                                      thumbnailBorderWidth: 1.5,
                                      thumbnailBorderRadius: 10,
                                      thumbnailWidth: 50,
                                      thumbnailHeight: 65,
                                      thumbnailBorderColor: Colors.blue,
                                    ),
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.timelapse,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 12,),
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
                                )
                              ],
                            )
                          ),

                          const SizedBox(height: 15,),

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
                                _buildServicesTab(),
                                _buildGalleryTab(),
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
      bottomNavigationBar: SizedBox(
        height: 60,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: ()async {

                      // if(selectedSize.isEmpty){
                      //   EasyLoading.showError('No size selected. Select a size first !');
                      //   return;
                      // }
                      if(theID.isEmpty){
                        handleLogin();
                        return;
                      }

                      EasyLoading.showInfo('No service available yet !');

                    },
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x3F000000),
                            blurRadius: 4,
                            offset: Offset(0, 4),
                            spreadRadius: 0,
                          )
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Visit Store',
                          style: GoogleFonts.poppins(
                            textStyle: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {

                      if(theID.isEmpty){
                        handleLogin();
                        return;
                      }

                      EasyLoading.showInfo('No service available yet !');

                    },
                    child: Container(
                      width: 195,
                      height: 60,
                      decoration: BoxDecoration(color: Colors.black),
                      child: Center(
                        child: Text(
                          'Home Service',
                          style: GoogleFonts.poppins(
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryTab() {
    return SizedBox(
      child: GridView.builder(
        padding: const EdgeInsets.all(0.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 6.0,
          mainAxisSpacing: 10.0,
          childAspectRatio: 0.7,
        ),
        itemCount: pictures.length,
        itemBuilder: (context, index) {
          return Container(
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
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                pictures[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewsTab(){
    return Center(
      child: Text('No reviews yet !'),
    );
  }

  Widget _buildServicesTab(){
    return Center(
      child: Text('No services yet !'),
    );
  }

  Future<void> handleLogin() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: Center(
            child: Text(
              'Login Alert !',
              style: GoogleFonts.montserrat(
                textStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          content: Text(
            'Login to the app to add this item to cart !',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              textStyle: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          actions: [
            GestureDetector(
              onTap: () => Navigator.pop(context, false),
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 60,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.black),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Cancel',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      textStyle: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15,),
            GestureDetector(
              onTap: () => Navigator.pop(context, true),
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 60,
                decoration: ShapeDecoration(
                  color: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.black),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Login',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      textStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      if(!mounted){
        return;
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return SignIn();
        },
      );

    }
  }

}