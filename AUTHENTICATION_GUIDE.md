# Authentication System Guide

## App Development Status

### ✅ Authentication (Complete)

- Full AWS Cognito integration
- Secure login/logout flow
- Session management
- User profile caching
- Email remembering functionality

### 🏗️ Marketplace (In Progress)

- Basic layout implemented
- Product listing structure ready
- Integration with backend services ongoing
- User transaction flow being developed

### 🏗️ Crowdfunding (In Development)

- Initial UI components created
- Campaign creation flow designed
- Funding mechanisms being implemented
- Integration with payment systems planned

### 📱 Core App Features

- Onboarding flow completed
- Navigation structure implemented
- Profile management active
- Data persistence configured

## Overview

The PoliGrain app now has a comprehensive authentication system that ensures users are authenticated before accessing the main application features.

## How It Works

### 1. App Startup Flow

1. **Onboarding Check**: App checks if user has seen onboarding
2. **Authentication Check**: If onboarding is complete, app checks authentication status
3. **Routing**:
   - If not seen onboarding → Onboarding Screen
   - If seen onboarding:
     - Shows Login Screen with last used email (if available)
     - After authentication → Main App (MainScreenWrapper)

### 2. Authentication Components

#### AuthWrapper (`lib/main.dart`)

- Checks authentication status on app startup
- Listens to authentication state changes
- Routes to appropriate screen based on auth status

#### AuthService (`lib/services/auth_service.dart`)

- Centralized authentication logic
- Provides methods for checking auth status, signing out, getting current user
- Singleton pattern for easy access throughout the app

#### AuthGuard (`lib/widgets/auth_guard.dart`)

- Widget wrapper for protecting individual screens
- Can be used to guard specific features that require authentication

### 3. User Flow

#### First Time Users

1. Onboarding Screen → Login Screen → Main App

#### Returning Users

1. Authentication Check → Main App (if authenticated) or Login Screen (if not)

#### Logout Flow

1. User taps logout in Profile screen
2. Confirmation dialog appears
3. If confirmed, user is signed out and redirected to Login Screen

## Key Features

### ✅ Authentication Required

- Users must be authenticated to access the main app
- Automatic redirection to login if not authenticated

### ✅ Session Management

- App remembers authentication state across sessions
- Automatic session checking on app startup

### ✅ Secure Logout

- Confirmation dialog before logout
- Proper session cleanup
- Redirect to login screen after logout

### ✅ Auth State Management

- Manual authentication state checking
- Periodic validation of authentication status
- AuthGuard component for protecting routes

## Usage Examples

### Using AuthService

```dart
// Check if user is authenticated
bool isAuth = await AuthService().isAuthenticated();

// Sign out user
await AuthService().signOut();

// Get current user
AuthUser? user = await AuthService().getCurrentUser();

// Check internet connectivity
bool hasConnection = await AuthService().hasInternetConnection();

// Change password
await AuthService().changePassword(
  oldPassword: 'current-password',
  newPassword: 'new-password',
);

// Get user attributes
Map<String, String> attributes = await AuthService().fetchUserAttributes();
```

### Using AuthGuard

```dart
AuthGuard(
  child: YourProtectedWidget(),
  loadingWidget: CustomLoadingWidget(),
  unauthorizedWidget: CustomUnauthorizedWidget(),
)
```

## Security Features

1. **Session Validation**: Every app startup validates authentication
2. **Secure Logout**: Proper session cleanup and redirection
3. **State Management**: Real-time authentication state monitoring
4. **Error Handling**: Graceful handling of authentication errors

## File Structure

```
lib/
├── main.dart (AuthWrapper)
├── services/
│   └── auth_service.dart (Authentication logic)
├── widgets/
│   └── auth_guard.dart (Protection widget)
├── screens/
│   ├── login_screen.dart (Login UI)
│   ├── onboarding_screen.dart (Onboarding)
│   └── main_screen_wrapper.dart (Main app with logout)
```

## Testing Authentication

1. **Fresh Install**: Should show onboarding → login
2. **Authenticated User**: Should go directly to main app
3. **Logout**: Should redirect to login screen
4. **Session Expiry**: Should redirect to login screen

## Current Features

- [x] Remember last email functionality
- [x] Manual session management
- [x] Internet connectivity checks
- [x] Comprehensive error handling
- [x] Password change functionality

## Future Enhancements

- [ ] Biometric authentication integration
- [ ] Full auto-login for returning users
- [ ] Session timeout handling
- [ ] Multi-factor authentication
- [ ] Real-time authentication state updates
