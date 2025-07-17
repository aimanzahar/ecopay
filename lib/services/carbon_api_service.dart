import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CarbonApiService {
  // Read your key from .env
  final String _apiKey = dotenv.env['CLIMATIQ_API_KEY'] ?? '';
  // Use the v1 “data” endpoint
  final String _endpoint = 'https://api.climatiq.io/data/v1/estimate';

  /// Returns estimated CO₂e (in kg) for the given activity.
  Future<double?> getCarbonEmission({
    required String activityId,
    required double amount,
    String unit = 'kg',
  }) async {
    final uri = Uri.parse(_endpoint);
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'emission_factor': {'activity_id': activityId},
        'parameters': {'amount': amount, 'unit': unit},
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['co2e'] as num).toDouble();
    } else {
      debugPrint('Climatiq error ${response.statusCode}: ${response.body}');
      return null;
    }
  }
}
