"""
Celery tasks for forecasting app.

Periodic background tasks for data aggregation and forecast generation.
"""

from celery import shared_task
from celery.schedules import crontab
from django.utils import timezone
from datetime import timedelta
import logging
from django.core.mail import send_mass_mail
from django.conf import settings
from apps.forecasting.services.data_aggregator import DataAggregator
from apps.forecasting.services.forecasting_service import ForecastingService
from apps.forecasting.services.enhanced_forecasting_service import EnhancedForecastingService
from apps.forecasting.models import ProductForecast, ForecastAlert, ForecastMetadata, HistoricalTransactions
from apps.users.models import SellerProduct, Admin
from django.db.models import Avg

logger = logging.getLogger(__name__)


@shared_task(bind=True, max_retries=3)
def aggregate_recent_transactions(self):
    """
    Daily batch job to aggregate recent SellerOrder transactions
    into HistoricalTransactions.
    
    Triggered daily at 1:00 AM UTC.
    
    Process:
    1. Query all SellerProduct records
    2. For each product, collect recent orders (last 24 hours)
    3. Aggregate to daily or weekly records
    4. Update or create HistoricalTransactions
    5. Log results
    
    Returns:
        dict: Summary of aggregation results
        {
            'status': 'success' | 'partial' | 'failed',
            'total_products': int,
            'products_updated': int,
            'records_created': int,
            'errors': [str],
        }
    """
    try:
        logger.info("Starting aggregate_recent_transactions task")
        
        results = {
            'status': 'success',
            'total_products': 0,
            'products_updated': 0,
            'records_created': 0,
            'errors': [],
        }
        
        # Get all active products
        products = SellerProduct.objects.filter(
            is_deleted=False,
            status='ACTIVE'
        )
        
        results['total_products'] = products.count()
        
        # Aggregate data for each product
        for product in products:
            try:
                records_created, quality_score = DataAggregator.aggregate_and_store(
                    product_id=product.id,
                    aggregation_period='W'  # Weekly aggregation
                )
                
                if records_created > 0:
                    results['products_updated'] += 1
                    results['records_created'] += records_created
                    
                    logger.debug(
                        f"Product {product.id} ({product.name}): "
                        f"{records_created} records created, quality={quality_score}%"
                    )
                    
            except Exception as e:
                error_msg = f"Error aggregating product {product.id}: {str(e)}"
                results['errors'].append(error_msg)
                logger.error(error_msg)
                results['status'] = 'partial'
        
        if results['errors']:
            results['status'] = 'partial'
        
        logger.info(
            f"Completed aggregate_recent_transactions: "
            f"{results['products_updated']}/{results['total_products']} products updated, "
            f"{results['records_created']} records created"
        )
        
        return results
        
    except Exception as e:
        error_msg = f"Failed to run aggregate_recent_transactions: {str(e)}"
        logger.error(error_msg)
        
        # Retry with exponential backoff
        raise self.retry(exc=e, countdown=60 * (2 ** self.request.retries))


@shared_task(bind=True, max_retries=3)
def aggregate_all_products_batch(self):
    """
    Batch aggregation of all products (typically run as one-time or weekly).
    
    More aggressive than daily aggregation - queries all historical orders.
    
    Used for:
    - Initial data population
    - Weekly refresh to rebuild complete time series
    - Recovery after data issues
    
    Returns:
        dict: Summary of batch aggregation results
    """
    try:
        logger.info("Starting aggregate_all_products_batch task")
        
        results = DataAggregator.aggregate_all_products()
        
        total_products = len(results)
        successful = sum(1 for records, score in results.values() if records > 0)
        total_records = sum(records for records, score in results.values())
        
        logger.info(
            f"Completed aggregate_all_products_batch: "
            f"{successful}/{total_products} products aggregated, "
            f"{total_records} total records created"
        )
        
        return {
            'status': 'success',
            'total_products': total_products,
            'successful_products': successful,
            'total_records_created': total_records,
            'details': results,
        }
        
    except Exception as e:
        error_msg = f"Failed to run aggregate_all_products_batch: {str(e)}"
        logger.error(error_msg)
        
        # Retry with exponential backoff
        raise self.retry(exc=e, countdown=60 * (2 ** self.request.retries))


@shared_task
def cleanup_old_historical_transactions(days=365):
    """
    Periodic cleanup task to archive or delete very old historical transactions.
    
    Triggered weekly to manage database growth.
    
    Keeps transactions from last N days (default: 365 days).
    Older transactions can be archived to cold storage if needed.
    
    Args:
        days: Number of days to keep (default: 365)
        
    Returns:
        dict: Cleanup results
    """
    try:
        from apps.forecasting.models import HistoricalTransactions
        
        logger.info(f"Starting cleanup_old_historical_transactions (keeping {days} days)")
        
        cutoff_date = timezone.now().date() - timedelta(days=days)
        
        # Delete transactions older than cutoff
        deleted_count, _ = HistoricalTransactions.objects.filter(
            transaction_date__lt=cutoff_date
        ).delete()
        
        logger.info(f"Cleanup complete: {deleted_count} old transactions deleted")
        
        return {
            'status': 'success',
            'deleted_count': deleted_count,
        }
        
    except Exception as e:
        error_msg = f"Failed to run cleanup_old_historical_transactions: {str(e)}"
        logger.error(error_msg)
        
        return {
            'status': 'failed',
            'error': error_msg,
        }


# ============================================================================
# PHASE 6.1: CORE BACKGROUND TASKS
# ============================================================================

@shared_task(bind=True, max_retries=3)
def refresh_all_forecasts(self):
    """
    Periodic Forecast Refresh - Weekly, Sunday 2 AM UTC
    
    Task: refresh_all_forecasts
    Schedule: @periodic_task(run_every=crontab(day_of_week=6, hour=2, minute=0))
    
    Process:
    1. Call ForecastingService.batch_generate_all_products()
    2. Log generation status for each product
    3. Create alerts if models fail or data is insufficient
    4. Email admins with comprehensive summary
    
    Returns:
        dict: Detailed forecast refresh results
        {
            'status': 'success' | 'partial' | 'failed',
            'timestamp': datetime,
            'total_products': int,
            'forecasts_generated': int,
            'forecasts_failed': int,
            'new_alerts_created': int,
            'errors': [str],
            'summary': str,
        }
    """
    try:
        logger.info("=" * 80)
        logger.info("🔄 STARTING: refresh_all_forecasts (Phase 6.1.a)")
        logger.info("=" * 80)
        
        start_time = timezone.now()
        
        # Initialize results tracking
        results = {
            'status': 'success',
            'timestamp': start_time.isoformat(),
            'total_products': 0,
            'forecasts_generated': 0,
            'forecasts_failed': 0,
            'new_alerts_created': 0,
            'errors': [],
            'failed_products': [],
        }
        
        # Get all active products
        products = SellerProduct.objects.filter(
            is_deleted=False,
            status='ACTIVE'
        )
        
        results['total_products'] = products.count()
        logger.info(f"Found {results['total_products']} active products to forecast")
        
        # Generate forecasts for all products
        forecasting_service = EnhancedForecastingService()
        
        for product in products:
            try:
                # Generate forecast WITH validation
                result = forecasting_service.generate_forecast_with_validation(
                    product_id=product.id,
                    validate=True,           # ✓ Validate models
                    use_best_model=True      # ✓ Use best by MAPE
                )
                
                if result:
                    forecasting_service.save_forecast_with_validation(result)
                    results['forecasts_generated'] += 1
                    logger.debug(f"Generated validated forecast for product {product.id}")
                else:
                    results['forecasts_failed'] += 1
                    results['failed_products'].append(product.id)
                    logger.warning(f"Failed to generate validated forecast for product {product.id}")
                    
            except Exception as e:
                error_msg = f"Error generating forecast for product {product.id}: {str(e)}"
                results['errors'].append(error_msg)
                results['forecasts_failed'] += 1
                results['failed_products'].append(product.id)
                logger.error(error_msg)
        
        for product_id in insufficient_data_products:
            try:
                product = SellerProduct.objects.get(id=product_id)
                
                # Create alert for insufficient data
                alert, created = ForecastAlert.objects.get_or_create(
                    product_id=product_id,
                    alert_type='INSUFFICIENT_DATA',
                    defaults={
                        'severity': 'WARNING',
                        'message': f'Product "{product.name}" has insufficient historical data for forecasting.',
                        'is_acknowledged': False,
                    }
                )
                
                if created:
                    results['new_alerts_created'] += 1
                    logger.info(f"🔔 Created insufficient data alert for product {product_id}")
                    
            except SellerProduct.DoesNotExist:
                logger.warning(f"Product {product_id} not found when creating alert")
        
        # Log errors from batch generation
        if batch_results.get('errors'):
            results['errors'] = batch_results.get('errors', [])
            logger.error(f"❌ Errors during batch generation: {results['errors']}")
        
        # Generate summary email
        elapsed_time = timezone.now() - start_time
        results['summary'] = (
            f"Forecast Refresh Complete\n"
            f"- Generated: {results['forecasts_generated']} forecasts\n"
            f"- Failed: {results['forecasts_failed']} forecasts\n"
            f"- Insufficient Data: {len(insufficient_data_products)} products\n"
            f"- New Alerts: {results['new_alerts_created']}\n"
            f"- Duration: {elapsed_time.total_seconds():.1f}s\n"
            f"- Status: {results['status'].upper()}"
        )
        
        # Send email to admins
        try:
            admin_emails = Admin.objects.filter(
                is_deleted=False,
                admin_role__in=['SUPER_ADMIN', 'ANALYTICS_ADMIN']
            ).values_list('user__email', flat=True)
            
            if admin_emails:
                email_subject = f"[OPAS] Forecasting Update - {results['status'].upper()}"
                email_body = (
                    f"Weekly Forecast Refresh Completed\n"
                    f"{'=' * 50}\n\n"
                    f"Status: {results['status'].upper()}\n"
                    f"Timestamp: {results['timestamp']}\n\n"
                    f"Results:\n"
                    f"  • Total Products: {results['total_products']}\n"
                    f"  • Forecasts Generated: {results['forecasts_generated']}\n"
                    f"  • Forecasts Failed: {results['forecasts_failed']}\n"
                    f"  • New Alerts Created: {results['new_alerts_created']}\n"
                    f"  • Duration: {elapsed_time.total_seconds():.1f}s\n\n"
                )
                
                if results['failed_products']:
                    email_body += (
                        f"Failed Products: {', '.join(str(p) for p in results['failed_products'][:5])}\n\n"
                    )
                
                if results['errors']:
                    email_body += (
                        f"Errors:\n"
                        f"{chr(10).join('  • ' + e for e in results['errors'][:3])}\n\n"
                    )
                
                email_body += "Check the admin dashboard for more details."
                
                # Send email
                send_mass_mail(
                    ((email_subject, email_body, settings.DEFAULT_FROM_EMAIL, [email]) for email in admin_emails),
                    fail_silently=True,
                )
                
                logger.info(f"📧 Sent summary email to {len(admin_emails)} admins")
        except Exception as e:
            logger.error(f"Failed to send summary email: {str(e)}")
        
        logger.info("=" * 80)
        logger.info(f"✅ COMPLETED: refresh_all_forecasts | {results['summary']}")
        logger.info("=" * 80)
        
        return results
        
    except Exception as e:
        error_msg = f"Critical error in refresh_all_forecasts: {str(e)}"
        logger.error(error_msg)
        
        # Retry with exponential backoff
        raise self.retry(exc=e, countdown=60 * (2 ** self.request.retries))


@shared_task(bind=True, max_retries=3)
def aggregate_recent_transactions_phase6(self):
    """
    Daily Data Aggregation - Daily at 1:00 AM UTC
    
    Task: aggregate_recent_transactions
    Schedule: @periodic_task(run_every=crontab(hour=1, minute=0))
    
    Process:
    1. Query SellerOrder from last 24 hours
    2. Update HistoricalTransactions table with new data
    3. Detect anomalies in recent sales (unusual qty/price)
    4. Calculate data quality scores
    5. Log aggregation status
    
    Returns:
        dict: Aggregation results
        {
            'status': 'success' | 'partial' | 'failed',
            'timestamp': datetime,
            'total_products': int,
            'products_updated': int,
            'records_created': int,
            'anomalies_detected': int,
            'errors': [str],
        }
    """
    try:
        logger.info("=" * 80)
        logger.info("📊 STARTING: aggregate_recent_transactions (Phase 6.1.b)")
        logger.info("=" * 80)
        
        start_time = timezone.now()
        
        # Initialize results tracking
        results = {
            'status': 'success',
            'timestamp': start_time.isoformat(),
            'total_products': 0,
            'products_updated': 0,
            'records_created': 0,
            'anomalies_detected': 0,
            'errors': [],
        }
        
        # Get all active products
        products = SellerProduct.objects.filter(
            is_deleted=False,
            status='ACTIVE'
        )
        
        results['total_products'] = products.count()
        logger.info(f"Processing {results['total_products']} active products")
        
        # Aggregate data for each product from last 24 hours
        for product in products:
            try:
                records_created, quality_score = DataAggregator.aggregate_and_store(
                    product_id=product.id,
                    aggregation_period='W',  # Weekly aggregation
                    days_back=1  # Only last 24 hours
                )
                
                if records_created > 0:
                    results['products_updated'] += 1
                    results['records_created'] += records_created
                    
                    logger.debug(
                        f"✓ Product {product.id} ({product.name}): "
                        f"{records_created} records created, quality={quality_score}%"
                    )
                    
                    # Detect anomalies in recent data
                    anomalies = DataAggregator.detect_anomalies(
                        product_id=product.id,
                        time_window=1  # Last 1 day
                    )
                    
                    if anomalies:
                        results['anomalies_detected'] += len(anomalies)
                        logger.warning(
                            f"⚠️ Anomalies detected for {product.name}: {anomalies}"
                        )
                        
            except Exception as e:
                error_msg = f"Error aggregating product {product.id}: {str(e)}"
                results['errors'].append(error_msg)
                logger.error(error_msg)
                results['status'] = 'partial'
        
        if results['errors']:
            results['status'] = 'partial'
        
        elapsed_time = timezone.now() - start_time
        
        logger.info(
            f"✅ Completed aggregation: {results['products_updated']}/{results['total_products']} products, "
            f"{results['records_created']} records, "
            f"{results['anomalies_detected']} anomalies, "
            f"Duration: {elapsed_time.total_seconds():.1f}s"
        )
        
        logger.info("=" * 80)
        logger.info(f"✅ COMPLETED: aggregate_recent_transactions | Status: {results['status'].upper()}")
        logger.info("=" * 80)
        
        return results
        
    except Exception as e:
        error_msg = f"Critical error in aggregate_recent_transactions: {str(e)}"
        logger.error(error_msg)
        
        # Retry with exponential backoff
        raise self.retry(exc=e, countdown=60 * (2 ** self.request.retries))


@shared_task(bind=True, max_retries=3)
def check_forecast_alerts_phase6(self):
    """
    Alert Generation - Daily at 6:00 AM UTC
    
    Task: check_forecast_alerts
    Schedule: @periodic_task(run_every=crontab(hour=6, minute=0))
    
    Process:
    1. Compare forecast vs actual (if available)
    2. Detect declining demand trends
    3. Detect price anomalies
    4. Create ForecastAlert records for concerning patterns
    5. Log alert generation summary
    
    Returns:
        dict: Alert generation results
        {
            'status': 'success' | 'partial' | 'failed',
            'timestamp': datetime,
            'total_products_checked': int,
            'alerts_created': int,
            'declining_demand_alerts': int,
            'price_spike_alerts': int,
            'low_confidence_alerts': int,
            'errors': [str],
        }
    """
    try:
        logger.info("=" * 80)
        logger.info("🔔 STARTING: check_forecast_alerts (Phase 6.1.c)")
        logger.info("=" * 80)
        
        start_time = timezone.now()
        
        # Initialize results tracking
        results = {
            'status': 'success',
            'timestamp': start_time.isoformat(),
            'total_products_checked': 0,
            'alerts_created': 0,
            'declining_demand_alerts': 0,
            'price_spike_alerts': 0,
            'low_confidence_alerts': 0,
            'errors': [],
        }
        
        # Get all current forecasts
        current_forecasts = ProductForecast.objects.filter(is_current=True)
        
        results['total_products_checked'] = current_forecasts.count()
        logger.info(f"Checking {results['total_products_checked']} current forecasts for anomalies")
        
        for forecast in current_forecasts:
            try:
                product = forecast.product
                
                # Alert 1: Declining Demand Trend
                # Check if demand forecast is declining compared to historical average
                recent_transactions = HistoricalTransactions.objects.filter(
                    product=product
                ).order_by('-transaction_date')[:8]  # Last 8 weeks
                
                if recent_transactions.exists():
                    recent_avg = recent_transactions.aggregate(
                        avg_qty=Avg('quantity_sold_kg')
                    )['avg_qty']
                    
                    # If forecast is significantly lower than recent average
                    if recent_avg and forecast.demand_forecast_kg < (recent_avg * 0.7):
                        alert, created = ForecastAlert.objects.get_or_create(
                            product=product,
                            alert_type='DECLINING_DEMAND',
                            defaults={
                                'severity': 'WARNING',
                                'message': (
                                    f'Forecast predicts {forecast.demand_forecast_kg}kg vs '
                                    f'historical avg {recent_avg:.1f}kg (30% decline).'
                                ),
                                'is_acknowledged': False,
                            }
                        )
                        
                        if created:
                            results['declining_demand_alerts'] += 1
                            results['alerts_created'] += 1
                            logger.info(f"🔔 Declining demand alert for {product.name}")
                
                # Alert 2: Price Spike Detection
                # Check if price forecast significantly higher than recent average
                if recent_transactions.exists():
                    recent_price_avg = recent_transactions.aggregate(
                        avg_price=Avg('average_price_per_kg')
                    )['avg_price']
                    
                    # If forecast price is significantly higher
                    if recent_price_avg and forecast.price_forecast > (recent_price_avg * 1.3):
                        alert, created = ForecastAlert.objects.get_or_create(
                            product=product,
                            alert_type='PRICE_SPIKE',
                            defaults={
                                'severity': 'INFO',
                                'message': (
                                    f'Price forecast: ₱{forecast.price_forecast:.2f}/kg vs '
                                    f'historical avg ₱{recent_price_avg:.2f}/kg (+30% increase).'
                                ),
                                'is_acknowledged': False,
                            }
                        )
                        
                        if created:
                            results['price_spike_alerts'] += 1
                            results['alerts_created'] += 1
                            logger.info(f"💰 Price spike alert for {product.name}")
                
                # Alert 3: Low Confidence in Forecast
                # If model has low confidence or insufficient data
                if forecast.confidence_level in ['LOW', 'MEDIUM']:
                    # Check metadata
                    try:
                        metadata = ForecastMetadata.objects.get(product=product)
                        
                        if not metadata.is_reliable:
                            alert, created = ForecastAlert.objects.get_or_create(
                                product=product,
                                alert_type='LOW_CONFIDENCE',
                                defaults={
                                    'severity': 'INFO',
                                    'message': (
                                        f'Forecast confidence is {forecast.confidence_level}. '
                                        f'Only {metadata.data_points_count} data points available.'
                                    ),
                                    'is_acknowledged': False,
                                }
                            )
                            
                            if created:
                                results['low_confidence_alerts'] += 1
                                results['alerts_created'] += 1
                                logger.info(f"⚠️ Low confidence alert for {product.name}")
                    except ForecastMetadata.DoesNotExist:
                        pass
                
            except Exception as e:
                error_msg = f"Error checking alerts for product {forecast.product_id}: {str(e)}"
                results['errors'].append(error_msg)
                logger.error(error_msg)
                results['status'] = 'partial'
        
        elapsed_time = timezone.now() - start_time
        
        logger.info(
            f"✅ Alert check complete: "
            f"{results['alerts_created']} alerts created "
            f"({results['declining_demand_alerts']} demand, "
            f"{results['price_spike_alerts']} price, "
            f"{results['low_confidence_alerts']} confidence), "
            f"Duration: {elapsed_time.total_seconds():.1f}s"
        )
        
        logger.info("=" * 80)
        logger.info(f"✅ COMPLETED: check_forecast_alerts | Total Alerts: {results['alerts_created']}")
        logger.info("=" * 80)
        
        return results
        
    except Exception as e:
        error_msg = f"Critical error in check_forecast_alerts: {str(e)}"
        logger.error(error_msg)
        
        # Retry with exponential backoff
        raise self.retry(exc=e, countdown=60 * (2 ** self.request.retries))


@shared_task
def validate_data_quality_reports():
    """
    Periodic task to analyze and report on data quality across all products.
    
    Triggered weekly to generate quality metrics for forecasting readiness.
    
    Checks:
    - Products with sufficient data (>=24 points)
    - Products approaching sufficiency (>=12 points)
    - Products with quality score >80%
    - Products with gaps in data
    
    Returns:
        dict: Data quality summary
    """
    try:
        from apps.forecasting.models import HistoricalTransactions
        from apps.users.models import SellerProduct
        
        logger.info("Starting validate_data_quality_reports task")
        
        products = SellerProduct.objects.filter(is_deleted=False)
        
        report = {
            'timestamp': timezone.now().isoformat(),
            'total_products': products.count(),
            'sufficient_data': [],  # >=24 points
            'approaching_sufficiency': [],  # 12-23 points
            'high_quality': [],  # score >80%
            'low_quality': [],  # score <50%
        }
        
        for product in products:
            # Get coverage stats
            stats = DataAggregator.get_data_coverage_stats(product.id)
            
            if stats['total_periods'] == 0:
                continue
            
            if stats['total_periods'] >= 24:
                report['sufficient_data'].append({
                    'product_id': product.id,
                    'product_name': product.name,
                    'data_points': stats['total_periods'],
                    'coverage': stats['coverage_percentage'],
                })
            
            if 12 <= stats['total_periods'] < 24:
                report['approaching_sufficiency'].append({
                    'product_id': product.id,
                    'product_name': product.name,
                    'data_points': stats['total_periods'],
                    'coverage': stats['coverage_percentage'],
                })
            
            # Get average quality score
            from django.db.models import Avg
            avg_quality = HistoricalTransactions.objects.filter(
                product=product
            ).values('data_quality_score').aggregate(
                avg_score=Avg('data_quality_score')
            )['avg_score']
            
            if avg_quality and avg_quality > 80:
                report['high_quality'].append({
                    'product_id': product.id,
                    'product_name': product.name,
                    'avg_quality_score': round(avg_quality, 2),
                })
            
            if avg_quality and avg_quality < 50:
                report['low_quality'].append({
                    'product_id': product.id,
                    'product_name': product.name,
                    'avg_quality_score': round(avg_quality, 2),
                })
        
        logger.info(
            f"Data quality report: {len(report['sufficient_data'])} products ready, "
            f"{len(report['approaching_sufficiency'])} approaching sufficiency"
        )
        
        return report
        
    except Exception as e:
        error_msg = f"Failed to run validate_data_quality_reports: {str(e)}"
        logger.error(error_msg)
        
        return {
            'status': 'failed',
            'error': error_msg,
        }
