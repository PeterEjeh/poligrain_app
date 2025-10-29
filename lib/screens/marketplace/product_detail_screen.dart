import 'package:flutter/material.dart';
import '../../models/product.dart';
import 'package:provider/provider.dart';
import '../../services/cart_service.dart';
import '../../services/marketplace_service.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../models/user_profile.dart' as app_model;
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import '../../widgets/common/smooth_scroll_behavior.dart';

String _formatPrice(double price) {
  final formatter = NumberFormat("#,##0.00", "en_US");
  return formatter.format(price);
}

class ProductDetailScreen extends StatefulWidget {
  final Product? product;
  final String? productId;

  const ProductDetailScreen({Key? key, this.product, this.productId})
    : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with TickerProviderStateMixin {
  Product? _product;
  app_model.UserProfile? _sellerProfile;
  bool _loadingProduct = true;
  bool _loadingProfile = true;
  String? _errorMessage;
  List<VideoPlayerController> _videoControllers = [];
  int _selectedMediaIdx = 0;
  List<Map<String, dynamic>> _mediaList = [];
  final PageController _pageController = PageController();

  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _imageAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  int _quantity = 1;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _imageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _imageAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _loadProduct();
    _animationController.forward();
  }

  Future<void> _loadProduct() async {
    try {
      setState(() => _loadingProduct = true);

      Product? product;

      if (widget.product != null) {
        // Product was provided directly
        product = widget.product;
      } else if (widget.productId != null) {
        // Need to fetch product by ID
        product = await fetchProductById(widget.productId!);
        if (product == null) {
          setState(() {
            _errorMessage = 'Product not found';
            _loadingProduct = false;
          });
          return;
        }
      } else {
        setState(() {
          _errorMessage = 'No product provided';
          _loadingProduct = false;
        });
        return;
      }

      setState(() {
        _product = product;
        _loadingProduct = false;
      });

      // Initialize media and fetch seller profile
      _initializeMedia();
      _fetchSellerProfile();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load product: ${e.toString()}';
        _loadingProduct = false;
      });
    }
  }

  void _initializeMedia() {
    if (_product == null) return;

    // Build a combined media list: images first, then videos
    _mediaList = [
      ..._product!.imageUrls.map((url) => {'type': 'image', 'url': url}),
      ..._product!.videoUrls.map((url) => {'type': 'video', 'url': url}),
    ];

    // Initialize video controllers
    _initVideoControllers();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _imageAnimationController.dispose();
    _pageController.dispose();
    for (final controller in _videoControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchSellerProfile() async {
    if (_product == null) return;

    setState(() => _loadingProfile = true);
    try {
      // Fetch user profile by owner (assume owner is email/username)
      final restOp =
          await Amplify.API
              .get('/user-profile/${_product!.owner}', apiName: 'PoligrainAPI')
              .response;
      if (restOp.statusCode == 200) {
        final data = app_model.UserProfile.fromJson(
          jsonDecode(restOp.decodeBody()),
        );
        setState(() {
          _sellerProfile = data;
        });
      }
    } catch (e) {
      // ignore error, show fallback
    } finally {
      setState(() => _loadingProfile = false);
    }
  }

  void _initVideoControllers() {
    if (_product == null) return;

    for (final url in _product!.videoUrls) {
      final controller = VideoPlayerController.network(
        getCloudFrontImageUrl(url),
      );
      controller.initialize();
      _videoControllers.add(controller);
    }
  }

  Future<String?> _getCurrentUserId() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      final identityId = (session as dynamic).identityIdResult.value;
      return identityId;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingProduct) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadProduct,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No product data available')),
      );
    }

    final product = _product!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ScrollConfiguration(
            behavior: SmoothScrollBehavior(),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  leading: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios, size: 18),
                      color: Colors.black,
                    ),
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _isFavorite = !_isFavorite;
                          });
                        },
                        icon: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? Colors.red : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Container(height: 300, child: _buildHeroImage()),
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProductInfo(product),
                              const SizedBox(height: 24),
                              _buildQuantitySelector(),
                              const SizedBox(height: 24),
                              _buildSellerInfo(),
                              const SizedBox(height: 32),
                              _buildAddToCartButton(product),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    if (_mediaList.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _mediaList.length,
            onPageChanged: (index) {
              setState(() {
                _selectedMediaIdx = index;
              });
            },
            itemBuilder: (context, index) {
              final media = _mediaList[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image:
                      media['type'] == 'image'
                          ? DecorationImage(
                            image: NetworkImage(
                              getCloudFrontImageUrl(media['url']),
                            ),
                            fit: BoxFit.cover,
                          )
                          : null,
                ),
                child: media['type'] == 'video' ? _buildVideoPlayer() : null,
              );
            },
          ),
        ),
        if (_mediaList.length > 1) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_mediaList.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _selectedMediaIdx == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color:
                      _selectedMediaIdx == index
                          ? Colors.black
                          : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildVideoPlayer() {
    final videoIdx =
        _mediaList
            .sublist(0, _selectedMediaIdx + 1)
            .where((m) => m['type'] == 'video')
            .length -
        1;

    if (videoIdx >= _videoControllers.length) {
      return const Center(child: Icon(Icons.videocam_off, size: 80));
    }

    final controller = _videoControllers[videoIdx];
    return controller.value.isInitialized
        ? Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.black54,
                onPressed: () {
                  setState(() {
                    controller.value.isPlaying
                        ? controller.pause()
                        : controller.play();
                  });
                },
                child: Icon(
                  controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        )
        : const Center(child: CircularProgressIndicator());
  }

  Widget _buildProductInfo(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            product.category,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              '₦${_formatPrice(product.price)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              ' / ${product.unit ?? "unit"}',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: product.quantity > 0 ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${product.quantity} available',
                style: TextStyle(
                  color:
                      product.quantity > 0
                          ? Colors.green[700]
                          : Colors.red[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          product.description,
          style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text(
            'Quantity',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed:
                      _quantity > 1 ? () => setState(() => _quantity--) : null,
                  icon: const Icon(Icons.remove),
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed:
                      _quantity < (_product?.quantity ?? 0)
                          ? () => setState(() => _quantity++)
                          : null,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerInfo() {
    if (_loadingProfile) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_sellerProfile == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage:
                _sellerProfile!.profilePicture.isNotEmpty
                    ? NetworkImage(_sellerProfile!.profilePicture)
                    : null,
            child:
                _sellerProfile!.profilePicture.isEmpty
                    ? const Icon(Icons.person)
                    : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_sellerProfile!.firstName} ${_sellerProfile!.lastName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _sellerProfile!.address,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Navigate to seller profile or contact
            },
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddToCartButton(Product product) {
    return FutureBuilder<String?>(
      future: _getCurrentUserId(),
      builder: (context, snapshot) {
        final currentUserId = snapshot.data;
        final isOwner = currentUserId != null && currentUserId == product.owner;
        final isSoldOut = product.quantity == 0;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (isOwner) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed:
                isSoldOut
                    ? null
                    : () {
                      try {
                        context.read<CartService>().addToCart(
                          product,
                          quantity: _quantity,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Added $_quantity ${product.name}(s) to cart!',
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
            style: ElevatedButton.styleFrom(
              backgroundColor: isSoldOut ? Colors.grey : Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              isSoldOut
                  ? 'Sold Out'
                  : 'Add to Cart • ₦${_formatPrice(product.price * _quantity)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
    );
  }
}

const String cloudFrontDomain = 'https://dqsnae4wms22.cloudfront.net';

String getCloudFrontImageUrl(String s3Key) {
  if (s3Key.isEmpty) return '';
  return '$cloudFrontDomain/$s3Key';
}
