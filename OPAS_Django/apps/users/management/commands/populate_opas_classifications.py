from django.core.management.base import BaseCommand
from django.db import models
from apps.users.opas_models import OPASProduct

# Mapping of Tagalog/Bisaya to English for types
LANGUAGE_TRANSLATION = {
    # Tagalog -> English
    'saging': 'Banana',
    'puso': 'Coconut Heart',
    'gabi': 'Taro',
    'ube': 'Purple Yam',
    'langka': 'Jackfruit',
    'mango': 'Mango',
    'papaya': 'Papaya',
    'pineapple': 'Pineapple',
    'kamatis': 'Tomato',
    'sibuyas': 'Onion',
    'bawang': 'Garlic',
    'carrots': 'Carrot',
    'kalamansi': 'Calamansi',
    'lemon': 'Lemon',
    'orange': 'Orange',
    'repolyo': 'Cabbage',
    'alogue': 'Lettuce',
    'patola': 'Bottle Gourd',
    'pechay': 'Bok Choy',
    'radish': 'Radish',
    'beans': 'Beans',
    'sitaw': 'Long Beans',
    'okra': 'Okra',
    'ampalaya': 'Bitter Melon',
    'labanos': 'Radish',
    'talong': 'Eggplant',
    'pipino': 'Cucumber',
    'tumpeng': 'Bottle Gourd',
    
    # Bisaya -> English
    'bananas': 'Banana',
    'plantain': 'Plantain',
    'calamansi': 'Calamansi',
    'mangga': 'Mango',
    'pinya': 'Pineapple',
    'kamote': 'Sweet Potato',
    'lubi': 'Coconut',
    'mais': 'Corn',
    'bigas': 'Rice',
    'tinapay': 'Bread',
    'karne': 'Meat',
    'pano': 'Fish',
    'bangus': 'Bangus',
    'tilapia': 'Tilapia',
    'catfish': 'Catfish',
    'manok': 'Chicken',
    'baboy': 'Pork',
    'baka': 'Beef',
    'itlog': 'Egg',
}

# Category keywords to infer from product names
CATEGORY_KEYWORDS = {
    'VEGETABLE': ['tomato', 'onion', 'garlic', 'carrot', 'cabbage', 'lettuce', 'bean', 
                  'okra', 'bitter', 'eggplant', 'cucumber', 'radish', 'potato', 'kamatis',
                  'sibuyas', 'bawang', 'repolyo', 'alogue', 'patola', 'pechay', 'sitaw',
                  'talong', 'pipino', 'tumpeng', 'pechay', 'ampalaya', 'labanos', 'gabi'],
    'FRUIT': ['mango', 'banana', 'papaya', 'pineapple', 'coconut', 'orange', 'lemon',
              'calamansi', 'kalamansi', 'apple', 'grape', 'watermelon', 'melon', 'jackfruit',
              'avocado', 'guava', 'rambutan', 'mango', 'saging', 'puso', 'langka', 'ube',
              'mangga', 'pinya', 'lubi', 'calamansi'],
    'LIVESTOCK': ['fish', 'bangus', 'tilapia', 'catfish', 'pano', 'baboy', 'pork', 'baka', 'beef', 'karne'],
    'POULTRY': ['chicken', 'egg', 'duck', 'manok', 'itlog'],
}


def infer_category(product_name):
    """Infer category from product name"""
    name_lower = product_name.lower()
    
    for category, keywords in CATEGORY_KEYWORDS.items():
        for keyword in keywords:
            if keyword in name_lower:
                return category
    
    return 'VEGETABLE'  # Default to vegetable if not matched


def extract_type_and_subtype(product_name):
    """
    Extract type and subtype from product name.
    
    Examples:
    - "Bangus sa Kawayan" -> type="Bangus", subtype="Kawayan"
    - "Saging Lakatan" -> type="Banana", subtype="Lakatan"
    - "Tomato Fresh" -> type="Tomato", subtype="Fresh"
    """
    parts = product_name.split()
    
    if not parts:
        return '', ''
    
    # First part is typically the main product type
    first_word = parts[0].lower()
    
    # Translate if it's a Tagalog/Bisaya word
    if first_word in LANGUAGE_TRANSLATION:
        product_type = LANGUAGE_TRANSLATION[first_word]
    else:
        # Capitalize the English word
        product_type = parts[0].capitalize()
    
    # Rest of the name is the subtype (keep original)
    subtype = ' '.join(parts[1:]) if len(parts) > 1 else ''
    
    # Clean up common patterns
    subtype = subtype.replace(' sa ', ' ').strip()  # Remove "sa" (meaning "from")
    subtype = subtype.replace(' ng ', ' ').strip()  # Remove "ng" (possessive marker)
    
    # Remove leading/trailing "sa" and "ng" if they appear alone
    subtype_parts = subtype.split()
    if subtype_parts and subtype_parts[0].lower() in ['sa', 'ng']:
        subtype_parts = subtype_parts[1:]
    if subtype_parts and subtype_parts[-1].lower() in ['sa', 'ng']:
        subtype_parts = subtype_parts[:-1]
    
    subtype = ' '.join(subtype_parts).strip()
    
    return product_type, subtype


class Command(BaseCommand):
    help = 'Populate classification for OPAS products (CSV imports) for demand forecasting'

    def handle(self, *args, **options):
        # Only process OPAS products with empty classifications
        products = OPASProduct.objects.filter(
            is_active=True
        ).filter(
            models.Q(category_forecast='') | models.Q(category_forecast__isnull=True)
        )
        
        self.stdout.write(self.style.SUCCESS(f"\n{'='*70}"))
        self.stdout.write(self.style.SUCCESS(f"OPAS PRODUCT CLASSIFICATION POPULATOR"))
        self.stdout.write(self.style.SUCCESS(f"(CSV Forecasting Products Only)"))
        self.stdout.write(self.style.SUCCESS(f"{'='*70}\n"))
        
        total = products.count()
        updated = 0
        failed = 0
        
        self.stdout.write(f"Searching for OPAS products with empty classifications...")
        self.stdout.write(f"Found {total} products to classify...\n")
        
        for idx, product in enumerate(products, 1):
            try:
                # Infer category
                category = infer_category(product.name)
                
                # Extract type and subtype
                product_type, product_subtype = extract_type_and_subtype(product.name)
                
                # Update product
                product.category_forecast = category
                product.product_type = product_type
                product.product_subtype = product_subtype
                product.save()
                
                updated += 1
                
                self.stdout.write(f"[{idx:2d}/{total}] ✓ {product.name}")
                self.stdout.write(f"         Category: {category} | Type: {product_type} | Subtype: {product_subtype}")
                
            except Exception as e:
                failed += 1
                self.stdout.write(self.style.ERROR(f"[{idx:2d}/{total}] ✗ ERROR: {product.name}"))
                self.stdout.write(self.style.ERROR(f"         Error: {str(e)}"))
        
        self.stdout.write(self.style.SUCCESS(f"\n{'='*70}"))
        self.stdout.write(self.style.SUCCESS(f"CLASSIFICATION COMPLETE"))
        self.stdout.write(self.style.SUCCESS(f"{'='*70}"))
        self.stdout.write(f"Total Processed: {total}")
        self.stdout.write(f"Successfully Updated: {updated}")
        self.stdout.write(f"Failed: {failed}")
        self.stdout.write(self.style.SUCCESS(f"{'='*70}\n"))
