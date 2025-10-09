import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:groovyn/widgets/custom_image_widget.dart';

class PerfectProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap;

  const PerfectProductCard({
    Key? key,
    required this.product,
    required this.isFavorite,
    this.onFavoriteToggle,
    this.onTap,
  }) : super(key: key);

  @override
  State<PerfectProductCard> createState() => _PerfectProductCardState();
}

class _PerfectProductCardState extends State<PerfectProductCard> {
  String _getImageUrl() {
    if (widget.product['productImages'] != null) {
      final images = widget.product['productImages'];
      if (images is List && images.isNotEmpty) {
        String url = images[0]?.toString() ?? '';
        // Filter out placeholder URLs
        if (url.contains('placeholder.com') || url.contains('via.placeholder')) {
          return '';
        }
        return url;
      } else if (images is String && images.isNotEmpty) {
        String url = images;
        if (url.contains('placeholder.com') || url.contains('via.placeholder')) {
          return '';
        }
        return url;
      }
    }
    return '';
  }

  String _formatPrice() {
    final price = widget.product['productPrice'];
    if (price == null) return '100';
    
    String priceStr = price.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    if (priceStr.isEmpty) return '100';
    
    try {
      double priceValue = double.parse(priceStr);
      return priceValue.toInt().toString();
    } catch (e) {
      return '100';
    }
  }

  String _getOriginalPrice() {
    final currentPrice = _formatPrice();
    final priceInt = int.tryParse(currentPrice) ?? 100;
    final originalPrice = (priceInt * 3.5).round().toString(); // More realistic discount
    return originalPrice;
  }

  String _getBrandName() {
    final productName = widget.product['productName']?.toString() ?? '';
    if (productName.toLowerCase().contains('fwd') || productName.toLowerCase().contains('fashion')) {
      return 'fwd SZN';
    } else if (productName.toLowerCase().contains('funday')) {
      return 'Funday Fashion';
    } else if (productName.toLowerCase().contains('kurti')) {
      return 'Ethnic Couture';
    } else if (productName.toLowerCase().contains('western')) {
      return 'Western Trends';
    } else if (productName.toLowerCase().contains('bottom')) {
      return 'Bottom Wear Co';
    }
    return 'Fashion Hub';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _getImageUrl();
    final rating = widget.product['rating']?.toString() ?? '4.2';
    final reviewCount = '${(double.tryParse(rating) ?? 4.2) * 150}';

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image Section - Fixed height to prevent overflow
            Container(
              height: 200, // Fixed height
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                color: Colors.grey[100],
              ),
              child: Stack(
                children: [
                  // Product Image or Placeholder
                  imageUrl.isNotEmpty
                      ? CustomImageWidget(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        )
                      : _buildPlaceholder(),
                  
                  // Rating Badge (bottom left)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromRGBO(0, 0, 0, 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            rating,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 11,
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_right,
                            color: Colors.grey,
                            size: 12,
                          ),
                          const SizedBox(width: 1),
                          Text(
                            reviewCount.split('.')[0],
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Favorite Button (top right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: widget.onFavoriteToggle,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(255, 255, 255, 0.9),
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
                          widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: widget.isFavorite ? Colors.red : Colors.grey[600],
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content Section - Fixed height to prevent overflow
            Container(
              height: 100, // Fixed height
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Brand Name
                  Text(
                    _getBrandName(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Product Name
                  Text(
                    widget.product['productName']?.toString() ?? 'Product Name',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[700],
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const Spacer(),
                  
                  // Price Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '₹${_formatPrice()}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '₹${_getOriginalPrice()}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[500],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '72% OFF',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFFF905A),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 2),
                      
                      // Best Price Text
                      Text(
                        'Best Price ₹${(int.tryParse(_formatPrice()) ?? 100) - 25} with coupon',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF00CCA3),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 200,
      color: const Color(0xFFF5F5F5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              color: Colors.grey[400],
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              widget.product['productName']?.toString().split(' ').take(2).join(' ') ?? 'Fashion Item',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}