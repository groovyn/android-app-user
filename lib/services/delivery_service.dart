import 'dart:convert';
import 'package:http/http.dart' as http;

class DeliveryService {
  // Delivery time estimation based on pincode patterns (Indian postal system)
  static final Map<String, DeliveryInfo> _deliveryData = {
    // Metro cities - faster delivery
    '1': DeliveryInfo(days: 1, label: 'Express delivery', isPremium: true), // Delhi, NCR
    '2': DeliveryInfo(days: 1, label: 'Express delivery', isPremium: true), // Gurgaon, Noida, Haryana
    '3': DeliveryInfo(days: 2, label: 'Fast delivery', isPremium: false), // Rajasthan
    '4': DeliveryInfo(days: 1, label: 'Express delivery', isPremium: true), // Mumbai, Maharashtra
    '5': DeliveryInfo(days: 2, label: 'Fast delivery', isPremium: false), // Pune, Maharashtra, Goa
    '6': DeliveryInfo(days: 1, label: 'Express delivery', isPremium: true), // Bengaluru, Karnataka
    '7': DeliveryInfo(days: 2, label: 'Standard delivery', isPremium: false), // Hyderabad, Andhra Pradesh
    '8': DeliveryInfo(days: 2, label: 'Standard delivery', isPremium: false), // Chennai, Tamil Nadu
    '9': DeliveryInfo(days: 3, label: 'Standard delivery', isPremium: false), // Other areas
    // Default for other patterns
    'default': DeliveryInfo(days: 4, label: 'Standard delivery', isPremium: false),
  };

  static Future<DeliveryEstimate?> getDeliveryEstimate(String pincode) async {
    if (pincode.length != 6) return null;
    
    try {
      // First validate pincode using postal API
      final isValid = await _validatePincode(pincode);
      if (!isValid) return null;

      // Get delivery info based on first digit
      final firstDigit = pincode[0];
      final deliveryInfo = _deliveryData[firstDigit] ?? _deliveryData['default']!;
      
      final estimatedDate = DateTime.now().add(Duration(days: deliveryInfo.days));
      
      return DeliveryEstimate(
        isServiceable: true,
        estimatedDays: deliveryInfo.days,
        estimatedDate: estimatedDate,
        deliveryType: deliveryInfo.label,
        isPremiumArea: deliveryInfo.isPremium,
        charges: deliveryInfo.isPremium ? 0 : (deliveryInfo.days > 2 ? 60 : 40),
      );
    } catch (e) {
      return null;
    }
  }

  static Future<bool> _validatePincode(String pincode) async {
    try {
      final response = await http.get(
        Uri.parse("https://api.postalpincode.in/pincode/$pincode"),
      ).timeout(Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data.isNotEmpty && 
               data[0]['Status'] == 'Success' && 
               data[0]['PostOffice'] != null;
      }
    } catch (e) {
      // If API fails, assume valid for metro city patterns and common regions
      return ['1', '2', '3', '4', '5', '6', '7', '8', '9'].contains(pincode[0]);
    }
    return false;
  }

  static String formatDeliveryDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }
}

class DeliveryInfo {
  final int days;
  final String label;
  final bool isPremium;

  DeliveryInfo({
    required this.days,
    required this.label,
    required this.isPremium,
  });
}

class DeliveryEstimate {
  final bool isServiceable;
  final int estimatedDays;
  final DateTime estimatedDate;
  final String deliveryType;
  final bool isPremiumArea;
  final double charges;

  DeliveryEstimate({
    required this.isServiceable,
    required this.estimatedDays,
    required this.estimatedDate,
    required this.deliveryType,
    required this.isPremiumArea,
    required this.charges,
  });

  String get deliveryText {
    if (estimatedDays == 1) {
      return 'Delivered by tomorrow';
    } else if (estimatedDays <= 3) {
      return 'Delivered in $estimatedDays days';
    } else {
      return 'Delivered in $estimatedDays-${estimatedDays + 1} days';
    }
  }

  String get formattedDate => DeliveryService.formatDeliveryDate(estimatedDate);
}