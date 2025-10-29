import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poligrain_app/main_screen_wrapper.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      image: 'assets/images/poligrain_img.png',
      title: 'PoliGrain',
      subtitle: 'Transforming agriculture for a sustainable future',
    ),
    OnboardingPage(
      image: 'assets/images/young_boys_planting.jpg',
      title: 'Smart Farming',
      subtitle: 'Precision, Productivity, and a Greener Tomorrow',
    ),
    OnboardingPage(
      image: 'assets/images/roady.jpg',
      title: 'Cultivating Innovation, Harvesting Hope',
      subtitle: 'Join us in building a greener tomorrow',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (_currentPage < _pages.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      } else {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Page content
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              return _buildPage(_pages[index]);
            },
          ),
          // Fixed bottom navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                top: 20,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page indicator dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              _currentPage == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Get Started button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('seenOnboarding', true);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[800],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(200, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive font sizes based on screen height
        final titleFontSize =
            constraints.maxHeight * 0.08; // 8% of screen height
        final subtitleFontSize =
            constraints.maxHeight * 0.02; // 2% of screen height
        final logoSize = constraints.maxHeight * 0.15; // 15% of screen height

        return Stack(
          fit: StackFit.expand,
          children: [
            // Full screen image
            Image.asset(page.image, fit: BoxFit.cover),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
            ),
            // Content
            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  bottom: MediaQuery.of(context).padding.bottom + 150,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_currentPage == 0) ...[
                      // Logo only on first slide
                      SizedBox(
                        height: constraints.maxHeight * 0.03,
                      ), // 3% spacing
                    ],
                    if (page.title.isNotEmpty)
                      Flexible(
                        child: Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: titleFontSize.clamp(40, 55),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    if (page.title.isNotEmpty && page.subtitle.isNotEmpty)
                      SizedBox(height: constraints.maxHeight * 0.02),
                    if (page.subtitle.isNotEmpty)
                      Flexible(
                        child: Text(
                          page.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: subtitleFontSize.clamp(14, 18),
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class OnboardingPage {
  final String image;
  final String title;
  final String subtitle;

  OnboardingPage({
    required this.image,
    required this.title,
    required this.subtitle,
  });
}
