"""
Enhanced Serializers for Forecasting API.

Shows validation metrics and model comparison results to admins.
"""

from rest_framework import serializers
from apps.forecasting.models import ProductForecast, ForecastMetadata


class ValidationMetricsSerializer(serializers.Serializer):
    """
    Displays validation metrics for a model.
    
    Shows admins how accurate the forecast is based on test set validation.
    """
    mape = serializers.FloatField(help_text="Mean Absolute Percentage Error (%)")
    rmse = serializers.FloatField(help_text="Root Mean Squared Error")
    mae = serializers.FloatField(help_text="Mean Absolute Error")
    smape = serializers.FloatField(help_text="Symmetric MAPE (%)")
    is_successful = serializers.BooleanField()


class ModelComparisonResultSerializer(serializers.Serializer):
    """
    Shows the comparison results between SARIMA, ARIMA, and SIMPLE models.
    
    Admins can see which model performed best and by how much.
    """
    model_type = serializers.CharField()
    mape = serializers.FloatField(allow_null=True)
    rmse = serializers.FloatField(allow_null=True)
    mae = serializers.FloatField(allow_null=True)
    is_successful = serializers.BooleanField()


class ModelComparisonSerializer(serializers.Serializer):
    """
    Full model comparison results.
    """
    best_model = serializers.CharField()
    best_mape = serializers.FloatField()
    ranking = serializers.ListField(
        child=serializers.DictField(),
        help_text="Models ranked by MAPE (best to worst)"
    )
    results = serializers.DictField(
        child=ModelComparisonResultSerializer(),
        help_text="Individual results for each model"
    )


class ForecastMetadataDetailedSerializer(serializers.ModelSerializer):
    """
    Enhanced metadata serializer showing validation metrics.
    
    Admins can see:
    - How many data points the model was trained on
    - Validation MAPE (how accurate the model is)
    - Which models were compared and which won
    - When the model was last validated
    """
    product_name = serializers.CharField(source='product.name', read_only=True)
    demand_validation = serializers.SerializerMethodField()
    price_validation = serializers.SerializerMethodField()
    model_comparison = serializers.SerializerMethodField()
    confidence_based_on_validation = serializers.SerializerMethodField()
    
    class Meta:
        model = ForecastMetadata
        fields = [
            'product_name',
            'model_type',
            'data_points_count',
            'is_reliable',
            'validation_mape_demand',
            'validation_mape_price',
            'validation_rmse_demand',
            'validation_rmse_price',
            'validation_mae_demand',
            'validation_mae_price',
            'validation_sample_size',
            'validation_date',
            'demand_validation',
            'price_validation',
            'model_comparison',
            'confidence_based_on_validation',
            'last_training_date',
            'last_successful_forecast_date',
            'notes',
        ]
    
    def get_demand_validation(self, obj):
        """Return demand validation metrics"""
        if obj.validation_mape_demand is not None:
            return {
                'mape': float(obj.validation_mape_demand),
                'rmse': float(obj.validation_rmse_demand) if obj.validation_rmse_demand else None,
                'mae': float(obj.validation_mae_demand) if obj.validation_mae_demand else None,
                'status': 'HIGH' if obj.validation_mape_demand <= 10 else ('MEDIUM' if obj.validation_mape_demand <= 20 else 'LOW')
            }
        return None
    
    def get_price_validation(self, obj):
        """Return price validation metrics"""
        if obj.validation_mape_price is not None:
            return {
                'mape': float(obj.validation_mape_price),
                'rmse': float(obj.validation_rmse_price) if obj.validation_rmse_price else None,
                'mae': float(obj.validation_mae_price) if obj.validation_mae_price else None,
                'status': 'HIGH' if obj.validation_mape_price <= 10 else ('MEDIUM' if obj.validation_mape_price <= 20 else 'LOW')
            }
        return None
    
    def get_model_comparison(self, obj):
        """Return model comparison results"""
        if obj.model_comparison_results:
            return obj.model_comparison_results
        return None
    
    def get_confidence_based_on_validation(self, obj):
        """
        Calculate confidence level based on actual validation MAPE.
        
        This is better than just data availability - it's based on real accuracy!
        """
        if obj.validation_mape_demand is not None:
            mape = float(obj.validation_mape_demand)
            if mape <= 10:
                return 'HIGH (±' + f'{mape:.1f}%' + ')'
            elif mape <= 20:
                return 'MEDIUM (±' + f'{mape:.1f}%' + ')'
            else:
                return 'LOW (±' + f'{mape:.1f}%' + ')'
        return 'UNKNOWN (not yet validated)'


class ForecastDetailedSerializer(serializers.ModelSerializer):
    """
    Enhanced forecast serializer showing validation context.
    """
    product_name = serializers.CharField(source='product.name', read_only=True)
    product_category = serializers.CharField(source='product.category.name', read_only=True)
    
    # Include validation metrics from metadata
    validation_mape = serializers.SerializerMethodField()
    validation_confidence = serializers.SerializerMethodField()
    model_accuracy_info = serializers.SerializerMethodField()
    
    class Meta:
        model = ProductForecast
        fields = [
            'id',
            'product_id',
            'product_name',
            'product_category',
            'forecast_date',
            'forecast_period',
            'model_type',
            'demand_forecast_kg',
            'demand_lower_bound',
            'demand_upper_bound',
            'price_forecast',
            'price_lower_bound',
            'price_upper_bound',
            'confidence_level',
            'mape_demand',
            'mape_price',
            'validation_mape',
            'validation_confidence',
            'model_accuracy_info',
            'is_current',
        ]
    
    def get_validation_mape(self, obj):
        """Get validation MAPE from related metadata"""
        if hasattr(obj.product, 'forecast_metadata'):
            metadata = obj.product.forecast_metadata
            return {
                'demand': float(metadata.validation_mape_demand) if metadata.validation_mape_demand else None,
                'price': float(metadata.validation_mape_price) if metadata.validation_mape_price else None,
            }
        return None
    
    def get_validation_confidence(self, obj):
        """Get confidence level based on validation results"""
        if hasattr(obj.product, 'forecast_metadata'):
            metadata = obj.product.forecast_metadata
            if metadata.validation_mape_demand:
                mape = float(metadata.validation_mape_demand)
                if mape <= 10:
                    return 'HIGH'
                elif mape <= 20:
                    return 'MEDIUM'
                else:
                    return 'LOW'
        return obj.confidence_level
    
    def get_model_accuracy_info(self, obj):
        """Provide detailed accuracy information"""
        if hasattr(obj.product, 'forecast_metadata'):
            metadata = obj.product.forecast_metadata
            return {
                'model_type': metadata.model_type,
                'training_data_points': metadata.data_points_count,
                'validation_date': metadata.validation_date.isoformat() if metadata.validation_date else None,
                'demand_mape_validation': float(metadata.validation_mape_demand) if metadata.validation_mape_demand else None,
                'price_mape_validation': float(metadata.validation_mape_price) if metadata.validation_mape_price else None,
                'note': 'Based on test set validation - how accurate the model is'
            }
        return None
