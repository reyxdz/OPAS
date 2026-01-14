"""
Data Aggregator Service for Forecasting

Collects transaction data from SellerOrder to build historical
time series data for forecasting models.
"""

from decimal import Decimal
from typing import Optional, Tuple
import pandas as pd
import numpy as np
from django.utils import timezone
from django.db.models import QuerySet
from apps.users.seller_models import SellerOrder, SellerProduct, OrderStatus
from apps.forecasting.models import HistoricalTransactions


class DataAggregator:
    """
    Collects and aggregates transaction data from SellerOrder records
    to build historical time series data for forecasting models.
    
    Workflow:
    1. Collect all fulfilled/delivered orders for a product
    2. Convert to DataFrame with date, quantity, price
    3. Aggregate to weekly or monthly periods
    4. Validate data quality
    5. Store in HistoricalTransactions table
    """
    
    # Completed order statuses to include in aggregation
    COMPLETED_STATUSES = [OrderStatus.FULFILLED, OrderStatus.DELIVERED]
    
    @staticmethod
    def collect_product_transactions(product_id: int) -> pd.DataFrame:
        """
        Query SellerOrder records for a product and extract transaction data.
        
        Only includes orders with FULFILLED or DELIVERED status.
        
        Args:
            product_id: ID of the SellerProduct
            
        Returns:
            DataFrame with columns: [date, quantity_kg, price_per_kg]
            Index: DatetimeIndex
            
        Raises:
            SellerProduct.DoesNotExist: If product doesn't exist
        """
        # Verify product exists
        product = SellerProduct.objects.get(id=product_id)
        
        # Query completed orders for this product
        orders = SellerOrder.objects.filter(
            product_id=product_id,
            status__in=DataAggregator.COMPLETED_STATUSES
        ).select_related('product').order_by('created_at')
        
        # If no orders, return empty DataFrame
        if not orders.exists():
            return pd.DataFrame(
                columns=['date', 'quantity_kg', 'price_per_kg']
            ).set_index('date')
        
        # Convert to list of dicts for DataFrame creation
        data = []
        for order in orders:
            # Determine order date (use fulfilled_at if available, else created_at)
            order_date = order.fulfilled_at or order.created_at
            
            data.append({
                'date': order_date,
                'quantity_kg': float(order.quantity),
                'price_per_kg': float(order.price_per_unit),
            })
        
        # Create DataFrame and set date as index
        df = pd.DataFrame(data)
        df['date'] = pd.to_datetime(df['date'])
        df = df.set_index('date').sort_index()
        
        return df
    
    @staticmethod
    def aggregate_to_weekly(df: pd.DataFrame) -> pd.DataFrame:
        """
        Resample transaction-level data to weekly aggregates.
        
        - Quantity: Sum across week
        - Price: Mean across week
        
        Args:
            df: DataFrame with index as datetime and columns [quantity_kg, price_per_kg]
            
        Returns:
            Weekly aggregated DataFrame
        """
        if df.empty:
            return df
        
        weekly = df.resample('W').agg({
            'quantity_kg': 'sum',
            'price_per_kg': 'mean'
        })
        
        return weekly
    
    @staticmethod
    def aggregate_to_monthly(df: pd.DataFrame) -> pd.DataFrame:
        """
        Resample transaction-level data to monthly aggregates.
        
        Used when not enough weekly data points.
        
        - Quantity: Sum across month
        - Price: Mean across month
        
        Args:
            df: DataFrame with index as datetime and columns [quantity_kg, price_per_kg]
            
        Returns:
            Monthly aggregated DataFrame
        """
        if df.empty:
            return df
        
        monthly = df.resample('M').agg({
            'quantity_kg': 'sum',
            'price_per_kg': 'mean'
        })
        
        return monthly
    
    @staticmethod
    def validate_data_quality(df: pd.DataFrame) -> Tuple[int, int]:
        """
        Validate data quality and return metrics.
        
        Checks:
        - Minimum 5 data points
        - Missing values percentage
        - Variance (ensure data isn't flat)
        
        Args:
            df: DataFrame with aggregated data
            
        Returns:
            Tuple of (data_points_count, quality_score_0_to_100)
            
        Example:
            >>> df = pd.DataFrame({'quantity_kg': [100, 110, 105], 'price_per_kg': [50, 51, 50]})
            >>> count, score = DataAggregator.validate_data_quality(df)
            >>> print(f"Points: {count}, Quality: {score}")
            Points: 3, Quality: 50
        """
        if df.empty:
            return 0, 0
        
        # Count valid data points
        data_points = len(df)
        
        # Check for minimum threshold (5 points needed)
        if data_points < 5:
            quality_score = max(0, (data_points / 5) * 60)  # Scale 0-60% for <5 points
            return data_points, int(quality_score)
        
        # Calculate missing values percentage
        total_values = df.size
        missing_values = df.isna().sum().sum()
        missing_percentage = (missing_values / total_values) * 100 if total_values > 0 else 0
        
        # Check for variance (data shouldn't be flat)
        quantity_variance = df['quantity_kg'].var()
        price_variance = df['price_per_kg'].var()
        has_variance = (quantity_variance > 0) and (price_variance > 0)
        
        # Calculate quality score (0-100)
        # - Max 40 points for enough data points
        # - Max 40 points for low missing values
        # - Max 20 points for good variance
        
        data_points_score = min(40, (data_points / 24) * 40)  # Max 40 with 24+ points
        
        missing_score = max(0, 40 - (missing_percentage * 0.4))  # Deduct 0.4 per %
        
        variance_score = 20 if has_variance else 5
        
        quality_score = data_points_score + missing_score + variance_score
        quality_score = min(100, max(0, quality_score))  # Clamp 0-100
        
        return data_points, int(quality_score)
    
    @staticmethod
    def aggregate_and_store(
        product_id: int,
        aggregation_period: str = 'W'
    ) -> Tuple[int, int]:
        """
        Complete workflow: collect → aggregate → validate → store.
        
        Args:
            product_id: ID of SellerProduct to aggregate
            aggregation_period: 'W' for weekly, 'M' for monthly (default: weekly)
            
        Returns:
            Tuple of (records_created, quality_score)
            
        Raises:
            SellerProduct.DoesNotExist: If product doesn't exist
            ValueError: If aggregation_period not 'W' or 'M'
        """
        if aggregation_period not in ('W', 'M'):
            raise ValueError("aggregation_period must be 'W' (weekly) or 'M' (monthly)")
        
        # Step 1: Collect transactions
        df = DataAggregator.collect_product_transactions(product_id)
        
        # If no data, return early
        if df.empty:
            return 0, 0
        
        # Step 2: Aggregate to selected period
        if aggregation_period == 'W':
            df_agg = DataAggregator.aggregate_to_weekly(df)
        else:
            df_agg = DataAggregator.aggregate_to_monthly(df)
        
        # Remove any remaining NaN rows
        df_agg = df_agg.dropna()
        
        if df_agg.empty:
            return 0, 0
        
        # Step 3: Validate quality
        data_points_count, quality_score = DataAggregator.validate_data_quality(df_agg)
        
        # Step 4: Store in HistoricalTransactions
        product = SellerProduct.objects.get(id=product_id)
        records_created = 0
        
        for date_idx, row in df_agg.iterrows():
            # Convert pandas Timestamp to Python date
            transaction_date = date_idx.date() if hasattr(date_idx, 'date') else date_idx
            
            # Calculate total revenue
            quantity = Decimal(str(row['quantity_kg']))
            price = Decimal(str(row['price_per_kg']))
            total_revenue = quantity * price
            
            # Create or update HistoricalTransaction
            obj, created = HistoricalTransactions.objects.update_or_create(
                product=product,
                transaction_date=transaction_date,
                defaults={
                    'quantity_sold_kg': quantity,
                    'average_price_per_kg': price,
                    'total_revenue': total_revenue,
                    'data_quality_score': quality_score,
                    'is_complete': True,
                }
            )
            
            if created:
                records_created += 1
        
        return records_created, quality_score
    
    @staticmethod
    def aggregate_all_products() -> dict:
        """
        Aggregate data for all active products.
        
        Returns:
            Dict with product_id as key and (records_created, quality_score) as value
            
        Example:
            >>> results = DataAggregator.aggregate_all_products()
            >>> for product_id, (records, score) in results.items():
            ...     print(f"Product {product_id}: {records} records, {score}% quality")
        """
        results = {}
        
        # Get all active products
        active_products = SellerProduct.objects.filter(
            is_deleted=False,
            status='ACTIVE'
        )
        
        for product in active_products:
            try:
                records, score = DataAggregator.aggregate_and_store(product.id)
                results[product.id] = (records, score)
            except Exception as e:
                # Log error but continue with next product
                results[product.id] = (0, 0)  # Mark as failed
        
        return results
    
    @staticmethod
    def get_data_coverage_stats(product_id: int) -> dict:
        """
        Get data coverage statistics for a product.
        
        Args:
            product_id: ID of SellerProduct
            
        Returns:
            Dict with coverage statistics
        """
        # Get all historical transactions for product
        transactions = HistoricalTransactions.objects.filter(
            product_id=product_id
        ).order_by('transaction_date')
        
        if not transactions.exists():
            return {
                'total_periods': 0,
                'complete_periods': 0,
                'coverage_percentage': 0,
                'date_range': None,
            }
        
        total_periods = transactions.count()
        complete_periods = transactions.filter(is_complete=True).count()
        
        first_date = transactions.first().transaction_date
        last_date = transactions.last().transaction_date
        
        coverage_percentage = (complete_periods / total_periods * 100) if total_periods > 0 else 0
        
        return {
            'total_periods': total_periods,
            'complete_periods': complete_periods,
            'coverage_percentage': round(coverage_percentage, 2),
            'date_range': f"{first_date} to {last_date}",
        }
