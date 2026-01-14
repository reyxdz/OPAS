"""
Machine Learning-based Demand Forecasting Module

Features:
- LSTM (Long Short-Term Memory) neural network for sequence learning
- XGBoost gradient boosting for feature-based prediction
- Feature engineering (temporal, seasonal, trend features)
- Ensemble methods combining multiple models
- Model training with historical data
- Performance evaluation and accuracy metrics (MAE, RMSE, MAPE)
- Fallback to statistical methods when insufficient data

Learning Type: SUPERVISED LEARNING
- Uses labeled data (historical sales as features, future sales as targets)
- Learns temporal dependencies and feature relationships
- Trains on historical patterns to predict future demand
"""

import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from typing import Dict, List, Tuple, Optional
import logging
from decimal import Decimal
import warnings

warnings.filterwarnings('ignore')
logger = logging.getLogger(__name__)

# ML libraries - optional, falls back gracefully if not installed
try:
    from sklearn.preprocessing import MinMaxScaler, StandardScaler
    from sklearn.model_selection import train_test_split
    from sklearn.metrics import mean_absolute_error, mean_squared_error, mean_absolute_percentage_error
    SKLEARN_AVAILABLE = True
except ImportError:
    SKLEARN_AVAILABLE = False
    logger.warning("scikit-learn not installed. ML features disabled.")

try:
    import xgboost as xgb
    XGBOOST_AVAILABLE = True
except ImportError:
    XGBOOST_AVAILABLE = False
    logger.warning("XGBoost not installed. XGBoost models disabled.")

try:
    import tensorflow as tf
    from tensorflow import keras
    from tensorflow.keras.models import Sequential
    from tensorflow.keras.layers import LSTM, Dense, Dropout
    from tensorflow.keras.optimizers import Adam
    TENSORFLOW_AVAILABLE = True
except ImportError:
    TENSORFLOW_AVAILABLE = False
    logger.warning("TensorFlow not installed. LSTM models disabled.")


class FeatureEngineer:
    """Extract temporal and statistical features from sales data"""
    
    @staticmethod
    def engineer_features(sales_data: List[Dict], lookback_window: int = 7) -> pd.DataFrame:
        """
        Extract features from sales data for ML models
        
        Features created:
        - Temporal: day_of_week, day_of_month, month, is_weekend, quarter
        - Lag features: sales from 1, 7, 14, 30 days ago
        - Rolling stats: moving average, std dev, min, max over windows
        - Trend: linear trend coefficient
        - Seasonality: seasonal indices
        
        Args:
            sales_data: List of dicts with date, quantity, price
            lookback_window: Days to look back for lag features
            
        Returns:
            DataFrame with engineered features
        """
        if not sales_data or len(sales_data) < 3:
            return pd.DataFrame()
        
        df = pd.DataFrame(sales_data)
        df['date'] = pd.to_datetime(df['date'])
        df = df.sort_values('date').reset_index(drop=True)
        
        # Temporal features
        df['day_of_week'] = df['date'].dt.dayofweek
        df['day_of_month'] = df['date'].dt.day
        df['month'] = df['date'].dt.month
        df['quarter'] = df['date'].dt.quarter
        df['is_weekend'] = df['day_of_week'].isin([5, 6]).astype(int)
        df['day_of_year'] = df['date'].dt.dayofyear
        
        # Lag features (past sales values)
        for lag in [1, 7, 14, 30]:
            if len(df) >= lag:
                df[f'lag_{lag}'] = df['quantity'].shift(lag)
        
        # Rolling statistics
        for window in [7, 14, 30]:
            if len(df) >= window:
                df[f'rolling_mean_{window}'] = df['quantity'].rolling(window=window, min_periods=1).mean()
                df[f'rolling_std_{window}'] = df['quantity'].rolling(window=window, min_periods=1).std()
                df[f'rolling_min_{window}'] = df['quantity'].rolling(window=window, min_periods=1).min()
                df[f'rolling_max_{window}'] = df['quantity'].rolling(window=window, min_periods=1).max()
        
        # Price features
        if 'price' in df.columns:
            df['price_lag_7'] = df['price'].shift(7)
            df['price_change'] = df['price'].pct_change()
        
        # Exponential moving average
        df['ema_7'] = df['quantity'].ewm(span=7, adjust=False).mean()
        df['ema_30'] = df['quantity'].ewm(span=30, adjust=False).mean()
        
        # Drop rows with NaN created by lag/rolling features
        df = df.dropna()
        
        return df
    
    @staticmethod
    def create_sequences(data: np.ndarray, seq_length: int = 14) -> Tuple[np.ndarray, np.ndarray]:
        """
        Create sequences for LSTM training
        
        Args:
            data: Array of quantity values
            seq_length: Length of sequence to use for prediction
            
        Returns:
            X (sequences), y (target values)
        """
        X, y = [], []
        for i in range(len(data) - seq_length):
            X.append(data[i:i+seq_length])
            y.append(data[i+seq_length])
        return np.array(X), np.array(y)


class LSTMForecaster:
    """LSTM neural network for time series forecasting"""
    
    def __init__(self, seq_length: int = 14):
        """
        Initialize LSTM forecaster
        
        Args:
            seq_length: Sequence length for LSTM input
        """
        self.seq_length = seq_length
        self.model = None
        self.scaler = MinMaxScaler(feature_range=(0, 1)) if SKLEARN_AVAILABLE else None
        self.is_trained = False
    
    def build_model(self, input_shape: Tuple):
        """Build LSTM neural network architecture"""
        if not TENSORFLOW_AVAILABLE:
            return None
        
        self.model = Sequential([
            LSTM(64, activation='relu', return_sequences=True, input_shape=input_shape),
            Dropout(0.2),
            LSTM(32, activation='relu', return_sequences=False),
            Dropout(0.2),
            Dense(16, activation='relu'),
            Dense(1)
        ])
        
        self.model.compile(optimizer=Adam(learning_rate=0.001), loss='mse', metrics=['mae'])
        return self.model
    
    def train(self, sales_data: List[Dict], epochs: int = 50, batch_size: int = 32) -> Dict:
        """
        Train LSTM model on historical sales data
        
        Args:
            sales_data: Historical sales data
            epochs: Number of training epochs
            batch_size: Training batch size
            
        Returns:
            Dict with training metrics
        """
        if not TENSORFLOW_AVAILABLE or not SKLEARN_AVAILABLE:
            return {'status': 'error', 'message': 'TensorFlow/scikit-learn not installed'}
        
        if len(sales_data) < self.seq_length + 10:
            return {'status': 'error', 'message': 'Insufficient data for LSTM training'}
        
        try:
            # Extract quantities
            quantities = np.array([d['quantity'] for d in sales_data]).reshape(-1, 1)
            
            # Normalize data
            scaled_data = self.scaler.fit_transform(quantities)
            
            # Create sequences
            X, y = FeatureEngineer.create_sequences(scaled_data.flatten(), self.seq_length)
            
            # Split data
            X_train, X_test, y_train, y_test = train_test_split(
                X, y, test_size=0.2, random_state=42
            )
            
            # Reshape for LSTM [samples, timesteps, features]
            X_train = X_train.reshape((X_train.shape[0], X_train.shape[1], 1))
            X_test = X_test.reshape((X_test.shape[0], X_test.shape[1], 1))
            
            # Build and train
            self.build_model((X_train.shape[1], 1))
            history = self.model.fit(
                X_train, y_train,
                epochs=epochs,
                batch_size=batch_size,
                validation_data=(X_test, y_test),
                verbose=0
            )
            
            # Evaluate
            train_pred = self.model.predict(X_train, verbose=0)
            test_pred = self.model.predict(X_test, verbose=0)
            
            train_mae = mean_absolute_error(y_train, train_pred)
            test_mae = mean_absolute_error(y_test, test_pred)
            test_mape = mean_absolute_percentage_error(y_test, test_pred)
            
            self.is_trained = True
            
            return {
                'status': 'success',
                'train_mae': float(train_mae),
                'test_mae': float(test_mae),
                'test_mape': float(test_mape),
                'epochs_trained': epochs,
                'samples_used': len(sales_data)
            }
        except Exception as e:
            logger.error(f"LSTM training error: {str(e)}")
            return {'status': 'error', 'message': str(e)}
    
    def predict(self, sales_data: List[Dict], days_ahead: int = 30) -> List[float]:
        """
        Generate LSTM predictions
        
        Args:
            sales_data: Historical sales data
            days_ahead: Number of days to forecast
            
        Returns:
            List of predicted quantities
        """
        if not self.is_trained or not TENSORFLOW_AVAILABLE:
            return []
        
        try:
            quantities = np.array([d['quantity'] for d in sales_data]).reshape(-1, 1)
            scaled_data = self.scaler.transform(quantities)
            
            # Use last sequence to start predictions
            current_seq = scaled_data[-self.seq_length:].flatten()
            predictions = []
            
            for _ in range(days_ahead):
                next_pred = self.model.predict(
                    current_seq.reshape(1, self.seq_length, 1),
                    verbose=0
                )[0][0]
                predictions.append(next_pred)
                current_seq = np.append(current_seq[1:], next_pred)
            
            # Inverse scale predictions
            predictions = np.array(predictions).reshape(-1, 1)
            predictions = self.scaler.inverse_transform(predictions).flatten()
            
            return predictions.tolist()
        except Exception as e:
            logger.error(f"LSTM prediction error: {str(e)}")
            return []


class XGBoostForecaster:
    """XGBoost gradient boosting model for demand forecasting"""
    
    def __init__(self):
        self.model = None
        self.scaler = StandardScaler() if SKLEARN_AVAILABLE else None
        self.feature_names = []
        self.is_trained = False
    
    def train(self, sales_data: List[Dict], test_size: float = 0.2) -> Dict:
        """
        Train XGBoost model with engineered features
        
        Args:
            sales_data: Historical sales data
            test_size: Test set fraction
            
        Returns:
            Dict with training metrics
        """
        if not XGBOOST_AVAILABLE or not SKLEARN_AVAILABLE:
            return {'status': 'error', 'message': 'XGBoost/scikit-learn not installed'}
        
        if len(sales_data) < 20:
            return {'status': 'error', 'message': 'Insufficient data for XGBoost training'}
        
        try:
            # Engineer features
            df = FeatureEngineer.engineer_features(sales_data)
            
            if df.empty:
                return {'status': 'error', 'message': 'Feature engineering failed'}
            
            # Prepare X and y
            feature_cols = [col for col in df.columns if col not in ['date', 'quantity']]
            X = df[feature_cols].values
            y = df['quantity'].values
            
            # Split data
            X_train, X_test, y_train, y_test = train_test_split(
                X, y, test_size=test_size, random_state=42
            )
            
            # Train model
            self.model = xgb.XGBRegressor(
                n_estimators=100,
                max_depth=6,
                learning_rate=0.1,
                subsample=0.8,
                colsample_bytree=0.8,
                random_state=42
            )
            
            self.model.fit(X_train, y_train, verbose=False)
            self.feature_names = feature_cols
            
            # Evaluate
            train_pred = self.model.predict(X_train)
            test_pred = self.model.predict(X_test)
            
            train_mae = mean_absolute_error(y_train, train_pred)
            test_mae = mean_absolute_error(y_test, test_pred)
            test_mape = mean_absolute_percentage_error(y_test, test_pred)
            test_rmse = np.sqrt(mean_squared_error(y_test, test_pred))
            
            self.is_trained = True
            
            return {
                'status': 'success',
                'train_mae': float(train_mae),
                'test_mae': float(test_mae),
                'test_rmse': float(test_rmse),
                'test_mape': float(test_mape),
                'features_used': len(feature_cols),
                'samples_used': len(sales_data),
                'feature_importance': dict(zip(feature_cols, self.model.feature_importances_.tolist()))
            }
        except Exception as e:
            logger.error(f"XGBoost training error: {str(e)}")
            return {'status': 'error', 'message': str(e)}
    
    def predict(self, sales_data: List[Dict], days_ahead: int = 30) -> List[float]:
        """
        Generate XGBoost predictions for future days
        
        Args:
            sales_data: Historical sales data
            days_ahead: Number of days to forecast
            
        Returns:
            List of predicted quantities
        """
        if not self.is_trained or not XGBOOST_AVAILABLE:
            return []
        
        try:
            df = FeatureEngineer.engineer_features(sales_data)
            
            if df.empty:
                return []
            
            predictions = []
            current_df = df.copy()
            last_date = pd.to_datetime(max([d['date'] for d in sales_data]))
            
            for day in range(1, days_ahead + 1):
                # Create future date features
                future_date = last_date + timedelta(days=day)
                future_features = {
                    'day_of_week': future_date.dayofweek,
                    'day_of_month': future_date.day,
                    'month': future_date.month,
                    'quarter': future_date.quarter,
                    'is_weekend': int(future_date.dayofweek in [5, 6]),
                    'day_of_year': future_date.dayofyear,
                }
                
                # Use last known values for lag and rolling features
                last_row = current_df.iloc[-1]
                for col in self.feature_names:
                    if col not in future_features:
                        future_features[col] = last_row[col]
                
                # Predict
                X_future = np.array([[future_features.get(col, 0) for col in self.feature_names]])
                pred = self.model.predict(X_future)[0]
                predictions.append(max(0, pred))
            
            return predictions
        except Exception as e:
            logger.error(f"XGBoost prediction error: {str(e)}")
            return []


class EnsembleForecaster:
    """Ensemble combining statistical, LSTM, and XGBoost methods"""
    
    def __init__(self):
        self.lstm_forecaster = LSTMForecaster() if TENSORFLOW_AVAILABLE else None
        self.xgboost_forecaster = XGBoostForecaster() if XGBOOST_AVAILABLE else None
        self.statistical_weights = {'lstm': 0.4, 'xgboost': 0.4, 'statistical': 0.2}
    
    def train_all_models(self, sales_data: List[Dict]) -> Dict:
        """
        Train all available models
        
        Args:
            sales_data: Historical sales data
            
        Returns:
            Dict with training results for each model
        """
        results = {
            'ensemble_status': 'training',
            'models': {}
        }
        
        if self.lstm_forecaster:
            results['models']['lstm'] = self.lstm_forecaster.train(sales_data)
        
        if self.xgboost_forecaster:
            results['models']['xgboost'] = self.xgboost_forecaster.train(sales_data)
        
        return results
    
    def predict_ensemble(self, sales_data: List[Dict], days_ahead: int = 30) -> Tuple[List[float], str]:
        """
        Generate ensemble predictions combining multiple models
        
        Args:
            sales_data: Historical sales data
            days_ahead: Days to forecast
            
        Returns:
            Tuple of (predictions, model_type_used)
        """
        predictions = []
        models_used = []
        weights = []
        
        # Collect predictions from available models
        if self.xgboost_forecaster and self.xgboost_forecaster.is_trained:
            xgb_pred = self.xgboost_forecaster.predict(sales_data, days_ahead)
            if xgb_pred:
                predictions.append(np.array(xgb_pred))
                models_used.append('xgboost')
                weights.append(self.statistical_weights['xgboost'])
        
        if self.lstm_forecaster and self.lstm_forecaster.is_trained:
            lstm_pred = self.lstm_forecaster.predict(sales_data, days_ahead)
            if lstm_pred:
                predictions.append(np.array(lstm_pred))
                models_used.append('lstm')
                weights.append(self.statistical_weights['lstm'])
        
        # Combine predictions with weighting
        if predictions:
            weights_array = np.array(weights)
            weights_array = weights_array / weights_array.sum()  # Normalize
            ensemble_pred = np.average(predictions, axis=0, weights=weights_array)
            model_type = f"ENSEMBLE({','.join(models_used)})"
            return ensemble_pred.tolist(), model_type
        
        # Fallback if no ML models available
        return [], "ML_UNAVAILABLE"
