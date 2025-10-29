import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../models/product.dart';

const String kProductDraftsKey = 'product_drafts';

class ProductDraft {
  final String id;
  final String title;
  final DateTime savedAt;
  final Map<String, dynamic> data;

  ProductDraft({
    required this.id,
    required this.title,
    required this.savedAt,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'savedAt': savedAt.toIso8601String(),
    'data': data,
  };

  static ProductDraft fromJson(Map<String, dynamic> json) => ProductDraft(
    id: json['id'],
    title: json['title'],
    savedAt: DateTime.parse(json['savedAt']),
    data: Map<String, dynamic>.from(json['data']),
  );

  /// Convert ProductDraft to Product for display purposes
  Product toProduct() {
    final data = this.data;
    return Product(
      id: id,
      name: data['name'] ?? title,
      description: data['description'] ?? '',
      category: data['category'] ?? 'Other',
      price: _parseDouble(data['price']) ?? 0.0,
      imageUrl: data['imageUrl'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      videoUrls: List<String>.from(data['videoUrls'] ?? []),
      unit: data['unit'],
      owner: data['owner'],
      sellerName: data['sellerName'],
      location: data['location'] ?? '',
      quantity: _parseInt(data['quantity']) ?? 0,
      createdAt: savedAt,
      updatedAt: savedAt,
      isActive: false, // Drafts are not active products
      rating: null,
      reviewCount: null,
    );
  }

  /// Safely parse double from various input types
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  /// Safely parse int from various input types
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}

class DraftService {
  /// Get the current user ID for user-specific draft storage
  static Future<String?> _getCurrentUserId() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      return user.userId;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  /// Get user-specific drafts key
  static Future<String> _getUserDraftsKey() async {
    final userId = await _getCurrentUserId();
    return userId != null ? '${kProductDraftsKey}_$userId' : kProductDraftsKey;
  }
  
  /// Fetch all drafts from local storage for current user
  static Future<List<ProductDraft>> fetchAllDrafts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDraftsKey = await _getUserDraftsKey();
      final draftsString = prefs.getString(userDraftsKey);
      
      if (draftsString == null) return [];
      
      final List<dynamic> list = jsonDecode(draftsString);
      return list.map((e) => ProductDraft.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error fetching drafts: $e');
      return [];
    }
  }

  /// Save a new draft or update existing one
  static Future<bool> saveDraft(ProductDraft draft) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final drafts = await fetchAllDrafts();
      final userDraftsKey = await _getUserDraftsKey();
      
      // Remove existing draft with same ID if it exists
      drafts.removeWhere((d) => d.id == draft.id);
      
      // Add the new/updated draft
      drafts.add(draft);
      
      // Sort by savedAt (most recent first)
      drafts.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      
      await prefs.setString(
        userDraftsKey,
        jsonEncode(drafts.map((d) => d.toJson()).toList()),
      );
      
      return true;
    } catch (e) {
      print('Error saving draft: $e');
      return false;
    }
  }

  /// Delete a draft by ID
  static Future<bool> deleteDraftById(String draftId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final drafts = await fetchAllDrafts();
      final userDraftsKey = await _getUserDraftsKey();
      final initialLength = drafts.length;
      
      drafts.removeWhere((d) => d.id == draftId);
      
      if (drafts.length < initialLength) {
        await prefs.setString(
          userDraftsKey,
          jsonEncode(drafts.map((d) => d.toJson()).toList()),
        );
        return true;
      }
      
      return false; // Draft not found
    } catch (e) {
      print('Error deleting draft: $e');
      return false;
    }
  }

  /// Get a specific draft by ID
  static Future<ProductDraft?> getDraftById(String draftId) async {
    try {
      final drafts = await fetchAllDrafts();
      return drafts.where((d) => d.id == draftId).firstOrNull;
    } catch (e) {
      print('Error getting draft by ID: $e');
      return null;
    }
  }

  /// Clear all drafts for current user
  static Future<bool> clearAllDrafts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDraftsKey = await _getUserDraftsKey();
      await prefs.remove(userDraftsKey);
      return true;
    } catch (e) {
      print('Error clearing all drafts: $e');
      return false;
    }
  }

  /// Convert drafts to Product objects for display
  static Future<List<Product>> getDraftsAsProducts() async {
    try {
      final drafts = await fetchAllDrafts();
      return drafts.map((draft) => draft.toProduct()).toList();
    } catch (e) {
      print('Error converting drafts to products: $e');
      return [];
    }
  }
}
