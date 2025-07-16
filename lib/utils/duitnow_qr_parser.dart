class DuitnowQrParser {
  // EMVCo TLV parsing for DuitNow QR codes
  static Map<String, String> _parseTLV(String qrData) {
    final Map<String, String> tlvMap = {};
    int i = 0;

    while (i < qrData.length - 3) {
      try {
        // Read tag (2 digits)
        if (i + 2 > qrData.length) break;
        final tag = qrData.substring(i, i + 2);
        i += 2;

        // Read length (2 digits)
        if (i + 2 > qrData.length) break;
        final lengthStr = qrData.substring(i, i + 2);
        final length = int.parse(lengthStr);
        i += 2;

        // Read value
        if (i + length > qrData.length) break;
        final value = qrData.substring(i, i + length);
        i += length;

        tlvMap[tag] = value;

        // For merchant account information (tags 26-51), parse nested TLV
        if ((tag.compareTo('26') >= 0 && tag.compareTo('51') <= 0) &&
            value.length > 4) {
          final nestedTLV = _parseTLV(value);
          nestedTLV.forEach((key, val) {
            tlvMap['$tag.$key'] = val;
          });
        }
      } catch (e) {
        // Skip invalid TLV entries
        break;
      }
    }

    return tlvMap;
  }

  static String? extractMerchantName(String qrData) {
    try {
      final tlvMap = _parseTLV(qrData);

      // Tag 59 - Merchant Name
      if (tlvMap.containsKey('59')) {
        return tlvMap['59']!.trim();
      }

      // Alternative: look in merchant account information tags
      for (int i = 26; i <= 51; i++) {
        final tag = i.toString().padLeft(2, '0');
        // Check for merchant name in nested TLV (usually tag 02 for merchant name)
        if (tlvMap.containsKey('$tag.02')) {
          return tlvMap['$tag.02']!.trim();
        }
        // Check for merchant identifier that might contain name
        if (tlvMap.containsKey('$tag.01')) {
          final merchantId = tlvMap['$tag.01']!.trim();
          if (merchantId.isNotEmpty && merchantId.length > 5) {
            return merchantId;
          }
        }
      }

      // Fallback: Try to extract merchant name from raw patterns
      final patterns = [
        RegExp(r'59(\d{2})([A-Z0-9\s\-\.\,]+)', caseSensitive: false),
        RegExp(r'2902([A-Z0-9\s\-\.\,]+?)30', caseSensitive: false),
        RegExp(
          r'26\d{2}[0-9]+01\d{2}([A-Z0-9\s\-\.\,]+)',
          caseSensitive: false,
        ),
      ];

      for (final pattern in patterns) {
        final match = pattern.firstMatch(qrData);
        if (match != null) {
          String merchantName;
          if (match.groupCount >= 2) {
            final length = int.tryParse(match.group(1)!) ?? 0;
            merchantName = match.group(2)!;
            if (length > 0 && merchantName.length >= length) {
              merchantName = merchantName.substring(0, length);
            }
          } else {
            merchantName = match.group(1)!;
          }

          if (merchantName.trim().isNotEmpty) {
            return merchantName.trim();
          }
        }
      }

      return null;
    } catch (e) {
      print('Error extracting merchant name: $e');
      return null;
    }
  }

  static bool isValidDuitnowQr(String qrData) {
    try {
      // Basic length check
      if (qrData.length < 20) return false;

      final tlvMap = _parseTLV(qrData);

      // Check payload format indicator (tag 00) - can be "01" or "02"
      if (!tlvMap.containsKey('00')) {
        return false;
      }
      final payloadFormat = tlvMap['00']!;
      if (payloadFormat != '01' && payloadFormat != '02') {
        print('Unsupported payload format: $payloadFormat');
        return false;
      }

      // Check point of initiation method (tag 01)
      if (!tlvMap.containsKey('01')) {
        return false;
      }

      // Check for merchant account information (tags 26-51)
      bool hasMerchantAccount = false;
      for (int i = 26; i <= 51; i++) {
        final tag = i.toString().padLeft(2, '0');
        if (tlvMap.containsKey(tag)) {
          hasMerchantAccount = true;
          break;
        }
      }

      // Check country code (tag 58) - should be "MY" for Malaysia
      final countryCode = tlvMap['58'];
      if (countryCode != null && countryCode != 'MY') {
        // Allow other country codes but prefer MY for DuitNow
        print('QR code from country: $countryCode');
      }

      // Check for essential payment QR elements
      final hasCountryCode = tlvMap.containsKey('58');
      final hasMerchantName = tlvMap.containsKey('59');
      final hasCRC = tlvMap.containsKey('63'); // CRC checksum

      // More flexible validation - accept if it has basic payment structure
      final isValidPaymentQR =
          hasCountryCode && (hasMerchantName || hasMerchantAccount) && hasCRC;

      if (isValidPaymentQR) {
        final countryCode = tlvMap['58'];
        if (countryCode != null && countryCode == 'MY') {
          print('Valid Malaysian payment QR code detected');
        } else {
          print('Valid payment QR code from country: $countryCode');
        }
        return true;
      }

      // Additional fallback validation for DuitNow patterns
      final qrLower = qrData.toLowerCase();
      final hasDuitnowIndicators =
          qrLower.contains('duitnow') ||
          qrLower.contains('my.') ||
          (hasMerchantAccount && hasCountryCode);

      return hasDuitnowIndicators;
    } catch (e) {
      print('Error validating QR code: $e');
      // Fallback validation
      return qrData.startsWith('0002') && qrData.length > 50;
    }
  }

  static Map<String, String> parseQrData(String qrData) {
    final result = <String, String>{};

    try {
      print(
        'Parsing QR data: ${qrData.substring(0, qrData.length > 100 ? 100 : qrData.length)}...',
      );

      final tlvMap = _parseTLV(qrData);
      print('Parsed TLV entries: ${tlvMap.keys.length}');

      // Extract merchant name
      final merchantName = extractMerchantName(qrData);
      if (merchantName != null && merchantName.isNotEmpty) {
        result['merchantName'] = merchantName;
        print('Found merchant name: $merchantName');
      } else {
        result['merchantName'] = 'Unknown Merchant';
        print('No merchant name found, using default');
      }

      // Extract country code (tag 58)
      if (tlvMap.containsKey('58')) {
        result['countryCode'] = tlvMap['58']!;
      }

      // Extract merchant city (tag 60)
      if (tlvMap.containsKey('60')) {
        result['merchantCity'] = tlvMap['60']!;
      }

      // Extract transaction amount (tag 54) if present
      if (tlvMap.containsKey('54')) {
        result['amount'] = tlvMap['54']!;
      }

      // Extract currency (tag 53)
      if (tlvMap.containsKey('53')) {
        result['currency'] = tlvMap['53']!;
      }

      // Validate QR code
      final isValid = isValidDuitnowQr(qrData);
      result['isValid'] = isValid.toString();

      print('QR validation result: $isValid');
      if (!isValid) {
        print('QR validation failed - not a valid payment QR code');
      }
    } catch (e) {
      print('Error parsing QR data: $e');
      result['error'] = 'Failed to parse QR code: $e';
      result['isValid'] = 'false';
    }

    return result;
  }
}
