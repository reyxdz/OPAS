"""
Product Grouping Service for Smart Forecasting

Groups similar products by category/type/subtype for better ML model training.
Example: "Bangus sa Kawayan" + "Bangus fresh" both group under Livestock > Fish > Bangus

This allows:
- Combining small datasets into larger ones for faster ML readiness
- Cross-supplier insights (which Bangus supplier sells more?)
- Smarter forecasting based on aggregate market demand
"""

from typing import Dict, List, Tuple, Optional
from decimal import Decimal
from datetime import datetime, timedelta
import logging
from django.db import models
from django.utils import timezone

logger = logging.getLogger(__name__)


class ProductGroupingService:
    """
    Service for grouping products by category/type/subtype
    and generating forecasts at the group level with individual adjustments
    """
    
    # Product hierarchy for OPAS Admin
    # Categories must match Flutter app categories: VEGETABLE, FRUIT, LIVESTOCK, POULTRY, SEEDS, FERTILIZERS, FEEDS, MEDICINES
    PRODUCT_HIERARCHY = {
        'VEGETABLE': {
            'Leafy': ['Kale', 'Lettuce', 'Spinach', 'Cabbage', 'Pechay'],
            'Root': ['Carrot', 'Radish', 'Turnip', 'Potato', 'Onion'],
            'Fruiting': ['Tomato', 'Eggplant', 'Talong', 'Pepper', 'Chili'],
        },
        'FRUIT': {
            'Citrus': ['Calamansi', 'Orange', 'Lemon', 'Lime'],
            'Tropical': ['Banana', 'Mango', 'Pineapple', 'Papaya', 'Avocado'],
            'Berries': ['Strawberry', 'Blueberry', 'Blackberry'],
        },
        'LIVESTOCK': {
            'Fish': ['Bangus', 'Tilapia', 'Catfish', 'Tuna', 'Lapu-lapu'],
            'Poultry': ['Chicken', 'Duck', 'Quail', 'Turkey'],
            'Meat': ['Pork', 'Beef', 'Goat', 'Lamb'],
            'Dairy': ['Milk', 'Cheese', 'Yogurt'],
        },
        'POULTRY': {
            'Chicken': ['Broiler', 'Layer', 'Free-range', 'Organic'],
            'Duck': ['Muscovy', 'Peking', 'Khaki Campbell'],
            'Other': ['Quail', 'Turkey', 'Goose'],
        },
        'SEEDS': {
            'Vegetable': ['Tomato', 'Pepper', 'Eggplant', 'Cucumber', 'Squash'],
            'Field Crops': ['Rice', 'Corn', 'Wheat', 'Soybean'],
            'Herbs': ['Basil', 'Mint', 'Oregano', 'Parsley'],
        },
        'FERTILIZERS': {
            'Organic': ['Compost', 'Animal Manure', 'Vermicompost'],
            'Inorganic': ['NPK', 'Urea', 'Phosphate', 'Potash'],
            'Specialty': ['Micronutrient', 'Foliar', 'Bio-fertilizer'],
        },
        'FEEDS': {
            'Poultry': ['Layer Feed', 'Broiler Feed', 'Starter Feed'],
            'Livestock': ['Cattle Feed', 'Swine Feed', 'Fish Feed'],
            'Aquaculture': ['Fingerling Feed', 'Juvenile Feed', 'Finishing Feed'],
        },
        'MEDICINES': {
            'Veterinary': ['Antibiotics', 'Antiparasitic', 'Vitamins'],
            'Plant': ['Fungicide', 'Insecticide', 'Herbicide'],
            'Supplements': ['Growth Promoter', 'Immune Booster'],
        },
    }
    
    @staticmethod
    def get_product_group_key(product) -> str:
        """
        Generate unique group key for an OPAS product
        Format: category:type:subtype
        
        Args:
            product: OPASProduct instance with category_forecast, product_type, product_subtype
            
        Returns:
            Group key string
        """
        return f"{product.category_forecast}:{product.product_type}:{product.product_subtype}"
    
    @staticmethod
    def get_products_in_group(product) -> models.QuerySet:
        """
        Get all active OPAS products belonging to the same group
        
        Args:
            product: OPASProduct instance with category_forecast, product_type, product_subtype
            
        Returns:
            QuerySet of OPAS products in same category/type/subtype
        """
        from apps.users.opas_models import OPASProduct
        
        return OPASProduct.objects.filter(
            category_forecast=product.category_forecast,
            product_type=product.product_type,
            product_subtype=product.product_subtype,
            is_active=True
        )
    
    @staticmethod
    def get_combined_sales_data(
        product,
        days_back: int = 180
    ) -> Tuple[List[Dict], Dict[int, float]]:
        """
        Combine OPAS sales data from all products in the same group
        
        CRITICAL: This method queries OPASProductSale table (OPAS admin historical sales)
        NOT SellerOrder (regular marketplace seller orders)
        
        Args:
            product: OPASProduct instance for group identification
            days_back: Number of days to look back
            
        Returns:
            Tuple of (combined_sales_data, product_weights)
            where product_weights maps product_id to average daily sales
        """
        from apps.users.opas_models import OPASProductSale
        
        group_products = ProductGroupingService.get_products_in_group(product)
        combined_sales = []
        product_weights = {}
        
        cutoff_date = timezone.now().date() - timedelta(days=days_back)
        
        for prod in group_products:
            try:
                # Query OPASProductSale (OPAS admin historical sales) NOT SellerOrder
                sales_records = OPASProductSale.objects.filter(
                    opas_product=prod,
                    sale_date__date__gte=cutoff_date
                ).values('sale_date__date').annotate(
                    quantity=models.Sum('quantity_sold'),
                    avg_price=models.Avg('price_per_unit')
                )
                
                sales = [
                    {
                        'date': record['sale_date__date'],
                        'quantity': int(record['quantity'] or 0),
                        'price': float(record['avg_price'] or 0),
                        'product_id': prod.id,
                        'product_name': prod.name,
                    }
                    for record in sales_records
                ]
                
                combined_sales.extend(sales)
                
                # Calculate weight (average daily sales for this product)
                if sales:
                    daily_avg = sum(s['quantity'] for s in sales) / len(sales)
                    product_weights[prod.id] = daily_avg
                else:
                    product_weights[prod.id] = 0
                    
            except Exception as e:
                logger.warning(f"Error getting OPAS sales for product {prod.id}: {e}")
                product_weights[prod.id] = 0
        
        # Sort by date
        combined_sales = sorted(combined_sales, key=lambda x: x['date'])
        
        logger.info(
            f"Combined {len(group_products)} OPAS products in group "
            f"{product.category_forecast}:{product.product_type}:{product.product_subtype} "
            f"with {len(combined_sales)} OPAS sales records"
        )
        
        return combined_sales, product_weights
    
    @staticmethod
    def get_group_data_summary(product) -> Dict:
        """
        Get summary statistics for an OPAS product group
        
        Args:
            product: OPASProduct instance
            
        Returns:
            Dict with group statistics
        """
        group_products = ProductGroupingService.get_products_in_group(product)
        combined_sales, product_weights = ProductGroupingService.get_combined_sales_data(product)
        
        if not combined_sales:
            return {
                'group_key': ProductGroupingService.get_product_group_key(product),
                'category': product.category_forecast,
                'type': product.product_type,
                'subtype': product.product_subtype,
                'product_count': group_products.count(),
                'total_data_points': 0,
                'status': 'NO_DATA',
                'message': 'No OPAS sales data available yet',
            }
        
        total_data_points = len(combined_sales)
        
        # Determine forecasting status
        if total_data_points < 20:
            status = 'NO_FORECAST'
        elif total_data_points < 60:
            status = 'BASIC_FORECAST'
        else:
            status = 'ADVANCED_FORECAST'
        
        total_quantity = sum(s['quantity'] for s in combined_sales)
        avg_daily = total_quantity / total_data_points if total_data_points > 0 else 0
        
        return {
            'group_key': ProductGroupingService.get_product_group_key(product),
            'category': product.category_forecast,
            'type': product.product_type,
            'subtype': product.product_subtype,
            'product_count': group_products.count(),
            'product_ids': [p.id for p in group_products],
            'total_data_points': total_data_points,
            'total_quantity': total_quantity,
            'average_daily': round(avg_daily, 2),
            'status': status,
            'days_until_basic': max(0, 20 - total_data_points),
            'days_until_advanced': max(0, 60 - total_data_points),
        }
    
    @staticmethod
    def forecast_with_grouping(product, forecast_algorithm=None, hybrid_forecaster=None):
        """
        Generate forecast using group data with individual product adjustments
        
        Args:
            product: Individual product to forecast
            forecast_algorithm: ForecastingAlgorithm instance
            hybrid_forecaster: HybridForecastingStrategy instance
            
        Returns:
            Forecast dict with group info and individual adjustment
        """
        from apps.users.forecasting_algorithm import ForecastingAlgorithm
        from apps.users.hybrid_forecasting import create_hybrid_forecaster
        
        # Initialize if not provided
        if not forecast_algorithm:
            forecast_algorithm = ForecastingAlgorithm()
        if not hybrid_forecaster:
            hybrid_forecaster = create_hybrid_forecaster()
        
        # Get combined group data
        combined_sales, product_weights = ProductGroupingService.get_combined_sales_data(product)
        
        if not combined_sales or len(combined_sales) < 3:
            return {
                'status': 'INSUFFICIENT_DATA',
                'message': 'Not enough group data for forecasting',
                'product_id': product.id,
                'group_key': ProductGroupingService.get_product_group_key(product),
            }
        
        try:
            # Generate group-level forecast
            group_forecast = hybrid_forecaster.generate_hybrid_forecast(
                sales_data=combined_sales,
                current_stock=product.stock_level,
                min_stock=product.minimum_stock,
                forecast_algorithm=forecast_algorithm
            )
            
            # Calculate product-specific multiplier
            group_avg = sum(s['quantity'] for s in combined_sales) / len(combined_sales)
            product_avg = product_weights.get(product.id, group_avg)
            multiplier = (product_avg / group_avg) if group_avg > 0 else 1.0
            
            # Apply multiplier to individual forecast
            individual_forecast = group_forecast.copy()
            individual_forecast['forecasted_demand'] = int(
                group_forecast['forecasted_demand'] * multiplier
            )
            
            # Adjust confidence based on product's data contribution
            product_data_points = len([s for s in combined_sales if s.get('product_id') == product.id])
            data_contribution = product_data_points / len(combined_sales) if combined_sales else 0
            
            # If product has less than 30% of data, reduce confidence slightly
            if data_contribution < 0.3:
                original_confidence = individual_forecast.get('confidence_score', 50)
                individual_forecast['confidence_score'] = max(30, original_confidence - 10)
            
            # Add grouping information
            individual_forecast['grouping_info'] = {
                'group_key': ProductGroupingService.get_product_group_key(product),
                'category': product.category_forecast,
                'type': product.product_type,
                'subtype': product.product_subtype,
                'group_forecast': int(group_forecast['forecasted_demand']),
                'product_multiplier': round(multiplier, 3),
                'total_products_in_group': len(product_weights),
                'total_group_data_points': len(combined_sales),
                'product_data_points': product_data_points,
                'data_contribution_percent': round(data_contribution * 100, 1),
            }
            
            logger.info(
                f"Generated grouped forecast for product {product.id} "
                f"({product.name}) with multiplier {multiplier:.3f}"
            )
            
            return individual_forecast
            
        except Exception as e:
            logger.error(f"Error generating grouped forecast: {e}")
            return {
                'status': 'ERROR',
                'message': str(e),
                'product_id': product.id,
                'group_key': ProductGroupingService.get_product_group_key(product),
            }
    
    @staticmethod
    def get_group_forecast_breakdown(product, forecast_algorithm=None, hybrid_forecaster=None) -> Dict:
        """
        Get forecast breakdown for entire group with individual product forecasts
        
        Args:
            product: Any product in the group
            forecast_algorithm: ForecastingAlgorithm instance
            hybrid_forecaster: HybridForecastingStrategy instance
            
        Returns:
            Dict with group forecast and individual product forecasts
        """
        from apps.users.forecasting_algorithm import ForecastingAlgorithm
        from apps.users.hybrid_forecasting import create_hybrid_forecaster
        
        if not forecast_algorithm:
            forecast_algorithm = ForecastingAlgorithm()
        if not hybrid_forecaster:
            hybrid_forecaster = create_hybrid_forecaster()
        
        group_summary = ProductGroupingService.get_group_data_summary(product)
        
        if group_summary['status'] == 'NO_DATA':
            return group_summary
        
        # Get forecasts for all products in group
        group_products = ProductGroupingService.get_products_in_group(product)
        individual_forecasts = []
        
        for prod in group_products:
            prod_forecast = ProductGroupingService.forecast_with_grouping(
                prod,
                forecast_algorithm,
                hybrid_forecaster
            )
            
            if prod_forecast.get('status') != 'INSUFFICIENT_DATA':
                individual_forecasts.append({
                    'product_id': prod.id,
                    'product_name': prod.name,
                    'price': float(prod.price or 0),
                    'forecasted_demand': prod_forecast.get('forecasted_demand', 0),
                    'confidence_score': prod_forecast.get('confidence_score', 0),
                    'multiplier': prod_forecast.get('grouping_info', {}).get('product_multiplier', 1.0),
                })
        
        # Sum individual forecasts to get group total
        group_total = sum(f['forecasted_demand'] for f in individual_forecasts)
        
        return {
            'group_key': group_summary['group_key'],
            'category': group_summary['category'],
            'type': group_summary['type'],
            'subtype': group_summary['subtype'],
            'status': group_summary['status'],
            'product_count': group_summary['product_count'],
            'total_data_points': group_summary['total_data_points'],
            'group_total_forecast': group_total,
            'individual_forecasts': individual_forecasts,
            'average_forecast_per_product': round(group_total / len(individual_forecasts), 0) if individual_forecasts else 0,
        }


class ProductClassificationHelper:
    """Helper functions for product classification"""
    
    @staticmethod
    def get_hierarchy():
        """Get the product hierarchy"""
        return ProductGroupingService.PRODUCT_HIERARCHY
    
    @staticmethod
    def get_categories() -> List[str]:
        """Get all available categories"""
        return list(ProductGroupingService.PRODUCT_HIERARCHY.keys())
    
    @staticmethod
    def get_types_for_category(category: str) -> List[str]:
        """Get all types for a given category"""
        hierarchy = ProductGroupingService.PRODUCT_HIERARCHY
        if category in hierarchy:
            return list(hierarchy[category].keys())
        return []
    
    @staticmethod
    def get_subtypes_for_type(category: str, product_type: str) -> List[str]:
        """Get all subtypes for a given category and type"""
        hierarchy = ProductGroupingService.PRODUCT_HIERARCHY
        if category in hierarchy and product_type in hierarchy[category]:
            return hierarchy[category][product_type]
        return []
    
    @staticmethod
    def is_valid_classification(category: str, product_type: str, subtype: str) -> bool:
        """Validate product classification"""
        hierarchy = ProductGroupingService.PRODUCT_HIERARCHY
        return (
            category in hierarchy
            and product_type in hierarchy.get(category, {})
            and subtype in hierarchy.get(category, {}).get(product_type, [])
        )
    
    @staticmethod
    def add_type(category: str, product_type: str) -> bool:
        """
        Add a new product type to a category in the hierarchy
        
        Note: This updates the in-memory PRODUCT_HIERARCHY dict.
        For production, consider persisting to database.
        """
        hierarchy = ProductGroupingService.PRODUCT_HIERARCHY
        
        if category not in hierarchy:
            return False
        
        if product_type in hierarchy[category]:
            return False
        
        # Add new type with empty subtypes list
        hierarchy[category][product_type] = []
        logger.info(f"Added type '{product_type}' to category '{category}'")
        return True
    
    @staticmethod
    def add_subtype(category: str, product_type: str, subtype: str) -> bool:
        """
        Add a new product subtype to a type in the hierarchy
        
        Note: This updates the in-memory PRODUCT_HIERARCHY dict.
        For production, consider persisting to database.
        """
        hierarchy = ProductGroupingService.PRODUCT_HIERARCHY
        
        if category not in hierarchy:
            return False
        
        if product_type not in hierarchy[category]:
            return False
        
        if subtype in hierarchy[category][product_type]:
            return False
        
        # Add new subtype
        hierarchy[category][product_type].append(subtype)
        logger.info(f"Added subtype '{subtype}' to {category}/{product_type}")
        return True
