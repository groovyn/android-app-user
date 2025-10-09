import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flexi_productimage_slider/flexi_productimage_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:groovyn/files/user/mains/main_landing.dart';
import 'package:groovyn/main.dart';
import 'package:groovyn/widgets/custom_image_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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
                      if(theID.isEmpty){
                        handleLogin();
                        return;
                      }

                      _showServiceSelectionDialog('store_visit');
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

                      _showServiceSelectionDialog('home_visit');
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
            child: CustomImageWidget(
              imageUrl: pictures[index],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.circular(8.0),
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeID)
          .collection('services')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.design_services_outlined, size: 60, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No services yet!',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        final services = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index].data() as Map<String, dynamic>;
            return _buildServiceCard(service, services[index].id);
          },
        );
      },
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service, String serviceId) {
    String name = service['name'] ?? 'Service';
    String price = service['price'] ?? '0';
    String originalPrice = service['originalPrice'] ?? '';
    String rating = service['rating'] ?? '4.0';
    String duration = service['duration'] ?? '';
    String description = service['description'] ?? '';
    String imageUrl = service['image'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Image
          if (imageUrl.isNotEmpty)
            CustomImageWidget(
              imageUrl: imageUrl,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),

          // Service Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Name and Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Duration if available
                if (duration.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Text(
                          duration,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Description
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 12),

                // Price and Book Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₹$price',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        if (originalPrice.isNotEmpty && originalPrice != price) ...[
                          const SizedBox(width: 8),
                          Text(
                            '₹$originalPrice',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Book Button
                    GestureDetector(
                      onTap: () {
                        _addServiceToCart(service, serviceId);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          'Book Now',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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
    );
  }

  Future<void> _addServiceToCart(Map<String, dynamic> service, String serviceId) async {
    if (theID.isEmpty) {
      await handleLogin();
      return;
    }

    // Show visit type dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(
            children: [
              Icon(Icons.location_on_outlined, size: 50, color: Color(0xFF6366F1)),
              const SizedBox(height: 8),
              Text(
                'Select Service Type',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            'How would you like to receive this service?',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          actions: [
            Column(
              children: [
                // Store Visit Button
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _showStoreVisitBooking(service, serviceId);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFF6366F1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.store, color: Color(0xFF6366F1), size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Store Visit',
                          style: GoogleFonts.poppins(
                            color: Color(0xFF6366F1),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Home Visit Button
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _showHomeVisitBooking(service, serviceId);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      color: Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Home Visit',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Show Store Visit Booking Dialog
  void _showStoreVisitBooking(Map<String, dynamic> service, String serviceId) {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(20),
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Book Store Visit',
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Service Details
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.design_services, color: Color(0xFF6366F1)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(service['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                Text('₹${service['price']}', style: GoogleFonts.poppins(color: Color(0xFF6366F1))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Date Selection
                    Text('Select Date', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 30)),
                        );
                        if (picked != null && picked != selectedDate) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 20, color: Color(0xFF6366F1)),
                            const SizedBox(width: 8),
                            Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Time Selection
                    Text('Select Time', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null && picked != selectedTime) {
                          setState(() {
                            selectedTime = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time, size: 20, color: Color(0xFF6366F1)),
                            const SizedBox(width: 8),
                            Text(selectedTime.format(context)),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Book Button
                    GestureDetector(
                      onTap: () async {
                        try {
                          EasyLoading.show(status: 'Booking appointment...');

                          // Create appointment
                          await FirebaseFirestore.instance.collection('appointments').add({
                            'userID': theID,
                            'serviceID': serviceId,
                            'serviceName': service['name'],
                            'servicePrice': service['price'],
                            'storeID': widget.storeID,
                            'storeName': productStoreName,
                            'appointmentDate': DateFormat('yyyy-MM-dd').format(selectedDate),
                            'appointmentTime': selectedTime.format(context),
                            'visitType': 'store_visit',
                            'status': 'pending',
                            'paymentStatus': 'pending',
                            'timestamp': FieldValue.serverTimestamp(),
                          });

                          EasyLoading.showSuccess('Appointment booked successfully!');
                          Navigator.pop(context);

                        } catch (e) {
                          EasyLoading.showError('Failed to book appointment');
                          debugPrint('Error booking appointment: $e');
                        }
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Book Appointment',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Show Home Visit Booking Dialog
  void _showHomeVisitBooking(Map<String, dynamic> service, String serviceId) {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    TextEditingController addressController = TextEditingController();
    TextEditingController measurementController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(20),
                height: MediaQuery.of(context).size.height * 0.85,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Book Home Visit',
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Service Details
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.design_services, color: Color(0xFF6366F1)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(service['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                            Text('₹${service['price']}', style: GoogleFonts.poppins(color: Color(0xFF6366F1))),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline, size: 16, color: Colors.orange),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '30% advance payment required (₹${((int.tryParse(service['price']?.toString() ?? '0') ?? 0) * 0.3).toStringAsFixed(0)})',
                                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange.shade900),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Date Selection
                            Text('Select Date', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(Duration(days: 30)),
                                );
                                if (picked != null && picked != selectedDate) {
                                  setState(() {
                                    selectedDate = picked;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 20, color: Color(0xFF6366F1)),
                                    const SizedBox(width: 8),
                                    Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Time Selection
                            Text('Select Time', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final TimeOfDay? picked = await showTimePicker(
                                  context: context,
                                  initialTime: selectedTime,
                                );
                                if (picked != null && picked != selectedTime) {
                                  setState(() {
                                    selectedTime = picked;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time, size: 20, color: Color(0xFF6366F1)),
                                    const SizedBox(width: 8),
                                    Text(selectedTime.format(context)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Address Field
                            Text('Delivery Address', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: addressController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText: 'Enter your complete address',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: EdgeInsets.all(12),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Measurement Details
                            Text('Measurement Details', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: measurementController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Enter your measurements (e.g., Chest: 40", Waist: 34", etc.)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: EdgeInsets.all(12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Payment Button
                    GestureDetector(
                      onTap: () async {
                        if (addressController.text.isEmpty || measurementController.text.isEmpty) {
                          EasyLoading.showError('Please fill all fields');
                          return;
                        }

                        try {
                          EasyLoading.show(status: 'Processing...');

                          double advanceAmount = (int.tryParse(service['price']?.toString() ?? '0') ?? 0) * 0.3;

                          // Create appointment
                          await FirebaseFirestore.instance.collection('appointments').add({
                            'userID': theID,
                            'serviceID': serviceId,
                            'serviceName': service['name'],
                            'servicePrice': service['price'],
                            'advanceAmount': advanceAmount.toStringAsFixed(0),
                            'storeID': widget.storeID,
                            'storeName': productStoreName,
                            'appointmentDate': DateFormat('yyyy-MM-dd').format(selectedDate),
                            'appointmentTime': selectedTime.format(context),
                            'visitType': 'home_visit',
                            'address': addressController.text,
                            'measurementDetails': measurementController.text,
                            'status': 'pending',
                            'paymentStatus': 'pending',
                            'timestamp': FieldValue.serverTimestamp(),
                          });

                          EasyLoading.dismiss();
                          Navigator.pop(context);

                          // Show payment dialog
                          EasyLoading.showInfo('Redirecting to payment...');
                          // TODO: Integrate Cashfree payment

                        } catch (e) {
                          EasyLoading.showError('Failed to book appointment');
                          debugPrint('Error booking home visit: $e');
                        }
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Pay ₹${((int.tryParse(service['price']?.toString() ?? '0') ?? 0) * 0.3).toStringAsFixed(0)} & Book',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Show service selection dialog when bottom buttons are clicked
  void _showServiceSelectionDialog(String visitType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    visitType == 'store_visit' ? 'Select Service - Store Visit' : 'Select Service - Home Visit',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('stores')
                      .doc(widget.storeID)
                      .collection('services')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.black));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.design_services_outlined, size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No services available!',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final services = snapshot.data!.docs;

                    return ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: services.length,
                      itemBuilder: (context, index) {
                        final service = services[index].data() as Map<String, dynamic>;
                        final serviceId = services[index].id;

                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            if (visitType == 'store_visit') {
                              _showStoreVisitBooking(service, serviceId);
                            } else {
                              _showHomeVisitBooking(service, serviceId);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                // Service Image
                                (service['image'] != null && service['image'].toString().isNotEmpty)
                                    ? CustomImageWidget(
                                        imageUrl: service['image'],
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        borderRadius: BorderRadius.circular(8),
                                      )
                                      : Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey.shade200,
                                          child: Icon(Icons.design_services, color: Colors.grey.shade400),
                                        ),
                                const SizedBox(width: 12),
                                // Service Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        service['name'] ?? 'Service',
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            '₹${service['price'] ?? '0'}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          if (service['duration'] != null && service['duration'].toString().isNotEmpty)
                                            Row(
                                              children: [
                                                Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                                                const SizedBox(width: 4),
                                                Text(
                                                  service['duration'],
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                      if (visitType == 'home_visit')
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade50,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '30% advance: ₹${((int.tryParse(service['price']?.toString() ?? '0') ?? 0) * 0.3).toStringAsFixed(0)}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: Colors.orange.shade800,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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