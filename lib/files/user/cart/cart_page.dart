import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:groovyn/files/user/cart/shipping_address.dart';
import 'package:groovyn/main.dart';

class CartPage extends StatefulWidget{
  const CartPage({super.key});

  @override
  State<CartPage> createState() => CartPageState();
}

class CartPageState extends State<CartPage> {

  bool isLoading = false;

  @override
  void initState() {
    theSelectedPageID = 0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0, right: 20.0),
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
                          Text(
                            'CART',
                            style: GoogleFonts.roboto(
                              textStyle: TextStyle(
                                color: Colors.black,
                                fontFamily: 'Manrope',
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8,),
                          Text(
                            '${cartProductIDs.length} products',
                            style: GoogleFonts.roboto(
                              textStyle: TextStyle(
                                color: Colors.black,
                                fontFamily: 'Manrope',
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20,),
                          Container(
                            width: MediaQuery.of(context).size.width,
                            height: 50,
                            decoration: ShapeDecoration(
                              color: Color(0xFFF5F0F0),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.done,
                                    color: Colors.black,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 12,),
                                  Expanded(
                                    child: Text(
                                      'Free Exchange. Free Returns',
                                      style: GoogleFonts.poppins(
                                        textStyle: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20,),
                          SizedBox(
                            height: (220 * cartProductIDs.length).toDouble(),
                            child: ListView.builder(
                              itemCount: cartProductIDs.length,
                              itemBuilder: (context, index) {
                                return SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  height: 210,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 20.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 4,
                                          child: Column(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  decoration: ShapeDecoration(
                                                    image: DecorationImage(
                                                      image: NetworkImage(cartProductImages[index]),
                                                      fit: BoxFit.fill,
                                                    ),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 20,),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                children: [
                                                  GestureDetector(
                                                    onTap:(){
                                                      setState(() {
                                                        if(cartProductQuantity[index] - 1 !=0){
                                                          cartProductQuantity[index]--;
                                                        }
                                                        else{
                                                          cartProductIDs.removeAt(index);
                                                          cartProductImages.removeAt(index);
                                                          cartProductNames.removeAt(index);
                                                          cartProductTags.removeAt(index);
                                                          cartProductSizes.removeAt(index);
                                                          cartProductColors.removeAt(index);
                                                          cartProductPrices.removeAt(index);
                                                          cartProductQuantity.removeAt(index);
                                                        }
                                                      });
                                                    },
                                                    child: Container(
                                                      width: 35,
                                                      height: 35,
                                                      decoration: ShapeDecoration(
                                                        shape: OvalBorder(
                                                          side: BorderSide(width: 1, color: Color(0xFFD9D9D9)),
                                                        ),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          '-',
                                                          style: GoogleFonts.montserrat(
                                                            textStyle: TextStyle(
                                                              fontSize: 20,
                                                              fontWeight: FontWeight.bold,
                                                            )
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    height: 35,
                                                    decoration: ShapeDecoration(
                                                      shape: RoundedRectangleBorder(
                                                        side: BorderSide(width: 1, color: Color(0xFFD9D9D9)),
                                                        borderRadius: BorderRadius.circular(1),
                                                      ),
                                                    ),
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                                      child: Center(
                                                        child: Text(
                                                          cartProductQuantity[index].toString(),
                                                          textAlign: TextAlign.center,
                                                          style: GoogleFonts.poppins(
                                                            textStyle: TextStyle(
                                                              color: Colors.black,
                                                              fontSize: 14,
                                                              fontFamily: 'Poppins',
                                                              fontWeight: FontWeight.w700,
                                                            ),
                                                          )
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  GestureDetector(
                                                    onTap:(){
                                                      setState(() {
                                                        cartProductQuantity[index]++;
                                                      });
                                                    },
                                                    child: Container(
                                                      width: 35,
                                                      height: 35,
                                                      decoration: ShapeDecoration(
                                                        shape: OvalBorder(
                                                          side: BorderSide(width: 1, color: Color(0xFFD9D9D9)),
                                                        ),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          '+',
                                                          style: GoogleFonts.montserrat(
                                                            textStyle: TextStyle(
                                                              fontSize: 20,
                                                              fontWeight: FontWeight.bold,
                                                            )
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 20,),
                                        Expanded(
                                          flex: 5,
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                cartProductNames[index],
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
                                                cartProductTags[index],
                                                style: GoogleFonts.poppins(
                                                  textStyle: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 12,
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                "Size: ${cartProductSizes[index]}",
                                                style: GoogleFonts.poppins(
                                                  textStyle: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 12,
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                "Expected Delivery ${getThreeDaysLaterDate()}",
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
                                                "Rs. ${cartProductPrices[index]}",
                                                style: GoogleFonts.poppins(
                                                  textStyle: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 20,
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),

                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 20,),

                          Text(
                            "Add Promo Code",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    hintText: 'Enter promo code',
                                    hintStyle: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFD9CFCF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                ),
                                onPressed: () {},
                                child: Text(
                                  "Apply",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24),
                          buildSummaryRow(
                            title: "Extra 0% OFF APPLIED",
                            value: "- ₹0",
                            isHighlighted: false,
                          ),
                          SizedBox(height: 8),
                          buildSummaryRow(
                            title: "SUBTOTAL",
                            value: "₹ ${calculateTotal(cartProductPrices, cartProductQuantity)}",
                            isHighlighted: false,
                          ),
                          SizedBox(height: 8),
                          buildSummaryRow(
                            title: "SHIPPING COSTS",
                            value: "₹ 0.00",
                            isHighlighted: false,
                          ),
                          SizedBox(height: 8),
                          buildSummaryRow(
                            title: "ORDER DISCOUNT",
                            value: "-₹ 0",
                            isHighlighted: false,
                          ),
                          Divider(thickness: 1, height: 32),
                          buildSummaryRow(
                            title: "GRAND TOTAL",
                            value: "₹ ${calculateTotal(cartProductPrices, cartProductQuantity)}",
                            isHighlighted: true,
                          ),
                          SizedBox(height: 4),
                          Text(
                            "(Prices include GST)",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey,
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
        height: 80,
        child: cartProductIDs.isNotEmpty ? GestureDetector(
          onTap: (){
            if(cartProductIDs.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ShippingAddress(total: calculateTotal(cartProductPrices, cartProductQuantity).toString(),)),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              width: MediaQuery.of(context).size.width,
              decoration: ShapeDecoration(
                color: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Center(
                child: Text(
                  'CHECKOUT',
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
        ):null,
      ),
    );
  }
  Widget buildSummaryRow({required String title, required String value, bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: isHighlighted ? 16 : 14,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            color: isHighlighted ? Colors.black : Colors.grey[800],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isHighlighted ? 16 : 14,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            color: isHighlighted ? Colors.black : Colors.grey[800],
          ),
        ),
      ],
    );
  }
  String getThreeDaysLaterDate() {
    DateTime today = DateTime.now();
    DateTime threeDaysLater = today.add(Duration(days: 3));
    String formattedDate = "${threeDaysLater.day} ${getMonthName(threeDaysLater.month)}";
    return formattedDate;
  }
  String getMonthName(int month) {
    const List<String> monthNames = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return monthNames[month - 1];
  }
  double calculateTotal(List<String> cartProductPrices, List<int> cartProductQuantities) {
    double total = 0.0;
    int i = 0;
    for (var price in cartProductPrices) {
      try {
        total += double.parse(price) * (cartProductQuantities[i]).toDouble();
        i++;
      } catch (e) {
        if (kDebugMode) {
          print('Invalid price: $price');
        }
      }
    }
    return total;
  }

}

