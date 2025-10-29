import 'package:flutter/material.dart';
import '../../models/product.dart';

class ProductInfoSection extends StatefulWidget {
  final Product product;
  final bool showExpandableDescription;
  final bool showRating;
  final bool showSpecifications;
  final bool showSellerInfo;
  final VoidCallback? onSellerTap;
  final Map<String, String>? additionalSpecs;

  const ProductInfoSection({
    Key? key,
    required this.product,
    this.showExpandableDescription = true,
    this.showRating = true,
    this.showSpecifications = true,
    this.showSellerInfo = true,
    this.onSellerTap,
    this.additionalSpecs,
  }) : super(key: key);

  @override
  State<ProductInfoSection> createState() => _ProductInfoSectionState();
}

class _ProductInfoSectionState extends State<ProductInfoSection>
    with TickerProviderStateMixin {
  bool _isDescriptionExpanded = false;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _expandController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _toggleDescription() {
    setState(() {
      _isDescriptionExpanded = !_isDescriptionExpanded;
    });

    if (_isDescriptionExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  Widget _buildPriceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50]!, Colors.green[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Price',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₦${widget.product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                if (widget.product.unit != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'per ${widget.product.unit}',
                    style: TextStyle(fontSize: 12, color: Colors.green[600]),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.attach_money, color: Colors.green[600], size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    if (!widget.showRating || widget.product.rating == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.star, color: Colors.orange[600], size: 20),
          const SizedBox(width: 8),
          Text(
            widget.product.rating!.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.orange[800],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'out of 5',
            style: TextStyle(fontSize: 14, color: Colors.orange[600]),
          ),
          if (widget.product.reviewCount != null) ...[
            const SizedBox(width: 8),
            Text(
              '(${widget.product.reviewCount} reviews)',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
          const Spacer(),
          TextButton(
            onPressed: () {
              // TODO: Navigate to reviews
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reviews feature coming soon'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              'View Reviews',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    final description = widget.product.description;
    final isLongDescription = description.length > 150;
    final shouldShowReadMore =
        widget.showExpandableDescription && isLongDescription;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),

        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Text(
            shouldShowReadMore && !_isDescriptionExpanded
                ? '${description.substring(0, 150)}...'
                : description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ),

        if (shouldShowReadMore) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _toggleDescription,
            child: Row(
              children: [
                Text(
                  _isDescriptionExpanded ? 'Read Less' : 'Read More',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _isDescriptionExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.green[600],
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSpecificationsSection() {
    if (!widget.showSpecifications) return const SizedBox.shrink();

    final specs = <String, String>{
      'Category': widget.product.category,
      'Location': widget.product.location,
      if (widget.product.unit != null) 'Unit': widget.product.unit!,
      'In Stock': '${widget.product.availableQuantity} units',
      if (widget.product.reservedQuantity > 0)
        'Reserved': '${widget.product.reservedQuantity} units',
      'Product ID': widget.product.id,
      ...?widget.additionalSpecs,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Specifications',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children:
                specs.entries.map((entry) {
                  final index = specs.entries.toList().indexOf(entry);
                  final isLast = index == specs.length - 1;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border:
                          isLast
                              ? null
                              : Border(
                                bottom: BorderSide(color: Colors.grey[200]!),
                              ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSellerSection() {
    if (!widget.showSellerInfo || widget.product.sellerName == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.store, color: Colors.blue[600], size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sold by',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.product.sellerName!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[800],
                  ),
                ),
                Text(
                  widget.product.location,
                  style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                ),
              ],
            ),
          ),
          if (widget.onSellerTap != null)
            IconButton(
              onPressed: widget.onSellerTap,
              icon: Icon(
                Icons.arrow_forward_ios,
                color: Colors.blue[600],
                size: 16,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStockIndicator() {
    final availableStock = widget.product.availableQuantity;
    final isLowStock = availableStock <= 10 && availableStock > 0;
    final isOutOfStock = availableStock <= 0;

    Color indicatorColor;
    IconData indicatorIcon;
    String indicatorText;

    if (isOutOfStock) {
      indicatorColor = Colors.red;
      indicatorIcon = Icons.error_outline;
      indicatorText = 'Out of Stock';
    } else if (isLowStock) {
      indicatorColor = Colors.orange;
      indicatorIcon = Icons.warning_amber_rounded;
      indicatorText = 'Low Stock - Only $availableStock left!';
    } else {
      indicatorColor = Colors.green;
      indicatorIcon = Icons.check_circle_outline;
      indicatorText = 'In Stock - $availableStock available';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: indicatorColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(indicatorIcon, color: indicatorColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              indicatorText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: indicatorColor.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product name and category
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
                      ),
                    ),
                    const SizedBox(height: 4),
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
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Price section
          _buildPriceSection(),

          const SizedBox(height: 16),

          // Stock indicator
          _buildStockIndicator(),

          const SizedBox(height: 16),

          // Rating section
          _buildRatingSection(),

          const SizedBox(height: 16),

          // Description section
          _buildDescriptionSection(),

          const SizedBox(height: 20),

          // Specifications section
          _buildSpecificationsSection(),

          const SizedBox(height: 20),

          // Seller section
          _buildSellerSection(),
        ],
      ),
    );
  }
}

// Compact version for smaller spaces
class CompactProductInfo extends StatelessWidget {
  final Product product;
  final bool showPrice;
  final bool showRating;

  const CompactProductInfo({
    Key? key,
    required this.product,
    this.showPrice = true,
    this.showRating = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name and category
        Text(
          product.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 4),

        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                product.category,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            if (showRating && product.rating != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.star, color: Colors.orange[400], size: 14),
              const SizedBox(width: 2),
              Text(
                product.rating!.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),

        if (showPrice) ...[
          const SizedBox(height: 8),
          Text(
            '₦${product.price.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
        ],
      ],
    );
  }
}
