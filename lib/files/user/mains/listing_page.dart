import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:groovyn/files/user/product/product_page.dart';
import 'package:groovyn/main.dart';

import 'main_landing.dart';

class ListingPage extends StatefulWidget {
  final bool isSearch;
  final String? collection;
  const ListingPage({super.key, required this.isSearch, this.collection});

  @override
  State<ListingPage> createState() => ListingPageState();
}

class ListingPageState extends State<ListingPage> {

  List<Map<String, dynamic>> rentals = [];
  List<Map<String, dynamic>> filteredRentals = [];

  bool isSearchActive = false;
  bool isLoading = false;
  bool hasMore = true;

  final TextEditingController searchController = TextEditingController();

  DocumentSnapshot? lastDocument;

  final int pageSize = 10;

  @override
  void initState() {
    theSelectedPageID = 3;
    isSearchActive = widget.isSearch;
    super.initState();
    fetchFavorites();
    fetchRentals();
  }

  Future<void> fetchRentals() async {
    if (isLoading || !hasMore) return;

    setState(() {
      isLoading = true;
    });

    Query query = FirebaseFirestore.instance.collection('products').where('status', isEqualTo: true).limit(pageSize);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument!);
    }

    QuerySnapshot querySnapshot = await query.get();

    if (querySnapshot.docs.isNotEmpty) {
      lastDocument = querySnapshot.docs.last;

      for (var doc in querySnapshot.docs) {
        var productData = doc.data() as Map<String, dynamic>;
        productData['documentID'] = doc.id;
        DocumentSnapshot storeDoc = await FirebaseFirestore.instance
            .collection('stores')
            .doc(productData['productStoreID'])
            .get();

        if (storeDoc.exists && storeDoc['businessField'] == 'Rental') {
          if(widget.collection != null) {
            if (productData['productHashtags'].toString().toLowerCase().contains(widget.collection.toString().toLowerCase())) {
              rentals.add(productData);
            }
          }
          else{
            rentals.add(productData);
          }
        }
      }

      setState(() {
        filteredRentals = rentals;
        hasMore = querySnapshot.docs.length == pageSize;
      });
    } else {
      setState(() {
        hasMore = false;
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  void filterSearchResults(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredRentals = rentals;
      });
    } else {
      setState(() {
        filteredRentals = rentals
            .where((rental) =>
            rental['productName']
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  Future<void> fetchFavorites() async {
    DocumentSnapshot userDoc =
    await FirebaseFirestore.instance.collection('users').doc(theID).get();
    if (userDoc.exists && userDoc.data() != null) {
      setState(() {
        favoriteProductIds = List<String>.from(userDoc['favourites'] ?? []);
      });
    }
  }

  Future<void> addToFavorites(String productId) async {
    DocumentReference userDoc =
    FirebaseFirestore.instance.collection('users').doc(theID);

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
                    child: Column(
                      children: [
                        _buildTitle(),
                        SizedBox(height: height * 0.02),
                        _buildRentalsList(),
                      ],
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
                onChanged: filterSearchResults,
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
                  filteredRentals = rentals;
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
      alignment: Alignment.centerLeft,
      child: Text(
        'Trending Rentals',
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

  Widget _buildRentalsList() {
    return Expanded(
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
              !isLoading &&
              hasMore) {
            fetchRentals();
          }
          return false;
        },
        child: isLoading ?
        Center(child: CircularProgressIndicator()): filteredRentals.isNotEmpty
            ? MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 12,
          itemCount: filteredRentals.length,
          itemBuilder: (context, index) {
            var rental = filteredRentals[index];
            bool isFavorite =
            favoriteProductIds.contains(rental['documentID']);
            return _buildRentalItem(rental, isFavorite);
          },
        ) : const Center(child: Text('No Rentals Found !')),
      ),
    );
  }

  Widget _buildRentalItem(Map<String, dynamic> rental, bool isFavorite) {
    return GestureDetector(
        onTap: () {
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
        child: Container(
            width: (MediaQuery
                .of(context)
                .size
                .width / 2) - 44,
            height: 200,
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
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    child: Image.network(
                      rental['productImages'][0],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
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
                              rental['productName'].toString().length > 7 ? '${rental['productName'].toString().substring(0,7)}...' : rental['productName'].toString(),
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
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite ? Colors.red : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rental['productDescription'].toString().length > 7 ? '${rental['productDescription'].toString().substring(0,7)}...' : rental['productDescription'].toString(),
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
                        Row(
                          children: [
                            Text(
                              '₹${rental['productPrice'] ?? '0'}',
                              style: GoogleFonts.poppins(
                                textStyle: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontFamily: 'Manrope',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '30% OFF',
                              style: GoogleFonts.poppins(
                                textStyle: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 10,
                                  fontFamily: 'Manrope',
                                  fontWeight: FontWeight.w500,
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
    );
  }
}
