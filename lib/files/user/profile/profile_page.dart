import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:groovyn/files/auth/login_path/intro_page.dart';
import 'package:groovyn/files/user/profile/update_profile_page.dart';
import 'package:groovyn/files/user/profile/wish_list.dart';
import 'package:groovyn/widgets/custom_image_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../main.dart';
import '../mains/main_landing.dart';
import '../orders/orders_page.dart';
import '../appointments/appointments_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {

  @override
  void initState() {
    theSelectedPageID = 0;
    super.initState();
    fetchUserData();
  }

  void fetchUserData() async {
    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(theID);

      DocumentSnapshot snapshot = await userDoc.get();

      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

        setState(() {
          theEmail = data['email'] ?? '';
          favoriteStoreIds = data['favouriteStores'] ?? [];
          favoriteProductIds = data['favourites'] ?? [];
          theName = data['name'] ?? '';
          theProfile = data['profilePic'] ?? '';
          thePhone = data['phone'] ?? '';
        });

      } else {
        if (kDebugMode) {
          print('Document with ID $theID does not exist.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user data: $e');
      }
    }
  }

  Future<void> updateProfilePicture() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile == null) {
        EasyLoading.showError('No image selected');
        return;
      }

      EasyLoading.show(status: 'Uploading...');

      File imageFile = File(pickedFile.path);
      String fileName = 'profile_pictures/${theID}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final storageRef = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = await storageRef.putFile(imageFile);

      if (uploadTask.state == TaskState.success) {
        String imageUrl = await storageRef.getDownloadURL();
        await FirebaseFirestore.instance.collection('users').doc(theID).update({'profilePic': imageUrl});
        setState(() {
          theProfile = imageUrl;
        });
        EasyLoading.showSuccess('Profile updated successfully');
      } else {
        EasyLoading.showError('Upload failed');
      }
    } catch (e) {
      EasyLoading.showError('Error: $e');
    }
  }

  Future<void> handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: Center(
            child: Text(
              'Logout Confirmation',
              style: GoogleFonts.montserrat(
                textStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
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
                    'Logout',
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
      try {
        EasyLoading.show(status: 'Logging out...');

        await FirebaseAuth.instance.signOut();

        theID = '';
        theName = '';
        theEmail = '';
        thePhone = '';
        theProfile = '';

        EasyLoading.dismiss();

        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const IntroPage()),(route)=>false);
      } catch (e) {
        EasyLoading.showError('Logout failed.');
        if (kDebugMode) {
          print('Error logging out: $e');
        }
      }
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
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'My Account',
                            style: GoogleFonts.montserrat(
                              textStyle: const TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: height * 0.02),
                        Container(
                          width: MediaQuery.of(context).size.width,
                          height: 75,
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
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
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: updateProfilePicture,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: Container(
                                      width: 46,
                                      height: 46,
                                      color: Colors.black,
                                      child: theProfile.isNotEmpty
                                          ? CustomImageWidget(
                                        imageUrl: theProfile,
                                        width: 46,
                                        height: 46,
                                        fit: BoxFit.cover,
                                        borderRadius: BorderRadius.circular(999),
                                      )
                                          : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: (){
                                      Navigator.push(context, MaterialPageRoute(builder: (context)=> UpdateProfilePage()));
                                    },
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          theName.isNotEmpty ? theName : 'Name not set',
                                          textAlign: TextAlign.center,
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
                                          theEmail,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            textStyle: TextStyle(
                                              color: Colors.black,
                                              fontSize: 10,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          thePhone.isNotEmpty ? thePhone : 'Phone not set',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            textStyle: TextStyle(
                                              color: Colors.black,
                                              fontSize: 10,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: (){
                                    Navigator.push(context, MaterialPageRoute(builder: (context)=> UpdateProfilePage()));
                                  },
                                  child: Text(
                                    'edit',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      textStyle: TextStyle(
                                        color: Color(0xFF7A64A4),
                                        fontSize: 10,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: height * 0.03),
                        buildRow('Orders'),
                        buildRow('Appointments'),
                        buildRow('Coupons'),
                        buildRow('Wishlist'),
                        buildRow('Size Details'),
                        buildRow('Address'),
                        buildRow('How To Return'),
                        buildRow('Help'),
                        buildRow('Return & Refund Policy'),
                        buildRow('Terms & Conditions'),
                        SizedBox(height: height * 0.03),
                        GestureDetector(
                          onTap: deleteAccount,
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            height: 60,
                            decoration: ShapeDecoration(
                              color: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'DELETE ACCOUNT',
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
                        const SizedBox(height: 10,),
                        GestureDetector(
                          onTap: handleLogout,
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            height: 60,
                            decoration: ShapeDecoration(
                              color: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'LOGOUT',
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
                        SizedBox(height: height * 0.02),
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
              Navigator.pop(context);
            },
            child: Icon(
              Icons.arrow_back,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          Text(
            'Profile',
            style: GoogleFonts.montserrat(
              textStyle: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: 'Manrope',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: SizedBox(width: 10),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget buildRow(String title) {
    return GestureDetector(
      onTap: () async {
        if(title == 'Wishlist') {
          Navigator.push(context, MaterialPageRoute(builder: (context)=> const WishList()));
        }
        if(title == 'Orders') {
          Navigator.push(context, MaterialPageRoute(builder: (context)=> const OrdersPage()));
        }
        if(title == 'Appointments') {
          Navigator.push(context, MaterialPageRoute(builder: (context)=> const AppointmentsPage()));
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                textStyle: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.black,
            )
          ],
        ),
      ),
    );
  }

  Future<void> deleteAccount() async {
    final passwordController = TextEditingController();
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Account', style: GoogleFonts.poppins()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want to delete your account? This action cannot be undone.',
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Enter your password to confirm',
                  hintStyle: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete', style: GoogleFonts.poppins(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      try {
        EasyLoading.show(status: 'Deleting account...');

        // Re-authenticate user
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          throw Exception('No user logged in');
        }

        String password = passwordController.text.trim();
        if (password.isEmpty) {
          EasyLoading.showError('Please enter your password');
          return;
        }

        AuthCredential credential = EmailAuthProvider.credential(
          email: currentUser.email ?? '',
          password: password,
        );

        // Re-authenticate
        await currentUser.reauthenticateWithCredential(credential);

        // Delete Firestore user document
        await FirebaseFirestore.instance.collection('users').doc(theID).delete();

        // Delete user authentication
        await currentUser.delete();

        // Sign out and navigate to intro page
        await FirebaseAuth.instance.signOut();
        EasyLoading.showSuccess('Account deleted successfully');
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const IntroPage()),
                (route) => false
        );

      } catch (e) {
        EasyLoading.showError('Account deletion failed: ${e.toString()}');
        if (kDebugMode) {
          print('Error deleting account: $e');
        }
      } finally {
        passwordController.clear();
      }
    }
  }
}