# Phase 5.2 Widgets - Quick Reference Guide

## 🎯 Widget Overview

### ModelMetadataTag
**Display model type and confidence level as a compact badge**

**Imports:**
```dart
import 'package:opas_flutter/features/admin/widgets/model_metadata_tag.dart';
```

**Basic Usage:**
```dart
ModelMetadataTag(
  modelType: 'SARIMA',
  confidenceLevel: 'HIGH',
)
```

**With Custom Styling:**
```dart
ModelMetadataTag(
  modelType: 'ARIMA',
  confidenceLevel: 'MEDIUM',
  fontSize: 14,
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
)
```

**Available Model Types:**
- `SARIMA` → 📈 Green (#4CAF50) - Best model for seasonal data
- `ARIMA` → 📊 Blue (#2196F3) - Good for trend data
- `SIMPLE` → 📉 Amber (#FFC107) - Fallback simple model
- `INSUFFICIENT_DATA` → ℹ️ Gray (#9E9E9E) - Not enough data

**Available Confidence Levels:**
- `HIGH` → ⭐⭐⭐⭐⭐ Green
- `MEDIUM` → ⭐⭐⭐⭐ Amber
- `LOW` → ⭐⭐⭐ Red

---

### NoForecastPlaceholder
**Empty state when forecast is unavailable**

**Imports:**
```dart
import 'package:opas_flutter/features/admin/widgets/no_forecast_placeholder.dart';
```

**Basic Usage:**
```dart
NoForecastPlaceholder(
  reason: 'INSUFFICIENT_DATA',
  productName: 'Talong',
)
```

**With Retry Button:**
```dart
NoForecastPlaceholder(
  productName: 'Papaya',
  reason: 'ERROR',
  onRetry: () {
    setState(() {
      _forecastFuture = _loadForecasts();
    });
  },
  showRetryButton: true,
)
```

**Available Reasons:**
- `INSUFFICIENT_DATA` - Need 5+ weeks of sales data
- `NOT_SELLING` - Product not currently being sold
- `ERROR` - Error during forecast generation
- `LOADING` - Generating forecast (shows spinner)
- `null` - Generic unavailable message

---

## 📋 Common Patterns

### Pattern 1: FutureBuilder with Both Widgets

```dart
FutureBuilder<List<ForecastModel>>(
  future: _forecastFuture,
  builder: (context, snapshot) {
    // Loading state
    if (snapshot.connectionState == ConnectionState.waiting) {
      return NoForecastPlaceholder(reason: 'LOADING');
    }
    
    // Error state
    if (snapshot.hasError) {
      return NoForecastPlaceholder(
        reason: 'ERROR',
        onRetry: () => setState(() => _forecastFuture = _loadForecasts()),
        showRetryButton: true,
      );
    }
    
    // No data
    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return NoForecastPlaceholder(
        productName: widget.productName,
        reason: 'INSUFFICIENT_DATA',
      );
    }
    
    // Success
    final forecast = snapshot.data!.first;
    return Column(
      children: [
        ModelMetadataTag(
          modelType: forecast.modelType,
          confidenceLevel: forecast.confidenceLevel,
        ),
        ForecastCard(forecast: forecast),
      ],
    );
  },
)
```

### Pattern 2: Conditional Display in ListView

```dart
ListView.builder(
  itemCount: forecasts.length,
  itemBuilder: (context, index) {
    final forecast = forecasts[index];
    
    // Show placeholder for unavailable forecasts
    if (forecast.modelType == 'INSUFFICIENT_DATA') {
      return NoForecastPlaceholder(
        productName: forecast.productName,
        reason: 'INSUFFICIENT_DATA',
      );
    }
    
    return Card(
      child: Column(
        children: [
          ModelMetadataTag(
            modelType: forecast.modelType,
            confidenceLevel: forecast.confidenceLevel,
          ),
          ForecastCard(forecast: forecast),
        ],
      ),
    );
  },
)
```

### Pattern 3: Dashboard Overview

```dart
GridView.count(
  crossAxisCount: 2,
  children: forecasts.map((forecast) {
    return Container(
      child: forecast.isReliable
          ? Column(
              children: [
                ModelMetadataTag(
                  modelType: forecast.modelType,
                  confidenceLevel: forecast.confidenceLevel,
                  fontSize: 11,
                ),
                ForecastCard(forecast: forecast),
              ],
            )
          : NoForecastPlaceholder(
              productName: forecast.productName,
              reason: forecast.modelType == 'INSUFFICIENT_DATA'
                  ? 'INSUFFICIENT_DATA'
                  : 'ERROR',
            ),
    );
  }).toList(),
)
```

---

## 🎨 Styling Tips

### Custom Colors
To override colors, extend or wrap the widgets:

```dart
// Wrapper for custom theming
Widget buildForecastTag(String modelType, String confidence) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      color: Colors.blue.withOpacity(0.1),
    ),
    child: ModelMetadataTag(
      modelType: modelType,
      confidenceLevel: confidence,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );
}
```

### Size Variants

**Small Tag (for lists):**
```dart
ModelMetadataTag(
  modelType: forecast.modelType,
  confidenceLevel: forecast.confidenceLevel,
  fontSize: 10,
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
)
```

**Large Tag (for details):**
```dart
ModelMetadataTag(
  modelType: forecast.modelType,
  confidenceLevel: forecast.confidenceLevel,
  fontSize: 14,
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
)
```

---

## 🔄 Integration Checklist

- [ ] Import widgets in your screen file
- [ ] Use ModelMetadataTag in forecast display
- [ ] Use NoForecastPlaceholder for error/loading states
- [ ] Test dark mode appearance
- [ ] Test with different model types and confidence levels
- [ ] Test retry callbacks
- [ ] Test responsive behavior on different screen sizes
- [ ] Add to analytics dashboard screens
- [ ] Document in admin training materials

---

## 💡 Best Practices

### DO ✅
- Use ModelMetadataTag in forecast cards to show model quality at a glance
- Use NoForecastPlaceholder for all unavailable states
- Provide meaningful onRetry callbacks
- Test with both dark and light themes
- Use appropriate reason for each scenario

### DON'T ❌
- Don't show ModelMetadataTag without context (use in cards/details)
- Don't mix reason types (use specific reason for accuracy)
- Don't disable retry button for ERROR states
- Don't hardcode colors (use getters in widgets)
- Don't forget null checks on optional parameters

---

## 🧪 Testing Snippets

### Widget Test Template

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:opas_flutter/features/admin/widgets/model_metadata_tag.dart';

void main() {
  testWidgets('ModelMetadataTag displays SARIMA with HIGH confidence', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ModelMetadataTag(
            modelType: 'SARIMA',
            confidenceLevel: 'HIGH',
          ),
        ),
      ),
    );
    
    expect(find.text('SARIMA'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
  });
}
```

---

## 📞 Support

For questions or issues with these widgets:
1. Check the phase 5.2 complete documentation
2. Review the widget source code (well-commented)
3. Test with debug output:
   ```dart
   print('ModelType: $modelType, Confidence: $confidenceLevel');
   ```
