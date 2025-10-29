import 'package:meta/meta.dart';

/// Unified Product model that combines all product-related functionality
/// This replaces the previous separate product.dart and product_models.dart files
@immutable
class Product {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final String imageUrl; // Legacy field for backward compatibility
  final List<String> imageUrls;
  final List<String> videoUrls;
  final String? unit;
  final String? owner;
  final String? sellerName;
  final String location;
  final int quantity;
  final int reservedQuantity; // Quantity reserved for pending orders
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final double? rating;
  final int? reviewCount;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.imageUrls,
    this.videoUrls = const [],
    this.unit,
    this.owner,
    this.sellerName,
    required this.location,
    required this.quantity,
    this.reservedQuantity = 0,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.rating,
    this.reviewCount,
  });

  /// Creates a Product from JSON data with comprehensive field mapping
  factory Product.fromJson(Map<String, dynamic> json) {
    try {
      // Handle both legacy and new field formats
      final imageUrls = _extractImageUrls(json);
      final videoUrls = _extractVideoUrls(json);

      return Product(
        id: json['id'] ?? json['_id'] ?? '',
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        category: json['category'] ?? '',
        price: _parsePrice(json['price']),
        imageUrl: _extractPrimaryImageUrl(json, imageUrls),
        imageUrls: imageUrls,
        videoUrls: videoUrls,
        unit: json['unit'] as String?,
        owner:
            (json['owner'] ?? json['ownerId'] ?? json['sellerId'])?.toString(),
        sellerName: (json['sellerName'] ?? json['ownerName'])?.toString(),
        location: (json['location'] ?? 'Unknown Location').toString(),
        quantity: _parseQuantity(json['quantity']),
        reservedQuantity: _parseQuantity(json['reservedQuantity']),
        createdAt: _parseDateTime(json['createdAt']),
        updatedAt: _parseDateTime(json['updatedAt']),
        isActive: json['isActive'] as bool? ?? true,
        rating:
            json['rating'] != null ? (json['rating'] as num).toDouble() : null,
        reviewCount: json['reviewCount'] as int?,
      );
    } catch (e) {
      print('Error parsing Product from JSON: $json');
      print('Error: $e');
      rethrow;
    }
  }

  /// Converts Product to JSON with consistent field naming
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'videoUrls': videoUrls,
      'unit': unit,
      'owner': owner,
      'sellerName': sellerName,
      'location': location,
      'quantity': quantity,
      'reservedQuantity': reservedQuantity,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  /// Creates a copy of this product with updated fields
  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    double? price,
    String? imageUrl,
    List<String>? imageUrls,
    List<String>? videoUrls,
    String? unit,
    String? owner,
    String? sellerName,
    String? location,
    int? quantity,
    int? reservedQuantity,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    double? rating,
    int? reviewCount,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      unit: unit ?? this.unit,
      owner: owner ?? this.owner,
      sellerName: sellerName ?? this.sellerName,
      location: location ?? this.location,
      quantity: quantity ?? this.quantity,
      reservedQuantity: reservedQuantity ?? this.reservedQuantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }

  /// Helper method to extract image URLs from various JSON formats
  static List<String> _extractImageUrls(Map<String, dynamic> json) {
    // Handle direct imageUrls array
    if (json['imageUrls'] is List) {
      return (json['imageUrls'] as List)
          .map((e) => e.toString())
          .where((url) => url.isNotEmpty)
          .toList();
    }

    // Handle legacy imageUrl field
    final legacyImageUrl = json['imageUrl'] as String?;
    if (legacyImageUrl != null && legacyImageUrl.isNotEmpty) {
      return [legacyImageUrl];
    }

    // Handle images array (alternative format)
    if (json['images'] is List) {
      return (json['images'] as List)
          .map((e) => e.toString())
          .where((url) => url.isNotEmpty)
          .toList();
    }

    return [];
  }

  /// Helper method to extract video URLs from various JSON formats
  static List<String> _extractVideoUrls(Map<String, dynamic> json) {
    // Handle direct videoUrls array
    if (json['videoUrls'] is List) {
      return (json['videoUrls'] as List)
          .map((e) => e.toString())
          .where((url) => url.isNotEmpty)
          .toList();
    }

    // Handle videos array (alternative format)
    if (json['videos'] is List) {
      return (json['videos'] as List)
          .map((e) => e.toString())
          .where((url) => url.isNotEmpty)
          .toList();
    }

    return [];
  }

  /// Helper method to extract primary image URL
  static String _extractPrimaryImageUrl(
    Map<String, dynamic> json,
    List<String> imageUrls,
  ) {
    // Use first image from imageUrls if available
    if (imageUrls.isNotEmpty) {
      return imageUrls.first;
    }

    // Fallback to legacy imageUrl
    final legacyImageUrl = json['imageUrl'] as String?;
    if (legacyImageUrl != null && legacyImageUrl.isNotEmpty) {
      return legacyImageUrl;
    }

    return '';
  }

  /// Helper method to parse price with type safety
  static double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) return double.tryParse(price) ?? 0.0;
    return 0.0;
  }

  /// Helper method to parse quantity with type safety
  static int _parseQuantity(dynamic quantity) {
    if (quantity == null) return 0;
    if (quantity is int) return quantity;
    if (quantity is String) return int.tryParse(quantity) ?? 0;
    return 0;
  }

  /// Helper method to parse DateTime with various formats
  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();
    if (dateTime is DateTime) return dateTime;
    if (dateTime is String) {
      return DateTime.tryParse(dateTime) ?? DateTime.now();
    }
    return DateTime.now();
  }

  /// Returns true if product has images
  bool get hasImages => imageUrls.isNotEmpty;

  /// Returns true if product has videos
  bool get hasVideos => videoUrls.isNotEmpty;

  /// Returns formatted price with currency symbol
  String get formattedPrice => '\$$price';

  /// Returns available quantity (total - reserved)
  int get availableQuantity => quantity - reservedQuantity;

  /// Returns true if product has available inventory
  bool get isInStock => availableQuantity > 0;

  /// Returns true if product is out of stock
  bool get isOutOfStock => availableQuantity <= 0;

  /// Returns true if product has total inventory (including reserved)
  bool get hasTotalInventory => quantity > 0;

  /// Returns true if all inventory is reserved
  bool get isFullyReserved => reservedQuantity >= quantity;

  /// Check if a specific quantity can be reserved
  bool canReserveQuantity(int requestedQuantity) {
    return availableQuantity >= requestedQuantity;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Product{id: $id, name: $name, category: $category, price: $price}';
  }
}

/// Paginated products response model
class PaginatedProducts {
  final List<Product> items;
  final bool hasMore;
  final String? lastKey;
  final int totalCount;

  const PaginatedProducts({
    required this.items,
    this.hasMore = false,
    this.lastKey,
    this.totalCount = 0,
  });

  /// Creates PaginatedProducts from JSON with flexible structure
  factory PaginatedProducts.fromJson(Map<String, dynamic> json) {
    // Handle different JSON structures
    final items = _extractItems(json);
    final pagination = _extractPagination(json);

    return PaginatedProducts(
      items: items,
      hasMore: pagination['hasMore'] ?? false,
      lastKey: pagination['lastKey'],
      totalCount: pagination['totalCount'] ?? items.length,
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'pagination': {
        'hasMore': hasMore,
        'lastKey': lastKey,
        'totalCount': totalCount,
      },
    };
  }

  /// Helper method to extract items from various JSON structures
  static List<Product> _extractItems(Map<String, dynamic> json) {
    // Handle direct items array
    if (json['items'] is List) {
      return (json['items'] as List)
          .map((item) => Product.fromJson(item))
          .toList();
    }

    // Handle products array (alternative format)
    if (json['products'] is List) {
      return (json['products'] as List)
          .map((item) => Product.fromJson(item))
          .toList();
    }

    // Handle data array (alternative format)
    if (json['data'] is List) {
      return (json['data'] as List)
          .map((item) => Product.fromJson(item))
          .toList();
    }

    return [];
  }

  /// Helper method to extract pagination info from various JSON structures
  static Map<String, dynamic> _extractPagination(Map<String, dynamic> json) {
    // Handle direct pagination object
    if (json['pagination'] is Map) {
      return json['pagination'] as Map<String, dynamic>;
    }

    // Handle pagination at root level
    return {
      'hasMore': json['hasMore'] ?? json['hasNext'] ?? false,
      'lastKey': json['lastKey'] ?? json['nextCursor'] ?? json['cursor'],
      'totalCount': json['totalCount'] ?? json['total'] ?? json['count'],
    };
  }

  /// Returns true if there are more items to load
  bool get canLoadMore => hasMore && lastKey != null;

  /// Returns the number of items in this page
  int get itemCount => items.length;

  /// Returns true if this is the first page
  bool get isFirstPage => lastKey == null;

  @override
  String toString() {
    return 'PaginatedProducts{items: ${items.length}, hasMore: $hasMore, totalCount: $totalCount}';
  }
}

/// Product filter options for search and filtering
class ProductFilterOptions {
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final String? location;
  final bool? inStock;
  final String? searchQuery;
  final String? sortBy;
  final bool? sortDescending;

  const ProductFilterOptions({
    this.category,
    this.minPrice,
    this.maxPrice,
    this.location,
    this.inStock,
    this.searchQuery,
    this.sortBy,
    this.sortDescending = false,
  });

  /// Creates a copy with updated fields
  ProductFilterOptions copyWith({
    String? category,
    double? minPrice,
    double? maxPrice,
    String? location,
    bool? inStock,
    String? searchQuery,
    String? sortBy,
    bool? sortDescending,
  }) {
    return ProductFilterOptions(
      category: category ?? this.category,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      location: location ?? this.location,
      inStock: inStock ?? this.inStock,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      sortDescending: sortDescending ?? this.sortDescending,
    );
  }

  /// Converts to query parameters for API calls
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};

    if (category != null && category!.isNotEmpty) params['category'] = category;
    if (minPrice != null) params['minPrice'] = minPrice;
    if (maxPrice != null) params['maxPrice'] = maxPrice;
    if (location != null && location!.isNotEmpty) params['location'] = location;
    if (inStock != null) params['inStock'] = inStock;
    if (searchQuery != null && searchQuery!.isNotEmpty)
      params['search'] = searchQuery;
    if (sortBy != null && sortBy!.isNotEmpty) params['sortBy'] = sortBy;
    if (sortDescending != null) params['sortDescending'] = sortDescending;

    return params;
  }

  @override
  String toString() {
    return 'ProductFilterOptions{category: $category, minPrice: $minPrice, maxPrice: $maxPrice, location: $location}';
  }
}
