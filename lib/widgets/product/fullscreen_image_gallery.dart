import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class FullscreenImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String? heroTag;

  const FullscreenImageGallery({
    Key? key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.heroTag,
  }) : super(key: key);

  @override
  State<FullscreenImageGallery> createState() => _FullscreenImageGalleryState();
}

class _FullscreenImageGalleryState extends State<FullscreenImageGallery>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _overlayAnimationController;
  late Animation<double> _overlayAnimation;

  int _currentIndex = 0;
  bool _showOverlay = true;
  PhotoViewScaleState? _scaleState;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    // Hide system UI for true fullscreen experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _overlayAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _overlayAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _overlayAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _overlayAnimationController.forward();

    // Auto-hide overlay after 3 seconds
    _startOverlayTimer();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _overlayAnimationController.dispose();

    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  void _startOverlayTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showOverlay) {
        _toggleOverlay();
      }
    });
  }

  void _toggleOverlay() {
    setState(() {
      _showOverlay = !_showOverlay;
    });

    if (_showOverlay) {
      _overlayAnimationController.forward();
      _startOverlayTimer();
    } else {
      _overlayAnimationController.reverse();
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onScaleStateChanged(PhotoViewScaleState scaleState) {
    setState(() {
      _scaleState = scaleState;
    });

    // Hide overlay when zooming
    if (scaleState != PhotoViewScaleState.initial && _showOverlay) {
      _toggleOverlay();
    }
  }

  Widget _buildOverlay() {
    return AnimatedBuilder(
      animation: _overlayAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _overlayAnimation.value,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [Colors.black54, Colors.transparent],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Image counter
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentIndex + 1} of ${widget.imageUrls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Share button
                    GestureDetector(
                      onTap: () {
                        // TODO: Implement share functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Share functionality coming soon'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.share,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomOverlay() {
    if (widget.imageUrls.length <= 1) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _overlayAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _overlayAnimation.value,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [Colors.black54, Colors.transparent],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Previous button
                    if (_currentIndex > 0)
                      GestureDetector(
                        onTap: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),

                    const SizedBox(width: 20),

                    // Page indicators
                    Container(
                      height: 40,
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.6,
                      ),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        itemCount: widget.imageUrls.length,
                        itemBuilder: (context, index) {
                          final isActive = index == _currentIndex;
                          return GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
                              width: isActive ? 12 : 8,
                              height: isActive ? 12 : 8,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.white : Colors.white54,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 20),

                    // Next button
                    if (_currentIndex < widget.imageUrls.length - 1)
                      GestureDetector(
                        onTap: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                  ],
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleOverlay,
        child: Stack(
          children: [
            // Main photo gallery
            PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              builder: (BuildContext context, int index) {
                return PhotoViewGalleryPageOptions.customChild(
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrls[index],
                    placeholder:
                        (context, url) => const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.white,
                                size: 50,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Failed to load image',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                  ),
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained * 0.8,
                  maxScale: PhotoViewComputedScale.covered * 3.0,
                  heroAttributes: PhotoViewHeroAttributes(
                    tag:
                        widget.heroTag ??
                        'image_${widget.imageUrls[index]}_$index',
                  ),
                  onScaleEnd: (context, details, controllerValue) {
                    // Handle scale state changes - photo_view package API update
                    if (controllerValue.scale != null) {
                      final scale = controllerValue.scale!;
                      if (scale > 1.0) {
                        _onScaleStateChanged(PhotoViewScaleState.zoomedIn);
                      } else {
                        _onScaleStateChanged(PhotoViewScaleState.initial);
                      }
                    }
                  },
                );
              },
              itemCount: widget.imageUrls.length,
              loadingBuilder:
                  (context, event) => const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              pageController: _pageController,
              onPageChanged: _onPageChanged,
              scrollDirection: Axis.horizontal,
            ),

            // Top overlay
            if (_showOverlay)
              Positioned(top: 0, left: 0, right: 0, child: _buildOverlay()),

            // Bottom overlay
            if (_showOverlay)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomOverlay(),
              ),

            // Zoom instruction overlay (shows briefly)
            if (_scaleState == null)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: _showOverlay ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Pinch to zoom • Double tap to fit',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
