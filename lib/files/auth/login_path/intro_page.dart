import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:groovyn/files/auth/login_path/sign_in.dart';

class IntroPage extends StatefulWidget{
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => IntroPageState();
}

class IntroPageState extends State<IntroPage> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double paddingHorizontal = MediaQuery.of(context).size.width > 600 ? MediaQuery.of(context).size.width * 0.22 : 20.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/img_4.png',),
            fit: BoxFit.cover,
          ),
          color: Colors.white,
        ),
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
                      Image.asset(
                        'assets/icons/img_8.png',
                        width: 150,
                        height: 150,
                      ),
                      Expanded(flex: 6, child: const SizedBox(height: 20,)),
                      GestureDetector(
                        onTap: (){
                          Navigator.push(context, MaterialPageRoute(builder: (context)=> const SignIn()));
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          height: 56,
                          decoration: ShapeDecoration(
                            color: const Color.fromRGBO(0, 0, 0, 0.8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Get Started',
                              style: GoogleFonts.poppins(
                                textStyle: TextStyle(
                                  color: Color(0xFFE5E5E5),
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
    );
  }
}