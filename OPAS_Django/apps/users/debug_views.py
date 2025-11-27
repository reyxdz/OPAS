"""
Test endpoint to debug request information
"""
from django.http import JsonResponse
from django.views.decorators.http import require_GET
import logging

logger = logging.getLogger(__name__)

@require_GET
def debug_request_info(request):
    """Debug endpoint to see what request information is available"""
    return JsonResponse({
        'host': request.get_host(),
        'scheme': request.scheme,
        'method': request.method,
        'path': request.path,
        'META': {
            'HTTP_HOST': request.META.get('HTTP_HOST'),
            'REMOTE_ADDR': request.META.get('REMOTE_ADDR'),
            'SERVER_NAME': request.META.get('SERVER_NAME'),
            'SERVER_PORT': request.META.get('SERVER_PORT'),
            'wsgi.url_scheme': request.META.get('wsgi.url_scheme'),
        }
    })

@require_GET
def debug_image_test(request):
    """Test endpoint to check image URL construction"""
    from .seller_models import SellerProduct, ProductImage, ProductStatus
    
    try:
        # Get first pending product with images
        product = SellerProduct.objects.filter(
            status=ProductStatus.PENDING
        ).prefetch_related('product_images').first()
        
        if not product:
            return JsonResponse({'error': 'No pending products found'}, status=404)
        
        # Get images
        images = product.product_images.all()
        
        response_data = {
            'product_id': product.id,
            'product_name': product.name,
            'image_count': images.count(),
            'server_info': {
                'host': request.get_host(),
                'scheme': request.scheme,
            },
            'images': []
        }
        
        for img in images:
            if img.image:
                relative_url = img.image.url
                # Correct way: manually construct with scheme and host
                scheme = request.scheme
                host = request.get_host()
                absolute_url = f'{scheme}://{host}{relative_url}'
                
                response_data['images'].append({
                    'id': img.id,
                    'relative_url': relative_url,
                    'absolute_url': absolute_url,
                    'absolute_url_build_method': request.build_absolute_uri(relative_url),
                    'file_exists': img.image.storage.exists(img.image.name),
                })
        
        return JsonResponse(response_data)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)
