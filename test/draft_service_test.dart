import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poligrain_app/services/draft_service.dart';

void main() {
  group('DraftService Tests', () {
    setUp(() async {
      // Initialize shared preferences for testing
      SharedPreferences.setMockInitialValues({});
    });

    test('should save and retrieve drafts correctly', () async {
      // Create a test draft
      final draft = ProductDraft(
        id: 'test-id-1',
        title: 'Test Draft',
        savedAt: DateTime.now(),
        data: {
          'name': 'Test Product',
          'category': 'Vegetables',
          'price': '100.0',
          'description': 'Test description',
        },
      );

      // Save the draft
      final saveResult = await DraftService.saveDraft(draft);
      expect(saveResult, true);

      // Retrieve drafts
      final drafts = await DraftService.fetchAllDrafts();
      expect(drafts.length, 1);
      expect(drafts.first.id, 'test-id-1');
      expect(drafts.first.title, 'Test Draft');
    });

    test('should delete drafts correctly', () async {
      // Create and save a draft
      final draft = ProductDraft(
        id: 'test-id-2',
        title: 'Draft to Delete',
        savedAt: DateTime.now(),
        data: {'name': 'Test Product 2'},
      );
      
      await DraftService.saveDraft(draft);
      
      // Verify it was saved
      var drafts = await DraftService.fetchAllDrafts();
      expect(drafts.length, 1);
      
      // Delete the draft
      final deleteResult = await DraftService.deleteDraftById('test-id-2');
      expect(deleteResult, true);
      
      // Verify it was deleted
      drafts = await DraftService.fetchAllDrafts();
      expect(drafts.length, 0);
    });

    test('should convert drafts to products correctly', () async {
      // Create a test draft
      final draft = ProductDraft(
        id: 'test-id-3',
        title: 'Product Draft',
        savedAt: DateTime.now(),
        data: {
          'name': 'Test Product',
          'category': 'Fruits',
          'price': '50.0',
          'description': 'A test product',
          'location': 'Test Location',
          'quantity': 10,
        },
      );

      await DraftService.saveDraft(draft);
      
      // Convert to products
      final products = await DraftService.getDraftsAsProducts();
      expect(products.length, 1);
      
      final product = products.first;
      expect(product.name, 'Test Product');
      expect(product.category, 'Fruits');
      expect(product.price, 50.0);
      expect(product.isActive, false); // Drafts should not be active
    });
  });
}
