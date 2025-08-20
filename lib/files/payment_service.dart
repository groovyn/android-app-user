import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<String?> createOrder(String orderID, double amount, String customerID, String customerName, String orderNotes) async {
  const String url = 'https://sandbox.cashfree.com/pg/orders';
  const Map<String, String> headers = {
    'x-client-id': 'TEST430329ae80e0f32e41a393d78b923034',
    'x-client-secret': 'TESTaf195616268bd6202eeb3bf8dc458956e7192a85',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'x-api-version': '2023-08-01',
  };

  Map<String, dynamic> body = {
    "order_amount": amount,
    "order_currency": "INR",
    "order_id": orderID,
    "customer_details": {
      "customer_id": customerID,
      "customer_phone": "8474090589",
      "customer_name": customerName,
      "customer_email": "test@cashfree.com"
    },
    "order_meta": {
      "return_url": "https://www.cashfree.com/devstudio/preview/pg/mobile/hybrid?order_id={$orderID}"
    },
    "order_note": orderNotes,
  };

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return responseData['payment_session_id'];
    } else {
      if (kDebugMode) {
        print('Error: ${response.statusCode} - ${response.body}');
      }
      return null;
    }
  } catch (e) {
    if (kDebugMode) {
      print('Exception: $e');
    }
    return null;
  }
}

CFSession? createSession(String orderID, String paymentSessionID) {
  try {
    var session = CFSessionBuilder()
        .setEnvironment(CFEnvironment.SANDBOX)
        .setOrderId(orderID)
        .setPaymentSessionId(paymentSessionID)
        .build();
    return session;
  } on CFException catch (e) {
    if (kDebugMode) {
      print(e.message);
    }
  }
  return null;
}

Future<bool> webCheckout(String orderID, String paymentSessionID) {
  // Create a completer to handle the asynchronous verification
  Completer<bool> paymentCompleter = Completer<bool>();

  try {
    var session = createSession(orderID, paymentSessionID);
    if (session == null) {
      if (kDebugMode) {
        print('Failed to create session.');
      }
      paymentCompleter.complete(false);
      return paymentCompleter.future;
    }

    // Build the payment
    var cfWebCheckout = CFWebCheckoutPaymentBuilder().setSession(session);
    var cFBuild = cfWebCheckout.build();

    // Set callbacks with the completer
    CFPaymentGatewayService().setCallback(
      // Modified to match the expected signature
          (verifiedOrderId) => onVerify(paymentCompleter, verifiedOrderId),
      // Modified to match the expected signature
          (errorResponse, verifiedOrderId) => onError(paymentCompleter, errorResponse, verifiedOrderId),
    );

    CFPaymentGatewayService().doPayment(cFBuild);

  } on CFException catch (e) {
    EasyLoading.showError(e.message);
    paymentCompleter.complete(false);
  }

  return paymentCompleter.future;
}

// Modified to accept the orderId parameter
void onVerify(Completer<bool> completer, String orderId) {
  // Perform any additional verification logic here if needed
  // For example, you might want to verify the payment status via an API call
  completer.complete(true);
}

// Signature modified to match the expected callback
void onError(Completer<bool> completer, CFErrorResponse errorResponse, String orderId) {
  // Show error message
  EasyLoading.showError(errorResponse.getMessage() ?? 'Payment Failed');
  completer.complete(false);
}