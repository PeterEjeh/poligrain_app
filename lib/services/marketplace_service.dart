import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart' hide NetworkException;
import '../models/product.dart';
import '../exceptions/product_exceptions.dart';

/// Fetches a paginated list of products from the marketplace
Future<List<Product>> fetchProducts({
  int limit = 10,
  String? category,
  String? searchQuery,
  String? sortBy = 'Newest',
}) async {
  try {
    final response =
        await Amplify.API
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
    final items =
        (jsonData['items'] as List<dynamic>)
            .map((item) => Product.fromJson(item as Map<String, dynamic>))
            .toList();

    return items;
  } on ProductException {
    rethrow;
  } catch (e) {
    throw NetworkException('Failed to fetch products: $e');
  }
}

/// Fetches a product by its ID
Future<Product?> fetchProductById(String productId) async {
  try {
    final response =
        await Amplify.API
            .get(
              '/products/$productId',
              apiName: 'PoligrainAPI',
            )
            .response;

    final responseBody = await response.decodeBody();
    final statusCode = response.statusCode;

    if (statusCode == 404) {
      return null; // Product not found
    }

    if (statusCode == 429) {
      throw RateLimitException();
    }

    if (statusCode >= 400) {
      final errorBody = json.decode(responseBody) as Map<String, dynamic>;
      throw ValidationException(errorBody);
    }

    final jsonData = json.decode(responseBody) as Map<String, dynamic>;
    return Product.fromJson(jsonData);
  } on ProductException {
    rethrow;
  } catch (e) {
    throw NetworkException('Failed to fetch product: $e');
  }
}

/// Fetches paginated products with advanced filtering and search
Future<PaginatedProducts> fetchPaginatedProducts({
  int limit = 10,
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

    final response =
        await Amplify.API
            .get(
              '/products',
              apiName: 'PoligrainAPI',
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

/// Search products with enhanced search functionality
Future<PaginatedProducts> searchProducts({
  required String query,
  int limit = 10,
  String? lastKey,
  String? category,
  String? sortBy = 'Relevance',
  double? minPrice,
  double? maxPrice,
  String? location,
  bool? inStock,
}) async {
  try {
    final filters = ProductFilterOptions(
      searchQuery: query,
      category: category,
      minPrice: minPrice,
      maxPrice: maxPrice,
      location: location,
      inStock: inStock,
      sortBy: sortBy,
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

/// Filter products by category with pagination
Future<PaginatedProducts> fetchProductsByCategory({
  required String category,
  int limit = 10,
  String? lastKey,
  String? sortBy = 'Newest',
}) async {
  try {
    final filters = ProductFilterOptions(
      category: category,
      sortBy: sortBy,
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

/// Get available product categories
Future<List<String>> fetchProductCategories() async {
  try {
    final response =
        await Amplify.API
            .get(
              '/products/categories',
              apiName: 'PoligrainAPI',
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
    final categories = (jsonData['categories'] as List<dynamic>)
        .map((category) => category.toString())
        .toList();

    return categories;
  } on ProductException {
    rethrow;
  } catch (e) {
    // Return default categories if API fails
    return [
      'Vegetables',
      'Fruits',
      'Dairy',
      'Grains',
      'Livestock',
      'Poultry',
      'Fishery',
    ];
  }
}

/// Get trending products
Future<List<Product>> fetchTrendingProducts({int limit = 5}) async {
  try {
    final filters = ProductFilterOptions(
      sortBy: 'Trending',
      inStock: true,
    );

    final result = await fetchPaginatedProducts(
      limit: limit,
      filters: filters,
    );

    return result.items;
  } catch (e) {
    throw NetworkException('Failed to fetch trending products: $e');
  }
}

/// Get recently added products
Future<List<Product>> fetchRecentProducts({int limit = 10}) async {
  try {
    final filters = ProductFilterOptions(
      sortBy: 'Newest',
      inStock: true,
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

/// Get products by location/region
Future<PaginatedProducts> fetchProductsByLocation({
  required String location,
  int limit = 10,
  String? lastKey,
  String? sortBy = 'Newest',
}) async {
  try {
    final filters = ProductFilterOptions(
      location: location,
      sortBy: sortBy,
      inStock: true,
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

/// Get featured/promoted products
Future<List<Product>> fetchFeaturedProducts({int limit = 3}) async {
  try {
    final response =
        await Amplify.API
            .get(
              '/products/featured',
              apiName: 'PoligrainAPI',
              queryParameters: {'limit': limit.toString()},
            )
            .response;

    final responseBody = await response.decodeBody();
    final statusCode = response.statusCode;

    if (statusCode == 429) {
      throw RateLimitException();
    }

    if (statusCode >= 400) {
      // If featured endpoint doesn't exist, fall back to recent products
      return await fetchRecentProducts(limit: limit);
    }

    final jsonData = json.decode(responseBody) as Map<String, dynamic>;
    final items =
        (jsonData['items'] as List<dynamic>)
            .map((item) => Product.fromJson(item as Map<String, dynamic>))
            .toList();

    return items;
  } on ProductException {
    rethrow;
  } catch (e) {
    // Fall back to recent products if featured products fail
    try {
      return await fetchRecentProducts(limit: limit);
    } catch (fallbackError) {
      throw NetworkException('Failed to fetch featured products: $e');
    }
  }
}
