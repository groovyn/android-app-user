import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:groovyn/main.dart';
import 'package:intl/intl.dart';
import '../../user/mains/main_landing.dart';
import 'intro_page.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => SignInState();
}

class SignInState extends State<SignIn> {

  final List<TextEditingController> editControllers = List.generate(6, (index) => TextEditingController());

  final phoneController = TextEditingController(text: '');
  final otpController = TextEditingController();

  String verificationId = '';

  bool otpSent = false;

  @override
  Widget build(BuildContext context) {
    double paddingHorizontal = MediaQuery.of(context).size.width > 600
        ? MediaQuery.of(context).size.width * 0.22
        : 20.0;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Center(
        child: Container(
          height: height,
          color: Colors.white,
          child: !otpSent ?
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/img_7.png',
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.width,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 20,
                    child: SafeArea(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: (){
                                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const IntroPage()),(route)=>false);
                                },
                                child: Icon(
                                  Icons.arrow_back_outlined,
                                  color: Color.fromRGBO(117, 104, 99, 1),
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomePage()),(route)=>false);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                                  decoration: ShapeDecoration(
                                    color: Colors.white.withOpacity(0.5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                  ),
                                  child: Text(
                                    'skip',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      textStyle: TextStyle(
                                        color: Colors.black.withOpacity(0.5),
                                        fontSize: 20,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  const SizedBox(width: 20,),
                  Expanded(
                    child: Container(
                      width: 114,
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 1,
                            strokeAlign: BorderSide.strokeAlignCenter,
                            color: Color(0xFFC0C0C0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12,),
                  Text(
                    'Join / Sign in.',
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12,),
                  Expanded(
                    child: Container(
                      width: 114,
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 1,
                            strokeAlign: BorderSide.strokeAlignCenter,
                            color: Color(0xFFC0C0C0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20,),
                ],
              ),
              Expanded(flex: 1, child: SizedBox(height: 20)),

              Row(
                children: [
                  const SizedBox(width: 20,),
                  Image.asset('assets/icons/img_9.png', width: 60, height: 50,),
                  const SizedBox(width: 12,),
                  Expanded(child: _buildTextField('Enter Phone Number...', phoneController)),
                  const SizedBox(width: 20,),
                ],
              ),
              Expanded(flex: 1, child: SizedBox(height: 20)),


              SizedBox(height: 20),
              GestureDetector(
                onTap: otpSent ? verifyOTP : sendOTP,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: 43,
                    decoration: ShapeDecoration(
                      color: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Continue',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          textStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.48,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(flex: 2, child: SizedBox(height: 20)),

              Row(
                children: [
                  const SizedBox(width: 20,),
                  Expanded(
                    child: Container(
                      width: 114,
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 1,
                            strokeAlign: BorderSide.strokeAlignCenter,
                            color: Color(0xFFC0C0C0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12,),
                  Text(
                    'or',
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12,),
                  Expanded(
                    child: Container(
                      width: 114,
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 1,
                            strokeAlign: BorderSide.strokeAlignCenter,
                            color: Color(0xFFC0C0C0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20,),
                ],
              ),

              Expanded(flex: 3, child: SizedBox(height: 20)),
              GestureDetector(
                onTap: (){
                  EasyLoading.showInfo('This method is not allowed in your environment');
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: OvalBorder(
                          side: BorderSide(width: 0.50, color: Color(0x1912121D)),
                        ),
                      ),
                      child: Image.asset('assets/icons/google.png'),
                    )
                  ],
                ),
              ),
              Expanded(flex: 3, child: SizedBox(height: 20)),

              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'By Continuing, I agree to Groovyn’s ',
                      style: GoogleFonts.poppins(
                        textStyle: TextStyle(
                          color: Color(0xFF605959),
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: GoogleFonts.poppins(
                        textStyle: TextStyle(
                          color: Color(0xFF605959),
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    TextSpan(
                      text: ' & ',
                      style: GoogleFonts.poppins(
                        textStyle: TextStyle(
                          color: Color(0xFF605959),
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    TextSpan(
                      text: 'Terms',
                      style: GoogleFonts.poppins(
                        textStyle: TextStyle(
                          color: Color(0xFF605959),
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],
          )
          : Padding(
            padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: 20.0),
            child: Column(
              children: [
                SafeArea(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: (){
                              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const IntroPage()),(route)=>false);
                            },
                            child: Icon(
                              Icons.arrow_back_outlined,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'OTP Verification',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              textStyle: GoogleFonts.poppins(
                                textStyle: TextStyle(
                                  color: Colors.black,
                                  fontSize: 25,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(child: SizedBox(width: 1,)),
                      ],
                    ),
                  ),
                ),
                Expanded(flex: 1, child: SizedBox(height: 20)),
                Text(
                  'We have sent a verification code to\n${phoneController.text}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildOtpTextField(0),
                    _buildOtpTextField(1),
                    _buildOtpTextField(2),
                    _buildOtpTextField(3),
                    _buildOtpTextField(4),
                    _buildOtpTextField(5),
                  ],
                ),
                SizedBox(height: 15),
                Text(
                  'Didn\'t get OTP? Edit phone number here',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                Expanded(flex: 10, child: SizedBox(height: 20)),
                GestureDetector(
                  onTap: (){
                    setState(() {
                      otpSent = false;
                    });
                  },
                  child: Text(
                    'Go back to login methods',
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20,),
                GestureDetector(
                  onTap: otpSent ? verifyOTP : sendOTP,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.6,
                      height: 43,
                      decoration: ShapeDecoration(
                        color: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Continue',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.48,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(flex: 2, child: SizedBox(height: 20)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hintText, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      onTapOutside: (event) {
        FocusScope.of(context).unfocus();
      },
      decoration: InputDecoration(
        hintText: hintText,
        prefixText: '+91 ',
        prefixStyle: GoogleFonts.montserrat(
          textStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        border: OutlineInputBorder(),
      ),
      style: GoogleFonts.montserrat(
        textStyle: TextStyle(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildOtpTextField(int value) {
    return Container(
      width: 50,
      height: 50,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1.23, color: Color(0xFF3A3E48)),
          borderRadius: BorderRadius.circular(13),
        ),
      ),
      child: Center(
        child: TextField(
          maxLength: 1,
          cursorColor: Colors.transparent,
          cursorHeight: 0,
          controller: editControllers[value],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          onChanged: (val) {
            bool check = true;
            for (int i = 0; i < editControllers.length; i++) {
              if (editControllers[i].text.isNotEmpty) {

              } else {
                check = false;
              }
            }
            if(check){
              String code = '';
              for (int i = 0; i < editControllers.length; i++) {
                code += editControllers[i].text;
              }
              otpController.text = code;
            }
            setState(() {

            });
            if (value != 5) {
              FocusScope.of(context).nextFocus();
            }
            else{
              verifyOTP();
            }
          },
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
          ),
          style: const TextStyle(
            color: Color(0xFF242833),
            fontSize: 36,
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w600,
            //height: 0.04,
          ),
        ),
      ),
    );
  }

  void sendOTP() async {
    String phone = phoneController.text.trim();
    
    // Handle different phone number formats
    if (!phone.startsWith('+')) {
      if (phone.startsWith('91')) {
        phone = '+$phone';
      } else if (phone.startsWith('92')) {
        phone = '+$phone';
      } else {
        phone = '+91$phone';
      }
    }

    // Validate phone number format
    if (!RegExp(r'^\+91\d{10}$|^\+92\d{10}$').hasMatch(phone)) {
      EasyLoading.showError('Enter a valid phone number');
      return;
    }

    if (kDebugMode) {
      print('Sending OTP to: $phone');
    }

    EasyLoading.show(status: 'Sending OTP...');
    
    try {
      // For development/testing, we can bypass Firebase Auth temporarily
      if (kDebugMode && (phone == '+919876543210' || phone == '+911234567890')) {
        EasyLoading.dismiss();
        setState(() {
          verificationId = 'test_verification_id';
          otpSent = true;
        });
        EasyLoading.showSuccess('Test OTP sent (use 123456)');
        return;
      }

      // Production note: Ensure the following are configured:
      // 1. Firebase project has correct SHA-1/SHA-256 fingerprints
      // 2. Phone Authentication is enabled in Firebase Console
      // 3. App verification is properly set up for production

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 120),
        forceResendingToken: null,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            if (kDebugMode) {
              print('Auto verification completed');
            }
            EasyLoading.dismiss();
            UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
            theID = userCredential.user!.uid;
            await _createUserDocument(userCredential.user!.uid, phone);
            EasyLoading.showSuccess('Login successful');
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            }
          } catch (e) {
            if (kDebugMode) {
              print('Auto verification error: $e');
            }
            EasyLoading.showError('Auto-verification failed');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          EasyLoading.dismiss();
          String errorMessage = 'Failed to send OTP';
          
          if (kDebugMode) {
            print('Verification failed: ${e.code} - ${e.message}');
          }
          
          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = 'Invalid phone number format';
              break;
            case 'too-many-requests':
              errorMessage = 'Too many requests. Please try again after some time';
              break;
            case 'quota-exceeded':
              errorMessage = 'SMS quota exceeded. Please contact support';
              break;
            case 'app-not-authorized':
              errorMessage = 'App not authorized for SMS verification';
              break;
            case 'network-request-failed':
              errorMessage = 'Network error. Please check your connection';
              break;
            default:
              errorMessage = e.message ?? 'Verification failed. Please try again';
          }
          EasyLoading.showError(errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          if (kDebugMode) {
            print('Code sent successfully. Verification ID: $verificationId');
          }
          EasyLoading.dismiss();
          setState(() {
            this.verificationId = verificationId;
            otpSent = true;
          });
          EasyLoading.showSuccess('OTP sent to $phone');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (kDebugMode) {
            print('Code auto-retrieval timeout: $verificationId');
          }
          setState(() {
            this.verificationId = verificationId;
          });
        },
      );
    } catch (e) {
      EasyLoading.dismiss();
      if (kDebugMode) {
        print('Send OTP error: $e');
      }
      EasyLoading.showError('Unable to send OTP. Please check your network connection');
    }
  }

  void verifyOTP() async {
    String otp = otpController.text.trim();

    if (otp.isEmpty || otp.length != 6) {
      EasyLoading.showError('Please enter a valid 6-digit OTP');
      return;
    }

    // Handle test OTP
    if (kDebugMode && verificationId == 'test_verification_id' && otp == '123456') {
      EasyLoading.show(status: 'Verifying OTP...');
      await Future.delayed(Duration(seconds: 1));
      EasyLoading.dismiss();
      EasyLoading.showSuccess('Test login successful');
      theID = 'test_user_id';
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
      return;
    }

    if (verificationId.isEmpty) {
      EasyLoading.showError('Verification ID not found. Please resend OTP');
      return;
    }

    EasyLoading.show(status: 'Verifying OTP...');
    
    try {
      if (kDebugMode) {
        print('Verifying OTP: $otp with verification ID: $verificationId');
      }
      
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final userId = userCredential.user?.uid;
      theID = userId!;
      
      String phone = phoneController.text.trim();
      if (!phone.startsWith('+')) {
        phone = '+91$phone';
      }
      
      await _createUserDocument(userId, phone);
      
      EasyLoading.dismiss();
      EasyLoading.showSuccess('Login successful');
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      EasyLoading.dismiss();
      String errorMessage = 'Failed to verify OTP';
      
      if (kDebugMode) {
        print('OTP verification failed: ${e.code} - ${e.message}');
      }
      
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'Invalid OTP. Please check and try again';
          break;
        case 'session-expired':
          errorMessage = 'OTP expired. Please resend OTP';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Please try again later';
          break;
        default:
          errorMessage = e.message ?? 'OTP verification failed';
      }
      EasyLoading.showError(errorMessage);
    } catch (e) {
      EasyLoading.dismiss();
      if (kDebugMode) {
        print('OTP verification error: $e');
      }
      EasyLoading.showError('Verification failed. Please try again');
    }
  }

  Future<void> _createUserDocument(String userId, String phone) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        String joinDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'phone': phone,
          'name': '',
          'joinDate': joinDate,
          'status': "0",
          'email': '',
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating user document: $e');
      }
    }
  }
}