import 'dart:convert';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'success_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String email;
  const ProfileSetupScreen({super.key, required this.email});

  @override
  _ProfileSetupScreenState createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  int _currentPage = 0;
  final PageController _pageController = PageController();

  String? _selectedGender;
  String? _selectedState;
  String? _selectedLga;
  String? _selectedRole;

  Map<String, dynamic> _dropdownData = {};
  List<String> _genders = [];
  List<String> _roles = [];
  Map<String, List<String>> _nigerianStatesAndLgas = {};

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    final String jsonString =
    await DefaultAssetBundle.of(context).loadString('assets/data/dropdown_data.json');
    final Map<String, dynamic> jsonData = jsonDecode(jsonString);

    setState(() {
      _dropdownData = jsonData;
      _genders = List<String>.from(jsonData['genders']);
      _roles = List<String>.from(jsonData['roles']);
      _nigerianStatesAndLgas = Map<String, List<String>>.from(
        jsonData['nigerianStatesAndLgas'].map(
              (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      );
    });
  }

  Future<void> _saveProfile() async {
    // Check if the user is signed in
    final session = await Amplify.Auth.fetchAuthSession();
    if (!session.isSignedIn) {
      setState(() {
        _errorMessage = 'You must be signed in to complete your profile.';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = '';
    });

    try {
      if (widget.email.isEmpty) {
        throw Exception('Email is required');
      }

      final profileData = {
        'username': widget.email,
        'name': _nameController.text,
        'phone': _phoneController.text,
        'gender': _selectedGender ?? '',
        'state': _selectedState ?? '',
        'lga': _selectedLga ?? '',
        'address': _addressController.text,
        'role': _selectedRole ?? '',
        'profile_complete': true,
      };

      debugPrint('Sending profile data: ${jsonEncode(profileData)}');

      // Get the current auth session
      final authSession = await Amplify.Auth.fetchAuthSession();
      debugPrint('Auth session: ${authSession.isSignedIn}');
      
      // Get the authentication token
      final cognitoSession = authSession as CognitoAuthSession;
      final token = cognitoSession.userPoolTokensResult.value.idToken.raw;
      debugPrint('Token available: ${token != null}');

      final response = await Amplify.API.post(
        '/profile',
        apiName: 'PoligrainAPI',
        body: HttpPayload.json(profileData),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).response;

      final bodyString = response.decodeBody();
      final responseBody = jsonDecode(bodyString);
      
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: $bodyString');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Profile saved: $responseBody');

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SuccessScreen()),
        );
      } else {
        setState(() {
          _errorMessage =
          '❌ Failed with status ${response.statusCode}: ${responseBody['message'] ?? 'Unknown error'}';
          if (responseBody['error'] != null) {
            _errorMessage = ' (${responseBody['error']})';
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
      setState(() {
        _errorMessage = '❌ API Error: ${e.message}';
      });
    } catch (e, stackTrace) {
      debugPrint('Unexpected error: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = '❌ Unexpected error: $e';
      });
    }
  }

  void _nextPage() {
    if (_formKey.currentState!.validate()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Setup'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              _buildBasicDetailsPage(),
              _buildContactDetailsPage(),
              _buildLocationDetailsPage(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 70.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentPage > 0)
              ElevatedButton(
                onPressed: _previousPage,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                child: const Text('Back'),
              ),
            if (_currentPage < 2)
              ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Next'),
              ),
            if (_currentPage == 2)
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Save Profile'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicDetailsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.person, color: Colors.green),
            SizedBox(width: 8),
            Text('Basic details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 20),
        const Text('ENTER FULL NAME', style: TextStyle(fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          decoration: _buildInputDecoration(),
          validator: (value) => value!.isEmpty ? 'Enter your name' : null,
        ),
        const SizedBox(height: 20),
        const Text('GENDER', style: TextStyle(fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          hint: const Text('Select Gender'),
          decoration: _buildInputDecoration(),
          items: _genders.map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
          onChanged: (value) => setState(() => _selectedGender = value),
          validator: (value) => value == null ? 'Select your gender' : null,
        ),
      ],
    );
  }

  Widget _buildContactDetailsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.phone, color: Colors.green),
            SizedBox(width: 8),
            Text('Contact details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 20),
        const Text('PHONE NUMBER', style: TextStyle(fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          decoration: _buildInputDecoration(prefixText: '(+234) '),
          keyboardType: TextInputType.phone,
          validator: (value) => value!.isEmpty ? 'Enter your phone number' : null,
        ),
        const SizedBox(height: 20),
        const Text('I AM', style: TextStyle(fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedRole,
          hint: const Text('Select Role'),
          decoration: _buildInputDecoration(),
          items: _roles.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
          onChanged: (value) => setState(() => _selectedRole = value),
          validator: (value) => value == null ? 'Select your role' : null,
        ),
      ],
    );
  }

  Widget _buildLocationDetailsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.location_on, color: Colors.green),
            SizedBox(width: 8),
            Text('Location details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 20),
        const Text('FULL ADDRESS', style: TextStyle(fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _addressController,
          decoration: _buildInputDecoration(),
          validator: (value) => value!.isEmpty ? 'Enter your address' : null,
        ),
        const SizedBox(height: 20),
        const Text('STATE', style: TextStyle(fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedState,
          hint: const Text('Select State'),
          decoration: _buildInputDecoration(),
          items: _nigerianStatesAndLgas.keys.map((state) => DropdownMenuItem(value: state, child: Text(state))).toList(),
          onChanged: (value) {
            setState(() {
              _selectedState = value;
              _selectedLga = null;
            });
          },
          validator: (value) => value == null ? 'Select your state' : null,
        ),
        const SizedBox(height: 20),
        const Text('LOCAL GOVERNMENT AREA', style: TextStyle(fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedLga,
          hint: const Text('Select LGA'),
          decoration: _buildInputDecoration(),
          items: _selectedState != null
              ? _nigerianStatesAndLgas[_selectedState]!.map((lga) => DropdownMenuItem(value: lga, child: Text(lga))).toList()
              : [],
          onChanged: (value) => setState(() => _selectedLga = value),
          validator: (value) => value == null ? 'Select your LGA' : null,
        ),
        const SizedBox(height: 20),
        if (_errorMessage != null)
          Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
      ],
    );
  }

  InputDecoration _buildInputDecoration({String? prefixText}) {
    return InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.green),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.green),
      ),
      prefixText: prefixText,
    );
  }
}
