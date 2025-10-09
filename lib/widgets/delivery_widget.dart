import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:groovyn/services/delivery_service.dart';

class DeliveryEstimationWidget extends StatefulWidget {
  final Function(String) onPincodeChanged;
  final TextEditingController pincodeController;

  const DeliveryEstimationWidget({
    Key? key,
    required this.onPincodeChanged,
    required this.pincodeController,
  }) : super(key: key);

  @override
  State<DeliveryEstimationWidget> createState() => _DeliveryEstimationWidgetState();
}

class _DeliveryEstimationWidgetState extends State<DeliveryEstimationWidget>
    with TickerProviderStateMixin {
  DeliveryEstimate? _deliveryEstimate;
  bool _isCheckingDelivery = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    widget.pincodeController.addListener(_onPincodeChanged);
  }

  @override
  void dispose() {
    widget.pincodeController.removeListener(_onPincodeChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onPincodeChanged() {
    final pincode = widget.pincodeController.text.trim();
    widget.onPincodeChanged(pincode);
    
    if (pincode.length == 6) {
      _checkDelivery(pincode);
    } else {
      setState(() {
        _deliveryEstimate = null;
        _errorMessage = null;
      });
      _animationController.reverse();
    }
  }

  Future<void> _checkDelivery(String pincode) async {
    setState(() {
      _isCheckingDelivery = true;
      _errorMessage = null;
    });

    try {
      final estimate = await DeliveryService.getDeliveryEstimate(pincode);
      
      setState(() {
        _deliveryEstimate = estimate;
        _isCheckingDelivery = false;
        if (estimate == null) {
          _errorMessage = "Sorry, we don't deliver to this pincode yet";
        }
      });

      if (estimate != null) {
        _animationController.forward();
      }
    } catch (e) {
      setState(() {
        _isCheckingDelivery = false;
        _errorMessage = "Unable to check delivery. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _errorMessage != null ? Colors.red.shade300 : Colors.grey.shade300,
              width: 1.5,
            ),
            color: Colors.white,
          ),
          child: TextFormField(
            controller: widget.pincodeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'Pincode',
              hintText: 'Enter delivery pincode',
              prefixIcon: Icon(
                Icons.location_on_outlined,
                color: Colors.grey.shade600,
              ),
              suffixIcon: _isCheckingDelivery
                  ? Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      ),
                    )
                  : _deliveryEstimate != null
                      ? Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        )
                      : null,
              border: InputBorder.none,
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              labelStyle: GoogleFonts.montserrat(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
              hintStyle: GoogleFonts.montserrat(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter pincode';
              }
              if (value.length != 6) {
                return 'Please enter valid 6-digit pincode';
              }
              return null;
            },
          ),
        ),
        
        // Error message
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red.shade600,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.montserrat(
                      color: Colors.red.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Delivery estimation
        if (_deliveryEstimate != null && _deliveryEstimate!.isServiceable)
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _deliveryEstimate!.isPremiumArea
                        ? [Colors.green.shade50, Colors.green.shade100]
                        : [Colors.blue.shade50, Colors.blue.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _deliveryEstimate!.isPremiumArea
                        ? Colors.green.shade200
                        : Colors.blue.shade200,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _deliveryEstimate!.isPremiumArea
                                ? Colors.green.shade600
                                : Colors.blue.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _deliveryEstimate!.isPremiumArea
                                ? Icons.local_shipping
                                : Icons.delivery_dining,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _deliveryEstimate!.deliveryText,
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Expected by ${_deliveryEstimate!.formattedDate}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_deliveryEstimate!.isPremiumArea)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'FREE',
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _deliveryEstimate!.charges == 0
                                ? 'Free delivery to your location'
                                : 'Delivery charges: ₹${_deliveryEstimate!.charges.toInt()}',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}