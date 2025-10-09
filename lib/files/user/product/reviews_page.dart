import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:groovyn/files/user/product/write_review.dart';
import 'package:groovyn/widgets/custom_image_widget.dart';

import '../mains/main_landing.dart';

class ReviewsPage extends StatefulWidget {
  final String shopID;
  final String productID;
  const ReviewsPage({super.key, required this.productID, required this.shopID});

  @override
  State<ReviewsPage> createState() => ReviewsPageState();
}

class ReviewsPageState extends State<ReviewsPage> {

  List<Map<String, dynamic>> reviews = [];
  bool isLoading = true;
  bool isSearchActive = true;

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('productID', isEqualTo: widget.productID)
          .get();

      setState(() {
        reviews = querySnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching reviews: $e');
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD9D9D9)),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                review['reviewerName'] ?? 'Anonymous',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                review['relativeTime'] ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (int i = 1; i <= 5; i++)
                Icon(
                  i <= int.parse(review['rating'].toString())
                      ? Icons.star
                      : Icons.star_border,
                  color: Colors.amber,
                  size: 16,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review['reviewText'] ?? '',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < (review['imageLinks'] as List).length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: CustomImageWidget(
                      imageUrl: review['imageLinks'][i],
                      fit: BoxFit.cover,
                      width: 66,
                      height: 66,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color.fromRGBO(250, 250, 250, 1),
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildSearchBar(),
                const SizedBox(height: 20),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildTitle(),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context)=> CreateReviewPage(productID: widget.productID, shopID: widget.shopID,)));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                            ),
                            child: Text(
                              'Write a Review',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Divider(),
                          const SizedBox(height: 12),
                          Text(
                            '${reviews.length} Reviews',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (int i = 1; i <= 5; i++)
                                Icon(
                                  i <= 5
                                      ? Icons.star_border
                                      : Icons.star,
                                  color: Colors.black,
                                  size: 20,
                                ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Divider(),
                          SizedBox(height: height * 0.02),
                          for (var review in reviews)
                            buildReviewCard(review),
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

  Widget _buildSearchBar() {
    return Container(
      height: 40,
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
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (!isSearchActive) {
                Navigator.pop(context);
              }
            },
            child: Icon(
              !isSearchActive ? Icons.arrow_back : Icons.search,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          if (!isSearchActive)
            Text(
              'Rentals',
              style: GoogleFonts.montserrat(
                textStyle: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (!isSearchActive)
          Expanded(child: SizedBox(width: 10,),),
          if (isSearchActive)
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(left: 10),
                ),
              ),
            ),
          GestureDetector(
            onTap: () {
              setState(() {
                isSearchActive = !isSearchActive;
                if (!isSearchActive) {
                  searchController.clear();
                }
              });
            },
            child: Icon(
              isSearchActive ? Icons.close : Icons.search,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Align(
      alignment: Alignment.center,
      child: Text(
        'Tell Others what you Thought',
        style: GoogleFonts.montserrat(
          textStyle: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontFamily: 'Manrope',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
