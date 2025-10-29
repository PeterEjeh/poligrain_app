import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:poligrain_app/screens/onboarding/onboarding_screen.dart';
import 'package:poligrain_app/main_screen_wrapper.dart';
import 'package:poligrain_app/screens/auth/login_screen.dart';
import 'package:poligrain_app/services/auth_service.dart';
import 'package:provider/provider.dart'; // Import provider
import 'amplifyconfiguration.dart';
import 'screens/home/home_screen.dart';
import 'screens/marketplace/marketplace_screen.dart';
import 'screens/crowdfunding/crowdfunding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/user_profile_cache.dart';
import 'models/user_profile.dart' as app_model;
import 'services/cart_service.dart'; // Import CartService
import 'services/mock_inventory_reservation_service.dart'; // Import Mock InventoryReservationService
import 'services/campaign_service.dart'; // Import CampaignService

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureAmplify();

  // Initialize CampaignService
  await CampaignService().initialize();

  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
  final lastEmail = prefs.getString('lastEmail') ?? '';
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<MockInventoryReservationService>(
          create:
              (context) => MockInventoryReservationService(
                authService: Provider.of<AuthService>(context, listen: false),
              )..initialize(), // Initialize the mock service
        ),
        ChangeNotifierProvider(
          create:
              (context) => CartService(
                reservationService:
                    Provider.of<MockInventoryReservationService>(
                      context,
                      listen: false,
                    ),
              )..initialize(), // Initialize the cart service
        ),
      ],
      child: MyApp(seenOnboarding: seenOnboarding, lastEmail: lastEmail),
    ),
  );
}

Future<void> _configureAmplify() async {
  try {
    final authPlugin = AmplifyAuthCognito();
    final apiPlugin = AmplifyAPI();
    final storagePlugin = AmplifyStorageS3();
    await Amplify.addPlugins([authPlugin, apiPlugin, storagePlugin]);
    await Amplify.configure(amplifyconfig);
    print('Successfully configured Amplify');
  } catch (e) {
    print('Error configuring Amplify: $e');
  }
}

class MyApp extends StatelessWidget {
  final bool seenOnboarding;
  final String lastEmail;
  const MyApp({
    super.key,
    required this.seenOnboarding,
    required this.lastEmail,
  });

  Future<void> _cacheUserProfile() async {
    try {
      final profile = await fetchUserProfile();
      UserProfileCache().userProfile = profile;
    } catch (e) {
      // Optionally handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    if (seenOnboarding) {
      // If user is logged in, prefetch and cache profile
      _cacheUserProfile();
    }
    return MaterialApp(
      title: 'PoliGrain App',
      theme: ThemeData(primarySwatch: Colors.green),
      home: Builder(
        builder: (context) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
            child:
                seenOnboarding
                    ? LoginScreen(initialEmail: lastEmail)
                    : const OnboardingScreen(),
          );
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
