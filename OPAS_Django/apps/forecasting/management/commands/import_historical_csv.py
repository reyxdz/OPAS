"""
Management command to import external market reference data from CSV.

This command imports historical market data (e.g., from agricultural bureau
or market reports) into MarketHistoricalData for benchmarking and trend analysis.

IMPORTANT: This is for EXTERNAL MARKET REFERENCE DATA ONLY.
For actual SellerProduct sales, use the signals/tasks to update HistoricalTransactions.

Usage:
    python manage.py import_historical_csv
    python manage.py import_historical_csv --file path/to/file.csv
    python manage.py import_historical_csv --dry-run
"""

import csv
import logging
from datetime import datetime
from decimal import Decimal
from collections import defaultdict

from django.core.management.base import BaseCommand, CommandError
from django.utils import timezone
from django.db import transaction

from apps.forecasting.models import MarketHistoricalData

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = 'Import external market reference data from CSV into MarketHistoricalData'

    def add_arguments(self, parser):
        parser.add_argument(
            '--file',
            type=str,
            default='demand_and_price_forecasting/cleaned data.csv',
            help='Path to CSV file (relative to project root)',
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Run without saving to database',
        )
        parser.add_argument(
            '--verbose',
            action='store_true',
            help='Print detailed import information',
        )

    def handle(self, *args, **options):
        csv_file = options['file']
        dry_run = options['dry_run']
        verbose = options['verbose']

        try:
            self.stdout.write(f"Reading CSV file: {csv_file}")
            
            # Read and parse CSV
            rows = self._read_csv(csv_file)
            self.stdout.write(f"Read {len(rows)} rows from CSV")
            
            # Aggregate data by product and date
            aggregated_data = self._aggregate_data(rows, verbose)
            self.stdout.write(f"Aggregated into {len(aggregated_data)} records")
            
            # Import into database
            stats = self._import_to_database(aggregated_data, dry_run, verbose)
            
            # Print summary
            self._print_summary(stats, dry_run)
            
        except Exception as e:
            raise CommandError(f"Error: {str(e)}")

    def _read_csv(self, csv_file):
        """Read and parse CSV file."""
        rows = []
        
        try:
            with open(csv_file, 'r', encoding='utf-8-sig') as f:  # utf-8-sig handles BOM
                reader = csv.DictReader(f)
                
                for row in reader:
                    # Skip empty rows and rows with only empty values
                    if not any(row.values()):
                        continue
                    
                    date_val = row.get('DATE', '').strip()
                    commodity_val = row.get('COMMODITY', '').strip()
                    
                    # Skip if DATE or COMMODITY are missing
                    if not date_val or not commodity_val:
                        continue
                    
                    # Skip header-like rows
                    if date_val.lower() in ['date', 'nan', ''] or commodity_val.lower() in ['commodity', 'nan', '']:
                        continue
                    
                    # Skip rows that are just commas (empty rows)
                    if all(v.strip() == '' for v in row.values() if v):
                        continue
                    
                    rows.append(row)
        
        except FileNotFoundError:
            raise CommandError(f"File not found: {csv_file}")
        except Exception as e:
            raise CommandError(f"Error reading CSV: {str(e)}")
        
        return rows

    def _aggregate_data(self, rows, verbose=False):
        """
        Aggregate transaction data by product and date.
        
        Returns dict: {(product_name, transaction_date): {quantity, price, count}}
        """
        aggregated = defaultdict(lambda: {
            'quantities': [],
            'prices': [],
        })
        
        for row in rows:
            try:
                # Parse date
                date_str = row['DATE'].strip()
                transaction_date = self._parse_date(date_str)
                if not transaction_date:
                    continue
                
                # Get product name (normalize)
                product_name = row['COMMODITY'].strip()
                if not product_name:
                    continue
                
                # Parse quantity
                qty_str = row['QUANTITY_kg(DEMAND)'].strip().replace('kg', '').replace('  ', ' ').strip()
                try:
                    quantity = float(qty_str)
                except (ValueError, TypeError):
                    if verbose:
                        print(f"⚠️  Skipping: Invalid quantity '{qty_str}' for {product_name}")
                    continue
                
                # Parse price
                price_str = row['PRICE per kg'].strip()
                try:
                    price = float(price_str)
                except (ValueError, TypeError):
                    if verbose:
                        print(f"⚠️  Skipping: Invalid price '{price_str}' for {product_name}")
                    continue
                
                # Aggregate
                key = (product_name, transaction_date)
                aggregated[key]['quantities'].append(quantity)
                aggregated[key]['prices'].append(price)
            
            except Exception as e:
                if verbose:
                    print(f"⚠️  Error processing row: {e}")
                continue
        
        # Convert to final format
        final_data = {}
        for (product_name, transaction_date), data in aggregated.items():
            total_quantity = sum(data['quantities'])
            avg_price = sum(data['prices']) / len(data['prices'])
            
            final_data[(product_name, transaction_date)] = {
                'quantity_kg': Decimal(str(round(total_quantity, 2))),
                'average_price_per_kg': Decimal(str(round(avg_price, 2))),
                'transaction_count': len(data['quantities']),
            }
        
        return final_data

    def _parse_date(self, date_str):
        """
        Parse date string in various formats.
        
        Handles: M/D/YYYY, MM/DD/YYYY, etc.
        """
        if not date_str:
            return None
        
        # Try common date formats
        formats = [
            '%m/%d/%Y',
            '%m-%d-%Y',
            '%d/%m/%Y',
            '%Y-%m-%d',
        ]
        
        for fmt in formats:
            try:
                dt = datetime.strptime(date_str, fmt)
                return dt.date()
            except ValueError:
                continue
        
        return None

    def _import_to_database(self, aggregated_data, dry_run=False, verbose=False):
        """Import aggregated data into MarketHistoricalData."""
        stats = {
            'total_records': len(aggregated_data),
            'imported': 0,
            'updated': 0,
            'products': defaultdict(lambda: {'imported': 0, 'data_points': 0}),
            'errors': [],
        }
        
        if verbose:
            print(f"\nImporting {len(aggregated_data)} records into MarketHistoricalData...")
        
        # Process each aggregated record
        with transaction.atomic():
            for (product_name, transaction_date), data in aggregated_data.items():
                try:
                    # Calculate total value
                    total_value = data['quantity_kg'] * data['average_price_per_kg']
                    
                    # Create or update record in MarketHistoricalData
                    if not dry_run:
                        obj, created = MarketHistoricalData.objects.update_or_create(
                            product_name=product_name,
                            market_date=transaction_date,
                            source='CSV Import',
                            defaults={
                                'quantity_kg': data['quantity_kg'],
                                'price_per_kg': data['average_price_per_kg'],
                                'total_value': total_value,
                                'data_quality_score': 100,  # Imported data is complete
                            }
                        )
                        
                        if created:
                            stats['imported'] += 1
                        else:
                            stats['updated'] += 1
                    
                    stats['products'][product_name]['imported'] += 1
                    stats['products'][product_name]['data_points'] += 1
                
                except Exception as e:
                    error_msg = f"Error importing {product_name} ({transaction_date}): {str(e)}"
                    stats['errors'].append(error_msg)
                    if verbose:
                        print(f"Error: {error_msg}")
        
        return stats

    def _print_summary(self, stats, dry_run):
        """Print import summary."""
        self.stdout.write("\n" + "="*70)
        self.stdout.write("MARKET DATA IMPORT SUMMARY")
        self.stdout.write("="*70)
        
        if dry_run:
            self.stdout.write(self.style.WARNING("[DRY RUN] - No data was saved"))
        
        self.stdout.write(f"\nStatistics:")
        self.stdout.write(f"   Total records processed: {stats['total_records']}")
        self.stdout.write(f"   Records imported: {stats['imported']}")
        self.stdout.write(f"   Records updated: {stats['updated']}")
        
        if stats['products']:
            self.stdout.write(f"\nBy Product (top 15):")
            sorted_products = sorted(
                stats['products'].items(),
                key=lambda x: x[1]['data_points'],
                reverse=True
            )[:15]
            
            for product_name, product_stats in sorted_products:
                self.stdout.write(
                    f"   * {product_name:20} - {product_stats['data_points']:3} data points"
                )
        
        if stats['errors']:
            self.stdout.write(self.style.ERROR(f"\nErrors ({len(stats['errors'])})"))
            for error in stats['errors'][:10]:
                self.stdout.write(f"   * {error}")
            
            if len(stats['errors']) > 10:
                self.stdout.write(f"   ... and {len(stats['errors']) - 10} more errors")
        
        self.stdout.write("\n" + "="*70)
        self.stdout.write(self.style.SUCCESS("Market data import complete!"))
        self.stdout.write("="*70 + "\n")
