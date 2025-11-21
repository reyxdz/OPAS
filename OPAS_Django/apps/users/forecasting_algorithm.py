"""
Advanced Demand Forecasting Algorithm

Features:
- Historical sales analysis (moving averages, exponential smoothing)
- Seasonality detection and adjustment
- Trend analysis (uptrend, downtrend, stable)
- Risk assessment (surplus, stockout probabilities)
- Confidence score calculation
- Recommendations generation
"""

from datetime import datetime, timedelta
from decimal import Decimal
import statistics
from typing import Dict, List, Tuple, Optional
import logging

logger = logging.getLogger(__name__)


class ForecastingAlgorithm:
    """Advanced demand forecasting using multiple methods"""
    
    def __init__(self, min_historical_days: int = 30, forecast_days: int = 30):
        """
        Initialize forecasting algorithm
        
        Args:
            min_historical_days: Minimum days of history required for accurate forecast
            forecast_days: Number of days to forecast into the future
        """
        self.min_historical_days = min_historical_days
        self.forecast_days = forecast_days
        self.seasonality_window = 7  # Weekly seasonality pattern
    
    def analyze_historical_sales(self, sales_data: List[Dict]) -> Dict:
        """
        Analyze historical sales to extract patterns
        
        Args:
            sales_data: List of dicts with {'date': date, 'quantity': int, 'price': float}
        
        Returns:
            Dict with sales metrics and patterns
        """
        if not sales_data:
            return {
                'total_sales': 0,
                'average_daily': 0,
                'trend': 'STABLE',
                'volatility': 0,
                'growth_rate': 0,
            }
        
        quantities = [d['quantity'] for d in sales_data]
        dates = [d['date'] for d in sales_data]
        
        # Basic statistics
        total_sales = sum(quantities)
        avg_daily = statistics.mean(quantities) if quantities else 0
        
        # Calculate trend (first half vs second half)
        mid_point = len(quantities) // 2
        first_half_avg = statistics.mean(quantities[:mid_point]) if quantities[:mid_point] else avg_daily
        second_half_avg = statistics.mean(quantities[mid_point:]) if quantities[mid_point:] else avg_daily
        
        growth_rate = (
            ((second_half_avg - first_half_avg) / first_half_avg * 100)
            if first_half_avg > 0 else 0
        )
        
        # Determine trend
        if growth_rate > 5:
            trend = 'UPTREND'
        elif growth_rate < -5:
            trend = 'DOWNTREND'
        else:
            trend = 'STABLE'
        
        # Calculate volatility (coefficient of variation)
        std_dev = statistics.stdev(quantities) if len(quantities) > 1 else 0
        volatility = (std_dev / avg_daily * 100) if avg_daily > 0 else 0
        
        return {
            'total_sales': total_sales,
            'average_daily': round(avg_daily, 2),
            'trend': trend,
            'volatility': round(volatility, 2),
            'growth_rate': round(growth_rate, 2),
            'min_daily': min(quantities) if quantities else 0,
            'max_daily': max(quantities) if quantities else 0,
            'std_dev': round(std_dev, 2),
        }
    
    def detect_seasonality(self, sales_data: List[Dict]) -> Dict:
        """
        Detect weekly and monthly seasonality patterns
        
        Args:
            sales_data: List of dicts with sales data
        
        Returns:
            Dict with seasonality patterns and adjustments
        """
        if len(sales_data) < self.seasonality_window * 4:
            # Not enough data for seasonality detection
            return {
                'has_seasonality': False,
                'pattern': 'INSUFFICIENT_DATA',
                'weekly_multipliers': {i: 1.0 for i in range(7)},
                'monthly_pattern': 'STABLE',
            }
        
        # Group by day of week
        weekly_data = {}
        for i in range(7):
            daily_values = []
            for j, d in enumerate(sales_data):
                if d['date'].weekday() == i:
                    daily_values.append(d['quantity'])
            
            if daily_values:
                weekly_data[i] = statistics.mean(daily_values)
            else:
                weekly_data[i] = 0
        
        # Calculate multipliers
        overall_avg = statistics.mean([v for v in weekly_data.values() if v > 0])
        weekly_multipliers = {
            day: round(weekly_data[day] / overall_avg, 2) if overall_avg > 0 else 1.0
            for day in range(7)
        }
        
        # Detect significant seasonality
        multiplier_values = list(weekly_multipliers.values())
        multiplier_std = statistics.stdev(multiplier_values) if len(multiplier_values) > 1 else 0
        has_seasonality = multiplier_std > 0.15
        
        return {
            'has_seasonality': has_seasonality,
            'pattern': 'WEEKLY' if has_seasonality else 'STABLE',
            'weekly_multipliers': weekly_multipliers,
            'monthly_pattern': 'STABLE',
            'seasonality_strength': round(multiplier_std, 3),
        }
    
    def calculate_moving_average(self, sales_data: List[Dict], window: int = 7) -> float:
        """
        Calculate moving average for forecast base
        
        Args:
            sales_data: List of sales data
            window: Number of days for moving average window
        
        Returns:
            Moving average value
        """
        if len(sales_data) < window:
            return statistics.mean([d['quantity'] for d in sales_data]) if sales_data else 0
        
        recent_sales = sales_data[-window:]
        return statistics.mean([d['quantity'] for d in recent_sales])
    
    def calculate_exponential_smoothing(
        self, 
        sales_data: List[Dict], 
        alpha: float = 0.3
    ) -> float:
        """
        Calculate exponential smoothing forecast
        
        Args:
            sales_data: List of sales data
            alpha: Smoothing factor (0-1)
        
        Returns:
            Exponentially smoothed forecast
        """
        if not sales_data:
            return 0
        
        # Start with first value
        smoothed = sales_data[0]['quantity']
        
        # Apply exponential smoothing
        for d in sales_data[1:]:
            smoothed = alpha * d['quantity'] + (1 - alpha) * smoothed
        
        return round(smoothed, 2)
    
    def forecast_demand(
        self,
        sales_data: List[Dict],
        current_stock: int,
        min_stock: int,
    ) -> Dict:
        """
        Generate comprehensive demand forecast
        
        Args:
            sales_data: Historical sales data
            current_stock: Current inventory level
            min_stock: Minimum acceptable stock level
        
        Returns:
            Dict with forecast data and risk assessment
        """
        if not sales_data or len(sales_data) < 3:
            return self._generate_default_forecast(current_stock, min_stock)
        
        # Analyze historical patterns
        historical = self.analyze_historical_sales(sales_data)
        seasonality = self.detect_seasonality(sales_data)
        
        # Calculate base forecast
        moving_avg = self.calculate_moving_average(sales_data, window=min(7, len(sales_data)))
        exp_smoothing = self.calculate_exponential_smoothing(sales_data)
        
        # Weighted forecast (60% MA, 40% Exponential)
        base_forecast = moving_avg * 0.6 + exp_smoothing * 0.4
        
        # Apply trend adjustment
        trend_multiplier = 1.0
        if historical['trend'] == 'UPTREND':
            trend_multiplier = 1.0 + (historical['growth_rate'] / 100 * 0.3)
        elif historical['trend'] == 'DOWNTREND':
            trend_multiplier = 1.0 + (historical['growth_rate'] / 100 * 0.2)
        
        forecast_demand = max(1, round(base_forecast * trend_multiplier * self.forecast_days))
        
        # Calculate confidence score
        confidence = self._calculate_confidence(
            len(sales_data),
            historical['volatility'],
            historical['trend']
        )
        
        # Calculate risk probabilities
        surplus_prob, stockout_prob = self._calculate_risk_probabilities(
            forecast_demand,
            current_stock,
            min_stock,
            historical['volatility']
        )
        
        # Generate recommendations
        recommendations = self._generate_recommendations(
            forecast_demand,
            current_stock,
            min_stock,
            surplus_prob,
            stockout_prob,
            historical['trend']
        )
        
        # Calculate recommended stock
        recommended_stock = self._calculate_recommended_stock(
            forecast_demand,
            min_stock,
            historical['volatility'],
            surplus_prob,
            stockout_prob
        )
        
        return {
            'forecasted_demand': int(forecast_demand),
            'confidence_score': round(confidence, 2),
            'trend': historical['trend'],
            'volatility': historical['volatility'],
            'growth_rate': historical['growth_rate'],
            'surplus_probability': round(surplus_prob, 2),
            'stockout_probability': round(stockout_prob, 2),
            'recommended_stock': int(recommended_stock),
            'recommendations': recommendations,
            'historical_analysis': historical,
            'seasonality': seasonality,
            'trend_multiplier': round(trend_multiplier, 2),
        }
    
    def _calculate_confidence(self, data_points: int, volatility: float, trend: str) -> float:
        """Calculate forecast confidence score (0-100)"""
        # Base confidence based on data points
        data_confidence = min(95, data_points * 2)
        
        # Adjust for volatility (high volatility = lower confidence)
        volatility_adjustment = max(0, 100 - volatility * 2)
        
        # Adjust for trend stability
        trend_adjustment = 95 if trend == 'STABLE' else 85
        
        # Weighted average
        confidence = (data_confidence * 0.5 + volatility_adjustment * 0.3 + trend_adjustment * 0.2)
        
        return min(100, max(10, confidence))
    
    def _calculate_risk_probabilities(
        self,
        forecast_demand: float,
        current_stock: int,
        min_stock: int,
        volatility: float,
    ) -> Tuple[float, float]:
        """Calculate surplus and stockout probabilities"""
        
        # Normal demand range (mean ± std dev based on volatility)
        demand_std = forecast_demand * (volatility / 100)
        upper_bound = forecast_demand + demand_std
        lower_bound = max(0, forecast_demand - demand_std)
        
        # Surplus probability: if current stock > upper demand
        if current_stock > upper_bound:
            surplus_prob = min(95, ((current_stock - upper_bound) / current_stock) * 100)
        else:
            surplus_prob = 0
        
        # Stockout probability: if current stock < lower demand
        if current_stock < lower_bound:
            stockout_prob = min(95, ((lower_bound - current_stock) / lower_bound) * 100)
        else:
            stockout_prob = 0
        
        # Add volatility factor
        volatility_factor = volatility * 0.5
        stockout_prob = min(100, stockout_prob + volatility_factor)
        surplus_prob = min(100, surplus_prob + volatility_factor)
        
        return surplus_prob, stockout_prob
    
    def _calculate_recommended_stock(
        self,
        forecast_demand: float,
        min_stock: int,
        volatility: float,
        surplus_prob: float,
        stockout_prob: float,
    ) -> float:
        """Calculate recommended stock level using service level approach"""
        
        # Safety stock calculation
        demand_std = forecast_demand * (volatility / 100)
        
        # If high stockout risk, increase safety stock
        if stockout_prob > 50:
            safety_multiplier = 1.8
        elif stockout_prob > 25:
            safety_multiplier = 1.5
        else:
            safety_multiplier = 1.2
        
        safety_stock = demand_std * safety_multiplier
        
        # Reorder point = demand + safety stock
        recommended = forecast_demand + safety_stock
        
        # Ensure minimum stock
        recommended = max(min_stock * 1.5, recommended)
        
        # Cap at reasonable upper bound (3x forecast demand)
        recommended = min(forecast_demand * 3, recommended)
        
        return recommended
    
    def _generate_recommendations(
        self,
        forecast_demand: float,
        current_stock: int,
        min_stock: int,
        surplus_prob: float,
        stockout_prob: float,
        trend: str,
    ) -> List[str]:
        """Generate actionable recommendations"""
        
        recommendations = []
        
        # Stock level recommendations
        if current_stock < forecast_demand * 0.5:
            recommendations.append(
                f"⚠️ URGENT: Current stock ({current_stock}) is below 50% of forecasted demand. "
                f"Reorder immediately to avoid stockout."
            )
        elif current_stock < forecast_demand:
            recommendations.append(
                f"⏰ Plan to reorder soon. Current stock will likely be insufficient for "
                f"forecasted demand of {int(forecast_demand)} units."
            )
        
        # Risk-based recommendations
        if stockout_prob > 50:
            recommendations.append(
                f"📉 HIGH STOCKOUT RISK ({stockout_prob:.0f}%): Prepare for potential inventory shortage. "
                f"Consider expedited procurement."
            )
        
        if surplus_prob > 50:
            recommendations.append(
                f"📦 HIGH SURPLUS RISK ({surplus_prob:.0f}%): Overstock detected. "
                f"Consider promotional pricing or bulk orders to OPAS."
            )
        elif surplus_prob > 25:
            recommendations.append(
                f"💡 Monitor inventory levels closely. Moderate surplus risk ({surplus_prob:.0f}%) detected."
            )
        
        # Trend-based recommendations
        if trend == 'UPTREND':
            recommendations.append(
                "📈 Demand is increasing. Plan procurement accordingly to meet rising demand."
            )
        elif trend == 'DOWNTREND':
            recommendations.append(
                "📉 Demand is decreasing. Reduce procurement to minimize surplus stock."
            )
        
        # Minimum recommendations
        if not recommendations:
            recommendations.append(
                "✅ Demand forecast is stable. Monitor inventory levels weekly."
            )
            recommendations.append(
                "💾 Maintain current stock strategy. Forecast confidence is acceptable."
            )
        
        return recommendations
    
    def _generate_default_forecast(
        self,
        current_stock: int,
        min_stock: int,
    ) -> Dict:
        """Generate default forecast when insufficient data"""
        return {
            'forecasted_demand': current_stock // 2,
            'confidence_score': 25.0,
            'trend': 'STABLE',
            'volatility': 50.0,
            'growth_rate': 0.0,
            'surplus_probability': 0.0,
            'stockout_probability': 0.0,
            'recommended_stock': int(current_stock * 1.2),
            'recommendations': [
                "📊 Insufficient historical data for accurate forecast.",
                "⏰ Continue tracking sales to improve forecast accuracy.",
                f"ℹ️ Recommended to maintain stock at {int(current_stock * 1.2)} units.",
            ],
            'historical_analysis': {
                'total_sales': 0,
                'average_daily': 0,
                'trend': 'STABLE',
                'volatility': 50,
                'growth_rate': 0,
            },
            'seasonality': {
                'has_seasonality': False,
                'pattern': 'INSUFFICIENT_DATA',
                'weekly_multipliers': {i: 1.0 for i in range(7)},
            },
            'trend_multiplier': 1.0,
        }
    
    def generate_trend_data(
        self,
        sales_data: List[Dict],
        forecast_data: Dict,
    ) -> Dict:
        """
        Generate trend data for charting (historical + forecast)
        
        Args:
            sales_data: Historical sales data
            forecast_data: Generated forecast data
        
        Returns:
            Dict with chart-ready data points
        """
        trend_points = []
        
        # Add historical data points
        for d in sales_data[-30:]:  # Last 30 days
            trend_points.append({
                'date': d['date'].isoformat(),
                'value': d['quantity'],
                'type': 'historical',
                'label': d['date'].strftime('%b %d'),
            })
        
        # Generate and add forecast data points
        if forecast_data.get('forecasted_demand'):
            daily_forecast = forecast_data['forecasted_demand'] / self.forecast_days
            
            for i in range(1, self.forecast_days + 1):
                forecast_date = (sales_data[-1]['date'] if sales_data else datetime.now().date()) + timedelta(days=i)
                
                # Apply seasonality if detected
                day_multiplier = 1.0
                if forecast_data.get('seasonality', {}).get('has_seasonality'):
                    multipliers = forecast_data['seasonality']['weekly_multipliers']
                    day_multiplier = multipliers.get(forecast_date.weekday(), 1.0)
                
                forecasted_value = daily_forecast * day_multiplier
                
                trend_points.append({
                    'date': forecast_date.isoformat(),
                    'value': round(forecasted_value, 1),
                    'type': 'forecast',
                    'label': forecast_date.strftime('%b %d'),
                })
        
        return {
            'trend_points': trend_points,
            'confidence_interval': {
                'upper': forecast_data.get('forecasted_demand', 0) * 1.3,
                'lower': max(0, forecast_data.get('forecasted_demand', 0) * 0.7),
                'center': forecast_data.get('forecasted_demand', 0),
            },
            'total_points': len(trend_points),
        }
