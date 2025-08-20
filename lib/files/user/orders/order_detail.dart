import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';

class OrderDetail extends StatefulWidget {
  final String orderId;

  const OrderDetail({super.key, required this.orderId});

  @override
  State<OrderDetail> createState() => _OrderDetailState();
}

class _OrderDetailState extends State<OrderDetail> {
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
              const SizedBox(height: 16),
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('orders')
                    .doc(widget.orderId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: Text('Order not found'));
                  }

                  final orderData = snapshot.data!.data() as Map<String, dynamic>;
                  return SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order number',
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w600, fontSize: 18)),
                          Text('#${widget.orderId}',
                              style: GoogleFonts.montserrat(fontSize: 16)),
                          const SizedBox(height: 16),
                          Text('Order date',
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w600, fontSize: 18)),
                          Text(orderData['orderTime'].toDate().toLocal().toString().split(' ')[0],
                              style: GoogleFonts.montserrat(fontSize: 16)),
                          const SizedBox(height: 16),
                          Text('Your Details',
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w600, fontSize: 18)),
                          Text(orderData['fullName'],
                              style: GoogleFonts.montserrat(fontSize: 16)),
                          Text(orderData['phone'],
                              style: GoogleFonts.montserrat(fontSize: 16)),
                          const SizedBox(height: 24),
                          const Divider(thickness: 1, color: Colors.grey),
                          const SizedBox(height: 24),
                          Text('Parcel 1',
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w600, fontSize: 18)),
                          Text('${orderData['productNames'].length} item(s) from ${orderData['productNames'][0]}',
                              style: GoogleFonts.montserrat(fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('Delivery Method',
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w600, fontSize: 18)),
                          Text('${orderData['address1']}, ${orderData['address2']}, ${orderData['city']}, ${orderData['state']}, ${orderData['country']}.',
                              style: GoogleFonts.montserrat(fontSize: 16)),
                          const SizedBox(height: 24),
                          const Divider(thickness: 1, color: Colors.grey),
                          const SizedBox(height: 24),
                          _buildOrderStatus(orderData),
                          const Divider(thickness: 1, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text('Order summary ${orderData['productNames'].length} Item(s)',
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w600, fontSize: 18)),
                          const SizedBox(height: 12),
                          ...List.generate(orderData['productNames'].length, (index) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Image.network(
                                      orderData['images'][index],
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            orderData['productNames'][index],
                                            style: GoogleFonts.montserrat(
                                                fontWeight: FontWeight.w600, fontSize: 14),
                                          ),
                                          Text('Rs. ${orderData['prices'][index]}',
                                              style: GoogleFonts.montserrat(fontSize: 14)),
                                          Text('Quantity: ${orderData['quantities'][index]}',
                                              style: GoogleFonts.montserrat(fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                            );
                          }),
                          const Divider(thickness: 1, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text('Total: Rs. ${orderData['total']}',
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w600, fontSize: 16)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              EasyLoading.showInfo('Feature not available for these product(s) !');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              'Return an item',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderStatus(Map<String, dynamic> orderData) {
    final steps = ['Order Received', 'Processed', 'Dispatched', 'Delivered', 'Cancelled'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps.asMap().entries.map((entry) {
        final stepIndex = entry.key + 1;
        final stepName = entry.value;

        String checkIDx = '';

        if(stepName == 'Order Received'){
          checkIDx = 'orderTime';
        }
        else if(stepName == 'Processed'){
          checkIDx = 'processedTime';
        }
        else if(stepName == 'Dispatched'){
          checkIDx = 'dispatchedTime';
        }
        else if(stepName == 'Delivered'){
          checkIDx = 'deliveredTime';
        }
        else if(stepName == 'Cancelled'){
          checkIDx = 'cancelledTime';
        }


        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$stepIndex - $stepName',
              style: GoogleFonts.montserrat(
                fontWeight:
                formatDate(orderData[checkIDx]) != '01/01/1970' ? FontWeight.bold : FontWeight.w400,
                fontSize: 18,
              ),
            ),
            if(formatDate(orderData[checkIDx]) != '01/01/1970' )
              Text(
                '       ${formatDate(orderData[checkIDx])}',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
              ),

            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  String formatDate(Timestamp timestamp) {
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch);
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    return '$day/$month/$year';
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
          Spacer(),
          Text(
            'Orders',
            style: GoogleFonts.montserrat(
              textStyle: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Spacer(),
        ],
      ),
    );
  }
}