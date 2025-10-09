import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:groovyn/widgets/custom_image_widget.dart';

class ProfessionalProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap;

  const ProfessionalProductCard({
    Key? key,
    required this.product,
    required this.isFavorite,
    this.onFavoriteToggle,
    this.onTap,
  }) : super(key: key);

  @override
  State<ProfessionalProductCard> createState() => _ProfessionalProductCardState();
}

class _ProfessionalProductCardState extends State<ProfessionalProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getImageUrl() {
    if (widget.product['productImages'] != null) {
      final images = widget.product['productImages'];
      if (images is List && images.isNotEmpty) {
        return images[0]?.toString() ?? '';
      } else if (images is String && images.isNotEmpty) {
        return images;
      }
    }
    return '';
  }

  String _formatPrice() {
    final price = widget.product['productPrice'];
    if (price == null) return '0';
    
    // Clean the price string
    String priceStr = price.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    if (priceStr.isEmpty) return '0';
    
    try {
      double priceValue = double.parse(priceStr);
      if (priceValue == priceValue.toInt()) {
        return priceValue.toInt().toString();
      } else {
        return priceValue.toStringAsFixed(0);
      }
    } catch (e) {
      return priceStr;
    }
  }

  String _getOriginalPrice() {
    final currentPrice = _formatPrice();
    final priceInt = int.tryParse(currentPrice) ?? 100;
    final originalPrice = (priceInt * 4).toString(); // 75% off means original was 4x
    return originalPrice;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(0, 0, 0, 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section
                  Expanded(
                    flex: 5,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                        color: Colors.grey[50],
                      ),
                      child: Stack(
                        children: [
                          // Product Image
                          _getImageUrl().isNotEmpty
                              ? CustomImageWidget(
                                  imageUrl: _getImageUrl(),
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[100],
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.image_outlined,
                                          color: Colors.grey[400],
                                          size: 32,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'No Image',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          
                          // Favorite Button
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: widget.onFavoriteToggle,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color.fromRGBO(0, 0, 0, 0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  widget.isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: widget.isFavorite
                                      ? const Color(0xFFFF6B6B)
                                      : Colors.grey[600],
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                          
                          // Rating Badge (bottom left of image)
                          if (widget.product['rating'] != null && 
                              widget.product['rating'].toString() != '0' &&
                              widget.product['rating'].toString().isNotEmpty)
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(0, 0, 0, 0.7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Color(0xFFFFC107),
                                      size: 10,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      widget.product['rating']?.toString() ?? '',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Content Section
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Product Name
                          Text(
                            widget.product['productName']?.toString() ?? 'Product Name',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Price Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Current Price
                              Text(
                                '₹${_formatPrice()}',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                              
                              // Original Price & Discount
                              Row(
                                children: [
                                  Text(
                                    '₹${_getOriginalPrice()}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.grey[600],
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '(75% OFF)',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFFFF6B35),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}