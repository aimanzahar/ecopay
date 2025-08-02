import 'package:flutter_test/flutter_test.dart';
import 'package:ecopay/helpers/merchant_helper.dart';

void main() {
  group('MerchantHelper Tests', () {
    test('should identify MOHAMMAD AZRI BIN AZIZ as F&B company', () {
      // Test the specific merchant name mentioned in requirements
      expect(MerchantHelper.isFoodAndBeverageCompany('MOHAMMAD AZRI BIN AZIZ'), true);
      
      // Test case insensitive matching
      expect(MerchantHelper.isFoodAndBeverageCompany('mohammad azri bin aziz'), true);
      expect(MerchantHelper.isFoodAndBeverageCompany('Mohammad Azri Bin Aziz'), true);
    });

    test('should not identify other merchants as F&B companies', () {
      expect(MerchantHelper.isFoodAndBeverageCompany('OFFICE'), false);
      expect(MerchantHelper.isFoodAndBeverageCompany('Regular Store'), false);
      expect(MerchantHelper.isFoodAndBeverageCompany('Some Other Merchant'), false);
    });

    test('should return correct display names', () {
      // F&B company should show "Food & Beverage Company"
      expect(MerchantHelper.getDisplayName('MOHAMMAD AZRI BIN AZIZ'), 'AZRI Food & Beverage Company');
      
      // Regular merchant should show original name
      expect(MerchantHelper.getDisplayName('OFFICE'), 'OFFICE');
      expect(MerchantHelper.getDisplayName('Regular Store'), 'Regular Store');
    });

    test('should return correct merchant categories', () {
      // F&B company should show "F&B COMPANY"
      expect(MerchantHelper.getMerchantCategory('MOHAMMAD AZRI BIN AZIZ'), 'F&B COMPANY');
      
      // Regular merchant should show "DUITNOW QR"
      expect(MerchantHelper.getMerchantCategory('OFFICE'), 'DUITNOW QR');
      expect(MerchantHelper.getMerchantCategory('Regular Store'), 'DUITNOW QR');
    });

    test('should calculate different ESG contribution rates', () {
      double transactionAmount = 100.0;
      
      // F&B companies should have 3% rate
      double fnbContribution = MerchantHelper.calculateESGContribution('MOHAMMAD AZRI BIN AZIZ', transactionAmount);
      expect(fnbContribution, 3.0); // 3% of 100
      
      // Regular merchants should have 1% rate
      double regularContribution = MerchantHelper.calculateESGContribution('OFFICE', transactionAmount);
      expect(regularContribution, 1.0); // 1% of 100
    });

    test('should return appropriate recommended ESG amounts', () {
      double transactionAmount = 50.0;
      
      // F&B companies should have higher recommended amounts (minimum RM 1.00)
      double fnbRecommended = MerchantHelper.getRecommendedESGAmount('MOHAMMAD AZRI BIN AZIZ', transactionAmount);
      expect(fnbRecommended, greaterThanOrEqualTo(1.00));
      expect(fnbRecommended, lessThanOrEqualTo(10.00));
      
      // Regular merchants should have lower recommended amounts (minimum RM 0.50)
      double regularRecommended = MerchantHelper.getRecommendedESGAmount('OFFICE', transactionAmount);
      expect(regularRecommended, greaterThanOrEqualTo(0.50));
      expect(regularRecommended, lessThanOrEqualTo(5.00));
      
      // F&B recommended amount should be higher than regular
      expect(fnbRecommended, greaterThan(regularRecommended));
    });

    test('should return correct project details', () {
      // F&B company should get sustainable food systems project
      Map<String, String> fnbProject = MerchantHelper.getProjectDetails('MOHAMMAD AZRI BIN AZIZ');
      expect(fnbProject['name'], 'Sustainable Food Systems');
      expect(fnbProject['description'], contains('sustainable agriculture'));
      expect(fnbProject['description'], contains('food waste'));
      expect(fnbProject['description'], contains('eco-friendly packaging'));
      
      // Regular merchant should get environmental conservation project
      Map<String, String> regularProject = MerchantHelper.getProjectDetails('OFFICE');
      expect(regularProject['name'], 'Environmental Conservation');
      expect(regularProject['description'], contains('environmental projects'));
      expect(regularProject['description'], contains('reforestation'));
    });

    test('should return appropriate ESG impact messages', () {
      double amount = 8.0;
      
      // F&B company should mention sustainable meals
      String fnbMessage = MerchantHelper.getESGImpactMessage('MOHAMMAD AZRI BIN AZIZ', amount);
      expect(fnbMessage, contains('sustainable meals'));
      expect(fnbMessage, contains('food industry environmental impact'));
      expect(fnbMessage, contains('RM 8.00'));
      
      // Regular merchant should mention trees
      String regularMessage = MerchantHelper.getESGImpactMessage('OFFICE', amount);
      expect(regularMessage, contains('trees'));
      expect(regularMessage, contains('environmental conservation'));
      expect(regularMessage, contains('RM 8.00'));
    });

    test('should handle edge cases for ESG calculations', () {
      // Very small transaction
      double smallAmount = 1.0;
      double fnbSmall = MerchantHelper.getRecommendedESGAmount('MOHAMMAD AZRI BIN AZIZ', smallAmount);
      expect(fnbSmall, 1.00); // Should clamp to minimum
      
      double regularSmall = MerchantHelper.getRecommendedESGAmount('OFFICE', smallAmount);
      expect(regularSmall, 0.50); // Should clamp to minimum
      
      // Very large transaction
      double largeAmount = 1000.0;
      double fnbLarge = MerchantHelper.getRecommendedESGAmount('MOHAMMAD AZRI BIN AZIZ', largeAmount);
      expect(fnbLarge, 10.00); // Should clamp to maximum
      
      double regularLarge = MerchantHelper.getRecommendedESGAmount('OFFICE', largeAmount);
      expect(regularLarge, 5.00); // Should clamp to maximum
    });
  });
}