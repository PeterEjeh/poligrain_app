import 'package:flutter/material.dart';

/// Represents a product variant option (e.g., size, color, type)
class ProductVariant {
  final String id;
  final String name;
  final String value;
  final String? displayValue;
  final double? priceModifier;
  final bool isAvailable;
  final Color? color;
  final String? imageUrl;

  const ProductVariant({
    required this.id,
    required this.name,
    required this.value,
    this.displayValue,
    this.priceModifier,
    this.isAvailable = true,
    this.color,
    this.imageUrl,
  });

  String get displayText => displayValue ?? value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductVariant &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Represents a group of variants (e.g., "Size", "Color")
class VariantGroup {
  final String name;
  final String displayName;
  final List<ProductVariant> variants;
  final bool isRequired;
  final bool allowMultiple;

  const VariantGroup({
    required this.name,
    required this.displayName,
    required this.variants,
    this.isRequired = true,
    this.allowMultiple = false,
  });

  List<ProductVariant> get availableVariants =>
      variants.where((v) => v.isAvailable).toList();
}

class VariantSelector extends StatefulWidget {
  final List<VariantGroup> variantGroups;
  final Map<String, ProductVariant> selectedVariants;
  final Function(Map<String, ProductVariant>) onVariantsChanged;
  final bool enabled;
  final String? title;

  const VariantSelector({
    Key? key,
    required this.variantGroups,
    required this.selectedVariants,
    required this.onVariantsChanged,
    this.enabled = true,
    this.title,
  }) : super(key: key);

  @override
  State<VariantSelector> createState() => _VariantSelectorState();
}

class _VariantSelectorState extends State<VariantSelector>
    with TickerProviderStateMixin {
  late Map<String, ProductVariant> _selectedVariants;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _selectedVariants = Map.from(widget.selectedVariants);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(VariantSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedVariants != widget.selectedVariants) {
      setState(() {
        _selectedVariants = Map.from(widget.selectedVariants);
      });
    }
  }

  void _selectVariant(VariantGroup group, ProductVariant variant) {
    if (!widget.enabled || !variant.isAvailable) return;

    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    setState(() {
      if (group.allowMultiple) {
        // Handle multiple selection (like tags/features)
        final currentList = _selectedVariants[group.name];
        // For now, treat as single selection - can be extended for multiple
        _selectedVariants[group.name] = variant;
      } else {
        // Single selection
        _selectedVariants[group.name] = variant;
      }
    });

    widget.onVariantsChanged(_selectedVariants);
  }

  Widget _buildVariantChip({
    required ProductVariant variant,
    required bool isSelected,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isSelected ? _scaleAnimation.value : 1.0,
          child: GestureDetector(
            onTap: enabled ? onTap : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Colors.green
                        : enabled
                        ? Colors.white
                        : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected
                          ? Colors.green
                          : enabled
                          ? Colors.grey[300]!
                          : Colors.grey[200]!,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                        : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Color indicator for color variants
                  if (variant.color != null) ...[
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: variant.color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Variant text
                  Text(
                    variant.displayText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color:
                          isSelected
                              ? Colors.white
                              : enabled
                              ? Colors.black87
                              : Colors.grey[500],
                    ),
                  ),

                  // Price modifier
                  if (variant.priceModifier != null &&
                      variant.priceModifier != 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      variant.priceModifier! > 0
                          ? '+₦${variant.priceModifier!.toStringAsFixed(0)}'
                          : '-₦${(-variant.priceModifier!).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color:
                            isSelected
                                ? Colors.white70
                                : enabled
                                ? Colors.grey[600]
                                : Colors.grey[400],
                      ),
                    ),
                  ],

                  // Unavailable indicator
                  if (!variant.isAvailable) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.block, size: 14, color: Colors.grey[400]),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorVariant({
    required ProductVariant variant,
    required bool isSelected,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: variant.color ?? Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child:
            !variant.isAvailable
                ? Icon(
                  Icons.block,
                  size: 20,
                  color: Colors.white.withOpacity(0.7),
                )
                : isSelected
                ? const Icon(Icons.check, size: 20, color: Colors.white)
                : null,
      ),
    );
  }

  Widget _buildVariantGroup(VariantGroup group) {
    final selectedVariant = _selectedVariants[group.name];
    final isColorGroup =
        group.name.toLowerCase().contains('color') ||
        group.variants.any((v) => v.color != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group title
        Row(
          children: [
            Text(
              group.displayName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            if (group.isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[600],
                ),
              ),
            ],
            if (selectedVariant != null &&
                selectedVariant.priceModifier != null) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      selectedVariant.priceModifier! > 0
                          ? Colors.orange[50]
                          : Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        selectedVariant.priceModifier! > 0
                            ? Colors.orange[200]!
                            : Colors.green[200]!,
                  ),
                ),
                child: Text(
                  selectedVariant.priceModifier! > 0
                      ? '+₦${selectedVariant.priceModifier!.toStringAsFixed(0)}'
                      : '-₦${(-selectedVariant.priceModifier!).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        selectedVariant.priceModifier! > 0
                            ? Colors.orange[700]
                            : Colors.green[700],
                  ),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 12),

        // Variants
        if (isColorGroup)
          // Color variant display
          Wrap(
            children:
                group.availableVariants.map((variant) {
                  final isSelected = selectedVariant?.id == variant.id;
                  return _buildColorVariant(
                    variant: variant,
                    isSelected: isSelected,
                    onTap: () => _selectVariant(group, variant),
                    enabled: widget.enabled && variant.isAvailable,
                  );
                }).toList(),
          )
        else
          // Regular chip display
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                group.availableVariants.map((variant) {
                  final isSelected = selectedVariant?.id == variant.id;
                  return _buildVariantChip(
                    variant: variant,
                    isSelected: isSelected,
                    onTap: () => _selectVariant(group, variant),
                    enabled: widget.enabled && variant.isAvailable,
                  );
                }).toList(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.variantGroups.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        if (widget.title != null) ...[
          Text(
            widget.title!,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Variant groups
        ...widget.variantGroups.map((group) {
          final index = widget.variantGroups.indexOf(group);
          return Column(
            children: [
              _buildVariantGroup(group),
              if (index < widget.variantGroups.length - 1)
                const SizedBox(height: 20),
            ],
          );
        }).toList(),

        // Validation messages
        if (widget.variantGroups.any(
          (group) =>
              group.isRequired && !_selectedVariants.containsKey(group.name),
        )) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please select all required options',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// Helper widget for simple size selection
class SizeSelector extends StatelessWidget {
  final List<String> sizes;
  final String? selectedSize;
  final Function(String) onSizeSelected;
  final bool enabled;

  const SizeSelector({
    Key? key,
    required this.sizes,
    this.selectedSize,
    required this.onSizeSelected,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final variantGroup = VariantGroup(
      name: 'size',
      displayName: 'Size',
      variants:
          sizes
              .map(
                (size) => ProductVariant(id: size, name: 'size', value: size),
              )
              .toList(),
    );

    final selectedVariants =
        selectedSize != null
            ? {
              'size': ProductVariant(
                id: selectedSize!,
                name: 'size',
                value: selectedSize!,
              ),
            }
            : <String, ProductVariant>{};

    return VariantSelector(
      variantGroups: [variantGroup],
      selectedVariants: selectedVariants,
      onVariantsChanged: (variants) {
        final sizeVariant = variants['size'];
        if (sizeVariant != null) {
          onSizeSelected(sizeVariant.value);
        }
      },
      enabled: enabled,
    );
  }
}
