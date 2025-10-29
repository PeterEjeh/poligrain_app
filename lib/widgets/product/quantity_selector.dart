import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuantitySelector extends StatefulWidget {
  final int initialQuantity;
  final int minQuantity;
  final int maxQuantity;
  final int availableStock;
  final Function(int) onQuantityChanged;
  final bool enabled;
  final String? label;
  final bool showStock;

  const QuantitySelector({
    Key? key,
    this.initialQuantity = 1,
    this.minQuantity = 1,
    this.maxQuantity = 999,
    required this.availableStock,
    required this.onQuantityChanged,
    this.enabled = true,
    this.label,
    this.showStock = true,
  }) : super(key: key);

  @override
  State<QuantitySelector> createState() => _QuantitySelectorState();
}

class _QuantitySelectorState extends State<QuantitySelector>
    with SingleTickerProviderStateMixin {
  late int _currentQuantity;
  late TextEditingController _textController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _currentQuantity = widget.initialQuantity.clamp(
      widget.minQuantity,
      widget.maxQuantity.clamp(widget.minQuantity, widget.availableStock),
    );
    _textController = TextEditingController(text: _currentQuantity.toString());

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(QuantitySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuantity != widget.initialQuantity) {
      _updateQuantity(widget.initialQuantity);
    }
  }

  void _updateQuantity(int newQuantity) {
    final clampedQuantity = newQuantity.clamp(
      widget.minQuantity,
      widget.maxQuantity.clamp(widget.minQuantity, widget.availableStock),
    );

    if (clampedQuantity != _currentQuantity) {
      setState(() {
        _currentQuantity = clampedQuantity;
        _textController.text = _currentQuantity.toString();
      });
      widget.onQuantityChanged(_currentQuantity);
    }
  }

  void _increment() {
    if (!widget.enabled) return;

    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    _updateQuantity(_currentQuantity + 1);
  }

  void _decrement() {
    if (!widget.enabled) return;

    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    _updateQuantity(_currentQuantity - 1);
  }

  void _onTextChanged(String value) {
    final newQuantity = int.tryParse(value);
    if (newQuantity != null) {
      _updateQuantity(newQuantity);
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _stopEditing() {
    setState(() {
      _isEditing = false;
    });
    _onTextChanged(_textController.text);
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool enabled,
  }) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? onPressed : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: enabled ? Colors.grey[100] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: enabled ? Colors.grey[300]! : Colors.grey[200]!,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: enabled ? Colors.grey[700] : Colors.grey[400],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canDecrement =
        widget.enabled && _currentQuantity > widget.minQuantity;
    final canIncrement =
        widget.enabled &&
        _currentQuantity < widget.maxQuantity &&
        _currentQuantity < widget.availableStock;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Quantity selector
        Row(
          children: [
            // Decrease button
            _buildQuantityButton(
              icon: Icons.remove,
              onPressed: _decrement,
              enabled: canDecrement,
            ),

            const SizedBox(width: 12),

            // Quantity display/input
            GestureDetector(
              onTap: widget.enabled ? _startEditing : null,
              child: Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.enabled ? Colors.white : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isEditing ? Colors.green : Colors.grey[300]!,
                    width: _isEditing ? 2 : 1,
                  ),
                ),
                child:
                    _isEditing
                        ? TextField(
                          controller: _textController,
                          enabled: widget.enabled,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (_) => _stopEditing(),
                          onEditingComplete: _stopEditing,
                          autofocus: true,
                        )
                        : Center(
                          child: Text(
                            _currentQuantity.toString(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color:
                                  widget.enabled
                                      ? Colors.black87
                                      : Colors.grey[500],
                            ),
                          ),
                        ),
              ),
            ),

            const SizedBox(width: 12),

            // Increase button
            _buildQuantityButton(
              icon: Icons.add,
              onPressed: _increment,
              enabled: canIncrement,
            ),

            const SizedBox(width: 16),

            // Stock info
            if (widget.showStock)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.availableStock} in stock',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            widget.availableStock > 10
                                ? Colors.green[600]
                                : widget.availableStock > 0
                                ? Colors.orange[600]
                                : Colors.red[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (widget.availableStock <= 10 &&
                        widget.availableStock > 0)
                      Text(
                        'Only ${widget.availableStock} left!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (widget.availableStock == 0)
                      Text(
                        'Out of stock',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),

        // Validation message
        if (_currentQuantity > widget.availableStock) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Only ${widget.availableStock} available in stock',
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
    );
  }
}

// Compact version for smaller spaces
class CompactQuantitySelector extends StatelessWidget {
  final int quantity;
  final int maxQuantity;
  final Function(int) onQuantityChanged;
  final bool enabled;

  const CompactQuantitySelector({
    Key? key,
    required this.quantity,
    required this.maxQuantity,
    required this.onQuantityChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrease button
          GestureDetector(
            onTap:
                enabled && quantity > 1
                    ? () => onQuantityChanged(quantity - 1)
                    : null,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color:
                    enabled && quantity > 1 ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.remove,
                size: 16,
                color:
                    enabled && quantity > 1
                        ? Colors.grey[700]
                        : Colors.grey[400],
              ),
            ),
          ),

          // Quantity display
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              quantity.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: enabled ? Colors.black87 : Colors.grey[500],
              ),
            ),
          ),

          // Increase button
          GestureDetector(
            onTap:
                enabled && quantity < maxQuantity
                    ? () => onQuantityChanged(quantity + 1)
                    : null,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color:
                    enabled && quantity < maxQuantity
                        ? Colors.white
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.add,
                size: 16,
                color:
                    enabled && quantity < maxQuantity
                        ? Colors.grey[700]
                        : Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
