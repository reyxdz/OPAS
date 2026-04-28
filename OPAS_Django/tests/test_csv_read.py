import csv

csv_file = 'demand_and_price_forecasting/cleaned data.csv'

with open(csv_file, 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    rows = list(reader)
    
    print(f'Total rows read: {len(rows)}')
    print(f'Fieldnames: {reader.fieldnames}')
    
    # Show first 5 valid rows
    valid_count = 0
    for i, row in enumerate(rows):
        if row.get('DATE') and row.get('COMMODITY'):
            if valid_count < 5:
                print(f"\nRow {i}: {row}")
            valid_count += 1
    
    print(f'\nTotal valid rows (with DATE and COMMODITY): {valid_count}')
