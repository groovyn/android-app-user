import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class FashionRefreshHeader extends StatelessWidget {
  final String? customText;
  const FashionRefreshHeader({Key? key, this.customText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomHeader(
      builder: (context, mode) {
        Widget child;
        if (mode == RefreshStatus.idle) {
          child = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_laundry_service, color: Colors.grey[400], size: 20),
              Text(customText ?? "Pull for fresh styles", 
                   style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[500])),
            ],
          );
        } else if (mode == RefreshStatus.refreshing) {
          child = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder(
                duration: Duration(seconds: 2),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, double value, child) {
                  return Transform.rotate(
                    angle: value * 2 * 3.14159,
                    child: Icon(Icons.style, color: Colors.black87, size: 24),
                  );
                },
              ),
              SizedBox(height: 4),
              Text("Updating styles...", 
                   style: GoogleFonts.montserrat(fontSize: 10, color: Colors.black87)),
            ],
          );
        } else if (mode == RefreshStatus.completed) {
          child = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.checkroom, color: Colors.green, size: 20),
              Text("Fresh styles loaded!", 
                   style: GoogleFonts.montserrat(fontSize: 10, color: Colors.green)),
            ],
          );
        } else {
          child = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_bag_outlined, color: Colors.grey[600], size: 20),
              Text("Loading styles...", 
                   style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[600])),
            ],
          );
        }
        
        return Container(
          height: 70,
          child: Center(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: child,
            ),
          ),
        );
      },
    );
  }
}