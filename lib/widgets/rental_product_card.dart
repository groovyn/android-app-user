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

  @override
  Widget build(BuildContext context) {
    final imageUrl = _getImageUrl();
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width / 2) - 20,
        margin: const EdgeInsets.only(right: 8.0, bottom: 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image Section - Fixed height to prevent overflow
            Container(
              height: 180,
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: CustomImageWidget(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  showShimmer: true,
                ),
              ),
            ),
            // Content Section - Flexible height
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product name and favorite icon
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product['productName']?.toString() ?? 'Fashion Item',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: onFavoriteToggle,
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey.shade400,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Description
                  Text(
                    product['productDescription']?.toString() ?? 'Beautiful fashion item',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade600,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Price and rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '₹${_formatPrice()}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.green.shade600,
                              size: 10,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _getRating(),
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
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
}