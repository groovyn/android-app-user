import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:groovyn/widgets/custom_image_widget.dart';

class RentalProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap;

  const RentalProductCard({
    super.key,
    required this.product,
    required this.isFavorite,
    this.onFavoriteToggle,
    this.onTap,
  });

  String _getImageUrl() {
    if (product['productImages'] != null) {
      final images = product['productImages'];
      if (images is List) {
        if (images.isNotEmpty) {
          String url = images[0]?.toString() ?? '';
          if (!url.contains('placeholder') && url.isNotEmpty) {
            return url;
          }
        }
      } else if (images is String && images.isNotEmpty) {
        String url = images;
        if (!url.contains('placeholder') && url.isNotEmpty) {
          return url;
        }
      }
    }
    // Return a placeholder image instead of empty string
    return 'https://via.placeholder.com/300x300.png?text=Fashion+Item';
  }

  String _formatPrice() {
    final price = product['productPrice'];
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

  String _getRating() {
    final rating = product['productRating'];
    if (rating == null) return '4.5';
    return rating.toString();
  }

  String _getOriginalPrice() {
    try {
      double price = double.parse(_formatPrice());
      double originalPrice = price * 1.25; // 25% more than current price
      return originalPrice.toInt().toString();
    } catch (e) {
      return '';
    }
  }

  String _getProductName() {
    final name = product['productName'] ?? product['name'];
    if (name == null) return '';
    return name.toString();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _getImageUrl();
    final productName = _getProductName();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 190,
        margin: const EdgeInsets.only(right: 12.0, bottom: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
              spreadRadius: 0,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: CustomImageWidget(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 220,
                      showShimmer: true,
                    ),
                  ),
                ),
                // Favorite button - top right
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onFavoriteToggle,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey.shade700,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                // Rating badge - bottom right
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: Colors.green,
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _getRating(),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Product Details
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  if (productName.isNotEmpty)
                    Text(
                      productName,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (productName.isNotEmpty) const SizedBox(height: 6),
                  // Price Section
                  Row(
                    children: [
                      Text(
                        '₹${_formatPrice()}',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      if (_getOriginalPrice().isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          '₹${_getOriginalPrice()}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.grey.shade500,
                          ),
                        ),
                      ],
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
}