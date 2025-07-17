import 'package:flutter/material.dart';
import '../services/carbon_api_service.dart';

class CarbonDetailsScreen extends StatefulWidget {
  const CarbonDetailsScreen({super.key});
  @override
  State<CarbonDetailsScreen> createState() => _CarbonDetailsScreenState();
}

class _CarbonDetailsScreenState extends State<CarbonDetailsScreen> {
  final CarbonApiService _api = CarbonApiService();
  double? _co2e;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final result = await _api.getCarbonEmission(
      activityId: 'transportation_car_fuel_combustion_gasoline',
      amount: 10,      // e.g., 10 km
      unit: 'km',
    );
    setState(() {
      _co2e = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CO₂ Details'), backgroundColor: Colors.green),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _co2e == null
                ? const Text('Failed to load data')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🌍 Estimated Emissions',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Text('${_co2e!.toStringAsFixed(2)} kg CO₂',
                          style: const TextStyle(fontSize: 32, color: Colors.green)),
                      const SizedBox(height: 8),
                      const Text(
                        'Based on driving 10 km in a gasoline car',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
      ),
    );
  }
}
