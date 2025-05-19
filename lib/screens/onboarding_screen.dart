import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'dart:ui' as ui;

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top half image
          Expanded(
            flex: 7,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/poliback.jpg',
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
                  child: Container(color: Colors.black.withOpacity(0),)),
            ]
            ),
          ),

          // Bottom content area
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              color: const Color(0xDB7DDC47), // light green
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 55),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      const Text(
                        'POLIGRAIN',
                        style: TextStyle(
                          fontFamily: 'Ragestu',
                          fontSize: 55,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Transforming agriculture for a sustainable future',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'BaskenRegular',
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),

                    ],
                  ),
                  // Get Started Button

                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[800],
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text('Get started',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}




