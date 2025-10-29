import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'dart:convert';
import 'dart:async';

import 'package:intl/intl.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

import '../../models/product.dart';
import '../../widgets/animated_product_card.dart';
import '../../exceptions/product_exceptions.dart' as product_exceptions;
import '../../services/draft_service.dart';
import '../../services/marketplace_service.dart';

import 'product_creation_screen.dart'; // This imports both ProductCreateScreen and ProductDraft
import 'product_detail_screen.dart';
import 'package:provider/provider.dart';
import '../../services/cart_service.dart';
import '../cart/cart_screen.dart';
import '../../widgets/common/smooth_scroll_behavior.dart';
import '../../services/auth_service.dart';
import '../../services/user_profile_cache.dart';
import '../../models/user_profile.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with TickerProviderStateMixin {
  // Controllers
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  late AnimationController _animationController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // UI State
  String _searchQuery = '';
  String _selectedSort = 'Newest';
  RangeValues? _priceRange;
  bool _fabHovered = false;
  bool _drawerIsOpen = false;

  // Categories
  final List<String> _categories = [
    'All',
    'Vegetables',
    'Fruits',
    'Dairy',
    'Grains',
    'Livestock',
    'Poultry',
    'Fishery',
  ];
  String _selectedCategory = 'All';

  // Product Loading State
  List<Product> _products = [];
  String? _lastKey;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isInitialLoad = true;
  static const int _pageSize = 10;
  // User State
  String? _currentUser;
  bool _isLoggedIn = false;

  // Draft State
  List<Product> _drafts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _scrollController.addListener(_onScroll);
    _initializeScreen();
    _animationController.forward();
  }

  Future<void> _initializeScreen() async {
    await _checkLoginStatus();
    await _getCurrentUser();
    await _loadInitialProducts();
    // Removed _loadDrafts() - drafts should only load in Sell tab
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreProducts();
    }
  }

  // Authentication Methods
  Future<void> _checkLoginStatus() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      setState(() {
        _isLoggedIn = session.isSignedIn;
      });

      if (!_isLoggedIn) {
        // Handle not signed in case - maybe redirect to login
        print('User not logged in');
      }
    } catch (e) {
      print('Error checking auth status: $e');
      setState(() {
        _isLoggedIn = false;
      });
    }
  }

  Future<void> _getCurrentUser() async {
    try {
      if (!_isLoggedIn) return;

      final session =
          await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
      setState(() {
        _currentUser = session.identityIdResult.value;
      });
    } catch (e) {
      print('Error getting current user: $e');
    }
  }

  // Product Loading Methods
  Future<void> _loadInitialProducts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _isInitialLoad = true;
    });

    try {
      final result = await _fetchProducts(
        limit: _pageSize,
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        sortBy: _selectedSort,
      );

      if (mounted) {
        setState(() {
          _products = result.items;
          _lastKey = result.lastKey;
          _hasMore = result.lastKey != null;
          _isInitialLoad = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialLoad = false;
          _isLoading = false;
        });
        _showErrorSnackbar('Error loading products: ${e.toString()}');
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _fetchProducts(
        limit: _pageSize,
        lastKey: _lastKey,
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        sortBy: _selectedSort,
      );

      if (mounted) {
        setState(() {
          _products.addAll(result.items);
          _lastKey = result.lastKey;
          _hasMore = result.lastKey != null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackbar('Error loading more products: ${e.toString()}');
      }
    }
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _products = [];
      _lastKey = null;
      _hasMore = true;
    });
    await _loadInitialProducts();
  }

  // API Methods
  Future<PaginatedProducts> _fetchProducts({
    int limit = 10,
    String? lastKey,
    String? category,
    String? searchQuery,
    String? sortBy,
  }) async {
    try {
      // Use the improved marketplace service
      final filters = ProductFilterOptions(
        category: category,
        searchQuery: searchQuery,
        sortBy: sortBy,
        inStock: true, // Only show products in stock
      );

      final result = await fetchPaginatedProducts(
        limit: limit,
        lastKey: lastKey,
        filters: filters,
      );

      safePrint('Products data received: ${result.items.length} items');
      return result;
    } catch (e) {
      safePrint('Error fetching products: $e');
      rethrow;
    }
  }

  Future<List<Product>> _getDrafts() async {
    try {
      return await DraftService.getDraftsAsProducts();
    } catch (e) {
      print('Error loading drafts: $e');
      return [];
    }
  }

  Future<void> _loadDrafts() async {
    if (!_isLoggedIn) {
      setState(() {
        _drafts = [];
      });
      return;
    }

    try {
      final drafts = await _getDrafts();
      if (mounted) {
        setState(() {
          _drafts = drafts;
        });
      }
    } catch (e) {
      print('Error loading drafts: $e');
      if (mounted) {
        setState(() {
          _drafts = [];
        });
      }
    }
  }

  Future<void> _deleteDraft(String draftId) async {
    try {
      final success = await DraftService.deleteDraftById(draftId);

      if (success) {
        await _loadDrafts();
        _showSuccessSnackbar('Draft deleted successfully');
      } else {
        throw Exception('Failed to delete draft');
      }
    } catch (e) {
      _showErrorSnackbar('Error deleting draft: ${e.toString()}');
    }
  }

  Future<void> _deleteProduct(Product product) async {
    if (!_isLoggedIn || product.owner == null || product.owner!.isEmpty) {
      _showErrorSnackbar(
        'Cannot delete product: unauthorized or missing owner',
      );
      return;
    }

    try {
      const apiName = 'PoligrainAPI';
      final response =
          await Amplify.API
              .delete(
                '/products/${product.id}',
                apiName: apiName,
                queryParameters: {'owner': product.owner!},
              )
              .response;

      if (response.statusCode == 200 || response.statusCode == 204) {
        await _refreshProducts();
        _showSuccessSnackbar('Product deleted successfully');
      } else {
        throw Exception('Failed to delete product: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('Error deleting product: ${e.toString()}');
    }
  }

  // Filter and Sort Methods
  List<Product> _filterProducts(List<Product> products) {
    List<Product> filtered = products;

    // Apply category filter
    if (_selectedCategory != 'All') {
      filtered =
          filtered.where((p) => p.category == _selectedCategory).toList();
    }

    // Apply search filter
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      filtered =
          filtered
              .where(
                (p) =>
                    p.name.toLowerCase().contains(query) ||
                    p.description.toLowerCase().contains(query) ||
                    p.category.toLowerCase().contains(query),
              )
              .toList();
    }

    // Apply price filter
    if (_priceRange != null) {
      filtered =
          filtered
              .where(
                (p) =>
                    p.price >= _priceRange!.start &&
                    p.price <= _priceRange!.end,
              )
              .toList();
    }

    // Apply sorting
    filtered = _applySorting(filtered);

    return filtered;
  }

  String _getCloudFrontImageUrl(String s3Key) {
    const String cloudFrontDomain = 'https://dqsnae4wms22.cloudfront.net';
    if (s3Key.isEmpty) return '';
    return '$cloudFrontDomain/$s3Key';
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _refreshProducts,
        ),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  // Modern Header
                  _buildModernHeader(),
                  // TabBar
                  _buildTabBar(),
                  // TabBarView
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildBuyTab(), _buildSellTab()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Marketplace',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          Consumer<CartService>(
            builder: (context, cartService, child) {
              return Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.shopping_bag_outlined, size: 24),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (cartService.totalItems > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${cartService.totalItems}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.black,
        indicatorWeight: 2,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        tabs: const [Tab(text: 'Buy'), Tab(text: 'Sell')],
      ),
    );
  }

  Widget _buildBuyTab() {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    final horizontalPadding = (screenWidth * 0.04).clamp(12.0, 24.0);
    final verticalSpacing = (screenHeight * 0.015).clamp(12.0, 20.0);
    final searchBarHeight = (screenHeight * 0.06).clamp(45.0, 60.0);
    final categoryChipHeight = (screenHeight * 0.045).clamp(32.0, 40.0);
    final fontSize = (screenWidth * 0.04).clamp(14.0, 18.0);

    return RefreshIndicator(
      onRefresh: _refreshProducts,
      child: Padding(
        padding: EdgeInsets.all(horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            SizedBox(
              height: searchBarHeight,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: TextStyle(fontSize: fontSize * 0.9),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[600],
                    size: (screenWidth * 0.05).clamp(18.0, 24.0),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: horizontalPadding,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                ),
                style: TextStyle(fontSize: fontSize),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _refreshProducts();
                },
              ),
            ),
            SizedBox(height: verticalSpacing),

            // Sorting and Price Filter Row
            Row(
              children: [
                DropdownButton<String>(
                  value: _selectedSort,
                  items: const [
                    DropdownMenuItem(value: 'Newest', child: Text('Newest')),
                    DropdownMenuItem(
                      value: 'Lowest Price',
                      child: Text('Lowest Price'),
                    ),
                    DropdownMenuItem(
                      value: 'Highest Price',
                      child: Text('Highest Price'),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedSort = val!;
                    });
                    _refreshProducts();
                  },
                  underline: Container(),
                  style: TextStyle(
                    color: Colors.green[800],
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize * 0.9,
                  ),
                  icon: Icon(
                    Icons.sort,
                    color: Colors.green[700],
                    size: (screenWidth * 0.05).clamp(18.0, 24.0),
                  ),
                ),
                SizedBox(width: screenWidth * 0.06),
                Expanded(child: _buildPriceRangeSlider()),
              ],
            ),
            SizedBox(height: verticalSpacing),

            // Categories
            Text(
              'Categories',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
            ),
            SizedBox(height: verticalSpacing * 0.5),
            SizedBox(
              height: categoryChipHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder:
                    (_, __) => SizedBox(width: screenWidth * 0.02),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final selected = cat == _selectedCategory;
                  return ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(fontSize: fontSize * 0.85),
                    ),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                      _refreshProducts();
                    },
                  );
                },
              ),
            ),
            SizedBox(height: verticalSpacing),

            // Product Grid
            Expanded(child: _buildProductGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredProducts = _filterProducts(_products);

    if (filteredProducts.isEmpty && !_isLoading) {
      return const Center(
        child: Text(
          'No products found.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive grid configuration
    int crossAxisCount;
    double childAspectRatio;
    double crossAxisSpacing;
    double mainAxisSpacing;

    if (screenWidth < 360) {
      crossAxisCount = 2;
      childAspectRatio = 0.7;
      crossAxisSpacing = 8.0;
      mainAxisSpacing = 8.0;
    } else if (screenWidth < 600) {
      crossAxisCount = 2;
      childAspectRatio = 0.75;
      crossAxisSpacing = 12.0;
      mainAxisSpacing = 12.0;
    } else if (screenWidth < 900) {
      crossAxisCount = 3;
      childAspectRatio = 0.8;
      crossAxisSpacing = 16.0;
      mainAxisSpacing = 16.0;
    } else {
      crossAxisCount = 4;
      childAspectRatio = 0.85;
      crossAxisSpacing = 20.0;
      mainAxisSpacing = 20.0;
    }

    return ScrollConfiguration(
      behavior: SmoothScrollBehavior(),
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
        ),
        itemCount: filteredProducts.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= filteredProducts.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final product = filteredProducts[index];
          return _buildProductCard(product, index);
        },
      ),
    );
  }

  Widget _buildProductCard(Product product, int index) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: Duration(milliseconds: 400 + (50 * index)),
      child: GestureDetector(
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailScreen(product: product),
              ),
            ),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Container(
                    width: double.infinity,
                    child: Image.network(
                      _getCloudFrontImageUrl(product.imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.broken_image,
                              size: 30,
                              color: Colors.grey[400],
                            ),
                          ),
                    ),
                  ),
                ),
              ),

              // Content section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Product name and price
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₦${_formatPrice(product.price)}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      // Add to Cart button
                      SizedBox(
                        width: double.infinity,
                        height: 27,
                        child: ElevatedButton(
                          onPressed: () {
                            try {
                              context.read<CartService>().addToCart(product);
                              _showSuccessSnackbar('Added to cart!');
                            } catch (e) {
                              _showErrorSnackbar(e.toString());
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 0),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Add to Cart'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRangeSlider() {
    // Set default price range if not set
    _priceRange ??= const RangeValues(0, 1000000);

    return Row(
      children: [
        const Text('₦'),
        Expanded(
          child: RangeSlider(
            values: _priceRange!,
            min: 0,
            max: 1000000,
            divisions: 20,
            labels: RangeLabels(
              _formatPrice(_priceRange!.start),
              _formatPrice(_priceRange!.end),
            ),
            onChanged: (values) {
              setState(() {
                _priceRange = values;
              });
            },
            activeColor: Colors.green[700],
            inactiveColor: Colors.green[100],
          ),
        ),
      ],
    );
  }

  Widget _buildSellTab() {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            await _refreshProducts();
            await _loadDrafts();
          },
          child: FutureBuilder(
            future: _loadDraftsIfNeeded(),
            builder: (context, snapshot) {
              return _buildSellContent();
            },
          ),
        ),
        // Floating Action Button
        Positioned(bottom: 24, right: 24, child: _buildFloatingActionButton()),
      ],
    );
  }

  Future<void> _loadDraftsIfNeeded() async {
    // Only load drafts if user is logged in and we haven't loaded them yet for this session
    if (_isLoggedIn && _drafts.isEmpty) {
      await _loadDrafts();
    }
  }

  Widget _buildSellContent() {
    if (_isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    final userProducts = _getUserProducts();
    final userName = _currentUser?.substring(0, 6) ?? 'Unknown';
    const userRole = 'Farmer';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drafts Section
          if (_drafts.isNotEmpty) ...[
            _buildDraftsSection(),
            const SizedBox(height: 24),
          ],

          // Profile Summary
          _buildProfileSummary(userName, userRole),
          const SizedBox(height: 20),

          // Sales Stats
          _buildSalesStats(userProducts.length),
          const SizedBox(height: 20),

          // My Products List
          _buildMyProductsList(userProducts),
        ],
      ),
    );
  }

  Widget _buildDraftsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Drafts',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.1,
            color: Colors.green[800],
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _drafts.length,
          itemBuilder: (context, index) => _buildDraftCard(_drafts[index]),
        ),
      ],
    );
  }

  Widget _buildDraftCard(Product draft) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 3,
      child: ListTile(
        leading: Icon(Icons.edit_document, color: Colors.green[700]),
        title: Text(draft.name),
        subtitle: Text(
          'Saved: ${_formatDateTime(DateTime.now())}', // Replace with actual saved date
          style: const TextStyle(fontSize: 12),
        ),
        onTap: () async {
          // Convert Product draft to ProductDraft format expected by ProductCreateScreen
          final productDraft = ProductDraft(
            id: draft.id,
            title: draft.name,
            savedAt: draft.createdAt,
            data: draft.toJson(),
          );

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductCreateScreen(draft: productDraft),
            ),
          );
          if (result == true) {
            await _loadDrafts();
          }
        },
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red[400]),
          tooltip: 'Delete',
          onPressed: () => _showDeleteDraftDialog(draft),
        ),
      ),
    );
  }

  Widget _buildProfileSummary(String userName, String userRole) {
    return FutureBuilder<Map<String, String>>(
      future: AuthService().fetchUserAttributes(),
      builder: (context, snapshot) {
        final userProfile = UserProfileCache().userProfile;
        final hasProfilePic = userProfile?.profilePicture.isNotEmpty ?? false;
        final displayId = snapshot.data?['owner'] ?? _currentUser ?? userName;
        final truncatedId =
            displayId.length > 12
                ? '${displayId.substring(0, 6)}...${displayId.substring(displayId.length - 6)}'
                : displayId;
        final displayRole =
            userProfile?.role ?? snapshot.data?['role'] ?? userRole;

        return Row(
          children: [
            if (hasProfilePic)
              CircleAvatar(
                backgroundImage: NetworkImage(userProfile!.profilePicture),
                backgroundColor: Colors.green[100],
                radius: 24,
              )
            else
              CircleAvatar(
                child: Text(
                  displayId.isNotEmpty ? displayId[0].toUpperCase() : '?',
                ),
                backgroundColor: Colors.green[100],
                foregroundColor: Colors.green[800],
                radius: 24,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    truncatedId,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      letterSpacing: 0.2,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    displayRole,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSalesStats(int productCount) {
    return Row(
      children: [
        _buildDashboardStat('Products', productCount),
        _buildDashboardStat('Sales', 0), // TODO: Implement actual sales count
        _buildDashboardStat('Revenue', 0), // TODO: Implement actual revenue
      ],
    );
  }

  Widget _buildDashboardStat(String label, int value) {
    return Padding(
      padding: const EdgeInsets.only(right: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          Text(label, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildMyProductsList(List<Product> userProducts) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Products',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child:
                userProducts.isEmpty
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No products yet.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap the + button to add your first product',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: userProducts.length,
                      itemBuilder:
                          (context, index) =>
                              _buildMyProductCard(userProducts[index]),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyProductCard(Product product) {
    final isSoldOut = product.quantity == 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 6,
      shadowColor: Colors.green.withOpacity(0.08),
      child: ListTile(
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: product),
              ),
            ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            _getCloudFrontImageUrl(product.imageUrl),
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder:
                (context, error, stackTrace) => const Icon(Icons.broken_image),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                product.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSoldOut ? Colors.red[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isSoldOut ? 'Out of Stock' : 'In Stock',
                style: TextStyle(
                  color: isSoldOut ? Colors.red[700] : Colors.green[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '₦${_formatPrice(product.price)} per ${product.unit} | Qty: ${product.quantity}',
          style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
        ),
        trailing: _buildProductMenuButton(product),
      ),
    );
  }

  Widget _buildProductMenuButton(Product product) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) => _handleProductMenuAction(value, product),
      itemBuilder:
          (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 18),
                  SizedBox(width: 8),
                  Text('View'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
    );
  }

  Widget _buildFloatingActionButton() {
    return MouseRegion(
      onEnter: (_) => setState(() => _fabHovered = true),
      onExit: (_) => setState(() => _fabHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _fabHovered = true),
        onTapUp: (_) => setState(() => _fabHovered = false),
        onTapCancel: () => setState(() => _fabHovered = false),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child:
              _fabHovered
                  ? FloatingActionButton.extended(
                    key: const ValueKey('fab-extended'),
                    onPressed: _navigateToProductCreate,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Product'),
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  )
                  : FloatingActionButton(
                    key: const ValueKey('fab-icon'),
                    onPressed: _navigateToProductCreate,
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.add),
                  ),
        ),
      ),
    );
  }

  // Dialog and Navigation Methods
  Future<void> _showDeleteDraftDialog(Product draft) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Draft'),
            content: const Text('Are you sure you want to delete this draft?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await _deleteDraft(draft.id);
    }
  }

  Future<void> _showDeleteProductDialog(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Product'),
            content: const Text(
              'Are you sure you want to delete this product?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await _deleteProduct(product);
    }
  }

  void _navigateToProductCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProductCreateScreen()),
    ).then((_) => _refreshProducts());
  }

  void _handleProductMenuAction(String action, Product product) {
    switch (action) {
      case 'view':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
        break;
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductCreateScreen(product: product),
          ),
        ).then((_) => _refreshProducts());
        break;
      case 'delete':
        _showDeleteProductDialog(product);
        break;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }

  // Missing method: Apply sorting to products
  List<Product> _applySorting(List<Product> products) {
    switch (_selectedSort) {
      case 'Newest':
        return products..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case 'Lowest Price':
        return products..sort((a, b) => a.price.compareTo(b.price));
      case 'Highest Price':
        return products..sort((a, b) => b.price.compareTo(a.price));
      default:
        return products;
    }
  }

  // Missing method: Format price with thousands separator
  String _formatPrice(double price) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(price);
  }

  // Missing method: Get products belonging to current user
  List<Product> _getUserProducts() {
    if (!_isLoggedIn || _currentUser == null) return [];
    return _products.where((product) => product.owner == _currentUser).toList();
  }
}
