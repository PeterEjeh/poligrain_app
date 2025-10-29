import 'package:flutter/material.dart';
import '../../models/product.dart';
import 'product_image_gallery.dart';
import 'product_info_section.dart';
import 'quantity_selector.dart';
import 'variant_selector.dart';

class EnhancedProductDetailScreen extends StatefulWidget {
  final Product product;
  final List<VariantGroup>? variantGroups;
  final Function(Product, int, Map<String, ProductVariant>)? onAddToCart;
  final Function(Product)? onBuyNow;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onShare;
  final bool isFavorite;

  const EnhancedProductDetailScreen({
    Key? key,
    required this.product,
    this.variantGroups,
    this.onAddToCart,
    this.onBuyNow,
    this.onFavoriteToggle,
    this.onShare,
    this.isFavorite = false,
  }) : super(key: key);

  @override
  State<EnhancedProductDetailScreen> createState() =>
      _EnhancedProductDetailScreenState();
}

class _EnhancedProductDetailScreenState
    extends State<EnhancedProductDetailScreen> {
  int _selectedQuantity = 1;
  Map<String, ProductVariant> _selectedVariants = {};
  double _totalPrice = 0.0;
  bool _canAddToCart = true;

  @override
  void initState() {
    super.initState();
    _calculateTotalPrice();
  }

  void _calculateTotalPrice() {
    double basePrice = widget.product.price;
    double variantModifier = 0.0;

    // Add variant price modifiers
    for (final variant in _selectedVariants.values) {
      if (variant.priceModifier != null) {
        variantModifier += variant.priceModifier!;
      }
    }

    setState(() {
      _totalPrice = (basePrice + variantModifier) * _selectedQuantity;
    });
  }

  void _onQuantityChanged(int quantity) {
    setState(() {
      _selectedQuantity = quantity;
    });
    _calculateTotalPrice();
  }

  void _onVariantsChanged(Map<String, ProductVariant> variants) {
    setState(() {
      _selectedVariants = variants;
    });
    _calculateTotalPrice();
    _validateSelection();
  }

  void _validateSelection() {
    bool isValid = true;

    // Check if all required variants are selected
    if (widget.variantGroups != null) {
      for (final group in widget.variantGroups!) {
        if (group.isRequired && !_selectedVariants.containsKey(group.name)) {
          isValid = false;
          break;
        }
      }
    }

    // Check stock availability
    if (_selectedQuantity > widget.product.availableQuantity) {
      isValid = false;
    }

    setState(() {
      _canAddToCart = isValid;
    });
  }

  void _handleAddToCart() {
    if (!_canAddToCart) return;

    widget.onAddToCart?.call(
      widget.product,
      _selectedQuantity,
      _selectedVariants,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added $_selectedQuantity ${widget.product.name} to cart',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Navigate to cart
          },
        ),
      ),
    );
  }

  void _handleBuyNow() {
    if (!_canAddToCart) return;

    widget.onBuyNow?.call(widget.product);

    // TODO: Navigate to checkout
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Proceeding to checkout...'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Total price display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Price:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[800],
                    ),
                  ),
                  Text(
                    '₦${_totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                // Add to Cart button
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _canAddToCart ? _handleAddToCart : null,
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: const Text('Add to Cart'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _canAddToCart ? Colors.green : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: _canAddToCart ? 2 : 0,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Buy Now button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _canAddToCart ? _handleBuyNow : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _canAddToCart ? Colors.orange : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: _canAddToCart ? 2 : 0,
                    ),
                    child: const Text('Buy Now'),
                  ),
                ),
              ],
            ),

            // Validation message
            if (!_canAddToCart) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Colors.red[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedQuantity > widget.product.availableQuantity
                            ? 'Not enough stock available'
                            : 'Please select all required options',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productImages =
        widget.product.imageUrls.isNotEmpty
            ? widget.product.imageUrls
            : widget.product.imageUrl.isNotEmpty
            ? [widget.product.imageUrl]
            : <String>[];

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
            onPressed: widget.onShare,
            icon: const Icon(Icons.share_outlined),
          ),
          IconButton(
            onPressed: widget.onFavoriteToggle,
            icon: Icon(
              widget.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: widget.isFavorite ? Colors.red : null,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image Gallery
                  if (productImages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ProductImageGallery(
                        productImages: productImages,
                        productName: widget.product.name,
                        height: 320,
                        onFavoritePressed: widget.onFavoriteToggle,
                        onSharePressed: widget.onShare,
                        isFavorite: widget.isFavorite,
                      ),
                    ),

                  // Product Information
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: ProductInfoSection(
                          product: widget.product,
                          showExpandableDescription: true,
                          showRating: true,
                          showSpecifications: true,
                          showSellerInfo: true,
                        ),
                      ),
                    ),
                  ),

                  // Variant Selection
                  if (widget.variantGroups != null &&
                      widget.variantGroups!.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: VariantSelector(
                            title: 'Select Options',
                            variantGroups: widget.variantGroups!,
                            selectedVariants: _selectedVariants,
                            onVariantsChanged: _onVariantsChanged,
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Quantity Selection
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: QuantitySelector(
                          label: 'Quantity',
                          initialQuantity: _selectedQuantity,
                          availableStock: widget.product.availableQuantity,
                          onQuantityChanged: _onQuantityChanged,
                          showStock: true,
                        ),
                      ),
                    ),
                  ),

                  // Bottom padding for action buttons
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildActionButtons(),
    );
  }
}

// Example usage with sample data
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

  // Sample variant groups
  List<VariantGroup> get _sampleVariantGroups => [
    VariantGroup(
      name: 'size',
      displayName: 'Size',
      variants: [
        const ProductVariant(
          id: 'small',
          name: 'size',
          value: 'Small',
          displayValue: 'S',
        ),
        const ProductVariant(
          id: 'medium',
          name: 'size',
          value: 'Medium',
          displayValue: 'M',
        ),
        const ProductVariant(
          id: 'large',
          name: 'size',
          value: 'Large',
          displayValue: 'L',
          priceModifier: 50.0,
        ),
      ],
    ),
    VariantGroup(
      name: 'color',
      displayName: 'Color',
      variants: [
        const ProductVariant(
          id: 'red',
          name: 'color',
          value: 'Red',
          color: Colors.red,
        ),
        const ProductVariant(
          id: 'green',
          name: 'color',
          value: 'Green',
          color: Colors.green,
        ),
        const ProductVariant(
          id: 'blue',
          name: 'color',
          value: 'Blue',
          color: Colors.blue,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return EnhancedProductDetailScreen(
      product: widget.product,
      variantGroups: _sampleVariantGroups,
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
      onAddToCart: (product, quantity, variants) {
        print('Added to cart: ${product.name}, Quantity: $quantity');
        print('Selected variants: $variants');
      },
      onBuyNow: (product) {
        print('Buy now: ${product.name}');
      },
    );
  }
}
