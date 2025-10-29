import 'package:flutter/material.dart';
import '../models/product.dart';
import 'product/product_image_gallery.dart';
import 'product/enhanced_image_gallery.dart';

class ProductDetailScreenExample extends StatefulWidget {
  final Product product;

  const ProductDetailScreenExample({Key? key, required this.product})
    : super(key: key);

  @override
  State<ProductDetailScreenExample> createState() =>
      _ProductDetailScreenExampleState();
}

class _ProductDetailScreenExampleState
    extends State<ProductDetailScreenExample> {
  bool _isFavorite = false;

  List<String> get _productImages {
    // Combine legacy imageUrl and new imageUrls list
    final List<String> images = [];

    // Add imageUrls first (primary images)
    if (widget.product.imageUrls.isNotEmpty) {
      images.addAll(widget.product.imageUrls);
    }

    // Add legacy imageUrl if not already included
    if (widget.product.imageUrl.isNotEmpty &&
        !images.contains(widget.product.imageUrl)) {
      images.insert(0, widget.product.imageUrl);
    }

    return images;
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    // TODO: Implement actual favorite toggle logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite ? 'Added to favorites' : 'Removed from favorites',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: _isFavorite ? Colors.green : Colors.grey[600],
      ),
    );
  }

  void _shareProduct() {
    // TODO: Implement actual share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality would open here'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.product.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _shareProduct,
            icon: const Icon(Icons.share_outlined),
          ),
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Product Image Gallery
            if (_productImages.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: ProductImageGallery(
                  productImages: _productImages,
                  productName: widget.product.name,
                  height: 320,
                  onFavoritePressed: _toggleFavorite,
                  onSharePressed: _shareProduct,
                  isFavorite: _isFavorite,
                ),
              ),
            ] else ...[
              // Empty state when no images
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  height: 320,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported_outlined,
                        size: 50,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No images available',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Product Information Card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product name and price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.product.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '₦${widget.product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Category and rating
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Text(
                              widget.product.category,
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          if (widget.product.rating != null) ...[
                            const SizedBox(width: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.orange[400],
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.product.rating!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (widget.product.reviewCount != null)
                                  Text(
                                    ' (${widget.product.reviewCount})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Description
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.product.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Product details grid
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              'Location',
                              widget.product.location,
                            ),
                            if (widget.product.unit != null)
                              _buildDetailRow('Unit', widget.product.unit!),
                            if (widget.product.sellerName != null)
                              _buildDetailRow(
                                'Seller',
                                widget.product.sellerName!,
                              ),
                            _buildDetailRow(
                              'In Stock',
                              '${widget.product.quantity - widget.product.reservedQuantity} units',
                            ),
                            if (widget.product.reservedQuantity > 0)
                              _buildDetailRow(
                                'Reserved',
                                '${widget.product.reservedQuantity} units',
                                valueColor: Colors.orange[700],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Added to cart!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('Add to Cart'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Buy now functionality coming soon!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Buy Now'),
                  ),
                ],
              ),
            ),

            // Alternative: Simple Enhanced Gallery (without product wrapper)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alternative Gallery Style',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This shows the basic EnhancedImageGallery without the product wrapper:',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),

                      if (_productImages.isNotEmpty)
                        EnhancedImageGallery(
                          imageUrls: _productImages,
                          height: 200,
                          showThumbnails: true,
                          enableZoom: true,
                          enableFullscreen: true,
                          borderRadius: BorderRadius.circular(8),
                          onImageChanged: (index) {
                            print('Image changed to index: $index');
                          },
                        )
                      else
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text('No images to display'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
