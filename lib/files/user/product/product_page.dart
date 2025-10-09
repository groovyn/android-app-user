import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:groovyn/files/auth/login_path/sign_in.dart';
import 'package:groovyn/files/user/product/reviews_page.dart';
import 'package:flexi_productimage_slider/flexi_productimage_slider.dart';
import 'package:groovyn/main.dart';
import 'package:intl/intl.dart';
import 'package:groovyn/widgets/custom_image_widget.dart';
import 'package:groovyn/widgets/premium_loading.dart';
import 'package:groovyn/widgets/delivery_widget.dart';

import '../cart/cart_page.dart';
import '../profile/wish_list.dart';

class ProductPage extends StatefulWidget{
  final String productID;
  const ProductPage({super.key, required this.productID});

  @override
  State<ProductPage> createState() => ProductPageState();
}

class ProductPageState extends State<ProductPage> {

  List<String> sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  List<String> colors = ['Black', 'White', 'Red', 'Blue', 'Green', 'Yellow', 'Grey', 'Brown'];
  List<String> pictures = ['assets/images/img_3.png'];
  List<DocumentSnapshot> reviews = [];

  String selectedSize = '';
  String selectedColor = '';

  String productName = 'Rat & Boe';
  String productTags = 'PRISCILLA DRESS';
  String productStoreName = 'FRISKE KNITS PRIVATE LIMITED - SJIT';
  String productStoreLocation = 'India';
  String productDetailVar1 = 'Pattern';
  String productDetailValue1 = 'Regular';
  String productDetailVar2 = 'Brand';
  String productDetailValue2 = 'Generic';
  String productFit = 'Regular';
  String productDetailVar3 = 'Material';
  String productDetailValue3 = 'Material not available';
  String productDescription = 'No Description Available';
  String storeID = '';
  String businessField = 'Rental'; // Default to rental, will be updated from store data

  DateTime? startDate;
  DateTime? endDate;
  final TextEditingController _pincodeController = TextEditingController();

  double rentPerDay = 500;
  double averageRating = 0;

  int selectedStock = 0;

  int selectedDays = 1;
  int totalRatings = 0;

  bool isLoading = true;
  bool isAddingToCart = false;
  bool isBuyingNow = false;

  List<Map<String, dynamic>> boutiques = [];
  List<Map<String, dynamic>> productSizesAndStock = [];

  List<Widget> imageSliders = [];

  @override
  void initState() {
    theSelectedPageID = 0;
    super.initState();
    fetchProductData();
    fetchFavorites();
    fetchReviews();
  }

  Future<void> fetchFavorites() async {
    if (theID.isEmpty) {
      setState(() {
        favoriteProductIds = [];
      });
      return;
    }
    
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(theID).get();
      if (userDoc.exists && userDoc.data() != null) {
        setState(() {
          favoriteProductIds = List<String>.from(userDoc['favourites'] ?? []);
        });
      }
    } catch (e) {
      print('Error fetching favorites: $e');
      setState(() {
        favoriteProductIds = [];
      });
    }
  }

  Future<void> addToFavorites(String productId) async {
    if (theID.isEmpty) return;
    
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

  Future<void> fetchProductData() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> productSnapshot = await FirebaseFirestore
          .instance
          .collection('products')
          .doc(widget.productID)
          .get();

      if (productSnapshot.exists) {
        final productData = productSnapshot.data()!;

        setState(() {
          sizes.clear();
          productSizesAndStock = List<Map<String, dynamic>>.from(productData['productSizesAndStock'] ?? []);
          sizes = productSizesAndStock.map((data) => data['size'] as String).toList();
          colors = productSizesAndStock.map((data) => data['color'] as String).toList();
          if(sizes.isNotEmpty) {
            selectedSize = sizes[0];
          }
          if(colors.isNotEmpty) {
            selectedColor = colors[0];
            selectedStock = productSizesAndStock.first['stock'];
          }

          productName = productData['productName'] ?? productName;
          productTags = productData['productHashtags'] ?? productTags;

          productDetailVar1 = productData['productVar1'] ?? productDetailVar1;
          productDetailValue1 = productData['productWeave'] ?? productDetailVar1;
          productDetailVar2 = productData['productVar2'] ?? productDetailVar2;
          productDetailValue2 = productData['productBrand'] ?? productDetailVar2;

          productFit = productData['productFit'] ?? productFit;

          productDetailVar3 = productData['productVar3'] ?? productDetailVar3;
          productDetailValue3 = productData['productMaterial'] ?? productDetailVar3;

          productDescription = productData['productDescription'] ?? productDescription;
          rentPerDay = double.tryParse(productData['productPrice'] ?? '$rentPerDay') ?? rentPerDay;

          pictures = List<String>.from(productData['productImages'] ?? pictures);
        });

        imageSliders = pictures.map((item) {
          return Container(
            width: MediaQuery.of(context).size.width,
            height: 600,
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: CustomImageWidget(
              imageUrl: item,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(12),
              showShimmer: true,
            ),
          );
        }).toList();

        storeID = productData['productStoreID'] ?? '';
        if (storeID.isNotEmpty) {
          DocumentSnapshot<Map<String, dynamic>> storeSnapshot = await FirebaseFirestore
              .instance
              .collection('stores')
              .doc(storeID)
              .get();

          if (storeSnapshot.exists) {
            final storeData = storeSnapshot.data()!;
            setState(() {
              productStoreName = storeData['businessName'] ?? productStoreName;
              productStoreLocation = storeData['businessLocation'] ?? productStoreLocation;
              businessField = storeData['businessField'] ?? 'Rental';
            });
          } else {
            debugPrint('Store document does not exist for ID: $storeID');
          }
        }
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

  void fetchReviews() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('reviews').where('productID', isEqualTo: widget.productID).limit(2).get();
    setState(() {
      reviews = snapshot.docs;
      totalRatings = reviews.length;
      if (totalRatings > 0) {
        double total = 0;
        for (var review in reviews) {
          if(review['productID'] == widget.productID) {
            total += int.parse(review['rating'].toString());
          }
        }
        averageRating = total / totalRatings;
      }
    });
  }

  List<String> getAvailableColorsForSelectedSize() {
    if (selectedSize.isEmpty) return [];
    return productSizesAndStock
        .where((data) => data['size'] == selectedSize && data['stock'] > 0)
        .map((data) => data['color'] as String)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    List<String> availableColors = getAvailableColorsForSelectedSize();

    return Scaffold(
      backgroundColor: Color.fromRGBO(250, 250, 250, 1),
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
                          GestureDetector(
                            onTap: (){
                              Navigator.push(context, MaterialPageRoute(builder: (context)=> const WishList()));
                            },
                            child: Container(
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
                const SizedBox(height: 20,),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 00.0, right: 00.0),
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
                        children: [
                          flexiProductimageSlider(
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
                          const SizedBox(height: 8,),
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                const SizedBox(height: 12,),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      productName,
                                      style: GoogleFonts.roboto(
                                        textStyle: TextStyle(
                                          color: Colors.black,
                                          fontFamily: 'Manrope',
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => addToFavorites(widget.productID),
                                      child: Icon(
                                        favoriteProductIds.contains(widget.productID) ? Icons.favorite : Icons.favorite_border,
                                        color: favoriteProductIds.contains(widget.productID) ? Colors.red : null,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2,),
                                Text(
                                  productTags,
                                  style: GoogleFonts.poppins(
                                      textStyle: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontFamily: 'Manrope',
                                        fontWeight: FontWeight.w400,
                                      )
                                  ),
                                ),
                                const SizedBox(height: 12,),

                                Text(
                                  'Rent at ₹$rentPerDay',
                                  style: GoogleFonts.poppins(
                                    textStyle: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontFamily: 'Manrope',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20,),

                                Text(
                                    'Size',
                                    style: GoogleFonts.poppins(
                                      textStyle: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                ),
                                const SizedBox(height: 8,),
                                if(sizes.isNotEmpty)
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: sizes.map((size) {
                                        final isSelected = selectedSize == size;
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              selectedSize = size;
                                              selectedColor = '';
                                              selectedStock = productSizesAndStock
                                                  .firstWhere((data) => data['size'] == size)['stock'];
                                            });
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 4),
                                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                            decoration: BoxDecoration(
                                              color: isSelected ? Colors.black : Colors.white,
                                              border: Border.all(color: Colors.black, width: 1),
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                            child: Text(
                                              size,
                                              style: TextStyle(
                                                color: isSelected ? Colors.white : Colors.black,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                if(sizes.isNotEmpty)
                                  const SizedBox(height: 12),
                                if(sizes.isNotEmpty)
                                  Text(
                                    'Available Stock: $selectedStock',
                                    style: GoogleFonts.poppins(
                                      textStyle: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                if(sizes.isEmpty)
                                  Center(child: Text('No Sizes Available'),),
                                if(sizes.isNotEmpty)
                                  const SizedBox(height: 30,),
                                if(sizes.isEmpty)
                                  const SizedBox(height: 15,),

                                Text(
                                  'Color',
                                  style: GoogleFonts.poppins(
                                    textStyle: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8,),
                                if(availableColors.isNotEmpty)
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: availableColors.map((color) {
                                        final isSelected = selectedColor == color;
                                        return GestureDetector(
                                          onTap: () {
                                            print(productSizesAndStock.firstWhere((data) => data['size'] == selectedSize && data['color'] == color));
                                            if(productSizesAndStock.firstWhere((data) => data['size'] == selectedSize && data['color'] == color).isNotEmpty) {
                                              try {
                                                setState(() {
                                                  selectedStock =
                                                  productSizesAndStock
                                                      .firstWhere((data) => data['size'] ==
                                                      selectedSize && data['color'] == color)['stock'];
                                                  selectedColor = color;
                                                });
                                              }
                                              catch(e){
                                                EasyLoading.showError('This color is not available in selected size !');
                                              }
                                            }
                                            else{
                                              EasyLoading.showError('This color is not available in selected size !');
                                            }
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 4),
                                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                            decoration: BoxDecoration(
                                              color: isSelected ? Colors.black : Colors.white,
                                              border: Border.all(color: Colors.black, width: 1),
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                            child: Text(
                                              color,
                                              style: TextStyle(
                                                color: isSelected ? Colors.white : Colors.black,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                if(availableColors.isNotEmpty)
                                  const SizedBox(height: 12),
                                if(availableColors.isNotEmpty)
                                  Text(
                                    'Available Stock: $selectedStock',
                                    style: GoogleFonts.poppins(
                                      textStyle: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                if(colors.isEmpty)
                                  Center(child: Text('No Colors Available'),),
                                if(colors.isNotEmpty)
                                  const SizedBox(height: 30,),
                                if(colors.isEmpty)
                                  const SizedBox(height: 15,),

                                Text(
                                  'Rental Duration',
                                  style: GoogleFonts.poppins(
                                    textStyle: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8,),
                                if (businessField == 'Rental') ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.black, width: 1),
                                          borderRadius: BorderRadius.circular(5),
                                          color: Colors.white,
                                        ),
                                        child: DropdownButton<int>(
                                          value: selectedDays,
                                          underline: const SizedBox(), // Removes the default underline
                                          icon: const Icon(Icons.arrow_drop_down),
                                          items: List.generate(10, (index) => index + 1)
                                              .map((day) => DropdownMenuItem<int>(
                                            value: day,
                                            child: Text(
                                              '$day',
                                              style: const TextStyle(fontSize: 16),
                                            ),
                                          )).toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              selectedDays = value!;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Days',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 16),

                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          '₹ ${selectedDays * rentPerDay}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8,),
                                  Text(
                                    'Rental for $selectedDays ${selectedDays == 1 ? 'day' : 'days'} - Get delivered by ${formatDate(DateTime.now().add(Duration(days: 3)))}',
                                    style: GoogleFonts.poppins(
                                      textStyle: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400
                                      )
                                    ),
                                  ),
                                ] else ...[
                                  // For boutique products, show simple pricing
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '₹ ${rentPerDay.toInt()}',
                                      style: GoogleFonts.montserrat(
                                        textStyle: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8,),
                                  Text(
                                    'Get delivered by ${formatDate(DateTime.now().add(Duration(days: 3)))}',
                                    style: GoogleFonts.poppins(
                                      textStyle: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400
                                      )
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16,),
                                // Delivery/Pincode Widget
                                DeliveryEstimationWidget(
                                  pincodeController: _pincodeController,
                                  onPincodeChanged: (pincode) {
                                    // Handle pincode change if needed
                                  },
                                ),
                                const SizedBox(height: 16,),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Store : ',
                                        style: GoogleFonts.poppins(
                                          textStyle: TextStyle(
                                            color: Colors.black,
                                            fontSize: 14,
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      TextSpan(
                                        text: productStoreName,
                                        style: GoogleFonts.poppins(
                                          textStyle: TextStyle(
                                            color: Color(0xFFF92668),
                                            fontSize: 14,
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4,),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Location : ',
                                        style: GoogleFonts.poppins(
                                          textStyle: TextStyle(
                                            color: Colors.black,
                                            fontSize: 14,
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      TextSpan(
                                        text: productStoreLocation,
                                        style: GoogleFonts.poppins(
                                          textStyle: TextStyle(
                                            color: Color(0xFFF92668),
                                            fontSize: 14,
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20,),

                                // Only show dates section for rental products
                                if (businessField == 'Rental') ...[
                                  Text(
                                    'Dates',
                                    style: GoogleFonts.poppins(
                                      textStyle: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () async {
                                      DateTime now = DateTime.now();
                                      DateTime? pickedDate = await showDatePicker(
                                        context: context,
                                        initialDate: now,
                                        firstDate: now,
                                        lastDate: DateTime(now.year + 1),
                                        builder: (BuildContext context, Widget? child) {
                                          return Theme(
                                            data: ThemeData.dark().copyWith(
                                              colorScheme: ColorScheme.dark(
                                                primary: Colors.black,
                                                onPrimary: Colors.white,
                                                surface: Colors.white,
                                                onSurface: Colors.black,
                                              ),
                                              dialogBackgroundColor: Colors.white,
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );

                                      if (pickedDate != null) {
                                        setState(() {
                                          startDate = pickedDate;
                                          endDate = pickedDate.add(
                                            Duration(days: selectedDays - 1),
                                          );
                                        });
                                      }
                                    },

                                    child: Container(
                                      padding:
                                      const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.black, width: 1),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            startDate == null || endDate == null
                                                ? 'Select Date Range'
                                                : '${DateFormat('d MMM yyyy').format(startDate!)} - ${DateFormat('d MMM yyyy').format(endDate!)}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const Icon(Icons.calendar_today_outlined),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20,),
                                ],

                                Row(
                                  children: [
                                    Image.asset('assets/icons/img_5.png', width: 40, height: 40, fit: BoxFit.fill,),
                                    SizedBox(width: 12,),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Get it in by ${formatDate(DateTime.now().add(Duration(days: 3)))}',
                                            style: GoogleFonts.poppins(
                                              textStyle: TextStyle(
                                                color: Colors.black,
                                                fontSize: 16,
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w600,
                                              ),
                                            )
                                          ),
                                          Text(
                                            'No Convenience Fee',
                                            style: GoogleFonts.poppins(
                                              textStyle: TextStyle(
                                                color: Colors.black,
                                                fontSize: 12,
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w300,
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Image.asset('assets/icons/img_6.png', width: 40, height: 40, fit: BoxFit.fill,),
                                    SizedBox(width: 12,),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Pay on Delivery is Available',
                                            style: GoogleFonts.poppins(
                                              textStyle: TextStyle(
                                                color: Colors.black,
                                                fontSize: 16,
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w600,
                                              ),
                                            )
                                          ),
                                          Text(
                                            '₹10 Additional fee applicable',
                                            style: GoogleFonts.poppins(
                                              textStyle: TextStyle(
                                                color: Colors.black,
                                                fontSize: 12,
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w300,
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Image.asset('assets/icons/img_7.png', width: 40, height: 40, fit: BoxFit.fill,),
                                    SizedBox(width: 12,),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Hassle free Returns & Exchange ',
                                            style: GoogleFonts.poppins(
                                              textStyle: TextStyle(
                                                color: Colors.black,
                                                fontSize: 16,
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w600,
                                              ),
                                            )
                                          ),
                                          Text(
                                            'Return any Time',
                                            style: GoogleFonts.poppins(
                                              textStyle: TextStyle(
                                                color: Colors.black,
                                                fontSize: 12,
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w300,
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    )
                                  ],
                                ),

                                const SizedBox(height: 20,),

                                Container(
                                  width: MediaQuery.of(context).size.width,
                                  decoration: ShapeDecoration(
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(width: 1, color: Color(0xFFD9D9D9)),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  productDetailVar1,
                                                  style: GoogleFonts.poppins(
                                                    textStyle: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 14,
                                                      fontFamily: 'Poppins',
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  )
                                                ),
                                                Text(
                                                  productDetailValue1,
                                                    style: GoogleFonts.poppins(
                                                      textStyle: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 12,
                                                        fontFamily: 'Poppins',
                                                        fontWeight: FontWeight.w400,
                                                      ),
                                                    )
                                                )
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  productDetailVar2,
                                                  style: GoogleFonts.poppins(
                                                    textStyle: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 14,
                                                      fontFamily: 'Poppins',
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  )
                                                ),
                                                Text(
                                                  productDetailValue2,
                                                  style: GoogleFonts.poppins(
                                                    textStyle: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 12,
                                                      fontFamily: 'Poppins',
                                                      fontWeight: FontWeight.w400,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20,),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Fit',
                                                  style: GoogleFonts.poppins(
                                                    textStyle: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 14,
                                                      fontFamily: 'Poppins',
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  productFit,
                                                  style: GoogleFonts.poppins(
                                                    textStyle: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 12,
                                                      fontFamily: 'Poppins',
                                                      fontWeight: FontWeight.w400,
                                                    ),
                                                  )
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 20,),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  productDetailVar3,
                                                  style: GoogleFonts.poppins(
                                                    textStyle: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 14,
                                                      fontFamily: 'Poppins',
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  productDetailValue3,
                                                  style: GoogleFonts.poppins(
                                                    textStyle: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 12,
                                                      fontFamily: 'Poppins',
                                                      fontWeight: FontWeight.w400,
                                                    ),
                                                  ),
                                                ),

                                              ],
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 20,),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Product Details',
                                                  style: GoogleFonts.poppins(
                                                    textStyle: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 14,
                                                      fontFamily: 'Poppins',
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: MediaQuery.of(context).size.width - 80,
                                                  child: Text(
                                                    productDescription,
                                                    style: GoogleFonts.poppins(
                                                      textStyle: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 12,
                                                        fontFamily: 'Poppins',
                                                        fontWeight: FontWeight.w400,
                                                      ),
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

                                const SizedBox(height: 20,),

                                Container(
                                  width: MediaQuery.of(context).size.width,
                                  decoration: ShapeDecoration(
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(width: 1, color: Color(0xFFD9D9D9)),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Rating & Reviews',
                                          style: GoogleFonts.poppins(
                                            textStyle: TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              averageRating.toStringAsFixed(1),
                                              style: GoogleFonts.poppins(
                                                textStyle: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(Icons.star, color: Colors.orange, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              '$totalRatings ratings',
                                              style: GoogleFonts.poppins(
                                                textStyle: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12),
                                        reviews.isNotEmpty
                                            ? Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: reviews.map((review) {
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 12.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        review['reviewerName'],
                                                        style: GoogleFonts.poppins(
                                                          textStyle: TextStyle(
                                                            color: Colors.black,
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                      Text(
                                                        review['relativeTime'],
                                                        style: GoogleFonts.poppins(
                                                          textStyle: TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: 10,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 4),
                                                  Row(
                                                    children: List.generate(5, (index) {
                                                      return Icon(
                                                        index < int.parse(review['rating'].toString()) ? Icons.star : Icons.star_border,
                                                        color: Colors.orange,
                                                        size: 16,
                                                      );
                                                    }),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    review['reviewText'],
                                                    style: GoogleFonts.poppins(
                                                      textStyle: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w300,
                                                      ),
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        )
                                            : Text(
                                          'No reviews available yet!',
                                          style: GoogleFonts.poppins(
                                            textStyle: TextStyle(
                                              color: Colors.black,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w300,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context)=> ReviewsPage(productID: widget.productID, shopID: storeID,)));
                                          },
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                                          child: Text(
                                            'View All Reviews',
                                            style: GoogleFonts.poppins(
                                              textStyle: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20,),

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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: PremiumButton(
                text: 'Add to Cart',
                icon: Icons.shopping_cart_outlined,
                isLoading: isAddingToCart,
                backgroundColor: Colors.white,
                textColor: Colors.black,
                onPressed: () async {
                  if(theID.isEmpty){
                    handleLogin();
                    return;
                  }

                  setState(() {
                    isAddingToCart = true;
                  });

                  await Future.delayed(Duration(milliseconds: 500));

                  if(!cartProductIDs.contains(widget.productID)) {
                    cartProductIDs.add(widget.productID);
                    cartProductNames.add(productName);
                    cartProductImages.add(pictures[0]);
                    cartProductPrices.add(businessField == 'Rental' ? (rentPerDay*selectedDays).toString() : rentPerDay.toString());
                    cartProductSizes.add(selectedSize.toString());
                    cartProductColors.add(selectedColor.toString());
                    cartProductTags.add(productTags);
                    cartProductQuantity.add(1);
                  } else {
                    cartProductQuantity[cartProductIDs.indexOf(widget.productID)]++;
                  }

                  setState(() {
                    isAddingToCart = false;
                  });

                  EasyLoading.showSuccess('Added to cart!');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PremiumButton(
                text: 'Buy Now',
                icon: Icons.flash_on,
                isLoading: isBuyingNow,
                backgroundColor: Colors.black,
                textColor: Colors.white,
                onPressed: () async {
                  if(theID.isEmpty){
                    handleLogin();
                    return;
                  }

                  if(selectedSize.isEmpty){
                    EasyLoading.showError('Please select a size first!');
                    return;
                  }

                  if(selectedColor.isEmpty){
                    EasyLoading.showError('Please select a color first!');
                    return;
                  }

                  setState(() {
                    isBuyingNow = true;
                  });

                  await Future.delayed(Duration(milliseconds: 500));

                  if(!cartProductIDs.contains(widget.productID)) {
                    cartProductIDs.add(widget.productID);
                    cartProductNames.add(productName);
                    cartProductImages.add(pictures[0]);
                    cartProductPrices.add(businessField == 'Rental' ? (rentPerDay*selectedDays).toString() : rentPerDay.toString());
                    cartProductSizes.add(selectedSize.toString());
                    cartProductColors.add(selectedColor.toString());
                    cartProductTags.add(productTags);
                    cartProductQuantity.add(1);
                  } else {
                    cartProductQuantity[cartProductIDs.indexOf(widget.productID)]++;
                  }

                  setState(() {
                    isBuyingNow = false;
                  });

                  Navigator.push(context, MaterialPageRoute(builder: (context)=> const CartPage()));
                },
              ),
            ),
          ],
        ),
      ),
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

  String formatDate(DateTime date) {

    final String dayOfWeek = DateFormat('EEEE').format(date);
    final String month = DateFormat('MMMM').format(date);
    final int day = date.day;

    String suffix;
    if (day % 10 == 1 && day != 11) {
      suffix = 'st';
    } else if (day % 10 == 2 && day != 12) {
      suffix = 'nd';
    } else if (day % 10 == 3 && day != 13) {
      suffix = 'rd';
    } else {
      suffix = 'th';
    }

    return '$dayOfWeek, $day$suffix $month';
  }

  @override
  void dispose() {
    _pincodeController.dispose();
    super.dispose();
  }
}