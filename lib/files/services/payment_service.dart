import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class PaymentService {
  // Cashfree API Configuration
  static const String _baseUrl = 'https://sandbox.cashfree.com/pg'; // Use production URL for live
  static const String _appId = 'YOUR_CASHFREE_APP_ID'; // Replace with actual App ID
  static const String _secretKey = 'YOUR_CASHFREE_SECRET_KEY'; // Replace with actual Secret Key

  // Initialize payment for appointment advance
  static Future<void> initiatePayment({
    required BuildContext context,
    required String appointmentId,
    required String userId,
    required double amount,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String serviceName,
  }) async {
    try {
      EasyLoading.show(status: 'Initiating payment...');

      // Create order ID
      String orderId = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';

      // Create payment session
      final sessionResponse = await _createPaymentSession(
        orderId: orderId,
        amount: amount,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
      );

      if (sessionResponse != null && sessionResponse['payment_session_id'] != null) {
        String sessionId = sessionResponse['payment_session_id'];

        // Store payment info in Firestore
        await FirebaseFirestore.instance.collection('payments').doc(orderId).set({
          'appointmentId': appointmentId,
          'userId': userId,
          'orderId': orderId,
          'sessionId': sessionId,
          'amount': amount,
          'serviceName': serviceName,
          'status': 'initiated',
          'timestamp': FieldValue.serverTimestamp(),
        });

        EasyLoading.dismiss();

        // Show payment options dialog
        _showPaymentOptionsDialog(
          context: context,
          sessionId: sessionId,
          orderId: orderId,
          appointmentId: appointmentId,
          amount: amount,
        );

      } else {
        EasyLoading.showError('Failed to create payment session');
      }
    } catch (e) {
      EasyLoading.showError('Payment initialization failed: $e');
      debugPrint('Payment error: $e');
    }
  }

  // Create Cashfree payment session
  static Future<Map<String, dynamic>?> _createPaymentSession({
    required String orderId,
    required double amount,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/orders');

      final headers = {
        'Content-Type': 'application/json',
        'x-api-version': '2023-08-01',
        'x-client-id': _appId,
        'x-client-secret': _secretKey,
      };

      final body = jsonEncode({
        'order_id': orderId,
        'order_amount': amount,
        'order_currency': 'INR',
        'customer_details': {
          'customer_id': 'USER_${DateTime.now().millisecondsSinceEpoch}',
          'customer_name': customerName,
          'customer_email': customerEmail,
          'customer_phone': customerPhone,
        },
        'order_meta': {
          'return_url': 'https://yourwebsite.com/payment/return',
          'notify_url': 'https://yourwebsite.com/payment/webhook',
        },
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Payment session error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Session creation error: $e');
      return null;
    }
  }

  // Show payment options dialog
  static void _showPaymentOptionsDialog({
    required BuildContext context,
    required String sessionId,
    required String orderId,
    required String appointmentId,
    required double amount,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Select Payment Method',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Amount: ₹${amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 20),

              // UPI Payment
              _buildPaymentOption(
                icon: Icons.account_balance_wallet,
                title: 'UPI',
                subtitle: 'Pay using UPI apps',
                onTap: () {
                  Navigator.pop(context);
                  _processUPIPayment(context, sessionId, orderId, appointmentId, amount);
                },
              ),

              // Card Payment
              _buildPaymentOption(
                icon: Icons.credit_card,
                title: 'Credit/Debit Card',
                subtitle: 'Pay using your card',
                onTap: () {
                  Navigator.pop(context);
                  _processCardPayment(context, sessionId, orderId, appointmentId);
                },
              ),

              // Net Banking
              _buildPaymentOption(
                icon: Icons.account_balance,
                title: 'Net Banking',
                subtitle: 'Pay through your bank',
                onTap: () {
                  Navigator.pop(context);
                  _processNetBankingPayment(context, sessionId, orderId, appointmentId);
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Build payment option widget
  static Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // Process UPI Payment
  static Future<void> _processUPIPayment(
    BuildContext context,
    String sessionId,
    String orderId,
    String appointmentId,
    double amount,
  ) async {
    try {
      // In production, integrate with Cashfree SDK
      // For now, simulate payment success
      await Future.delayed(const Duration(seconds: 2));

      await _handlePaymentSuccess(appointmentId, orderId, amount);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Process Card Payment
  static Future<void> _processCardPayment(
    BuildContext context,
    String sessionId,
    String orderId,
    String appointmentId,
  ) async {
    // In production, integrate with Cashfree SDK for card payments
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Card payment integration pending'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Process Net Banking Payment
  static Future<void> _processNetBankingPayment(
    BuildContext context,
    String sessionId,
    String orderId,
    String appointmentId,
  ) async {
    // In production, integrate with Cashfree SDK for net banking
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Net banking integration pending'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Handle successful payment
  static Future<void> _handlePaymentSuccess(
    String appointmentId,
    String orderId,
    double amount,
  ) async {
    // Update payment status in Firestore
    await FirebaseFirestore.instance.collection('payments').doc(orderId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });

    // Update appointment payment status
    await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).update({
      'paymentStatus': 'paid',
      'advancePaid': amount,
      'paymentOrderId': orderId,
    });
  }

  // Verify payment status
  static Future<bool> verifyPaymentStatus(String orderId) async {
    try {
      final url = Uri.parse('$_baseUrl/orders/$orderId');

      final headers = {
        'x-api-version': '2023-08-01',
        'x-client-id': _appId,
        'x-client-secret': _secretKey,
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['order_status'] == 'PAID';
      }
      return false;
    } catch (e) {
      debugPrint('Payment verification error: $e');
      return false;
    }
  }

  // Process refund
  static Future<bool> processRefund({
    required String orderId,
    required double amount,
    required String reason,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/orders/$orderId/refunds');

      final headers = {
        'Content-Type': 'application/json',
        'x-api-version': '2023-08-01',
        'x-client-id': _appId,
        'x-client-secret': _secretKey,
      };

      final body = jsonEncode({
        'refund_amount': amount,
        'refund_id': 'REFUND_${DateTime.now().millisecondsSinceEpoch}',
        'refund_note': reason,
      });

      final response = await http.post(url, headers: headers, body: body);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Refund error: $e');
      return false;
    }
  }
}