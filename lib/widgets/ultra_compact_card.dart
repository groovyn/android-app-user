import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:groovyn/widgets/custom_image_widget.dart';

class UltraCompactCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap;

  const UltraCompactCard({
    Key? key,
    required this.product,
    required this.isFavorite,
    this.onFavoriteToggle,
    this.onTap,
  }) : super(key: key);

  String _getImageUrl() {
    if (product['productImages'] != null) {
      final images = product['productImages'];
      if (images is List && images.isNotEmpty) {
        String url = images[0]?.toString() ?? '';
        if (!url.contains('placeholder') && url.isNotEmpty) {
          return url;
        }
      } else if (images is String && images.isNotEmpty) {
        String url = images;
        if (!url.contains('placeholder') && url.isNotEmpty) {
          return url;
        }
      }
    }
    return '';
  }

  String _formatPrice() {
    final price = product['productPrice'];
    if (price == null) return '₹100';
    
    String priceStr = price.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    if (priceStr.isEmpty) return '₹100';
    
    try {
      double priceValue = double.parse(priceStr);
      return '₹${priceValue.toInt()}';
    } catch (e) {
      return '₹100';
    }
  }

  String _getOriginalPrice() {
    final currentPrice = _formatPrice().replaceAll('₹', '');
    final priceInt = int.tryParse(currentPrice) ?? 100;
    final originalPrice = (priceInt * 2.5).round();
    return '₹$originalPrice';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _getImageUrl();
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 32 - 8) / 2; // Account for padding and spacing

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        height: 280, // Fixed height to prevent overflow
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section - Fixed height
            Container(
              height: 160, // Fixed image height
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                color: Colors.grey[50],
              ),
              child: Stack(
                children: [
                  imageUrl.isNotEmpty
                      ? CustomImageWidget(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          height: 160,
                          fit: BoxFit.cover,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        )
                      : _buildPlaceholder(),
                  
                  // Favorite Button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onFavoriteToggle,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(255, 255, 255, 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromRGBO(0, 0, 0, 0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey[600],
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content Section - Fixed height with overflow protection
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Product Name - Limited lines to prevent overflow
                    Flexible(
                      flex: 2,
                      child: Text(
                        product['productName']?.toString() ?? 'Fashion Item',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Price Section - Compact layout
                    Flexible(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Current Price
                          Text(
                            _formatPrice(),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          // Original Price & Discount
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _getOriginalPrice(),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey[500],
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '60% OFF',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFFF905A),
                                ),
                              ),
                            ],
                          ),
                          
                          // Rating Badge
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(76, 175, 80, 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.green,
                                  size: 10,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '4.2',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 160,
      width: double.infinity,
      color: const Color(0xFFF8F9FA),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            color: Colors.grey[400],
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            'Fashion',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}