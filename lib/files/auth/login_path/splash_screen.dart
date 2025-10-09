import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:groovyn/files/auth/login_path/sign_in.dart';
import 'package:groovyn/files/user/mains/main_landing.dart';

import '../../../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _animation;

  bool isAuthenticated = false;

  @override
  void initState() {
    super.initState();

    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;

    if(user!=null){
      isAuthenticated = true;
      validateData(user);
    }

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _animation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) => isAuthenticated ? HomePage() : SignIn(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          )
        );
      }
    });
  }

  Future<void> validateData(User? user) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).get();
    var userData = userDoc.data();
    theID = user!.uid;
    theEmail = user.email ?? '';
    favoriteProductIds = userData?['favourites'] ?? [];
    favoriteStoreIds = userData?['favouriteStores'] ?? [];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double paddingHorizontal = MediaQuery.of(context).size.width > 600 ? MediaQuery.of(context).size.width * 0.22 : 20.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/img_4.png',),
            fit: BoxFit.cover,
          ),
          color: Colors.white,
        ),
        child: Center(
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: 20.0),
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10,),
                        Padding(
                          padding: EdgeInsets.only(left: 20.0, right: 20.0),
                          child: Center(
                            child: Text(
                                'Groovyn!',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  textStyle: TextStyle(
                                    color: Colors.black,
                                    fontSize: 48,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                            ),
                          ),
                        ),
                        Expanded(flex: 6, child: const SizedBox(height: 20,)),
                        AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _animation.value,
                              child: Transform.scale(
                                scale: (_animation.value / (2 * 3.14159)),
                                child: child,
                              ),
                            );
                          },
                          child: Image.asset(
                            'assets/icons/img_8.png',
                            width: 150,
                            height: 150,
                          ),
                        ),
                        Expanded(flex: 6, child: const SizedBox(height: 20,)),
                        GestureDetector(
                          onTap: (){
                            // Navigator.push(context, MaterialPageRoute(builder: (context)=> const SignIn()));
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            height: 56,
                            decoration: ShapeDecoration(
                              color: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                  'Get Started',
                                  style: GoogleFonts.poppins(
                                    textStyle: TextStyle(
                                      color: Colors.transparent,
                                      fontSize: 16,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w800,
                                    ),
                                  )
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 60,),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}