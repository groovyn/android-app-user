import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'files/auth/login_path/splash_screen.dart';
import 'firebase_options.dart';

String theID = '';
String theName = '';
String thePhone = '';
String theEmail = '';
String theProfile = '';

List<dynamic> favoriteProductIds = [];
List<dynamic> favoriteStoreIds = [];

List<String> cartProductIDs = [];
List<String> cartProductImages = [];
List<String> cartProductNames = [];
List<String> cartProductTags = [];
List<String> cartProductSizes = [];
List<String> cartProductColors = [];
List<String> cartProductPrices = [];

List<int> cartProductQuantity = [];

int theSelectedPageID = 1;

String? savedChoice = '-1';

void main()async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
    name: 'Groovyn'
  );
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData.fromView(WidgetsBinding.instance.window).copyWith(
        textScaler: TextScaler.linear(0.8),
      ),
      child: MaterialApp(
        title: 'Groovyn',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
          useMaterial3: true,
        ),
        home: SplashScreen(),
        builder: EasyLoading.init(),
      ),
    );
  }
}