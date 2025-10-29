// lib/models/user_profile.dart
class UserProfile {
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String gender;
  final String address;
  final String city;
  final String postalCode;
  final String profilePicture;
  final String role;
  final String owner;

  UserProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.gender,
    required this.address,
    required this.city,
    required this.postalCode,
    required this.profilePicture,
    required this.role,
    required this.owner,
  });

  // A factory constructor for creating a new UserProfile instance from a map.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // The `json['item'] ?? {}` handles cases where the 'item' key might be missing.
    final item = json['item'] as Map<String, dynamic>? ?? {};

    return UserProfile(
      firstName: item['first_name'] as String? ?? '',
      lastName: item['last_name'] as String? ?? '',
      email: item['username'] as String? ?? '',
      phoneNumber: (item['phone'] ?? '').toString(),
      gender: (item['gender'] ?? '').toString(),
      address: (item['address'] ?? '').toString(),
      city: (item['city'] ?? '').toString(),
      postalCode: (item['postal_code'] ?? '').toString(),
      profilePicture: (item['profile_image'] ?? '').toString(),
      role: (item['role'] ?? '').toString(),
      owner: (item['owner'] ?? '').toString(),
    );
  }

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? gender,
    String? address,
    String? city,
    String? postalCode,
    String? profilePicture,
    String? role,
    String? owner,
  }) {
    return UserProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      profilePicture: profilePicture ?? this.profilePicture,
      role: role ?? this.role,
      owner: owner ?? this.owner,
    );
  }
}
