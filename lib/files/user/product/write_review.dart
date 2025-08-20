import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:groovyn/files/user/product/product_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CreateReviewPage extends StatefulWidget {
  final String productID;
  final String shopID;
  const CreateReviewPage({super.key, required this.productID, required this.shopID});

  @override
  State<CreateReviewPage> createState() => _CreateReviewPageState();
}

class _CreateReviewPageState extends State<CreateReviewPage> {

  final TextEditingController reviewController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final searchController = TextEditingController();

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final ImagePicker picker = ImagePicker();

  final List<File> selectedImages = [];

  bool isLoading = false;
  bool isSearchActive = true;

  int selectedRating = 0;

  Future<void> pickImage() async {
    final XFile? pickedFile =
    await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImages.add(File(pickedFile.path));
      });
    }
  }

  Future<List<String>> uploadImages() async {
    List<String> downloadUrls = [];
    try {
      for (int i = 0; i < selectedImages.length; i++) {
        File imageFile = selectedImages[i];

        String fileName = 'review_images/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

        UploadTask uploadTask = storageRef.putFile(imageFile);
        TaskSnapshot snapshot = await uploadTask;

        String downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading images: $e');
      }
      rethrow;
    }
    return downloadUrls;
  }

  Future<void> submitReview() async {
    if (selectedRating == 0 ||
        reviewController.text.isEmpty ||
        nameController.text.isEmpty) {
      EasyLoading.showInfo("Please complete all fields.");
      return;
    }

    EasyLoading.show(status: 'Registering feedback...');

    setState(() {
      isLoading = true;
    });

    try {
      List<String> imageLinks = await uploadImages();
      await firestore.collection('reviews').add({
        'rating': selectedRating.toString(),
        'reviewText': reviewController.text,
        'reviewerName': nameController.text,
        'imageLinks': imageLinks,
        'shopID': widget.shopID,
        'productID': widget.productID,
        'relativeTime': getCurrentFormattedDate(),
      });

      EasyLoading.showSuccess("Review submitted successfully!");

      setState(() {
        selectedRating = 0;
        reviewController.clear();
        nameController.clear();
        selectedImages.clear();
        isLoading = false;
      });

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> ProductPage(productID: widget.productID)));

    } catch (e) {
      EasyLoading.showError("Failed to submit review.");
      setState(() {
        isLoading = false;
      });
    }
  }

  String getCurrentFormattedDate() {
    DateTime now = DateTime.now();
    String day = now.day.toString().padLeft(2, '0');
    String month = now.month.toString().padLeft(2, '0');
    String year = now.year.toString();

    return "$day/$month/$year";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(

          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          5,
                              (index) => IconButton(
                            onPressed: () {
                              setState(() {
                                selectedRating = index + 1;
                              });
                            },
                            icon: Icon(
                              selectedRating > index
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 32,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Add Photo or Video",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 1.0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: GestureDetector(
                            onTap: pickImage,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 32,
                                  color: Colors.black,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Click here to upload",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: selectedImages
                            .map((file) => Image.file(
                          file,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ))
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Write your Review",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: reviewController,
                        maxLength: 400,
                        maxLines: 6,
                        decoration: InputDecoration(
                          hintText:
                          "Would you like to write anything about this product?",
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black.withOpacity(0.6),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.black),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.black),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Name",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: "Your Name",
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black.withOpacity(0.6),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.black),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.black),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : submitReview,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                              "Submit",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
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
}
