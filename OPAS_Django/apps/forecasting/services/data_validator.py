"""
Data Validation Service - Validates data quality for forecasting.

Provides robust data validation to ensure:
- No NaN/null values in critical fields
- Outliers are detected and flagged
- Data completeness is verified
- Timestamp consistency is maintained

Author: OPAS System
Created: December 2025
"""

import logging
import numpy as np
import pandas as pd
from typing import Tuple, Dict, List
from decimal import Decimal

logger = logging.getLogger(__name__)


class DataValidator:
    """
    Validates historical transaction data before model training.
    
    Ensures data quality through:
    - NaN/missing value detection and handling
    - Outlier detection (IQR method)
    - Data completeness checks
    - Timestamp validation
    """
    
    # Outlier detection thresholds
    IQR_MULTIPLIER = 1.5  # Standard IQR multiplier for outlier detection
    MAX_NULL_PERCENTAGE = 0.4  # Max 40% missing values allowed
    MIN_DATA_POINTS = 5  # Minimum data points required
    
    @staticmethod
    def validate_dataframe(df: pd.DataFrame) -> Tuple[pd.DataFrame, Dict[str, any]]:
        """
        Comprehensive validation of historical transactions DataFrame.
        
        Args:
            df: DataFrame with columns ['quantity_kg', 'average_price']
            
        Returns:
            Tuple of (cleaned_dataframe, validation_report)
            
        Report contains:
            - is_valid: Boolean indicating if data passed validation
            - issues: List of issues found
            - null_count: Count of NaN values found
            - outliers_removed: Count of outliers removed
            - rows_before: Original row count
            - rows_after: Final row count
            - data_completeness: Percentage of valid data
        """
        validation_report = {
            'is_valid': True,
            'issues': [],
            'null_count': 0,
            'outliers_removed': 0,
            'rows_before': len(df),
            'rows_after': len(df),
            'data_completeness': 100.0,
            'quality_score': 100
        }
        
        if df.empty:
            validation_report['is_valid'] = False
            validation_report['issues'].append('DataFrame is empty')
            return df, validation_report
        
        if len(df) < DataValidator.MIN_DATA_POINTS:
            validation_report['is_valid'] = False
            validation_report['issues'].append(
                f'Insufficient data points: {len(df)} < {DataValidator.MIN_DATA_POINTS}'
            )
            return df, validation_report
        
        # Work with a copy to avoid modifying original
        df_clean = df.copy()
        
        # Step 1: Check for NaN values
        null_count = df_clean.isnull().sum().sum()
        if null_count > 0:
            validation_report['null_count'] = int(null_count)
            validation_report['issues'].append(f'Found {null_count} NaN values')
            
            # Check if NaN percentage exceeds threshold
            null_percentage = null_count / (len(df_clean) * len(df_clean.columns))
            if null_percentage > DataValidator.MAX_NULL_PERCENTAGE:
                validation_report['is_valid'] = False
                validation_report['issues'].append(
                    f'NaN percentage too high: {null_percentage*100:.1f}% > '
                    f'{DataValidator.MAX_NULL_PERCENTAGE*100:.0f}%'
                )
                return df_clean, validation_report
            
            # Drop rows with NaN
            df_clean = df_clean.dropna()
        
        if len(df_clean) < DataValidator.MIN_DATA_POINTS:
            validation_report['is_valid'] = False
            validation_report['issues'].append(
                f'Insufficient data after removing NaN: {len(df_clean)} < {DataValidator.MIN_DATA_POINTS}'
            )
            validation_report['rows_after'] = len(df_clean)
            return df_clean, validation_report
        
        # Step 2: Detect outliers (IQR method)
        outliers_removed = 0
        for column in ['quantity_kg', 'average_price']:
            if column in df_clean.columns:
                Q1 = df_clean[column].quantile(0.25)
                Q3 = df_clean[column].quantile(0.75)
                IQR = Q3 - Q1
                
                lower_bound = Q1 - DataValidator.IQR_MULTIPLIER * IQR
                upper_bound = Q3 + DataValidator.IQR_MULTIPLIER * IQR
                
                # Flag outliers (don't remove automatically, just flag for review)
                outlier_mask = (df_clean[column] < lower_bound) | (df_clean[column] > upper_bound)
                n_outliers = outlier_mask.sum()
                
                if n_outliers > 0:
                    validation_report['issues'].append(
                        f'Found {n_outliers} potential outliers in {column}'
                    )
                    logger.warning(f'Detected {n_outliers} outliers in {column}')
                    
                    # Only remove if outliers are severe (> 50% beyond bounds)
                    severe_outliers = df_clean[column].isin(
                        df_clean[column][(df_clean[column] < lower_bound*0.5) | 
                                        (df_clean[column] > upper_bound*1.5)]
                    )
                    
                    if severe_outliers.sum() > 0:
                        df_clean = df_clean[~severe_outliers]
                        outliers_removed += severe_outliers.sum()
        
        # Step 3: Check for zero or negative values (invalid for forecasting)
        invalid_quantity = (df_clean['quantity_kg'] <= 0).sum()
        invalid_price = (df_clean['average_price'] <= 0).sum()
        
        if invalid_quantity > 0 or invalid_price > 0:
            validation_report['issues'].append(
                f'Found invalid values: {invalid_quantity} zero/negative quantity, '
                f'{invalid_price} zero/negative price'
            )
            # Remove invalid values
            df_clean = df_clean[
                (df_clean['quantity_kg'] > 0) & 
                (df_clean['average_price'] > 0)
            ]
        
        # Step 4: Verify minimum data points after cleaning
        if len(df_clean) < DataValidator.MIN_DATA_POINTS:
            validation_report['is_valid'] = False
            validation_report['issues'].append(
                f'Insufficient clean data: {len(df_clean)} < {DataValidator.MIN_DATA_POINTS}'
            )
        
        # Update report
        validation_report['rows_after'] = len(df_clean)
        validation_report['outliers_removed'] = outliers_removed
        validation_report['data_completeness'] = (
            (len(df_clean) / len(df)) * 100 if len(df) > 0 else 0
        )
        
        # Calculate quality score (0-100)
        # Deduct points for issues
        quality_score = 100
        if null_count > 0:
            quality_score -= min(20, null_count * 2)
        if outliers_removed > 0:
            quality_score -= min(15, outliers_removed * 2)
        if len(df_clean) < 10:
            quality_score -= 10
        
        validation_report['quality_score'] = max(0, quality_score)
        
        # Warn if data is borderline valid
        if len(df_clean) < 10 and len(df_clean) >= DataValidator.MIN_DATA_POINTS:
            validation_report['issues'].append(
                f'Warning: Small dataset size ({len(df_clean)} points) - forecasts may be unreliable'
            )
        
        logger.info(f"Data validation complete: {len(df_clean)} valid records, "
                   f"quality_score={validation_report['quality_score']}")
        
        return df_clean, validation_report
    
    @staticmethod
    def detect_and_flag_outliers(series: pd.Series) -> List[int]:
        """
        Detect outlier indices using IQR method.
        
        Args:
            series: Pandas series to check
            
        Returns:
            List of indices that are outliers
        """
        Q1 = series.quantile(0.25)
        Q3 = series.quantile(0.75)
        IQR = Q3 - Q1
        
        lower_bound = Q1 - DataValidator.IQR_MULTIPLIER * IQR
        upper_bound = Q3 + DataValidator.IQR_MULTIPLIER * IQR
        
        outlier_mask = (series < lower_bound) | (series > upper_bound)
        return series[outlier_mask].index.tolist()
    
    @staticmethod
    def check_data_consistency(df: pd.DataFrame) -> Dict[str, any]:
        """
        Check temporal consistency of transaction data.
        
        Verifies:
        - Dates are in chronological order
        - No duplicate dates
        - Reasonable time gaps
        
        Args:
            df: DataFrame with 'transaction_date' index or column
            
        Returns:
            Dictionary with consistency check results
        """
        consistency = {
            'is_consistent': True,
            'issues': [],
            'duplicate_dates': 0,
            'time_gaps': []
        }
        
        # Ensure transaction_date is a column if it's the index
        if df.index.name == 'transaction_date':
            dates = df.index
        else:
            dates = df['transaction_date']
        
        # Check for duplicates
        duplicates = dates.duplicated().sum()
        if duplicates > 0:
            consistency['duplicate_dates'] = int(duplicates)
            consistency['issues'].append(f'Found {duplicates} duplicate dates')
            consistency['is_consistent'] = False
        
        # Check chronological order
        if not dates.is_monotonic_increasing:
            consistency['issues'].append('Data is not in chronological order')
            consistency['is_consistent'] = False
        
        # Check for gaps (optional warning only)
        date_diffs = dates.diff()
        large_gaps = date_diffs[date_diffs > pd.Timedelta(days=60)]
        if len(large_gaps) > 0:
            consistency['time_gaps'] = [str(gap) for gap in large_gaps.values]
            consistency['issues'].append(
                f'Found {len(large_gaps)} time gaps > 60 days - may affect seasonality detection'
            )
        
        return consistency
