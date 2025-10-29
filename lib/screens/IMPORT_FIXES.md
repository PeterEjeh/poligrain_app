# Import Fixes Required After Screen Reorganization

## Summary

After reorganizing screens into folders, many import statements need to be updated to reflect the new file locations.

## Files That Need Import Updates

### 1. Main Application Files

- `lib/main.dart` ✅ **FIXED**
  - Updated onboarding, login, home, marketplace, and crowdfunding imports

### 2. Home Screens

- `lib/screens/home/home_screen.dart`

  - Update: `package:poligrain_app/screens/logistics_screen.dart` → `package:poligrain_app/screens/logistics/logistics_screen.dart`
  - Update: `package:poligrain_app/screens/product_creation_screen.dart` → `package:poligrain_app/screens/marketplace/product_creation_screen.dart`
  - Update: `package:poligrain_app/screens/campaign_creation_screen.dart` → `package:poligrain_app/screens/crowdfunding/campaign_creation_screen.dart`

- `lib/screens/home/enhanced_home_screen.dart`
  - Same updates as home_screen.dart

### 3. Marketplace Screens

- `lib/screens/marketplace/marketplace_screen.dart` ✅ **FIXED**

  - Updated relative imports to use `../../` for services, models, etc.

- `lib/screens/marketplace/enhanced_marketplace_screen.dart`

  - Update all `../` imports to `../../` for services, models, widgets
  - Update `'cart/cart_screen.dart'` → `'../cart/cart_screen.dart'`

- `lib/screens/marketplace/product_creation_screen.dart`
  - Update all `../` imports to `../../` for services

### 4. Auth Screens

- All auth screens ✅ **CORRECT** (using relative imports within same folder)

### 5. Index Files Conflicts

- `lib/screens/home/index.dart` - Has naming conflict with `mockLogisticsRequestsPreview`
  - Solution: Hide conflicting exports or rename the conflicting variable

## Quick Fix Commands

You can run these commands to fix the imports:

```bash
# Fix home screens
find lib/screens/home -name "*.dart" -exec sed -i 's|package:poligrain_app/screens/logistics_screen.dart|package:poligrain_app/screens/logistics/logistics_screen.dart|g' {} \;
find lib/screens/home -name "*.dart" -exec sed -i 's|package:poligrain_app/screens/product_creation_screen.dart|package:poligrain_app/screens/marketplace/product_creation_screen.dart|g' {} \;
find lib/screens/home -name "*.dart" -exec sed -i 's|package:poligrain_app/screens/campaign_creation_screen.dart|package:poligrain_app/screens/crowdfunding/campaign_creation_screen.dart|g' {} \;

# Fix enhanced marketplace screen
sed -i 's|../models/|../../models/|g' lib/screens/marketplace/enhanced_marketplace_screen.dart
sed -i 's|../widgets/|../../widgets/|g' lib/screens/marketplace/enhanced_marketplace_screen.dart
sed -i 's|../services/|../../services/|g' lib/screens/marketplace/enhanced_marketplace_screen.dart
sed -i 's|../exceptions/|../../exceptions/|g' lib/screens/marketplace/enhanced_marketplace_screen.dart
sed -i "s|'cart/cart_screen.dart'|'../cart/cart_screen.dart'|g" lib/screens/marketplace/enhanced_marketplace_screen.dart

# Fix product creation screen
sed -i 's|../services/|../../services/|g' lib/screens/marketplace/product_creation_screen.dart
```

## Alternative Solution: Use Index Files

Instead of fixing individual imports, you can use the index files:

```dart
// Instead of individual imports
import 'package:poligrain_app/screens/auth/login_screen.dart';
import 'package:poligrain_app/screens/auth/signup_screen.dart';

// Use index import
import 'package:poligrain_app/screens/auth/index.dart';
```

## Status

- ✅ Main.dart - Fixed
- ✅ Marketplace screen - Fixed
- ✅ Auth screens - Correct (relative imports)
- ❌ Home screens - Need fixing
- ❌ Enhanced marketplace - Need fixing
- ❌ Product creation - Need fixing
- ❌ Index conflicts - Need resolving

## Recommendation

1. Use the quick fix commands above
2. Or manually update the import paths as listed
3. Test the app after each batch of fixes
4. Consider using index files for cleaner imports in the future
