import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart' hide NetworkException;
import '../models/product.dart';
import '../exceptions/product_exceptions.dart';

/// Enhanced Marketplace Service with comprehensive product management
class MarketplaceService {
  static const String _apiName = 'PoligrainAPI';
  static const int _defaultLimit = 10;
  static const Duration _cacheTimeout = Duration(minutes: 5);
  
  // Simple cache to avoid repeated API calls
  static final Map<String, _CacheEntry> _cache = {};

  /// Fetches a paginated list of products from the marketplace
  static Future<List<Product>> fetchProducts({
    int limit = _defaultLimit,
    String? category,
    String? searchQuery,
    String? sortBy = 'Newest',
  }) async {
    try {
      final response = await Amplify.API
          .post(
            '/products',
            body: HttpPayload.json({
              'limit': limit,
              'category': category,
              'searchQuery': searchQuery,
              'sortBy': sortBy,
            }),
          )
          .response;

      final responseBody = await response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode == 429) {
        throw RateLimitException();
      }

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw ValidationException(errorBody);
      }

      final jsonData = json.decode(responseBody) as Map<String, dynamic>;
      final items = (jsonData['items'] as List<dynamic>)
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();

      return items;
    } on ProductException {
      rethrow;
    } catch (e) {
      throw NetworkException('Failed to fetch products: $e');
    }
  }

  /// Fetches a product by its ID with caching
  static Future<Product?> fetchProductById(String productId) async {
    // Check cache first
    final cacheKey = 'product_$productId';
    final cachedEntry = _cache[cacheKey];
    if (cachedEntry != null && !cachedEntry.isExpired) {
      return cachedEntry.data as Product?;
    }

    try {
      final response = await Amplify.API
          .get(
            '/products/$productId',
            apiName: _apiName,
          )
          .response;

      final responseBody = await response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode == 404) {
        // Cache null result to avoid repeated failed requests
        _cache[cacheKey] = _CacheEntry(null, DateTime.now());
        return null;
      }

      if (statusCode == 429) {
        throw RateLimitException();
      }

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw ValidationException(errorBody);
      }

      final jsonData = json.decode(responseBody) as Map<String, dynamic>;
      final product = Product.fromJson(jsonData);
      
      // Cache the result
      _cache[cacheKey] = _CacheEntry(product, DateTime.now());
      
      return product;
    } on ProductException {
      rethrow;
    } catch (e) {
      throw NetworkException('Failed to fetch product: $e');
    }
  }

  /// Fetches multiple products by their IDs efficiently
  static Future<Map<String, Product?>> fetchProductsByIds(List<String> productIds) async {
    final results = <String, Product?>{};
    final uncachedIds = <String>[];
    
    // Check cache for each product
    for (final productId in productIds) {
      final cacheKey = 'product_$productId';
      final cachedEntry = _cache[cacheKey];
      if (cachedEntry != null && !cachedEntry.isExpired) {
        results[productId] = cachedEntry.data as Product?;
      } else {
        uncachedIds.add(productId);
      }
    }
    
    // Fetch uncached products
    if (uncachedIds.isNotEmpty) {
      try {
        final response = await Amplify.API
            .post(
              '/products/batch',
              apiName: _apiName,
              body: HttpPayload.json({'productIds': uncachedIds}),
            )
            .response;

        final responseBody = await response.decodeBody();
        final statusCode = response.statusCode;

        if (statusCode == 429) {
          throw RateLimitException();
        }

        if (statusCode >= 400) {
          // Fall back to individual requests
          for (final productId in uncachedIds) {
            try {
              results[productId] = await fetchProductById(productId);
            } catch (e) {
              results[productId] = null;
            }
          }
        } else {
          final jsonData = json.decode(responseBody) as Map<String, dynamic>;
          final products = jsonData['products'] as Map<String, dynamic>;
          
          for (final productId in uncachedIds) {
            final productData = products[productId];
            if (productData != null) {
              final product = Product.fromJson(productData as Map<String, dynamic>);
              results[productId] = product;
              _cache['product_$productId'] = _CacheEntry(product, DateTime.now());
            } else {
              results[productId] = null;
              _cache['product_$productId'] = _CacheEntry(null, DateTime.now());
            }
          }
        }
      } catch (e) {
        // Fall back to individual requests
        for (final productId in uncachedIds) {
          try {
            results[productId] = await fetchProductById(productId);
          } catch (e) {
            results[productId] = null;
          }
        }
      }
    }
    
    return results;
  }

  /// Fetches paginated products with advanced filtering and search
  static Future<PaginatedProducts> fetchPaginatedProducts({
    int limit = _defaultLimit,
    String? lastKey,
    ProductFilterOptions? filters,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        if (lastKey != null) 'lastKey': lastKey,
      };

      // Add filter options to query parameters
      if (filters != null) {
        final filterParams = filters.toQueryParams();
        filterParams.forEach((key, value) {
          queryParams[key] = value.toString();
        });
      }

      final response = await Amplify.API
          .get(
            '/products',
            apiName: _apiName,
            queryParameters: queryParams,
          )
          .response;

      final responseBody = await response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode == 429) {
        throw RateLimitException();
      }

      if (statusCode >= 400) {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        throw ValidationException(errorBody);
      }

      final jsonData = json.decode(responseBody) as Map<String, dynamic>;
      return PaginatedProducts.fromJson(jsonData);
    } on ProductException {
      rethrow;
    } catch (e) {
      throw NetworkException('Failed to fetch products: $e');
    }
  }

  /// Enhanced search products with comprehensive search capabilities
  static Future<PaginatedProducts> searchProducts({
    required String query,
    int limit = _defaultLimit,
    String? lastKey,
    String? category,
    String? sortBy = 'Relevance',
    double? minPrice,
    double? maxPrice,
    String? location,
    bool? inStock,
    List<String>? tags,
  }) async {
    try {
      // Validate search query
      if (query.trim().isEmpty) {
        throw ValidationException({'searchQuery': 'Search query cannot be empty'});
      }

      // Create comprehensive search filters
      final filters = ProductFilterOptions(
        searchQuery: query.trim(),
        category: category,
        minPrice: minPrice,
        maxPrice: maxPrice,
        location: location,
        inStock: inStock,
        sortBy: sortBy,
      );

      // Use dedicated search endpoint for better results
      final queryParams = <String, String>{
        'q': query.trim(),
        'limit': limit.toString(),
        if (lastKey != null) 'lastKey': lastKey,
      };

      // Add filter options
      final filterParams = filters.toQueryParams();
      filterParams.forEach((key, value) {
        if (key != 'search') { // Avoid duplicate search parameter
          queryParams[key] = value.toString();
        }
      });

      // Add tags if provided
      if (tags != null && tags.isNotEmpty) {
        queryParams['tags'] = tags.join(',');
      }

      final response = await Amplify.API
          .get(
            '/products/search',
            apiName: _apiName,
            queryParameters: queryParams,
          )
          .response;

      final responseBody = await response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode == 429) {
        throw RateLimitException();
      }

      if (statusCode >= 400) {
        // Fallback to regular paginated search if dedicated search endpoint fails
        return await fetchPaginatedProducts(
          limit: limit,
          lastKey: lastKey,
          filters: filters,
        );
      }

      final jsonData = json.decode(responseBody) as Map<String, dynamic>;
      return PaginatedProducts.fromJson(jsonData);
    } on ProductException {
      rethrow;
    } catch (e) {
      throw NetworkException('Failed to search products: $e');
    }
  }

  /// Filter products by category with enhanced options
  static Future<PaginatedProducts> fetchProductsByCategory({
    required String category,
    int limit = _defaultLimit,
    String? lastKey,
    String? sortBy = 'Newest',
    double? minPrice,
    double? maxPrice,
    bool? inStock = true,
  }) async {
    try {
      // Validate category
      if (category.trim().isEmpty) {
        throw ValidationException({'category': 'Category cannot be empty'});
      }

      final filters = ProductFilterOptions(
        category: category.trim(),
        sortBy: sortBy,
        minPrice: minPrice,
        maxPrice: maxPrice,
        inStock: inStock,
      );

      return await fetchPaginatedProducts(
        limit: limit,
        lastKey: lastKey,
        filters: filters,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get available product categories with caching
  static Future<List<String>> fetchProductCategories() async {
    const cacheKey = 'product_categories';
    final cachedEntry = _cache[cacheKey];
    if (cachedEntry != null && !cachedEntry.isExpired) {
      return cachedEntry.data as List<String>;
    }

    try {
      final response = await Amplify.API
          .get(
            '/products/categories',
            apiName: _apiName,
          )
          .response;

      final responseBody = await response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode == 429) {
        throw RateLimitException();
      }

      if (statusCode >= 400) {
        // Return default categories if API fails
        return _getDefaultCategories();
      }

      final jsonData = json.decode(responseBody) as Map<String, dynamic>;
      final categories = (jsonData['categories'] as List<dynamic>)
          .map((category) => category.toString())
          .toList();

      // Cache the result
      _cache[cacheKey] = _CacheEntry(categories, DateTime.now());

      return categories;
    } on ProductException {
      rethrow;
    } catch (e) {
      // Return default categories if API fails
      return _getDefaultCategories();
    }
  }

  /// Get trending products with enhanced analytics
  static Future<List<Product>> fetchTrendingProducts({
    int limit = 5,
    String? category,
    String? location,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        if (category != null) 'category': category,
        if (location != null) 'location': location,
      };

      final response = await Amplify.API
          .get(
            '/products/trending',
            apiName: _apiName,
            queryParameters: queryParams,
          )
          .response;

      final responseBody = await response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode == 429) {
        throw RateLimitException();
      }

      if (statusCode >= 400) {
        // Fallback to recent products with trending sort
        final filters = ProductFilterOptions(
          sortBy: 'Trending',
          inStock: true,
          category: category,
          location: location,
        );

        final result = await fetchPaginatedProducts(
          limit: limit,
          filters: filters,
        );

        return result.items;
      }

      final jsonData = json.decode(responseBody) as Map<String, dynamic>;
      final items = (jsonData['items'] as List<dynamic>)
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();

      return items;
    } catch (e) {
      throw NetworkException('Failed to fetch trending products: $e');
    }
  }

  /// Get recently added products
  static Future<List<Product>> fetchRecentProducts({
    int limit = 10,
    String? category,
    bool inStockOnly = true,
  }) async {
    try {
      final filters = ProductFilterOptions(
        sortBy: 'Newest',
        inStock: inStockOnly,
        category: category,
      );

      final result = await fetchPaginatedProducts(
        limit: limit,
        filters: filters,
      );

      return result.items;
    } catch (e) {
      throw NetworkException('Failed to fetch recent products: $e');
    }
  }

  /// Get products by location/region with radius support
  static Future<PaginatedProducts> fetchProductsByLocation({
    required String location,
    int limit = _defaultLimit,
    String? lastKey,
    String? sortBy = 'Distance',
    double? radiusKm,
    String? category,
  }) async {
    try {
      final queryParams = <String, String>{
        'location': location,
        'limit': limit.toString(),
        'sortBy': sortBy ?? 'Distance',
        if (lastKey != null) 'lastKey': lastKey,
        if (radiusKm != null) 'radius': radiusKm.toString(),
        if (category != null) 'category': category,
      };

      final response = await Amplify.API
          .get(
            '/products/location',
            apiName: _apiName,
            queryParameters: queryParams,
          )
          .response;

      final responseBody = await response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode == 429) {
        throw RateLimitException();
      }

      if (statusCode >= 400) {
        // Fallback to regular filter by location
        final filters = ProductFilterOptions(
          location: location,
          sortBy: sortBy,
          inStock: true,
          category: category,
        );

        return await fetchPaginatedProducts(
          limit: limit,
          lastKey: lastKey,
          filters: filters,
        );
      }

      final jsonData = json.decode(responseBody) as Map<String, dynamic>;
      return PaginatedProducts.fromJson(jsonData);
    } catch (e) {
      rethrow;
    }
  }

  /// Get featured/promoted products
  static Future<List<Product>> fetchFeaturedProducts({
    int limit = 3,
    String? category,
  }) async {
    const cacheKey = 'featured_products';
    final cachedEntry = _cache[cacheKey];
    if (cachedEntry != null && !cachedEntry.isExpired && category == null) {
      return cachedEntry.data as List<Product>;
    }

    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        if (category != null) 'category': category,
      };

      final response = await Amplify.API
          .get(
            '/products/featured',
            apiName: _apiName,
            queryParameters: queryParams,
          )
          .response;

      final responseBody = await response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode == 429) {
        throw RateLimitException();
      }

      if (statusCode >= 400) {
        // If featured endpoint doesn't exist, fall back to recent products
        return await fetchRecentProducts(limit: limit, category: category);
      }

      final jsonData = json.decode(responseBody) as Map<String, dynamic>;
      final items = (jsonData['items'] as List<dynamic>)
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();

      // Cache featured products if no category filter
      if (category == null) {
        _cache[cacheKey] = _CacheEntry(items, DateTime.now());
      }

      return items;
    } on ProductException {
      rethrow;
    } catch (e) {
      // Fall back to recent products if featured products fail
      try {
        return await fetchRecentProducts(limit: limit, category: category);
      } catch (fallbackError) {
        throw NetworkException('Failed to fetch featured products: $e');
      }
    }
  }

  /// Get product recommendations based on a product or user preferences
  static Future<List<Product>> fetchRecommendedProducts({
    String? basedOnProductId,
    String? category,
    List<String>? userPreferences,
    int limit = 5,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        if (basedOnProductId != null) 'productId': basedOnProductId,
        if (category != null) 'category': category,
        if (userPreferences != null && userPreferences.isNotEmpty) 
          'preferences': userPreferences.join(','),
      };

      final response = await Amplify.API
          .get(
            '/products/recommendations',
            apiName: _apiName,
            queryParameters: queryParams,
          )
          .response;

      final responseBody = await response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode == 429) {
        throw RateLimitException();
      }

      if (statusCode >= 400) {
        // Fallback to related products in same category
        if (category != null) {
          final result = await fetchProductsByCategory(
            category: category,
            limit: limit,
            sortBy: 'Popular',
          );
          return result.items;
        } else {
          return await fetchTrendingProducts(limit: limit);
        }
      }

      final jsonData = json.decode(responseBody) as Map<String, dynamic>;
      final items = (jsonData['items'] as List<dynamic>)
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();

      return items;
    } catch (e) {
      // Fallback to trending products
      try {
        return await fetchTrendingProducts(limit: limit, category: category);
      } catch (fallbackError) {
        throw NetworkException('Failed to fetch recommended products: $e');
      }
    }
  }

  /// Advanced search with auto-suggestions and spell correction
  static Future<SearchResults> advancedSearch({
    required String query,
    int limit = _defaultLimit,
    String? lastKey,
    ProductFilterOptions? filters,
    bool includeSuggestions = true,
    bool correctSpelling = true,
  }) async {
    try {
      final queryParams = <String, String>{
        'q': query.trim(),
        'limit': limit.toString(),
        'includeSuggestions': includeSuggestions.toString(),
        'correctSpelling': correctSpelling.toString(),
        if (lastKey != null) 'lastKey': lastKey,
      };

      // Add filter options
      if (filters != null) {
        final filterParams = filters.toQueryParams();
        filterParams.forEach((key, value) {
          if (key != 'search') {
            queryParams[key] = value.toString();
          }
        });
      }

      final response = await Amplify.API
          .get(
            '/products/search/advanced',
            apiName: _apiName,
            queryParameters: queryParams,
          )
          .response;

      final responseBody = await response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode == 429) {
        throw RateLimitException();
      }

      if (statusCode >= 400) {
        // Fallback to regular search
        final results = await searchProducts(
          query: query,
          limit: limit,
          lastKey: lastKey,
          category: filters?.category,
          sortBy: filters?.sortBy,
          minPrice: filters?.minPrice,
          maxPrice: filters?.maxPrice,
          location: filters?.location,
          inStock: filters?.inStock,
        );

        return SearchResults(
          products: results,
          suggestions: [],
          correctedQuery: null,
          totalCount: results.totalCount,
        );
      }

      final jsonData = json.decode(responseBody) as Map<String, dynamic>;
      return SearchResults.fromJson(jsonData);
    } catch (e) {
      throw NetworkException('Failed to perform advanced search: $e');
    }
  }

  /// Get search suggestions based on partial query
  static Future<List<String>> getSearchSuggestions(String partialQuery) async {
    if (partialQuery.length < 2) return [];

    try {
      final response = await Amplify.API
          .get(
            '/products/search/suggestions',
            apiName: _apiName,
            queryParameters: {'q': partialQuery.trim()},
          )
          .response;

      final responseBody = await response.decodeBody();
      final statusCode = response.statusCode;

      if (statusCode != 200) {
        return [];
      }

      final jsonData = json.decode(responseBody) as Map<String, dynamic>;
      return (jsonData['suggestions'] as List<dynamic>)
          .map((s) => s.toString())
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Clear cache manually
  static void clearCache() {
    _cache.clear();
  }

  /// Clear expired cache entries
  static void clearExpiredCache() {
    _cache.removeWhere((key, entry) => entry.isExpired);
  }

  /// Get default categories when API fails
  static List<String> _getDefaultCategories() {
    return [
      'Vegetables',
      'Fruits',
      'Dairy',
      'Grains',
      'Livestock',
      'Poultry',
      'Fishery',
      'Herbs & Spices',
      'Organic',
      'Seeds & Seedlings',
    ];
  }
}

/// Cache entry for storing temporary data
class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;

  _CacheEntry(this.data, this.timestamp);

  bool get isExpired => 
      DateTime.now().difference(timestamp) > MarketplaceService._cacheTimeout;
}

/// Enhanced search results with suggestions and metadata
class SearchResults {
  final PaginatedProducts products;
  final List<String> suggestions;
  final String? correctedQuery;
  final int totalCount;

  const SearchResults({
    required this.products,
    required this.suggestions,
    this.correctedQuery,
    required this.totalCount,
  });

  factory SearchResults.fromJson(Map<String, dynamic> json) {
    return SearchResults(
      products: PaginatedProducts.fromJson(json['results'] ?? json),
      suggestions: (json['suggestions'] as List<dynamic>?)
          ?.map((s) => s.toString())
          .toList() ?? [],
      correctedQuery: json['correctedQuery'] as String?,
      totalCount: json['totalCount'] as int? ?? 0,
    );
  }

  bool get hasSuggestions => suggestions.isNotEmpty;
  bool get hasCorrectedQuery => correctedQuery != null;
  bool get hasResults => products.items.isNotEmpty;
}
