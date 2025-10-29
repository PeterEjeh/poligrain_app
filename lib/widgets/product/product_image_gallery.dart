import 'package:flutter/material.dart';
import 'enhanced_image_gallery.dart';

class ProductImageGallery extends StatefulWidget {
  final List<String> productImages;
  final String? productName;
  final double height;
  final bool showProductInfo;
  final VoidCallback? onSharePressed;
  final VoidCallback? onFavoritePressed;
  final bool isFavorite;

  const ProductImageGallery({
    Key? key,
    required this.productImages,
    this.productName,
    this.height = 300,
    this.showProductInfo = true,
    this.onSharePressed,
    this.onFavoritePressed,
    this.isFavorite = false,
  }) : super(key: key);

  @override
  State<ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<ProductImageGallery>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
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

  void _onImageChanged(int index) {
    setState(() {
      _currentImageIndex = index;
    });
  }

  void _onFavoritePressed() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    widget.onFavoritePressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image gallery with overlay controls
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: EnhancedImageGallery(
                  imageUrls: widget.productImages,
                  height: widget.height,
                  showThumbnails: true,
                  enableZoom: true,
                  enableFullscreen: true,
                  onImageChanged: _onImageChanged,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
              ),
              
              // Top overlay controls
              Positioned(
                top: 12,
                right: 12,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Share button
                    if (widget.onSharePressed != null)
                      _buildControlButton(
                        icon: Icons.share_outlined,
                        onPressed: widget.onSharePressed!,
                        backgroundColor: Colors.white.withOpacity(0.9),
                        iconColor: Colors.grey[700]!,
                      ),
                    
                    const SizedBox(width: 8),
                    
                    // Favorite button
                    if (widget.onFavoritePressed != null)
                      AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: _buildControlButton(
                              icon: widget.isFavorite 
                                ? Icons.favorite 
                                : Icons.favorite_border,
                              onPressed: _onFavoritePressed,
                              backgroundColor: widget.isFavorite
                                ? Colors.red.withOpacity(0.9)
                                : Colors.white.withOpacity(0.9),
                              iconColor: widget.isFavorite
                                ? Colors.white
                                : Colors.grey[700]!,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          // Product info section
          if (widget.showProductInfo && widget.productName != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.productName!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green[200]!,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1}/${widget.productImages.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Image navigation hint
                  if (widget.productImages.length > 1)
                    Row(
                      children: [
                        Icon(
                          Icons.swipe,
                          size: 16,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Swipe to view more images',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.zoom_out_map,
                          size: 16,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tap for fullscreen',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: iconColor,
        ),
      ),
    );
  }
}

// Helper widget for empty gallery state
class EmptyProductGallery extends StatelessWidget {
  final double height;
  final String message;

  const EmptyProductGallery({
    Key? key,
    this.height = 300,
    this.message = 'No images available',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Images will appear here once uploaded',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
