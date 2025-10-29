import 'package:flutter/material.dart';
import 'package:poligrain_app/screens/marketplace/marketplace_screen.dart'
    as marketplace;
import '../../services/marketplace_service.dart' as market;
import 'package:poligrain_app/screens/crowdfunding/crowdfunding_screen.dart';
import 'package:poligrain_app/screens/logistics/logistics_screen.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:collection/collection.dart'; // For firstWhereOrNull
import 'dart:convert';
import 'package:poligrain_app/models/user_profile.dart'
    as app_model; // Import your UserProfile model with prefix
import 'package:poligrain_app/models/product.dart';
import 'package:poligrain_app/screens/marketplace/product_detail_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:poligrain_app/screens/marketplace/product_creation_screen.dart';
import 'package:intl/intl.dart';
import 'package:poligrain_app/main_screen_wrapper.dart';
import 'package:poligrain_app/services/user_profile_cache.dart';
import '../../widgets/common/smooth_scroll_behavior.dart';
import 'package:poligrain_app/widgets/project_card.dart';

// Crowdfunding Project Data Model
class Project {
  final String name;
  final double goal;
  final double raised;
  final double minInvest;
  final double returnPercent;
  final String? createdAt; // Add createdAt for sorting recent campaigns
  final String status; // Add status for recent campaigns
  final String loanType; // Add loanType for filtering

  Project({
    required this.name,
    required this.goal,
    required this.raised,
    required this.minInvest,
    required this.returnPercent,
    this.createdAt,
    this.status = 'Active',
    this.loanType = 'structured',
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      name: json['campaignName'] ?? json['title'] ?? 'Flexible Loan',
      goal:
          (json['amount'] as num?)?.toDouble() ??
          (json['targetAmount'] as num?)?.toDouble() ??
          0.0,
      raised:
          0.0, // Loan requests don't have a "raised" amount, they're requests
      minInvest: (json['minimumInvestment'] as num?)?.toDouble() ?? 0.0,
      returnPercent: 0.0, // Loan requests don't have a return percentage
      createdAt: json['createdAt'],
      status: json['status'] ?? 'Active',
      loanType: json['type'] ?? json['loanType'] ?? 'structured',
    );
  }
}

// Fetch real loan requests from backend
Future<List<Project>> fetchCrowdfundingProjects() async {
  final session = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
  if (!session.isSignedIn) {
    debugPrint('User not signed in. Cannot fetch crowdfunding projects.');
    return [];
  }
  // Debug: Print identityId and AWS credentials
  try {
    debugPrint('identityId: ${session.identityIdResult.value}');
    final creds = session.credentialsResult.value;
    debugPrint(
      'awsCredentials: accessKeyId=${creds.accessKeyId}, secretKey=${creds.secretAccessKey}, sessionToken=${creds.sessionToken}',
    );
  } catch (e) {
    debugPrint('Could not fetch AWS credentials: ${e.toString()}');
  }
  // Fetch Cognito groups from ID token
  final idToken = session.userPoolTokensResult.value.idToken.raw;
  Map<String, dynamic> _parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw Exception('invalid token');
    final payload = base64Url.normalize(parts[1]);
    final payloadMap = json.decode(utf8.decode(base64Url.decode(payload)));
    if (payloadMap is! Map<String, dynamic>) throw Exception('invalid payload');
    return payloadMap;
  }

  final payload = _parseJwt(idToken);
  final groups = payload['cognito:groups'];
  // Derive role from Cognito groups to avoid using undefined state
  String? role;
  if (groups is List) {
    if (groups.contains('Investors')) {
      role = 'Investor';
    } else if (groups.contains('Farmers')) {
      role = 'Farmer';
    }
  } else if (groups is String) {
    if (groups == 'Investors') {
      role = 'Investor';
    } else if (groups == 'Farmers') {
      role = 'Farmer';
    }
  }
  debugPrint('User Cognito groups (HomeScreen): $groups');
  debugPrint('User role (HomeScreen): $role');
  try {
    // Add type parameter for investors to fetch structured loans
    final Map<String, String> queryParams =
        role == 'Investor' ? {'type': 'structured'} : {};
    final response =
        await Amplify.API
            .get(
              '/loan-requests',
              apiName: 'PoligrainAPI',
              queryParameters: queryParams,
            )
            .response;
    debugPrint('Crowdfunding API status: ${response.statusCode}');
    debugPrint('Crowdfunding API body: ${response.decodeBody()}');
    if (response.statusCode == 200) {
      final dynamic responseData = jsonDecode(response.decodeBody());
      final List<dynamic> data;
      if (responseData is List) {
        data = responseData;
      } else if (responseData is Map && responseData.containsKey('campaigns')) {
        data = responseData['campaigns'] ?? [];
      } else {
        debugPrint('Unexpected response structure: $responseData');
        return [];
      }

      // Convert to Project format and sort by createdAt (most recent first)
      final List<Project> projects =
          data.map((json) => Project.fromJson(json)).toList()..sort((a, b) {
            // Sort by createdAt if available, otherwise use default order
            if (a.createdAt != null && b.createdAt != null) {
              return DateTime.parse(
                b.createdAt!,
              ).compareTo(DateTime.parse(a.createdAt!));
            }
            return 0; // Default order if no createdAt
          });

      debugPrint('Loaded ${projects.length} recent crowdfunding projects');
      return projects.take(3).toList();
    } else {
      throw Exception('Failed to load loan requests: ${response.statusCode}');
    }
  } catch (e, st) {
    debugPrint('Crowdfunding API error: ${e.toString()}');
    debugPrint('Crowdfunding API stack: ${st.toString()}');
    rethrow;
  }
}

// Helper for formatting currency
String formatNaira(num amount) {
  final formatter = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}

// Crop Availability Data Model
class CropAvailability {
  final String cropName;
  final String farmName;
  final String timeAgo;

  CropAvailability({
    required this.cropName,
    required this.farmName,
    required this.timeAgo,
  });
}

// Logistics Request Data Model
class LogisticsRequest {
  final String description;
  final String status;
  final String type;

  LogisticsRequest({
    required this.description,
    required this.status,
    required this.type,
  });
}

// Mock Logistics Request Data
final List<LogisticsRequest> mockLogisticsRequestsPreview = [
  LogisticsRequest(
    description: 'Pickup for 50 crates of tomatoes',
    status: 'Pending',
    type: 'Pickup',
  ),
  LogisticsRequest(
    description: 'Storage needed for pineapples',
    status: 'In Review',
    type: 'Storage',
  ),
];

// Simulated API Call
Future<List<LogisticsRequest>> fetchLogisticsRequestsPreview() async {
  await Future.delayed(const Duration(milliseconds: 500));
  return mockLogisticsRequestsPreview;
}

// --- Helper Functions ---

Color _getLogisticsStatusColor(String status) {
  switch (status) {
    case 'Pending':
      return Colors.green[600]!;
    case 'In Review':
      return Colors.purple[600]!;
    case 'Completed':
      return Colors.green;
    default:
      return Colors.grey;
  }
}

IconData _getLogisticsRequestIcon(String type) {
  switch (type) {
    case 'Pickup':
      return Icons.local_shipping;
    case 'Storage':
      return Icons.warehouse;
    case 'Delivery':
      return Icons.delivery_dining;
    default:
      return Icons.assignment;
  }
}

const String cloudFrontDomain = 'https://dqsnae4wms22.cloudfront.net';

String getCloudFrontImageUrl(String s3Key) {
  if (s3Key.isEmpty) return '';
  return '$cloudFrontDomain/$s3Key';
}

// --- HomeScreen Widget ---

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  bool _isUploadingPic = false;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final cognitoSession = session as CognitoAuthSession;
      final token = cognitoSession.userPoolTokensResult.value.idToken.raw;

      // Get user role from Cognito groups
      final payload = _parseJwt(token);
      List<String> groups = [];
      if (payload.containsKey('cognito:groups')) {
        final groupVal = payload['cognito:groups'];
        if (groupVal is List) {
          groups = List<String>.from(groupVal);
        } else if (groupVal is String) {
          groups = [groupVal];
        }
      }

      String? role;
      if (groups.contains('Farmers')) {
        role = 'Farmer';
      } else if (groups.contains('Investors')) {
        role = 'Investor';
      }

      final attributes = await Amplify.Auth.fetchUserAttributes();
      final emailAttr = attributes.firstWhereOrNull(
        (attr) => attr.userAttributeKey.key == 'email',
      );
      if (emailAttr == null) {
        setState(() {
          _userRole = role;
          _isLoading = false;
        });
        return;
      }
      final email = emailAttr.value;
      final response =
          await Amplify.API
              .get(
                '/profile',
                apiName: 'PoligrainAPI',
                queryParameters: {'username': email},
              )
              .response;
      final bodyString = response.decodeBody();
      final profileData = jsonDecode(bodyString);

      // Prefer role from profile (server truth) and fall back to Cognito groups
      String? profileRole;
      try {
        if (profileData is Map && profileData['role'] is String) {
          final r = (profileData['role'] as String).trim();
          if (r.isNotEmpty) profileRole = r;
        }
      } catch (_) {}

      final userProfile = app_model.UserProfile.fromJson({'item': profileData});
      UserProfileCache().updateUserProfile(userProfile);

      setState(() {
        _userRole = profileRole ?? role;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      debugPrint('API Error fetching user profile: ${e.message}');
      setState(() {
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Generic error fetching user profile: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper to decode JWT
  Map<String, dynamic> _parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('invalid token');
    }
    final payload = base64Url.normalize(parts[1]);
    final payloadMap = json.decode(utf8.decode(base64Url.decode(payload)));
    if (payloadMap is! Map<String, dynamic>) {
      throw Exception('invalid payload');
    }
    return payloadMap;
  }

  Future<void> _changeProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _isUploadingPic = true;
    });
    final file = File(pickedFile.path);
    final fileName =
        'profile_pictures/${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
    try {
      final uploadResult =
          await Amplify.Storage.uploadFile(
            localFile: AWSFile.fromPath(file.path),
            path: StoragePath.fromString(fileName),
          ).result;
      final s3Key = uploadResult.uploadedItem.path;
      final urlResult =
          await Amplify.Storage.getUrl(
            path: StoragePath.fromString(s3Key),
          ).result;
      final newProfilePicUrl = urlResult.url.toString();
      await _updateProfilePictureUrl(newProfilePicUrl);
      final userProfile = UserProfileCache().userProfile;
      if (userProfile != null) {
        setState(() {
          UserProfileCache().updateUserProfile(
            app_model.UserProfile(
              firstName: userProfile.firstName,
              lastName: userProfile.lastName,
              email: userProfile.email,
              phoneNumber: userProfile.phoneNumber,
              gender: userProfile.gender,
              address: userProfile.address,
              city: userProfile.city,
              postalCode: userProfile.postalCode,
              profilePicture: newProfilePicUrl,
              role: userProfile.role,
              owner: userProfile.owner,
            ),
          );
        });
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Profile picture updated!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload profile picture: $e')),
      );
    } finally {
      setState(() {
        _isUploadingPic = false;
      });
    }
  }

  Future<void> _updateProfilePictureUrl(String url) async {
    try {
      final session =
          await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
      final token = session.userPoolTokensResult.value.idToken.raw;
      // Send all fields to backend for update
      final response =
          await Amplify.API
              .put(
                '/profile',
                apiName: 'PoligrainAPI',
                body: HttpPayload.json({
                  'username': UserProfileCache().userProfile?.email ?? '',
                  'first_name': UserProfileCache().userProfile?.firstName ?? '',
                  'last_name': UserProfileCache().userProfile?.lastName ?? '',
                  'phone': UserProfileCache().userProfile?.phoneNumber ?? '',
                  'gender': UserProfileCache().userProfile?.gender ?? '',
                  'address': UserProfileCache().userProfile?.address ?? '',
                  'profile_image': url,
                }),
              )
              .response;
      if (response.statusCode != 200) {
        throw Exception('Failed to update profile picture');
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchUserProfile();
    setState(() {}); // Or reload other data as needed
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = UserProfileCache().userProfile;
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // Responsive breakpoints
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 600;
    final isLargeScreen = screenWidth >= 600;

    // Dynamic spacing and sizing
    final horizontalPadding = (screenWidth * 0.04).clamp(12.0, 24.0);
    final verticalSpacing = (screenHeight * 0.02).clamp(16.0, 32.0);
    // Slightly tighter section spacing for a compact, consistent layout
    final sectionSpacing = (screenHeight * 0.02).clamp(16.0, 32.0);

    // Avatar size based on screen
    final avatarRadius = (screenWidth * 0.06).clamp(20.0, 32.0);

    // Welcome text sizes
    final welcomeTextSize = (screenWidth * 0.035).clamp(12.0, 16.0);
    final nameTextSize = (screenWidth * 0.045).clamp(16.0, 22.0);

    return Material(
      color: Colors.white,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: ScrollConfiguration(
            behavior: SmoothScrollBehavior(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Top Bar: Profile, Welcome, Notification (responsive)
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      verticalSpacing * 0.75,
                      horizontalPadding,
                      verticalSpacing,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap:
                              userProfile == null
                                  ? null
                                  : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => EditProfileScreen(
                                              userProfile: userProfile,
                                            ),
                                      ),
                                    );
                                  },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              (userProfile != null &&
                                      userProfile.profilePicture.isNotEmpty)
                                  ? CircleAvatar(
                                    radius: avatarRadius,
                                    backgroundColor: Colors.green[700],
                                    backgroundImage: NetworkImage(
                                      userProfile.profilePicture,
                                    ),
                                    onBackgroundImageError: (_, __) {
                                      // fallback to default icon if image fails
                                    },
                                    child: null,
                                  )
                                  : CircleAvatar(
                                    radius: avatarRadius,
                                    backgroundColor: Colors.green[700],
                                    child: Icon(
                                      Icons.person,
                                      size: avatarRadius * 1.3,
                                      color: Colors.white,
                                    ),
                                  ),
                              if (_isUploadingPic)
                                Container(
                                  width: avatarRadius * 2,
                                  height: avatarRadius * 2,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: SizedBox(
                                      width: avatarRadius,
                                      height: avatarRadius,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(width: horizontalPadding * 0.5),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: TextStyle(
                                  fontSize: welcomeTextSize,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                _isLoading
                                    ? 'Loading...'
                                    : (userProfile != null &&
                                        userProfile.firstName.isNotEmpty)
                                    ? userProfile.firstName
                                    : 'Guest',
                                style: TextStyle(
                                  fontSize: nameTextSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            iconSize: (screenWidth * 0.06).clamp(20.0, 28.0),
                            icon: Icon(
                              Icons.notifications_none,
                              color: Colors.green[700],
                            ),
                            onPressed: () {
                              /* TODO: Navigate to notifications */
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main content with responsive padding
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_userRole == 'Farmer' || _userRole == null) ...[
                          // Farm Status Section (Placeholder for Farmer)
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            color: Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: Colors.green[700],
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Your Farm Status',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.analytics_outlined,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Stats
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(16.0),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.green[100]!,
                                              width: 1,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                '12',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green[700],
                                                ),
                                              ),
                                              Text(
                                                'Active Listings',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(16.0),
                                          decoration: BoxDecoration(
                                            color: Colors.green[50],
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.green[200]!,
                                              width: 1,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                '5',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green[700],
                                                ),
                                              ),
                                              Text(
                                                'Ongoing Deliveries',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
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
                          SizedBox(height: sectionSpacing),
                        ] else if (_userRole == 'Investor') ...[
                          // Portfolio Status Section (Placeholder for Investor)
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            color: Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: Colors.green[700],
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Your Portfolio',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.analytics_outlined,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Stats
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(16.0),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 1,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                '₦150,000',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green[700],
                                                ),
                                              ),
                                              Text(
                                                'Total Value',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(16.0),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 1,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                '3',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green[700],
                                                ),
                                              ),
                                              Text(
                                                'Active Investments',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
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
                          SizedBox(height: sectionSpacing),
                        ],

                        // Quick Actions: 4 compact tiles for Farmer
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(
                              color: Colors.white,
                              width: 1,
                            ),
                          ),
                          elevation: 2,
                          color: Colors.white,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: (screenHeight * 0.01).clamp(8.0, 14.0),
                              horizontal: (screenWidth * 0.02).clamp(8.0, 16.0),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.green[700],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Add Product
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const ProductCreateScreen(),
                                        ),
                                      );
                                    },
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.green[800],
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.add,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const SizedBox(
                                          width: 70,
                                          child: Text(
                                            'Add Product',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 10,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Logistics
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const LogisticsScreen(),
                                        ),
                                      );
                                    },
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.green[800],
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.local_shipping,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const SizedBox(
                                          width: 70,
                                          child: Text(
                                            'Logistics',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 10,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Crowdfund
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const CrowdfundingScreen(),
                                        ),
                                      );
                                    },
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.green[800],
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.volunteer_activism,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const SizedBox(
                                          width: 70,
                                          child: Text(
                                            'Crowdfund',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 10,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Market
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const marketplace.MarketplaceScreen(),
                                        ),
                                      );
                                    },
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.green[800],
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.store_mall_directory,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const SizedBox(
                                          width: 70,
                                          child: Text(
                                            'Market',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 10,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
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
                        SizedBox(height: sectionSpacing),

                        // Marketplace Preview Section with responsive height
                        _buildSectionHeader(context, 'Featured Products', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      const marketplace.MarketplaceScreen(),
                            ),
                          );
                        }),
                        SizedBox(height: verticalSpacing * 0.5),
                        SizedBox(
                          height: _getResponsiveCardHeight(
                            screenSize,
                            isProductCard: true,
                          ),
                          child: FutureBuilder<List<Product>>(
                            future: market.fetchFeaturedProducts(limit: 3),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              } else if (snapshot.hasError) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        size: 32,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Unable to load products',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      TextButton(
                                        onPressed: () {
                                          setState(
                                            () {},
                                          ); // Trigger rebuild to retry
                                        },
                                        child: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                );
                              } else if (!snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
                                return const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.shopping_basket_outlined,
                                        size: 32,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'No products available',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                final products = snapshot.data!;
                                return ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: horizontalPadding * 0.25,
                                  ),
                                  itemCount: products.length,
                                  itemBuilder:
                                      (context, index) =>
                                          _buildProductCard(products[index]),
                                );
                              }
                            },
                          ),
                        ),
                        SizedBox(height: sectionSpacing),
                      ],
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

  // Helper method to get responsive card heights
  double _getResponsiveCardHeight(
    Size screenSize, {
    required bool isProductCard,
  }) {
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    if (isProductCard) {
      // Reduced height for product cards
      return (screenHeight * 0.28).clamp(220.0, 320.0);
    } else {
      // This else block can be removed since we're not using project cards anymore
      return (screenHeight * 0.18).clamp(140.0, 200.0);
    }
  }

  // --- Builder Widgets (Moved for better organization) ---

  Widget _buildQuickActionButton(
    BuildContext context,
    IconData? icon,
    String label,
    VoidCallback onPressed, {
    bool isOnGreen = false,
    Widget? customIcon,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tileSize = (screenWidth * 0.12).clamp(48, 72).toDouble();
    final iconSize = (screenWidth * 0.07).clamp(18, 28).toDouble();
    final fontSize = (screenWidth * 0.032).clamp(12, 14).toDouble();
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.green[700],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: tileSize,
                  height: tileSize,
                  decoration: BoxDecoration(
                    color: Colors.green[800],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child:
                        customIcon ??
                        (icon != null
                            ? Icon(icon, size: iconSize, color: Colors.white)
                            : const SizedBox.shrink()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    VoidCallback onSeeAllPressed,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = (screenWidth * 0.045).clamp(15, 22).toDouble();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        TextButton(
          onPressed: onSeeAllPressed,
          child: Text(
            'See all',
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.6).clamp(180.0, 300.0).toDouble();
    // Reduce image height to 50% of card width
    final imageSize = (cardWidth * 0.5).toDouble();
    // Font sizes for text elements
    final nameFontSize = (screenWidth * 0.036).clamp(14, 17).toDouble();
    final categoryFontSize = (screenWidth * 0.028).clamp(11, 13).toDouble();
    final ownerFontSize = (screenWidth * 0.028).clamp(11, 13).toDouble();
    final priceFontSize = (screenWidth * 0.032).clamp(12, 15).toDouble();
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.only(right: 16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image container with gradient overlay
              Container(
                width: double.infinity,
                height: imageSize,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        getCloudFrontImageUrl(product.imageUrl),
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                              strokeWidth: 2,
                              color: Colors.green[700],
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.grey[400],
                            size: 32,
                          );
                        },
                      ),
                      // Subtle gradient overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.1),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Product details container
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name
                    Text(
                      product.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: nameFontSize,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),

                    // Category and owner info
                    if (product.category.isNotEmpty)
                      Text(
                        product.category,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: categoryFontSize,
                          height: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    if (product.owner != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'by ${product.owner}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: ownerFontSize,
                          height: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Price with currency and unit
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (product.unit != null && product.unit!.isNotEmpty)
                            ? '${formatNaira(product.price)} / ${product.unit}'
                            : formatNaira(product.price),
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                          fontSize: priceFontSize,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.62).clamp(180, 320).toDouble();
    final cardPadding = (screenWidth * 0.03).clamp(10, 20).toDouble();
    final nameFontSize = (screenWidth * 0.042).clamp(14, 20).toDouble();
    final infoFontSize = (screenWidth * 0.032).clamp(10, 15).toDouble();
    final progress =
        project.goal > 0
            ? (project.raised / project.goal).clamp(0.0, 1.0)
            : 0.0;

    // Get status color for recent campaigns
    Color statusColor = Colors.green[600]!;
    switch (project.status.toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange[600]!;
        break;
      case 'approved':
        statusColor = Colors.blue[600]!;
        break;
      case 'rejected':
        statusColor = Colors.red[600]!;
        break;
      default:
        statusColor = Colors.green[600]!;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CrowdfundingScreen()),
        );
      },
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.only(right: 16),
        child: Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Green header with status badge for recent campaigns
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: cardPadding,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF18813A),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        project.name,
                        style: TextStyle(
                          fontSize: nameFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        project.status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: infoFontSize - 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Goal: ${formatNaira(project.goal)}',
                          style: TextStyle(
                            fontSize: infoFontSize,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          'Min: ${formatNaira(project.minInvest)}',
                          style: TextStyle(
                            fontSize: infoFontSize,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      color: const Color(0xFF18813A),
                      minHeight: (screenWidth * 0.015).clamp(4, 8).toDouble(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${formatNaira(project.raised)} raised',
                          style: TextStyle(
                            fontSize: infoFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          '${project.returnPercent.toStringAsFixed(0)}% Return',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                            fontSize: infoFontSize,
                          ),
                        ),
                      ],
                    ),
                    if (project.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'New - Posted recently',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: infoFontSize - 2,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogisticsCard(BuildContext context, LogisticsRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(
              _getLogisticsRequestIcon(request.type),
              size: 20,
              color: Colors.green[700],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.description,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Status: ${request.status}',
                    style: TextStyle(
                      color: _getLogisticsStatusColor(request.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoxPlusIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.inventory_2_outlined, size: 36, color: Colors.white),
        Positioned(
          bottom: 2,
          right: 2,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green[700],
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(2),
            child: Icon(Icons.add, size: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
