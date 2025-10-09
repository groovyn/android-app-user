import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:groovyn/widgets/custom_image_widget.dart';

class MyntraStyleProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap;

  const MyntraStyleProductCard({
    Key? key,
    required this.product,
    required this.isFavorite,
    this.onFavoriteToggle,
    this.onTap,
  }) : super(key: key);

  @override
  State<MyntraStyleProductCard> createState() => _MyntraStyleProductCardState();
}

class _MyntraStyleProductCardState extends State<MyntraStyleProductCard> {
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
    
    String priceStr = price.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    if (priceStr.isEmpty) return '0';
    
    try {
      double priceValue = double.parse(priceStr);
      return priceValue.toInt().toString();
    } catch (e) {
      return priceStr;
    }
  }

  String _getOriginalPrice() {
    final currentPrice = _formatPrice();
    final priceInt = int.tryParse(currentPrice) ?? 100;
    final originalPrice = (priceInt * 4).toString();
    return originalPrice;
  }

  String _getBrandName() {
    // Extract brand name from product name or use generic names
    final productName = widget.product['productName']?.toString() ?? '';
    if (productName.toLowerCase().contains('kurti')) {
      return 'Ethnic Wear';
    } else if (productName.toLowerCase().contains('western')) {
      return 'Western Wear';
    } else if (productName.toLowerCase().contains('bottom')) {
      return 'Bottom Wear';
    }
    return 'Fashion';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _getImageUrl();
    final rating = widget.product['rating']?.toString() ?? '4.5';
    final reviews = '${(double.tryParse(rating) ?? 4.5) * 400}';

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image Section
            Container(
              height: 220,
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
                  // Product Image
                  imageUrl.isNotEmpty
                      ? CustomImageWidget(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        )
                      : Container(
                          height: 220,
                          color: Colors.grey[100],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                        color: Colors.grey[400],
                                        size: 40,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Image not available',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            height: 220,
                            color: Colors.grey[100],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_outlined,
                                    color: Colors.grey[400],
                                    size: 40,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No Image',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                  
                  // Rating Badge (bottom left)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(255, 255, 255, 0.9),
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
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_right,
                            color: Colors.grey,
                            size: 12,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            reviews,
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
                          widget.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: widget.isFavorite
                              ? Colors.red
                              : Colors.grey[600],
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content Section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand Name
                  Text(
                    _getBrandName(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 2),
                  
                  // Product Name
                  Text(
                    widget.product['productName']?.toString() ?? 'Product Name',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[700],
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Price Section
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
                        '75% OFF',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFFF905A),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Best Price Text
                  Text(
                    'Best Price ₹${(int.tryParse(_formatPrice()) ?? 100) - 50} with coupon',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF00CCA3),
                    ),
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