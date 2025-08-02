// lib/utils/carbon_calculator.dart

class CarbonCalculator {
  static const Map<String, double> _carbonFactors = {
    'General':       0.084,
    'Transportation':0.156,
    'Food & Dining': 0.067,
    'Utilities':     0.198,
    'Shopping':      0.045,
    'Entertainment': 0.032,
    'Healthcare':    0.089,
    'Education':     0.023,
  };

  static const double _defaultFactor = 0.084;

  /// Public list of categories
  static List<String> get categories => _carbonFactors.keys.toList();

  /// Return factor for a category, or default if missing
  static double factorFor(String category) =>
      _carbonFactors[category] ?? _defaultFactor;

  /// Calculate total kg CO₂ for [amount] (RM) in [category]
  static double calculate({
    required double amount,
    required String category,
  }) => amount * factorFor(category);
}
