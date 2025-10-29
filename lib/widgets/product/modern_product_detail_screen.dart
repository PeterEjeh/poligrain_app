import 'package:flutter/material.dart';
import '../../models/product.dart';
import 'enhanced_image_gallery.dart';

class ModernProductDetailScreen extends StatefulWidget {
  final Product product;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onShare;
  final Function(Product, int)? onAddToCart;
  final bool isFavorite;

  const ModernProductDetailScreen({
    Key? key,
    required this.product,
    this.onFavoriteToggle,
    this.onShare,
    this.onAddToCart,
    this.isFavorite = false,
  }) : super(key: key);

  @override
  State<ModernProductDetailScreen> createState() =>
      _ModernProductDetailScreenState();
}

class _ModernProductDetailScreenState extends State<ModernProductDetailScreen>
    with SingleTickerProviderStateMixin {
  int _quantity = 1;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _incrementQuantity() {
    if (_quantity < widget.product.availableQuantity) {
      setState(() {
        _quantity++;
      });
    }
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _handleAddToCart() {
    widget.onAddToCart?.call(widget.product, _quantity);

    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Added $_quantity ${widget.product.name} to cart'),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildImageSection() {
    final productImages =
        widget.product.imageUrls.isNotEmpty
            ? widget.product.imageUrls
            : widget.product.imageUrl.isNotEmpty
            ? [widget.product.imageUrl]
            : <String>[];

    return Container(
      height: 400,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          // Product Image
          if (productImages.isNotEmpty)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: EnhancedImageGallery(
                  imageUrls: productImages,
                  height: 360,
                  showThumbnails: false,
                  enableZoom: true,
                  enableFullscreen: true,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            )
          else
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.agriculture,
                  size: 80,
                  color: Colors.grey[400],
                ),
              ),
            ),

          // Top Navigation Bar
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      size: 20,
                      color: Colors.black87,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onFavoriteToggle,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 20,
                      color: widget.isFavorite ? Colors.red : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating Action Button (for AR/3D view placeholder)
          Positioned(
            bottom: 30,
            right: 30,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[400],
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.view_in_ar,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfo() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Name and Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.product.category,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '₦${widget.product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[600],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Stats Row (Views, Likes, etc.)
            Row(
              children: [
                _buildStatItem(
                  Icons.visibility_outlined,
                  '${widget.product.quantity} Available',
                ),
                const SizedBox(width: 20),
                _buildStatItem(
                  Icons.location_on_outlined,
                  widget.product.location,
                ),
                if (widget.product.sellerName != null) ...[
                  const SizedBox(width: 20),
                  _buildStatItem(
                    Icons.store_outlined,
                    widget.product.sellerName!,
                  ),
                ],
              ],
            ),

            const SizedBox(height: 24),

            // Description
            Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.product.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),

            const SizedBox(height: 32),

            // Quantity Selector
            Row(
              children: [
                Text(
                  'Quantity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _decrementQuantity,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                _quantity > 1
                                    ? Colors.white
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.remove,
                            size: 20,
                            color:
                                _quantity > 1
                                    ? Colors.black87
                                    : Colors.grey[400],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          _quantity.toString().padLeft(2, '0'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _incrementQuantity,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                _quantity < widget.product.availableQuantity
                                    ? Colors.green
                                    : Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.add,
                            size: 20,
                            color:
                                _quantity < widget.product.availableQuantity
                                    ? Colors.white
                                    : Colors.grey[500],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Total Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  '₦${(widget.product.price * _quantity).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Add to Cart Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    widget.product.availableQuantity > 0
                        ? _handleAddToCart
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_cart_outlined, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      widget.product.availableQuantity > 0
                          ? 'Add To Cart'
                          : 'Out of Stock',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(children: [_buildImageSection(), _buildProductInfo()]),
      ),
    );
  }
}

// Example usage with sample agricultural product
class ModernProductDetailExample extends StatefulWidget {
  final Product product;

  const ModernProductDetailExample({Key? key, required this.product})
    : super(key: key);

  @override
  State<ModernProductDetailExample> createState() =>
      _ModernProductDetailExampleState();
}

class _ModernProductDetailExampleState
    extends State<ModernProductDetailExample> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    return ModernProductDetailScreen(
      product: widget.product,
      isFavorite: _isFavorite,
      onFavoriteToggle: () {
        setState(() {
          _isFavorite = !_isFavorite;
        });
      },
      onShare: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Share functionality would open here'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      onAddToCart: (product, quantity) {
        print('Added to cart: ${product.name}, Quantity: $quantity');
      },
    );
  }
}
