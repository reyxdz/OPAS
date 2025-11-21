import 'package:flutter/material.dart';
import '../models/seller_forecast_model.dart';
import '../services/seller_service.dart';

/// Enhanced Forecast Listing Screen with Trend Analysis (Phase 3.3)
/// Displays demand forecasts with advanced risk assessment and trend visualization
class EnhancedForecastListingScreen extends StatefulWidget {
  const EnhancedForecastListingScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedForecastListingScreen> createState() => _EnhancedForecastListingScreenState();
}

class _EnhancedForecastListingScreenState extends State<EnhancedForecastListingScreen> {
  late Future<List<SellerForecast>> _forecastFuture;
  String _selectedRisk = 'ALL'; // ALL, LOW, MEDIUM, HIGH
  String _sortBy = 'DEMAND_DESC'; // DEMAND_DESC, DEMAND_ASC, CONFIDENCE_DESC

  @override
  void initState() {
    super.initState();
    _forecastFuture = SellerService.getNextMonthForecast();
  }

  void _refreshForecasts() {
    setState(() {
      _forecastFuture = SellerService.getNextMonthForecast();
    });
  }

  List<SellerForecast> _filterAndSort(List<SellerForecast> forecasts) {
    // Filter by risk level
    List<SellerForecast> filtered = forecasts;
    if (_selectedRisk != 'ALL') {
      filtered = forecasts.where((f) => f.riskLevel == _selectedRisk).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'DEMAND_DESC':
        filtered.sort((a, b) => b.forecastedDemand.compareTo(a.forecastedDemand));
        break;
      case 'DEMAND_ASC':
        filtered.sort((a, b) => a.forecastedDemand.compareTo(b.forecastedDemand));
        break;
      case 'CONFIDENCE_DESC':
        filtered.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));
        break;
    }

    return filtered;
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'HIGH':
        return Colors.red.shade100;
      case 'MEDIUM':
        return Colors.orange.shade100;
      case 'LOW':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Demand Forecasts'),
        elevation: 0,
        backgroundColor: Colors.deepOrange,
      ),
      body: FutureBuilder<List<SellerForecast>>(
        future: _forecastFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshForecasts,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 64, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text('No forecasts available'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshForecasts,
                    child: const Text('Generate Forecasts'),
                  ),
                ],
              ),
            );
          }

          final forecasts = _filterAndSort(snapshot.data!);

          return RefreshIndicator(
            onRefresh: () async {
              _refreshForecasts();
              await _forecastFuture;
            },
            color: Colors.deepOrange,
            child: Column(
              children: [
                // Filter and Sort Bar
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.grey.shade100,
                  child: Column(
                    children: [
                      // Risk Level Filter
                      Row(
                        children: [
                          const Text('Risk Level:', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: ['ALL', 'LOW', 'MEDIUM', 'HIGH'].map((risk) {
                                  final isSelected = _selectedRisk == risk;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(risk),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() => _selectedRisk = risk);
                                      },
                                      backgroundColor: Colors.white,
                                      selectedColor: Colors.deepOrange.shade200,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Sort Dropdown
                      Row(
                        children: [
                          const Text('Sort by:', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _sortBy,
                            underline: Container(),
                            items: const [
                              DropdownMenuItem(value: 'DEMAND_DESC', child: Text('Demand (High → Low)')),
                              DropdownMenuItem(value: 'DEMAND_ASC', child: Text('Demand (Low → High)')),
                              DropdownMenuItem(value: 'CONFIDENCE_DESC', child: Text('Confidence (High → Low)')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _sortBy = value);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Forecasts List
                Expanded(
                  child: ListView.builder(
                    itemCount: forecasts.length,
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (context, index) {
                      final forecast = forecasts[index];
                      return _buildForecastCard(forecast);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildForecastCard(SellerForecast forecast) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: _getRiskColor(forecast.riskLevel),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Product name and risk badge
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        forecast.productName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Forecast Date: ${forecast.forecastDate.toString().split(' ')[0]}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: forecast.riskLevel == 'HIGH'
                        ? Colors.red
                        : forecast.riskLevel == 'MEDIUM'
                            ? Colors.orange
                            : Colors.green,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    forecast.riskLevel,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Demand and Trend
            Row(
              children: [
                Expanded(
                  child: _buildInfoTile(
                    icon: '📊',
                    label: 'Forecasted Demand',
                    value: '${forecast.forecastedDemand} units',
                  ),
                ),
                Expanded(
                  child: _buildInfoTile(
                    icon: forecast.trendEmoji,
                    label: 'Trend',
                    value: forecast.trend,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Confidence and Volatility
            Row(
              children: [
                Expanded(
                  child: _buildInfoTile(
                    icon: '🎯',
                    label: 'Confidence',
                    value: '${forecast.confidenceScore.toStringAsFixed(1)}%',
                  ),
                ),
                Expanded(
                  child: _buildInfoTile(
                    icon: '📈',
                    label: 'Volatility',
                    value: '${forecast.volatility.toStringAsFixed(1)}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Risk Probabilities
            Row(
              children: [
                Expanded(
                  child: _buildRiskIndicator(
                    label: 'Surplus Risk',
                    probability: forecast.surplusProbability,
                    color: Colors.blue.shade400,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildRiskIndicator(
                    label: 'Stockout Risk',
                    probability: forecast.stockoutProbability,
                    color: Colors.red.shade400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Recommended Stock
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recommended Stock:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '${forecast.recommendedStock} units',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.deepOrange),
                  ),
                ],
              ),
            ),
            if (forecast.recommendations.isNotEmpty) ...[
              const SizedBox(height: 8),
              // Top Recommendation
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.deepOrange.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💡 Recommendation:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      forecast.recommendations.first,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({required String icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRiskIndicator({
    required String label,
    required double probability,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: probability / 100,
              minHeight: 6,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${probability.toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
