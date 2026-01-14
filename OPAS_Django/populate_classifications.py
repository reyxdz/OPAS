from apps.users.seller_models import SellerProduct

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
    'LIVESTOCK': ['fish', 'bangus', 'tilapia', 'catfish', 'pano'],
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
    subtype = subtype.replace(' sa ', ' ')  # Remove "sa" (meaning "from")
    subtype = subtype.replace(' ng ', ' ')  # Remove "ng" (possessive marker)
    subtype = subtype.strip()
    
    return product_type, subtype

def populate_classifications():
    """Main function to populate product classifications"""
    
    products = SellerProduct.objects.filter(
        category_forecast='',  # Empty classification
        is_deleted=False
    )
    
    print(f"\n{'='*70}")
    print(f"SMART PRODUCT CLASSIFICATION POPULATOR")
    print(f"{'='*70}\n")
    
    total = products.count()
    updated = 0
    failed = 0
    
    print(f"Found {total} products to classify...\n")
    
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
            
            status = "✓"
            print(f"[{idx:2d}/{total}] {status} {product.name}")
            print(f"         Category: {category} | Type: {product_type} | Subtype: {product_subtype}")
            
        except Exception as e:
            failed += 1
            print(f"[{idx:2d}/{total}] ✗ ERROR: {product.name}")
            print(f"         Error: {str(e)}")
    
    print(f"\n{'='*70}")
    print(f"CLASSIFICATION COMPLETE")
    print(f"{'='*70}")
    print(f"Total Processed: {total}")
    print(f"Successfully Updated: {updated}")
    print(f"Failed: {failed}")
    print(f"{'='*70}\n")

# Execute the population
populate_classifications()
