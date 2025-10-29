import 'dart:convert';
import 'dart:io';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../common/success_screen.dart';
import '../../main_screen_wrapper.dart';
import '../../services/auth_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String email;
  const ProfileSetupScreen({super.key, required this.email});

  @override
  _ProfileSetupScreenState createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  int _currentPage = 0;
  final PageController _pageController = PageController();
  bool _isCheckingProfile = true;

  String? _selectedGender;
  String? _selectedState;
  String? _selectedLga;
  String? _selectedRole;

  Map<String, dynamic> _dropdownData = {};
  List<String> _genders = [];
  List<String> _roles = [];
  Map<String, List<String>> _nigerianStatesAndLgas = {};

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkProfileCompletion();
  }

  Future<void> _checkProfileCompletion() async {
    try {
      debugPrint('🔍 ProfileSetupScreen: Starting profile completion check');
      final authService = AuthService();
      final profile = await authService.fetchUserProfile();

      if (!mounted) return;

      if (profile == null) {
        debugPrint(
          '❌ ProfileSetupScreen: Profile is null, showing setup screen',
        );
        await _loadDropdownData();
        if (mounted) {
          setState(() => _isCheckingProfile = false);
        }
        return;
      }

      // Log the entire profile for debugging
      debugPrint('📋 ProfileSetupScreen: Raw profile data: $profile');

      // Check if profile_complete field exists
      if (!profile.containsKey('profile_complete')) {
        debugPrint(
          '❌ ProfileSetupScreen: profile_complete field not found in profile',
        );
        debugPrint(
          '📋 ProfileSetupScreen: Available fields: ${profile.keys.toList()}',
        );
        await _loadDropdownData();
        if (mounted) {
          setState(() => _isCheckingProfile = false);
        }
        return;
      }

      final profileCompleteValue = profile['profile_complete'];
      debugPrint(
        '🔍 ProfileSetupScreen: profile_complete value: $profileCompleteValue (type: ${profileCompleteValue.runtimeType})',
      );

      // Handle different data types (boolean vs string)
      bool isComplete = false;

      if (profileCompleteValue is bool) {
        isComplete = profileCompleteValue;
        debugPrint(
          '✅ ProfileSetupScreen: profile_complete is boolean: $isComplete',
        );
      } else if (profileCompleteValue is String) {
        // Handle string values
        if (profileCompleteValue.toLowerCase() == 'true') {
          isComplete = true;
          debugPrint(
            '✅ ProfileSetupScreen: profile_complete is string "true", converted to: $isComplete',
          );
        } else if (profileCompleteValue.toLowerCase() == 'false') {
          isComplete = false;
          debugPrint(
            '❌ ProfileSetupScreen: profile_complete is string "false", converted to: $isComplete',
          );
        } else {
          debugPrint(
            '⚠️ ProfileSetupScreen: profile_complete is string but not "true" or "false": "$profileCompleteValue"',
          );
          isComplete = false;
        }
      } else {
        debugPrint(
          '⚠️ ProfileSetupScreen: profile_complete is unexpected type: ${profileCompleteValue.runtimeType}',
        );
        // Try to convert to boolean as fallback
        try {
          isComplete = profileCompleteValue.toString().toLowerCase() == 'true';
          debugPrint(
            '🔄 ProfileSetupScreen: Converted to boolean as fallback: $isComplete',
          );
        } catch (e) {
          debugPrint(
            '❌ ProfileSetupScreen: Failed to convert profile_complete to boolean: $e',
          );
          isComplete = false;
        }
      }

      if (isComplete) {
        // Profile exists and is complete, redirect to main screen
        debugPrint(
          '🎯 ProfileSetupScreen: Profile is complete, redirecting to main screen',
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreenWrapper()),
        );
        return;
      }

      // Profile exists but is not complete, show setup screen
      debugPrint(
        '❌ ProfileSetupScreen: Profile exists but is not complete, showing setup screen',
      );
      await _loadDropdownData();
      if (mounted) {
        setState(() => _isCheckingProfile = false);
      }
    } catch (e) {
      debugPrint('❌ ProfileSetupScreen: Error checking profile completion: $e');
      // On network/API errors, assume profile might exist and redirect to main screen
      // This prevents users from being stuck in profile setup due to temporary issues
      if (e.toString().contains('404') ||
          e.toString().contains('Profile not found')) {
        // 404 means profile doesn't exist, show setup screen
        debugPrint(
          '🔄 ProfileSetupScreen: Profile not found (404), showing setup screen',
        );
        await _loadDropdownData();
        if (mounted) {
          setState(() => _isCheckingProfile = false);
        }
      } else {
        // Other errors (network, etc.) - assume profile might be complete
        debugPrint(
          '🔄 ProfileSetupScreen: Network/API error, assuming profile might be complete and redirecting to main screen',
        );
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreenWrapper()),
          );
        }
      }
    }
  }

  Future<void> _loadDropdownData() async {
    try {
      final String jsonString = await DefaultAssetBundle.of(
        context,
      ).loadString('assets/data/dropdown_data.json');
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);

      if (!mounted) return;
      setState(() {
        _dropdownData = jsonData;
        _genders = List<String>.from(jsonData['genders'] ?? []);
        _roles = List<String>.from(jsonData['roles'] ?? []);
        _nigerianStatesAndLgas = Map<String, List<String>>.from(
          (jsonData['nigerianStatesAndLgas'] as Map<String, dynamic>?)?.map(
                (key, value) => MapEntry(key, List<String>.from(value ?? [])),
              ) ??
              {},
        );
      });
    } catch (e) {
      debugPrint("Error loading dropdown data: $e");
      if (!mounted) return;
      setState(() {
        _errorMessage = "Failed to load necessary data. Please try again.";
      });
    }
  }

  // Helper method for consistent InputDecoration
  InputDecoration _buildInputDecoration({
    String? hintText,
    String? prefixText,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixText: prefixText,
      filled: true,
      // use a neutral light grey fill for a clean white-card look
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.green.shade600, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 16.0,
        horizontal: 16.0,
      ),
      labelStyle: TextStyle(
        color: Colors.grey.shade800,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Future<void> _saveProfile() async {
    final session = await Amplify.Auth.fetchAuthSession();
    if (!session.isSignedIn) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'You must be signed in to complete your profile.';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;
    setState(() {
      _errorMessage = '';
    });

    try {
      if (widget.email.isEmpty) {
        throw Exception('Email is required');
      }

      String? profileImageUrl;
      if (_profileImage != null) {
        profileImageUrl = await _uploadProfileImage(_profileImage!);
      }

      final profileData = {
        'username': widget.email,
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'phone': _phoneController.text,
        'gender': _selectedGender ?? '',
        'state': _selectedState ?? '',
        'lga': _selectedLga ?? '',
        'address': _addressController.text,
        'city': _cityController.text,
        'postal_code': _postalCodeController.text,
        'role': _selectedRole ?? '',
        'profile_complete': true,
        if (profileImageUrl != null) 'profile_image': profileImageUrl,
      };

      debugPrint('Sending profile data: ${jsonEncode(profileData)}');

      final authSession = await Amplify.Auth.fetchAuthSession();
      final cognitoSession = authSession as CognitoAuthSession;
      final token = cognitoSession.userPoolTokensResult.value.idToken.raw;

      final response =
          await Amplify.API
              .put(
                '/profile',
                apiName: 'PoligrainAPI',
                body: HttpPayload.json(profileData),
              )
              .response;

      final bodyString = response.decodeBody();
      final responseBody = jsonDecode(bodyString);

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: $bodyString');

      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Profile saved: $responseBody');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SuccessScreen()),
        );
      } else {
        setState(() {
          _errorMessage =
              '❌ Failed with status ${response.statusCode}: ${responseBody['message'] ?? 'Unknown error'}';
          if (responseBody['error'] != null) {
            _errorMessage = '${_errorMessage!} (${responseBody['error']})';
          }
        });
      }
    } on ApiException catch (e) {
      debugPrint('API Exception: ${e.message}');
      if (e.recoverySuggestion != null) {
        debugPrint('Recovery suggestion: ${e.recoverySuggestion}');
      }
      if (e.underlyingException != null) {
        debugPrint('Underlying exception: ${e.underlyingException}');
      }
      if (!mounted) return;
      setState(() {
        _errorMessage = '❌ API Error: ${e.message}';
      });
    } catch (e, stackTrace) {
      debugPrint('Unexpected error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _errorMessage = '❌ Unexpected error: $e';
      });
    }
  }

  void _nextPage() {
    if (_formKey.currentState!.validate()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _pickProfileImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (!mounted) return;
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadProfileImage(File imageFile) async {
    try {
      final String imageFileName =
          'profile_pictures/${widget.email}_${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';

      final uploadOp = Amplify.Storage.uploadFile(
        localFile: AWSFile.fromPath(imageFile.path),
        path: StoragePath.fromString(imageFileName),
      );
      final StorageUploadFileResult result = await uploadOp.result;

      const bucketUrl =
          'https://poligrainstorage85a4b-dev.s3.us-east-1.amazonaws.com/'; // Consider making this configurable
      final publicProfilePicUrl = bucketUrl + result.uploadedItem.path;
      return publicProfilePicUrl;
    } on StorageException catch (e) {
      debugPrint('Storage Exception: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Failed to upload image: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while checking profile completion
    if (_isCheckingProfile) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 16),
                Text(
                  "Checking profile status...",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Complete Your Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B5E20),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.green.shade800,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF3F5F7),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 20.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18.0,
                    horizontal: 12.0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: List.generate(
                        5,
                        (index) => Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color:
                                  _currentPage >= index
                                      ? Colors.green.shade400
                                      : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      if (!mounted) return;
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      _buildProfileImagePage(),
                      _buildNamePage(),
                      _buildContactDetailsPage(),
                      _buildLocationDetailsPage(),
                      _buildRolePage(),
                    ],
                  ),
                ),
                if (_errorMessage != null && _errorMessage!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 12.0,
                      bottom: 8.0,
                      left: 16.0,
                      right: 16.0,
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom:
              MediaQuery.of(context).viewInsets.bottom +
              10.0, // Add 10.0 for a small gap
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade200, width: 1.0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentPage > 0)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ElevatedButton(
                      onPressed: _previousPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        side: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        'Previous',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: _currentPage > 0 ? 8.0 : 0),
                  child: ElevatedButton(
                    onPressed: _currentPage == 4 ? _saveProfile : _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      _currentPage == 4 ? 'Complete Setup' : 'Next',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImagePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                color: Colors.green.shade700,
                size: 26,
              ),
              const SizedBox(width: 10),
              Text(
                'Profile Picture',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green.shade300, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.15),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: _pickProfileImage,
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.green.shade100,
                      backgroundImage:
                          _profileImage != null
                              ? FileImage(_profileImage!)
                              : null,
                      child:
                          _profileImage == null
                              ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt_outlined,
                                    size: 40,
                                    color: Colors.green.shade600,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to add photo',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                              : null,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Add a profile picture to personalize your account',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildNamePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: Colors.green.shade700,
                size: 26,
              ),
              const SizedBox(width: 10),
              Text(
                'Your Name',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildLabel('First Name'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _firstNameController,
            decoration: _buildInputDecoration(
              hintText: 'Enter your first name',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your first name';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildLabel('Last Name'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _lastNameController,
            decoration: _buildInputDecoration(hintText: 'Enter your last name'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your last name';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBasicDetailsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_pin_outlined,
                color: Colors.green.shade700,
                size: 26,
              ),
              const SizedBox(width: 10),
              Text(
                'Basic Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green.shade300, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.15),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: _pickProfileImage,
                    child: CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.green.shade100,
                      backgroundImage:
                          _profileImage != null
                              ? FileImage(_profileImage!)
                              : null,
                      child:
                          _profileImage == null
                              ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt_outlined,
                                    size: 36,
                                    color: Colors.green.shade600,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Add Photo',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                              : null,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildLabel('First Name'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _firstNameController,
            decoration: _buildInputDecoration(hintText: 'Enter First Name'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your first name';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildLabel('Last Name'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _lastNameController,
            decoration: _buildInputDecoration(hintText: 'Enter Last Name'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your last name';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          if (_genders.isNotEmpty) ...[
            _buildLabel('Gender'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: _buildInputDecoration(hintText: 'Select Gender'),
              value: _selectedGender,
              items:
                  _genders.map((String gender) {
                    return DropdownMenuItem<String>(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
              onChanged: (value) {
                if (!mounted) return;
                setState(() {
                  _selectedGender = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select your gender';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _buildContactDetailsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.contact_phone_outlined,
                color: Colors.green.shade700,
                size: 26,
              ),
              const SizedBox(width: 10),
              Text(
                'Contact Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildLabel('Phone Number'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            decoration: _buildInputDecoration(
              hintText: 'e.g. 8123456789',
              prefixText: '+234 ',
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              if (!RegExp(r'^\d{1,11}$').hasMatch(value)) {
                // allow up to 11 digits after the +234 prefix
                return 'Enter up to 11 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          if (_genders.isNotEmpty) ...[
            _buildLabel('Gender'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: _buildInputDecoration(hintText: 'Select your gender'),
              value: _selectedGender,
              items:
                  _genders.map((String gender) {
                    return DropdownMenuItem<String>(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
              onChanged: (value) {
                if (!mounted) return;
                setState(() {
                  _selectedGender = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select your gender';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLocationDetailsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: Colors.green.shade700,
                size: 26,
              ),
              const SizedBox(width: 10),
              Text(
                'Location & Role',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_nigerianStatesAndLgas.keys.isNotEmpty) ...[
            _buildLabel('State'),
            const SizedBox(height: 8),
            SizedBox(
              height: 56,
              child: DropdownButtonFormField<String>(
                decoration: _buildInputDecoration(
                  hintText: 'Select your state',
                ),
                value: _selectedState,
                isExpanded: true,
                items:
                    _nigerianStatesAndLgas.keys.map((String state) {
                      return DropdownMenuItem<String>(
                        value: state,
                        child: Text(state, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (!mounted) return;
                  setState(() {
                    _selectedState = value;
                    _selectedLga = null;
                  });
                },
                validator:
                    (value) => value == null ? 'Please select a state' : null,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (_selectedState != null &&
              _nigerianStatesAndLgas[_selectedState!] != null &&
              _nigerianStatesAndLgas[_selectedState!]!.isNotEmpty) ...[
            _buildLabel('Local Government Area'),
            const SizedBox(height: 8),
            SizedBox(
              height: 56,
              child: DropdownButtonFormField<String>(
                decoration: _buildInputDecoration(hintText: 'Select your LGA'),
                value: _selectedLga,
                isExpanded: true,
                items:
                    _nigerianStatesAndLgas[_selectedState!]!.map((String lga) {
                      return DropdownMenuItem<String>(
                        value: lga,
                        child: Text(lga, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (!mounted) return;
                  setState(() {
                    _selectedLga = value;
                  });
                },
                validator:
                    (value) => value == null ? 'Please select an LGA' : null,
              ),
            ),
          ] else if (_selectedState != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No LGAs available for $_selectedState or LGAs not loaded.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildLabel('City'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _cityController,
            decoration: _buildInputDecoration(hintText: 'Enter your city'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your city';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildLabel('Home Address'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _addressController,
            decoration: _buildInputDecoration(
              hintText: 'Enter your complete home address',
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildLabel('Postal Code'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _postalCodeController,
            decoration: _buildInputDecoration(
              hintText: 'Enter postal code (optional)',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRolePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.work_outline, color: Colors.green.shade700, size: 26),
              const SizedBox(width: 10),
              Text(
                'Choose Your Role',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (_roles.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    'What best describes you?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This helps us personalize your experience',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ..._roles.map((String role) {
                    final isSelected = _selectedRole == role;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () {
                          if (!mounted) return;
                          setState(() {
                            _selectedRole = role;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? Colors.green.shade600
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? Colors.green.shade600
                                      : Colors.grey.shade300,
                              width: 2,
                            ),
                            boxShadow:
                                isSelected
                                    ? [
                                      BoxShadow(
                                        color: Colors.green.shade200,
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                    : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                role == 'Farmer'
                                    ? Icons.agriculture
                                    : Icons.trending_up,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : Colors.green.shade600,
                                size: 28,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      role,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      role == 'Farmer'
                                          ? 'Grow and sell agricultural products'
                                          : 'Invest in agricultural opportunities',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            isSelected
                                                ? Colors.white.withOpacity(0.9)
                                                : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
