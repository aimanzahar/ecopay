class EnvironmentalImpactCalculator {
  // CO2 offset rate: 0.12kg per RM donated (based on existing app pattern)
  static const double co2OffsetPerRM = 0.12;
  
  // Additional environmental impact metrics
  static const double waterSavedLitersPerRM = 5.0;
  static const double treeEquivalentPerRM = 0.02;
  static const double energySavedKwhPerRM = 0.8;
  
  /// Calculate CO2 offset for a contribution amount
  static double calculateCO2Offset(double amount) {
    return amount * co2OffsetPerRM;
  }
  
  /// Calculate water saved in liters for a contribution amount
  static double calculateWaterSaved(double amount) {
    return amount * waterSavedLitersPerRM;
  }
  
  /// Calculate tree equivalent for a contribution amount
  static double calculateTreeEquivalent(double amount) {
    return amount * treeEquivalentPerRM;
  }
  
  /// Calculate energy saved in kWh for a contribution amount
  static double calculateEnergySaved(double amount) {
    return amount * energySavedKwhPerRM;
  }
  
  /// Get comprehensive environmental impact metrics
  static Map<String, dynamic> getEnvironmentalImpact(double amount) {
    return {
      'co2_offset_kg': calculateCO2Offset(amount),
      'water_saved_liters': calculateWaterSaved(amount),
      'tree_equivalent': calculateTreeEquivalent(amount),
      'energy_saved_kwh': calculateEnergySaved(amount),
      'amount': amount,
    };
  }
  
  /// Get aggregated environmental impact for multiple contributions
  static Map<String, dynamic> getAggregatedImpact(List<Map<String, dynamic>> contributions) {
    if (contributions.isEmpty) {
      return {
        'total_amount': 0.0,
        'total_co2_offset_kg': 0.0,
        'total_water_saved_liters': 0.0,
        'total_tree_equivalent': 0.0,
        'total_energy_saved_kwh': 0.0,
        'contribution_count': 0,
      };
    }
    
    final totalAmount = contributions.fold<double>(
      0.0, 
      (sum, contribution) => sum + (contribution['amount'] as double? ?? 0.0)
    );
    
    return {
      'total_amount': totalAmount,
      'total_co2_offset_kg': calculateCO2Offset(totalAmount),
      'total_water_saved_liters': calculateWaterSaved(totalAmount),
      'total_tree_equivalent': calculateTreeEquivalent(totalAmount),
      'total_energy_saved_kwh': calculateEnergySaved(totalAmount),
      'contribution_count': contributions.length,
    };
  }
  
  /// Format environmental impact for display
  static String formatCO2Impact(double amount) {
    final co2 = calculateCO2Offset(amount);
    if (co2 >= 1.0) {
      return '${co2.toStringAsFixed(1)}kg CO₂';
    } else {
      return '${(co2 * 1000).toStringAsFixed(0)}g CO₂';
    }
  }
  
  static String formatWaterImpact(double amount) {
    final water = calculateWaterSaved(amount);
    if (water >= 1000) {
      return '${(water / 1000).toStringAsFixed(1)}m³ water';
    } else {
      return '${water.toStringAsFixed(0)}L water';
    }
  }
  
  static String formatTreeImpact(double amount) {
    final trees = calculateTreeEquivalent(amount);
    if (trees >= 1.0) {
      return '${trees.toStringAsFixed(1)} trees';
    } else {
      return '${(trees * 100).toStringAsFixed(0)}% of a tree';
    }
  }
  
  static String formatEnergyImpact(double amount) {
    final energy = calculateEnergySaved(amount);
    if (energy >= 1.0) {
      return '${energy.toStringAsFixed(1)} kWh';
    } else {
      return '${(energy * 1000).toStringAsFixed(0)}Wh';
    }
  }
  
  /// Get impact message for contribution
  static String getImpactMessage(double amount) {
    final co2 = formatCO2Impact(amount);
    final water = formatWaterImpact(amount);
    return 'Your RM${amount.toStringAsFixed(2)} contribution offsets $co2 and saves $water! 🌱';
  }
  
  /// Get project-specific impact calculations
  static Map<String, dynamic> getProjectImpact(String projectName, double amount) {
    final baseImpact = getEnvironmentalImpact(amount);
    
    // Project-specific multipliers
    Map<String, double> projectMultipliers = {
      'Mangrove Restoration': 1.5, // Higher CO2 absorption
      'Solar Panel Installation': 2.0, // Higher energy impact
      'Clean Water Wells': 1.0, // Standard impact
      'Rainforest Conservation': 1.8, // Higher biodiversity impact
      'Ocean Cleanup': 1.2, // Moderate impact
    };
    
    final multiplier = projectMultipliers[projectName] ?? 1.0;
    
    return {
      'co2_offset_kg': baseImpact['co2_offset_kg'] * multiplier,
      'water_saved_liters': baseImpact['water_saved_liters'] * multiplier,
      'tree_equivalent': baseImpact['tree_equivalent'] * multiplier,
      'energy_saved_kwh': baseImpact['energy_saved_kwh'] * multiplier,
      'amount': amount,
      'project_name': projectName,
      'impact_multiplier': multiplier,
    };
  }
}