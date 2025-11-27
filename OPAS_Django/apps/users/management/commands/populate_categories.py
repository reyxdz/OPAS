"""
Populate product categories with Philippine agricultural products.
Categories: Vegetable, Fruit, Livestock, Agricultural Product
"""

from django.core.management.base import BaseCommand
from apps.users.seller_models import ProductCategory


class Command(BaseCommand):
    help = 'Populate product categories with Philippine agricultural products'

    def handle(self, *args, **options):
        self.stdout.write('Populating product categories...')

        # Delete existing categories first
        ProductCategory.objects.all().delete()
        self.stdout.write('Cleared existing categories')

        # Define category structure with Tagalog names
        # Structure: Category -> Type (Product) -> Subtype (Variety)
        categories_data = {
            'Vegetable': {
                'Kamatis': ['Cherry Tomato', 'Beef Tomato', 'Roma Tomato'],
                'Talong': ['Talong na Bilog', 'Talong na Haba'],
                'Sitaw': ['Berde', 'Puti'],
                'Ampalaya': ['Ampalaya Amplaya', 'Ampalaya Makiling'],
                'Kalabasa': ['Kalabasa Tagalog', 'Butternut Squash'],
                'Okra': ['Green Okra', 'Red Okra'],
                'Pechay': ['Pechay Baguio', 'Pechay Tagalog', 'Pechay Wombok'],
                'Kangkong': ['Kangkong Puti', 'Kangkong Pula'],
                'Repolyo': ['Green Cabbage', 'Red Cabbage'],
                'Letsugas': ['Iceberg', 'Romaine', 'Butterhead'],
                'Sibuyas': ['Sibuyas Bombay', 'Sibuyas Tagalog', 'Red Onion'],
                'Bawang': ['Native Garlic', 'Imported Garlic'],
                'Kamote': ['Kamote Kahoy', 'Ube', 'Yellow Kamote'],
                'Patatas': ['White Potato', 'Red Potato'],
                'Karot': ['Orange Carrot', 'Purple Carrot'],
            },
            'Fruit': {
                'Mangga': ['Carabao Mango', 'Indian Mango', 'Apple Mango', 'Piko'],
                'Saging': ['Lakatan', 'Latundan', 'Saba', 'Señorita', 'Cardaba'],
                'Pinya': ['Queen Pineapple', 'Formosa', 'MD2'],
                'Papaya': ['Solo Papaya', 'Red Lady', 'Sinta'],
                'Kalamansi': ['Native Kalamansi', 'Seedless Kalamansi'],
                'Dalandan': ['Native Dalandan', 'Sweet Orange'],
                'Suha': ['Pomelo Pink', 'Pomelo White'],
                'Avokado': ['Hass Avocado', 'Native Avocado'],
                'Rambutan': ['Red Rambutan', 'Yellow Rambutan'],
                'Lanzones': ['Longkong', 'Duku'],
                'Durian': ['Puyat', 'Arancillo', 'Native Durian'],
                'Niyog': ['Buko', 'Mature Coconut'],
                'Santol': ['Yellow Santol', 'Red Santol'],
            },
            'Livestock': {
                'Manok': ['Native Chicken', 'Broiler', 'Layer', 'Darag'],
                'Pato': ['Pateros Duck', 'Muscovy Duck', 'Peking Duck'],
                'Baboy': ['Native Pig', 'Large White', 'Duroc', 'Landrace'],
                'Baka': ['Brahman', 'Native Cattle', 'Dairy Cow'],
                'Kalabaw': ['Swamp Buffalo', 'River Buffalo'],
                'Kambing': ['Anglo-Nubian', 'Native Goat', 'Boer'],
                'Itlog ng Manok': ['White Eggs', 'Brown Eggs', 'Free Range'],
                'Itlog ng Pato': ['Salted Eggs', 'Fresh Duck Eggs'],
                'Balut': ['14-day', '16-day', '18-day'],
            },
            'Agricultural Product': {
                'Palay': ['RC160', 'PSB Rc82', 'NSIC Rc222', 'Dinorado'],
                'Mais': ['Yellow Corn', 'White Corn', 'Sweet Corn'],
                'Luya': ['Native Ginger', 'Hawaiian Ginger'],
                'Sili': ['Labuyo', 'Espada', 'Bell Pepper'],
                'Tanglad': ['Native Lemongrass', 'Thai Lemongrass'],
                'Pandan': ['Bansiwag', 'Native Pandan'],
                'Mani': ['Roasted Peanuts', 'Raw Peanuts'],
                'Kasoy': ['Roasted Cashew', 'Raw Cashew'],
                'Pili': ['Roasted Pili', 'Raw Pili'],
            },
        }

        created_count = 0
        
        for category_name, types in categories_data.items():
            # Create or get category
            category, created = ProductCategory.objects.get_or_create(
                slug=category_name.upper().replace(' ', '_'),
                defaults={
                    'name': category_name,
                    'description': f'{category_name} products',
                    'active': True,
                }
            )
            if created:
                created_count += 1
                self.stdout.write(f'  Created category: {category_name}')
            
            for type_name, subtypes in types.items():
                # Create or get type
                product_type, created = ProductCategory.objects.get_or_create(
                    slug=f"{category_name.upper().replace(' ', '_')}_{type_name.upper().replace(' ', '_')}",
                    defaults={
                        'name': type_name,
                        'parent': category,
                        'description': f'{type_name} in {category_name}',
                        'active': True,
                    }
                )
                if created:
                    created_count += 1
                    self.stdout.write(f'    Created type: {type_name}')
                
                for subtype_name in subtypes:
                    # Create or get subtype
                    subtype, created = ProductCategory.objects.get_or_create(
                        slug=f"{category_name.upper().replace(' ', '_')}_{type_name.upper().replace(' ', '_')}_{subtype_name.upper().replace(' ', '_')}",
                        defaults={
                            'name': subtype_name,
                            'parent': product_type,
                            'description': f'{subtype_name}',
                            'active': True,
                        }
                    )
                    if created:
                        created_count += 1

        total = ProductCategory.objects.count()
        self.stdout.write(self.style.SUCCESS(
            f'\nSuccessfully populated categories! Created {created_count} new entries. Total: {total}'
        ))
