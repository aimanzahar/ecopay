import '../models/contribution.dart';
import 'database_helper.dart';

class MerchantHelper {
  static final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// List of merchant names that are classified as Food & Beverage companies
  static const List<String> _fnbMerchants = [
    'MOHAMMAD AZRI BIN AZIZ',
    // Add more F&B merchant names here as needed
  ];

  /// Check if a merchant is a Food & Beverage company
  static bool isFoodAndBeverageCompany(String merchantName) {
    return _fnbMerchants.contains(merchantName.toUpperCase());
  }

  /// Get display name for merchant
  /// Returns "Food & Beverage Company" for F&B merchants, original name otherwise
  static String getDisplayName(String merchantName) {
    if (isFoodAndBeverageCompany(merchantName)) {
      return 'AZRI Food & Beverage Company';
    }
    return merchantName;
  }

  /// Get merchant category for display
  static String getMerchantCategory(String merchantName) {
    if (isFoodAndBeverageCompany(merchantName)) {
      return 'F&B COMPANY';
    }
    return 'DUITNOW QR';
  }

  /// Calculate ESG contribution amount based on merchant type
  /// F&B companies use different calculation logic
  static double calculateESGContribution(String merchantName, double baseAmount) {
    if (isFoodAndBeverageCompany(merchantName)) {
      // F&B companies: Higher ESG contribution rate (e.g., 3% of transaction)
      // This encourages more sustainable practices in food industry
      return baseAmount * 0.03; // 3% for F&B companies
    } else {
      // Regular merchants: Standard rate (e.g., 1% of transaction)
      return baseAmount * 0.01; // 1% for regular merchants
    }
  }

  /// Get recommended ESG contribution for a merchant type
  static double getRecommendedESGAmount(String merchantName, double transactionAmount) {
    if (isFoodAndBeverageCompany(merchantName)) {
      // F&B companies get higher recommended amounts to promote sustainability
      double calculated = calculateESGContribution(merchantName, transactionAmount);
      // Minimum RM 1.00 for F&B, maximum RM 10.00
      return calculated.clamp(1.00, 10.00);
    } else {
      // Regular merchants
      double calculated = calculateESGContribution(merchantName, transactionAmount);
      // Minimum RM 0.50 for regular merchants, maximum RM 5.00
      return calculated.clamp(0.50, 5.00);
    }
  }

  /// Create contribution record with appropriate project mapping
  static Future<void> createContributionRecord({
    required String merchantName,
    required double amount,
    required String transactionId,
    int userId = 1,
  }) async {
    int projectId;
    
    if (isFoodAndBeverageCompany(merchantName)) {
      // F&B companies contribute to sustainable agriculture/food projects
      projectId = 6; // We'll create a new project for sustainable agriculture
    } else {
      // Regular merchants contribute to general environmental projects
      projectId = 1; // Default environmental project
    }

    final contribution = Contribution(
      userId: userId,
      projectId: projectId,
      amount: amount,
      transactionId: transactionId,
      timestamp: DateTime.now(),
    );

    await _databaseHelper.insertContribution(contribution);
    print('DEBUG: MerchantHelper - Created contribution for ${isFoodAndBeverageCompany(merchantName) ? "F&B" : "regular"} merchant: $merchantName');
  }

  /// Initialize F&B specific projects in database
  static Future<void> initializeFnbProjects() async {
    final db = await _databaseHelper.database;
    
    // Check if F&B project already exists
    final existing = await db.query(
      'projects', 
      where: 'id = ?', 
      whereArgs: [6],
      limit: 1
    );
    
    if (existing.isEmpty) {
      // Insert F&B specific project
      await db.insert('projects', {
        'id': 6,
        'name': 'Sustainable Food Systems',
        'description': 'Support sustainable agriculture, reduce food waste, and promote eco-friendly food packaging',
        'cost_per_unit': 8.0,
        'unit_label': 'sustainable meal',
      });
      print('DEBUG: MerchantHelper - Initialized F&B project');
    }
  }

  /// Get project details for a merchant type
  static Map<String, String> getProjectDetails(String merchantName) {
    if (isFoodAndBeverageCompany(merchantName)) {
      return {
        'name': 'Sustainable Food Systems',
        'description': 'Your contribution supports sustainable agriculture, reduces food waste, and promotes eco-friendly packaging in the F&B industry.',
        'impact': 'Help create a more sustainable food ecosystem',
      };
    } else {
      return {
        'name': 'Environmental Conservation',
        'description': 'Your contribution supports various environmental projects including reforestation, clean energy, and ocean cleanup.',
        'impact': 'Help protect our planet for future generations',
      };
    }
  }

  /// Get ESG impact message based on merchant type
  static String getESGImpactMessage(String merchantName, double amount) {
    if (isFoodAndBeverageCompany(merchantName)) {
      double meals = amount / 8.0; // Based on cost_per_unit
      return 'Your RM ${amount.toStringAsFixed(2)} contribution helps provide ${meals.toStringAsFixed(1)} sustainable meals and reduces food industry environmental impact.';
    } else {
      double trees = amount / 5.0; // Based on mangrove project cost_per_unit
      return 'Your RM ${amount.toStringAsFixed(2)} contribution helps plant ${trees.toStringAsFixed(1)} trees and supports environmental conservation.';
    }
  }
}