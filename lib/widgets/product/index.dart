export 'enhanced_image_gallery.dart';
export 'fullscreen_image_gallery.dart';
export 'product_image_gallery.dart';

export 'product_info_section.dart';
export 'quantity_selector.dart';
export 'variant_selector.dart';
export 'enhanced_product_detail_screen.dart';
export 'modern_product_detail_screen.dart';

// Demo and examples
export 'image_gallery_demo.dart';

/// Usage Examples:
///
/// 1. Enhanced Image Gallery:
/// ```dart
/// EnhancedImageGallery(
///   imageUrls: productImages,
///   height: 300,
///   showThumbnails: true,
///   enableZoom: true,
///   enableFullscreen: true,
/// )
/// ```
///
/// 2. Product Image Gallery:
/// ```dart
/// ProductImageGallery(
///   productImages: product.imageUrls,
///   productName: product.name,
///   onFavoritePressed: () => toggleFavorite(),
///   onSharePressed: () => shareProduct(),
///   isFavorite: product.isFavorite,
/// )
/// ```
///
/// 3. Product Info Section:
/// ```dart
/// ProductInfoSection(
///   product: product,
///   showExpandableDescription: true,
///   showRating: true,
///   showSpecifications: true,
/// )
/// ```
///
/// 4. Quantity Selector:
/// ```dart
/// QuantitySelector(
///   initialQuantity: 1,
///   availableStock: product.availableQuantity,
///   onQuantityChanged: (quantity) => updateQuantity(quantity),
/// )
/// ```
///
/// 5. Variant Selector:
/// ```dart
/// VariantSelector(
///   variantGroups: [sizeGroup, colorGroup],
///   selectedVariants: selectedVariants,
///   onVariantsChanged: (variants) => updateVariants(variants),
/// )
/// ```
///
/// 6. Modern Product Detail Screen:
/// ```dart
/// ModernProductDetailScreen(
///   product: product,
///   isFavorite: isFavorite,
///   onFavoriteToggle: () => toggleFavorite(),
///   onAddToCart: (product, quantity) => addToCart(product, quantity),
/// )
/// ```
///
/// Features implemented:
///
/// ✅ IMAGE GALLERY (Monday - Aug 11):
/// ✅ Swipeable image carousel with smooth animations
/// ✅ Pinch-to-zoom functionality in fullscreen mode
/// ✅ Thumbnail navigation strip below main image
/// ✅ Fullscreen image viewer with gesture controls
/// ✅ Loading states and error handling
/// ✅ Hero animations between gallery and fullscreen
/// ✅ Share and favorite functionality
/// ✅ Image counter and navigation indicators
/// ✅ Responsive design for different screen sizes
/// ✅ Memory-optimized image caching
///
/// ✅ PRODUCT DETAILS (Tuesday - Aug 12):
/// ✅ Expandable product description with "Read More"
/// ✅ Star rating display with review count
/// ✅ Product specifications table
/// ✅ Quantity selector with +/- buttons
/// ✅ Variant selection (size, color, type)
/// ✅ Stock availability indicator
/// ✅ Price calculation with discounts
/// ✅ Seller information display
/// ✅ Interactive elements with animations
/// ✅ Comprehensive validation and error handling
/// ✅ Modern UI design matching contemporary app standards
/// ✅ Clean, minimalist product detail screen (without rating)
/// ✅ Smooth animations and micro-interactions
/// ✅ Agricultural product focus with relevant information
