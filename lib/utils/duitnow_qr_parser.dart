class DuitnowQrParser {
  static String? extractMerchantName(String qrData) {
    try {
      // DUITNOW QR Code follows ISO 20022 format
      // The merchant name is typically in field 59 (Merchant Name)
      // Format: 59XX<merchant_name> where XX is the length
      
      // Look for field 59 (Merchant Name)
      final merchantNamePattern = RegExp(r'59(\d{2})([A-Z0-9\s]+)');
      final match = merchantNamePattern.firstMatch(qrData);
      
      if (match != null) {
        final length = int.parse(match.group(1)!);
        final merchantName = match.group(2)!;
        
        // Validate length matches
        if (merchantName.length >= length) {
          return merchantName.substring(0, length).trim();
        }
      }
      
      // Fallback: Try to find any merchant name pattern
      // Sometimes the format might vary slightly
      final fallbackPattern = RegExp(r'5906([A-Z0-9\s]+)6008');
      final fallbackMatch = fallbackPattern.firstMatch(qrData);
      
      if (fallbackMatch != null) {
        return fallbackMatch.group(1)!.trim();
      }
      
      return null;
    } catch (e) {
      print('Error parsing DUITNOW QR code: $e');
      return null;
    }
  }
  
  static bool isValidDuitnowQr(String qrData) {
    // Basic validation for DUITNOW QR codes
    // Should start with 00020201 (Payload Format Indicator)
    // Should contain Malaysian data (MY country code)
    return qrData.startsWith('00020201') && 
           qrData.contains('MY') && 
           qrData.length > 50; // Minimum expected length
  }
  
  static Map<String, String> parseQrData(String qrData) {
    final result = <String, String>{};
    
    try {
      // Extract merchant name
      final merchantName = extractMerchantName(qrData);
      if (merchantName != null) {
        result['merchantName'] = merchantName;
      }
      
      // Extract country code (typically 5802MY)
      final countryPattern = RegExp(r'5802([A-Z]{2})');
      final countryMatch = countryPattern.firstMatch(qrData);
      if (countryMatch != null) {
        result['countryCode'] = countryMatch.group(1)!;
      }
      
      // Extract merchant city (field 60)
      final cityPattern = RegExp(r'60(\d{2})([A-Z0-9\s]+)');
      final cityMatch = cityPattern.firstMatch(qrData);
      if (cityMatch != null) {
        final length = int.parse(cityMatch.group(1)!);
        final city = cityMatch.group(2)!;
        if (city.length >= length) {
          result['merchantCity'] = city.substring(0, length).trim();
        }
      }
      
      // Mark as valid DUITNOW QR
      result['isValid'] = isValidDuitnowQr(qrData).toString();
      
    } catch (e) {
      print('Error parsing QR data: $e');
      result['error'] = 'Failed to parse QR code';
    }
    
    return result;
  }
}