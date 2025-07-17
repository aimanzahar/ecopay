class EnvironmentalImpactCalculator {
  // CO2 offset rate: 0.12kg per RM donated (based on existing app pattern)
  static const double co2OffsetPerRM = 0.12;
  
  // Additional environmental impact metrics (at least 10 types)
  static const double waterSavedLitersPerRM = 5.0;
  static const double treeEquivalentPerRM = 0.02;
  static const double energySavedKwhPerRM = 0.8;
  static const double plasticBottlesReducedPerRM = 0.3;
  static const double riverMetersCleanedPerRM = 0.15;
  static const double wildlifeProtectedPerRM = 0.05;
  static const double airQualityImprovedM3PerRM = 8.0;
  static const double soilRestoredM2PerRM = 0.4;
  static const double solarPanelsEquivalentPerRM = 0.001;
  static const double carbonFootprintReducedPerRM = 0.18;
  static const double biodiversityProtectedPerRM = 0.08;
  static const double wasteDivertedKgPerRM = 0.6;
  
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
  
  /// Calculate plastic bottles reduced for a contribution amount
  static double calculatePlasticBottlesReduced(double amount) {
    return amount * plasticBottlesReducedPerRM;
  }
  
  /// Calculate river meters cleaned for a contribution amount
  static double calculateRiverCleaned(double amount) {
    return amount * riverMetersCleanedPerRM;
  }
  
  /// Calculate wildlife protected for a contribution amount
  static double calculateWildlifeProtected(double amount) {
    return amount * wildlifeProtectedPerRM;
  }
  
  /// Calculate air quality improved in m³ for a contribution amount
  static double calculateAirQualityImproved(double amount) {
    return amount * airQualityImprovedM3PerRM;
  }
  
  /// Calculate soil restored in m² for a contribution amount
  static double calculateSoilRestored(double amount) {
    return amount * soilRestoredM2PerRM;
  }
  
  /// Calculate solar panels equivalent for a contribution amount
  static double calculateSolarPanelsEquivalent(double amount) {
    return amount * solarPanelsEquivalentPerRM;
  }
  
  /// Calculate carbon footprint reduced for a contribution amount
  static double calculateCarbonFootprintReduced(double amount) {
    return amount * carbonFootprintReducedPerRM;
  }
  
  /// Calculate biodiversity protected for a contribution amount
  static double calculateBiodiversityProtected(double amount) {
    return amount * biodiversityProtectedPerRM;
  }
  
  /// Calculate waste diverted in kg for a contribution amount
  static double calculateWasteDiverted(double amount) {
    return amount * wasteDivertedKgPerRM;
  }
  
  /// Get comprehensive environmental impact metrics
  static Map<String, dynamic> getEnvironmentalImpact(double amount) {
    return {
      'co2_offset_kg': calculateCO2Offset(amount),
      'water_saved_liters': calculateWaterSaved(amount),
      'tree_equivalent': calculateTreeEquivalent(amount),
      'energy_saved_kwh': calculateEnergySaved(amount),
      'plastic_bottles_reduced': calculatePlasticBottlesReduced(amount),
      'river_meters_cleaned': calculateRiverCleaned(amount),
      'wildlife_protected': calculateWildlifeProtected(amount),
      'air_quality_improved_m3': calculateAirQualityImproved(amount),
      'soil_restored_m2': calculateSoilRestored(amount),
      'solar_panels_equivalent': calculateSolarPanelsEquivalent(amount),
      'carbon_footprint_reduced': calculateCarbonFootprintReduced(amount),
      'biodiversity_protected': calculateBiodiversityProtected(amount),
      'waste_diverted_kg': calculateWasteDiverted(amount),
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
        'total_plastic_bottles_reduced': 0.0,
        'total_river_meters_cleaned': 0.0,
        'total_wildlife_protected': 0.0,
        'total_air_quality_improved_m3': 0.0,
        'total_soil_restored_m2': 0.0,
        'total_solar_panels_equivalent': 0.0,
        'total_carbon_footprint_reduced': 0.0,
        'total_biodiversity_protected': 0.0,
        'total_waste_diverted_kg': 0.0,
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
      'total_plastic_bottles_reduced': calculatePlasticBottlesReduced(totalAmount),
      'total_river_meters_cleaned': calculateRiverCleaned(totalAmount),
      'total_wildlife_protected': calculateWildlifeProtected(totalAmount),
      'total_air_quality_improved_m3': calculateAirQualityImproved(totalAmount),
      'total_soil_restored_m2': calculateSoilRestored(totalAmount),
      'total_solar_panels_equivalent': calculateSolarPanelsEquivalent(totalAmount),
      'total_carbon_footprint_reduced': calculateCarbonFootprintReduced(totalAmount),
      'total_biodiversity_protected': calculateBiodiversityProtected(totalAmount),
      'total_waste_diverted_kg': calculateWasteDiverted(totalAmount),
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
  
  static String formatPlasticBottlesImpact(double amount) {
    final bottles = calculatePlasticBottlesReduced(amount);
    return '${bottles.toStringAsFixed(1)} bottles';
  }
  
  static String formatRiverCleanedImpact(double amount) {
    final meters = calculateRiverCleaned(amount);
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    } else {
      return '${meters.toStringAsFixed(1)}m';
    }
  }
  
  static String formatWildlifeProtectedImpact(double amount) {
    final animals = calculateWildlifeProtected(amount);
    return '${animals.toStringAsFixed(2)} animals';
  }
  
  static String formatAirQualityImpact(double amount) {
    final airM3 = calculateAirQualityImproved(amount);
    return '${airM3.toStringAsFixed(1)}m³ air';
  }
  
  static String formatSoilRestoredImpact(double amount) {
    final soilM2 = calculateSoilRestored(amount);
    if (soilM2 >= 10000) {
      return '${(soilM2 / 10000).toStringAsFixed(1)} hectares';
    } else {
      return '${soilM2.toStringAsFixed(1)}m²';
    }
  }
  
  static String formatSolarPanelsImpact(double amount) {
    final panels = calculateSolarPanelsEquivalent(amount);
    if (panels >= 1.0) {
      return '${panels.toStringAsFixed(1)} panels';
    } else {
      return '${(panels * 100).toStringAsFixed(1)}% panel';
    }
  }
  
  static String formatCarbonFootprintImpact(double amount) {
    final carbon = calculateCarbonFootprintReduced(amount);
    if (carbon >= 1.0) {
      return '${carbon.toStringAsFixed(1)}kg footprint';
    } else {
      return '${(carbon * 1000).toStringAsFixed(0)}g footprint';
    }
  }
  
  static String formatBiodiversityImpact(double amount) {
    final bio = calculateBiodiversityProtected(amount);
    return '${bio.toStringAsFixed(2)} species';
  }
  
  static String formatWasteDivertedImpact(double amount) {
    final waste = calculateWasteDiverted(amount);
    if (waste >= 1000) {
      return '${(waste / 1000).toStringAsFixed(1)} tonnes';
    } else {
      return '${waste.toStringAsFixed(1)}kg';
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