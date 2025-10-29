import 'package:flutter/material.dart';
import 'package:poligrain_app/screens/home/home_screen.dart';
import 'package:poligrain_app/screens/marketplace/marketplace_screen.dart';
import 'package:poligrain_app/screens/crowdfunding/crowdfunding_screen.dart';
import 'package:poligrain_app/screens/logistics/logistics_screen.dart';
import 'package:poligrain_app/screens/marketplace/crop_availability_screen.dart';
import 'package:poligrain_app/screens/auth/login_screen.dart';
import 'package:poligrain_app/screens/auth/change_password_screen.dart';
import 'package:poligrain_app/screens/profile/profile_setup_screen.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:poligrain_app/services/auth_service.dart';
import 'dart:convert';
import 'package:poligrain_app/models/user_profile.dart' as app_model;
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'services/user_profile_cache.dart';

// Placeholder for a Profile screen
// Convert to StatefulWidget to manage data fetching state
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

// Simulated function to fetch user profile data
Future<app_model.UserProfile> fetchUserProfile() async {
  final authService = AuthService();
  final user = await authService.getCurrentUser();
  final attributes = await authService.fetchUserAttributes();
  final email = attributes['email'] ?? user?.username;
  if (email == null) {
    throw Exception('No email/username found for user');
  }

  // Fetch profile from backend API (DynamoDB)
  // Let Amplify handle authentication automatically
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
  return app_model.UserProfile.fromJson({'item': profileData});
}

// --- Add EditProfileScreen ---
class EditProfileScreen extends StatefulWidget {
  final app_model.UserProfile userProfile;
  const EditProfileScreen({super.key, required this.userProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _genderController;
  late TextEditingController _addressController;
  String? _profilePictureUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.userProfile.firstName,
    );
    _lastNameController = TextEditingController(
      text: widget.userProfile.lastName,
    );
    _emailController = TextEditingController(
      text: widget.userProfile.email ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.userProfile.phoneNumber ?? '',
    );
    _genderController = TextEditingController(
      text: widget.userProfile.gender ?? '',
    );
    _addressController = TextEditingController(
      text: widget.userProfile.address ?? '',
    );
    _profilePictureUrl = widget.userProfile.profilePicture;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _genderController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    setState(() {
      _isUploading = true;
    });
    final file = File(pickedFile.path);
    final fileName =
        'profile_pictures/${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
    final oldProfilePicUrl = _profilePictureUrl; // Save before updating
    try {
      final uploadResult =
          await Amplify.Storage.uploadFile(
            localFile: AWSFile.fromPath(file.path),
            path: StoragePath.fromString(fileName),
          ).result;
      final s3Key = uploadResult.uploadedItem.path;
      // Construct the public S3 URL (without query params)
      final bucketUrl =
          'https://poligrainstorage85a4b-dev.s3.us-east-1.amazonaws.com/';
      final publicProfilePicUrl = bucketUrl + s3Key;
      // Update backend profile_image field
      try {
        final response =
            await Amplify.API
                .put(
                  '/profile',
                  apiName: 'PoligrainAPI',
                  body: HttpPayload.json({
                    'username': widget.userProfile.email,
                    'first_name': widget.userProfile.firstName,
                    'last_name': widget.userProfile.lastName,
                    'phone': widget.userProfile.phoneNumber,
                    'gender': widget.userProfile.gender,
                    'address': widget.userProfile.address,
                    'profile_image': publicProfilePicUrl,
                  }),
                )
                .response;
        if (response.statusCode != 200) {
          throw Exception('Failed to update profile image in backend');
        }
      } catch (e) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update backend: $e')));
        return;
      }
      setState(() {
        _profilePictureUrl = publicProfilePicUrl;
        _isUploading = false;
      });
      final cache = UserProfileCache();
      if (cache.userProfile != null) {
        cache.updateUserProfile(
          cache.userProfile!.copyWith(profilePicture: publicProfilePicUrl),
        );
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile picture updated!')));

      // --- Delete old profile image from S3 if needed ---
      if (oldProfilePicUrl != null && oldProfilePicUrl.isNotEmpty) {
        final oldS3Key = _extractS3KeyFromUrl(oldProfilePicUrl);
        if (oldS3Key != null && oldS3Key.startsWith('profile_pictures/')) {
          try {
            await Amplify.Storage.remove(
              path: StoragePath.fromString(oldS3Key),
            ).result;
            print('Old profile image deleted from S3: $oldS3Key');
          } catch (e) {
            print('Failed to delete old profile image: $e');
          }
        }
      }
      // --- End delete logic ---
      // Pop and signal update to parent
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload profile picture: $e')),
      );
    }
  }

  // Helper to extract S3 key from a full S3 URL
  String? _extractS3KeyFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final path = uri.path;
    if (path.startsWith('/')) {
      return path.substring(1);
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Custom Top Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(0, 48, 0, 16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.green[700],
                    size: 28,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: Colors.green[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar with edit icon overlay
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 54,
                            backgroundColor: Colors.grey[300],
                            backgroundImage:
                                (_profilePictureUrl != null &&
                                        _profilePictureUrl!.isNotEmpty)
                                    ? NetworkImage(_profilePictureUrl!)
                                    : const AssetImage(
                                      'assets/images/default.jpg',
                                    ),
                            child:
                                (_profilePictureUrl == null ||
                                        _profilePictureUrl!.isEmpty)
                                    ? const Icon(
                                      Icons.person,
                                      size: 64,
                                      color: Colors.white,
                                    )
                                    : null,
                          ),
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap:
                                  _isUploading
                                      ? null
                                      : _pickAndUploadProfileImage,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.green[700],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                padding: const EdgeInsets.all(4),
                                child:
                                    _isUploading
                                        ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                        : const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Full Name (read-only)
                    _buildLabel('Full Name'),
                    const SizedBox(height: 4),
                    _buildReadOnlyField(
                      '${widget.userProfile.firstName} ${widget.userProfile.lastName}',
                    ),
                    const SizedBox(height: 18),
                    // Email (read-only)
                    _buildLabel('Email'),
                    const SizedBox(height: 4),
                    _buildReadOnlyField(widget.userProfile.email ?? ''),
                    const SizedBox(height: 18),
                    // Phone Number (read-only)
                    _buildLabel('Phone Number'),
                    const SizedBox(height: 4),
                    _buildReadOnlyField(widget.userProfile.phoneNumber ?? ''),
                    const SizedBox(height: 18),
                    // Gender (read-only)
                    _buildLabel('Gender'),
                    const SizedBox(height: 4),
                    _buildReadOnlyField(widget.userProfile.gender ?? ''),
                    const SizedBox(height: 18),
                    // Address (read-only)
                    _buildLabel('Address'),
                    const SizedBox(height: 4),
                    _buildReadOnlyField(widget.userProfile.address ?? ''),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Save',
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
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const Text(
          ' *',
          style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String value) {
    return TextField(
      controller: TextEditingController(text: value),
      readOnly: true,
      decoration: InputDecoration(
        border: InputBorder.none,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
      style: const TextStyle(fontSize: 16, color: Colors.black87),
    );
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _userRole;
  bool _isLoadingProfile = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    _fetchAndCacheUserProfile();
  }

  Future<void> _fetchUserRole() async {
    try {
      final session =
          await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
      final idToken = session.userPoolTokensResult.value.idToken.raw;
      final payload = _parseJwt(idToken);
      List<String> groups = [];
      if (payload.containsKey('cognito:groups')) {
        final groupVal = payload['cognito:groups'];
        if (groupVal is List) {
          groups = List<String>.from(groupVal);
        } else if (groupVal is String) {
          groups = [groupVal];
        }
      }
      if (groups.contains('Farmers')) {
        setState(() => _userRole = 'Farmer');
      } else if (groups.contains('Investors')) {
        setState(() => _userRole = 'Investor');
      } else {
        setState(() => _userRole = 'User');
      }
    } catch (e) {
      setState(() => _userRole = null);
    }
  }

  Future<void> _fetchAndCacheUserProfile() async {
    try {
      setState(() {
        _isLoadingProfile = true;
        _errorMessage = null;
      });

      final userProfile = await fetchUserProfile();
      UserProfileCache().updateUserProfile(userProfile);

      setState(() {
        _isLoadingProfile = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingProfile = false;
        _errorMessage = 'Failed to load profile: $e';
      });
    }
  }

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

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while fetching profile
    if (_isLoadingProfile) {
      return SizedBox.expand(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Show error message if profile fetch failed
    if (_errorMessage != null) {
      return SizedBox.expand(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchAndCacheUserProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final userProfile = UserProfileCache().userProfile;
    if (userProfile == null) {
      return SizedBox.expand(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'No profile data found. Please complete your profile.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  try {
                    // Get current user email
                    final authService = AuthService();
                    final user = await authService.getCurrentUser();
                    final attributes = await authService.fetchUserAttributes();
                    final email = attributes['email'] ?? user?.username ?? '';

                    // Navigate to profile setup screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileSetupScreen(email: email),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Complete Profile'),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.green[50]!, Colors.grey[100]!],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  // Avatar Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.green[100]!,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.07),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 48.0,
                          horizontal: 8.0,
                        ),
                        child: Column(
                          children: [
                            Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.green[200]!,
                                    width: 3,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 48,
                                  backgroundColor: Colors.green[50],
                                  backgroundImage:
                                      userProfile.profilePicture.isNotEmpty
                                          ? NetworkImage(
                                            userProfile.profilePicture,
                                          )
                                          : const AssetImage(
                                            'assets/images/default_profile.png',
                                          ),
                                  child:
                                      userProfile.profilePicture.isEmpty
                                          ? const Icon(
                                            Icons.person,
                                            size: 56,
                                            color: Colors.green,
                                          )
                                          : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "${userProfile.firstName} ${userProfile.lastName}",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Lato',
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _userRole != null ? _userRole! : '',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Lato',
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: 140,
                              child: OutlinedButton(
                                onPressed: () async {
                                  final updated = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => EditProfileScreen(
                                            userProfile: userProfile,
                                          ),
                                    ),
                                  );
                                  if (updated == true) {
                                    setState(
                                      () {},
                                    ); // Refresh to show new profile picture
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(color: Colors.green[300]!),
                                  foregroundColor: Colors.green[700],
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: const Text('Edit Profile'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Card with menu items
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      color: Colors.white,
                      child: Column(
                        children: [
                          _buildProfileMenuItem(
                            context,
                            Icons.verified_user_rounded,
                            'Verification',
                            () {},
                            trailing: Icon(
                              Icons.check_circle,
                              color: Colors.green[400],
                              size: 20,
                            ),
                          ),
                          _buildDivider(),
                          _buildProfileMenuItem(
                            context,
                            Icons.settings,
                            'Settings',
                            () {},
                          ),
                          _buildDivider(),
                          _buildProfileMenuItem(
                            context,
                            Icons.lock_outline,
                            'Change password',
                            () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ChangePasswordScreen(),
                                ),
                              );
                              if (result == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Password changed successfully!',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          _buildDivider(),
                          _buildProfileMenuItem(
                            context,
                            Icons.card_giftcard,
                            'Refer friends',
                            () {},
                          ),
                          _buildDivider(),
                          _buildProfileMenuItem(
                            context,
                            Icons.logout,
                            'Sign out',
                            () async {
                              final shouldLogout = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Sign out'),
                                    content: const Text(
                                      'Are you sure you want to sign out?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(
                                              context,
                                            ).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () =>
                                                Navigator.of(context).pop(true),
                                        child: const Text('Sign out'),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (shouldLogout == true) {
                                try {
                                  await AuthService().signOut();
                                  if (mounted) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const LoginScreen(),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error signing out: $e'),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            trailing: null,
                            iconColor: Colors.red[400],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() => const Divider(height: 0, indent: 16, endIndent: 16);

  Widget _buildProfileMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    Widget? trailing,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 18.0),
        child: Row(
          children: [
            Icon(icon, size: 24, color: iconColor ?? Colors.grey[700]),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing ??
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
          ],
        ),
      ),
    );
  }
}

// Placeholder for a general Crops screen if CropAvailabilityScreen is a subsection,
// otherwise CropAvailabilityScreen can be used directly for the tab.
class CropsScreen extends StatelessWidget {
  const CropsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Crops Screen (or navigate to Crop Availability)'),
    );
  }
}

// Global connectivity banner widget
class ConnectivityBanner extends StatefulWidget {
  final Widget child;
  const ConnectivityBanner({required this.child, super.key});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  bool _isOffline = false;
  late final Connectivity _connectivity;
  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      setState(() {
        _isOffline =
            results.isEmpty ||
            results.every((r) => r == ConnectivityResult.none);
      });
    });
    // Initial check
    _connectivity.checkConnectivity().then((result) {
      setState(() {
        _isOffline = result == ConnectivityResult.none;
      });
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isOffline) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            duration: const Duration(
              days: 1,
            ), // stays until dismissed or online
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(top: 24, left: 24, right: 24),
            content: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              decoration: BoxDecoration(
                color: Colors.red[600],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'No Internet Connection',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
      }
    });
    return widget.child;
  }
}

class MainScreenWrapper extends StatefulWidget {
  const MainScreenWrapper({super.key});

  @override
  _MainScreenWrapperState createState() => _MainScreenWrapperState();
}

class _MainScreenWrapperState extends State<MainScreenWrapper> {
  int _selectedIndex = 0;
  DateTime? _lastBackPressed;

  // List of screens for the bottom navigation bar
  final List<Widget> _screens = [
    const HomeScreen(),
    const MarketplaceScreen(),
    const CrowdfundingScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityBanner(
      child: WillPopScope(
        onWillPop: () async {
          final now = DateTime.now();
          if (_lastBackPressed == null ||
              now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
            _lastBackPressed = now;
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(bottom: 20, left: 24, right: 24),
                content: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Click again to exit',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        letterSpacing: 0.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );
            return false;
          }
          return true;
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: IndexedStack(index: _selectedIndex, children: _screens),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Market'),
              BottomNavigationBarItem(
                icon: Icon(Icons.trending_up),
                label: 'Crowdfunding',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.green[800],
            type: BottomNavigationBarType.fixed,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }
}
