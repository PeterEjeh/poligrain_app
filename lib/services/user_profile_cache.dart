import 'package:poligrain_app/models/user_profile.dart' as app_model;

class UserProfileCache {
  static final UserProfileCache _instance = UserProfileCache._internal();
  factory UserProfileCache() => _instance;
  UserProfileCache._internal();

  app_model.UserProfile? userProfile;

  void updateUserProfile(app_model.UserProfile profile) {
    userProfile = profile;
  }
}
