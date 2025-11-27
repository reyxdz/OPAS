"""
URL configuration for OPAS project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/4.2/topics/http/urls/
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from apps.users.debug_views import debug_request_info, debug_image_test

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include('apps.authentication.urls')),
    path('api/users/', include('apps.users.urls')),
    path('api/admin/', include('apps.users.admin_urls')),
    path('api/', include('apps.users.urls')),  # Buyer endpoints at /api/products and /api/seller
    path('api/debug/request-info/', debug_request_info, name='debug_request_info'),
    path('api/debug/image-test/', debug_image_test, name='debug_image_test'),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
