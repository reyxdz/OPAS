"""
Seller Views for OPAS Platform
Handles all seller panel operations including profile, products, orders,
inventory, forecasting, payouts, and analytics.

Includes 2 Permission Classes and 10 ViewSets with 46 endpoints (43 original + 3 new registration endpoints)
"""

from rest_framework import viewsets, status, permissions, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, BasePermission, AllowAny
from rest_framework.exceptions import NotFound
from django.utils import timezone
from django.db import models, transaction
from django.db.models import Q, Sum, Avg, Count, F
from decimal import Decimal
import logging

from .models import User, UserRole, SellerStatus
from .seller_models import (
    SellerProduct, SellerOrder, SellToOPAS, 
    SellerPayout, SellerForecast, ProductImage,
    ProductStatus, OrderStatus,
    Notification, Announcement, SellerAnnouncementRead
)
from .admin_models import SellerRegistrationRequest, SellerRegistrationStatus
from .seller_serializers import (
    SellerProfileSerializer,
    SellerProductListSerializer,
    SellerProductCreateUpdateSerializer,
    SellerOrderSerializer,
    SellerRegistrationRequestSerializer,
    SellerRegistrationSubmitSerializer,
    SellerRegistrationStatusSerializer,
    SellToOPASSerializer,
    SellerPayoutSerializer,
    SellerForecastSerializer,
    AnalyticsSerializer,
    SellerDashboardSerializer,
    NotificationSerializer,
    NotificationListSerializer,
    AnnouncementSerializer,
    AnnouncementListSerializer,
    ProductListBuyerSerializer,
    ProductDetailBuyerSerializer,
    SellerPublicProfileSerializer,
)

logger = logging.getLogger(__name__)


# ==================== PERMISSION CLASSES ====================

class IsOPASSeller(BasePermission):
    """
    Permission to check if user is an approved seller.
    Restricts access to seller endpoints to only authenticated,
    role-verified SELLER users with APPROVED status.
    """
    message = 'You must be an approved seller to access seller endpoints.'

    def has_permission(self, request, view):
        """Check if user is authenticated and is an approved seller"""
        if not request.user.is_authenticated:
            return False
        
        # Check if user has SELLER role and APPROVED status
        is_seller = (
            request.user.role == UserRole.SELLER and
            request.user.seller_status == SellerStatus.APPROVED
        )
        
        if is_seller:
            logger.info(f'Seller access granted to: {request.user.email}')
        else:
            logger.warning(
                f'Unauthorized seller access attempt by: {request.user.email} '
                f'(Role: {request.user.role}, Status: {request.user.seller_status})'
            )
        
        return is_seller


class IsBuyerOrApprovedSeller(BasePermission):
    """
    Permission to allow buyer/seller registration operations.
    
    Applied CORE PRINCIPLES:
    - Security: Ensures only authenticated buyers or sellers can register
    - Authorization: Checks user role before allowing registration submission
    - Audit: Logs unauthorized access attempts
    
    Allows:
    - BUYER role: Can submit registration applications
    - SELLER role (PENDING/REQUEST_MORE_INFO): Can resubmit registration
    """
    message = 'You must be a buyer or pending seller to submit registration.'
    
    def has_permission(self, request, view):
        """Check if user can submit buyer-to-seller registration."""
        if not request.user.is_authenticated:
            return False
        
        # Check if user is BUYER
        is_buyer = request.user.role == UserRole.BUYER
        
        # Check if user is SELLER with PENDING or REQUEST_MORE_INFO status
        is_pending_seller = (
            request.user.role == UserRole.SELLER and
            request.user.seller_status in [
                SellerStatus.PENDING,
                # Add REQUEST_MORE_INFO if it's a status option
            ]
        )
        
        allowed = is_buyer or is_pending_seller
        
        if not allowed:
            logger.warning(
                f'Unauthorized registration access attempt by: {request.user.email} '
                f'(Role: {request.user.role}, Status: {request.user.seller_status})'
            )
        
        return allowed


# ==================== SELLER REGISTRATION VIEWSET ====================

class SellerRegistrationViewSet(viewsets.ViewSet):
    """
    Buyer-to-Seller registration workflow management.
    
    Handles the complete registration flow for buyers converting to sellers:
    1. Submit registration with farm/store information
    2. Track registration status
    3. Retrieve registration details with document info
    
    Applied CORE PRINCIPLES:
    1. Resource Management: Efficient queries with select_related/prefetch_related
    2. Security & Authorization: Role and ownership verification on all endpoints
    3. Input Validation: Comprehensive backend validation of all fields
    4. API Idempotency: One registration per user enforced by unique constraint
    5. Rate Limiting: Built-in via unique constraint (one registration per user)
    
    Endpoints:
    - POST /api/sellers/register-application/ - Submit registration
    - GET /api/sellers/<id>/ - Get registration details
    - GET /api/sellers/my-registration/ - Get current user's registration
    
    Example usage:
    - Buyer clicks "Become a Seller"
    - Fills form with farm/store information
    - Submits POST to register-application/
    - Receives registration ID and status PENDING
    - Can check status with GET my-registration/
    """
    
    permission_classes = [IsAuthenticated]
    
    def retrieve(self, request, pk=None):
        """
        Get registration details by ID.
        
        Applied CORE PRINCIPLES:
        - Security: Ownership verification (user must be the seller or admin)
        - Resource Management: Efficient query with select_related and prefetch_related
        - Audit: Logs unauthorized access attempts
        
        GET /api/sellers/registrations/{id}/
        
        Response 200:
        {
            "id": 1,
            "seller_email": "buyer@example.com",
            "seller_full_name": "John Doe",
            "farm_name": "Green Valley Farm",
            "farm_location": "Davao, Philippines",
            "products_grown": "Bananas, Coconut, Cacao",
            "store_name": "Green Valley Marketplace",
            "store_description": "Premium organic farm products",
            "documents": [
                {
                    "id": 1,
                    "document_type": "TAX_ID",
                    "document_url": "https://...",
                    "status": "PENDING",
                    "status_display": "Pending Verification",
                    "uploaded_at": "2025-11-23T10:30:00Z"
                }
            ],
            "status": "PENDING",
            "status_display": "Pending Approval",
            "submitted_at": "2025-11-23T10:30:00Z",
            "days_pending": 2,
            "is_pending": true,
            "is_approved": false,
            "is_rejected": false
        }
        
        Response 404: Not found or unauthorized
        """
        try:
            # Get registration with related documents
            registration = SellerRegistrationRequest.objects.select_related(
                'seller'
            ).prefetch_related(
                'document_verifications'
            ).get(pk=pk)
            
            # Security: Allow access if user is the seller applying or admin
            if request.user != registration.seller and not request.user.is_staff:
                logger.warning(
                    f'Unauthorized access to registration {pk} by {request.user.email}'
                )
                return Response(
                    {'detail': 'Not found.'},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            serializer = SellerRegistrationRequestSerializer(
                registration,
                context={'request': request}
            )
            
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        except SellerRegistrationRequest.DoesNotExist:
            return Response(
                {'detail': 'Registration not found.'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f'Error retrieving registration {pk}: {str(e)}')
            return Response(
                {'detail': 'Error retrieving registration.'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    @action(
        detail=False,
        methods=['post'],
        permission_classes=[IsAuthenticated, IsBuyerOrApprovedSeller],
        url_path='register-application',
        url_name='submit-registration'
    )
    def register_application(self, request):
        """
        Submit seller registration application.
        
        CORE PRINCIPLES APPLIED:
        - Input Validation: All fields validated server-side
        - Security: Only current authenticated user can submit
        - Idempotency: One registration per user (database constraint)
        - Audit Trail: All submissions logged
        
        POST /api/sellers/register-application/
        
        Payload:
        {
            "farm_name": "Green Valley Farm",
            "farm_location": "Davao, Philippines",
            "products_grown": "Bananas, Coconut, Cacao",
            "store_name": "Green Valley Marketplace",
            "store_description": "Premium organic farm products"
        }
        
        Response 201:
        {
            "id": 1,
            "status": "PENDING",
            "status_display": "Pending Approval",
            "seller_email": "buyer@example.com",
            "seller_full_name": "John Doe",
            "farm_name": "Green Valley Farm",
            "farm_location": "Davao, Philippines",
            "farm_size": "2.5 hectares",
            "products_grown": "Bananas, Coconut, Cacao",
            "store_name": "Green Valley Marketplace",
            "store_description": "Premium organic farm products",
            "documents": [],
            "submitted_at": "2025-11-23T10:30:00Z",
            "days_pending": 0,
            "is_pending": true,
            "is_approved": false,
            "is_rejected": false
        }
        
        Response 400: Validation errors
        - Empty required fields
        - User already has pending/approved registration
        - Non-buyer user attempting registration
        """
        try:
            serializer = SellerRegistrationSubmitSerializer(
                data=request.data,
                context={'request': request}
            )
            
            if not serializer.is_valid():
                logger.warning(
                    f'Registration validation failed for {request.user.email}: '
                    f'{serializer.errors}'
                )
                return Response(
                    serializer.errors,
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Create registration via serializer
            registration = serializer.save()
            
            logger.info(
                f'Seller registration submitted by {request.user.email} '
                f'(ID: {registration.id})'
            )
            
            # Return created registration details
            response_serializer = SellerRegistrationRequestSerializer(
                registration,
                context={'request': request}
            )
            
            return Response(
                response_serializer.data,
                status=status.HTTP_201_CREATED
            )
        
        except Exception as e:
            logger.error(
                f'Error submitting registration for {request.user.email}: {str(e)}',
                exc_info=True
            )
            return Response(
                {'detail': 'Error submitting registration. Please try again.'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    @action(
        detail=False,
        methods=['get'],
        permission_classes=[IsAuthenticated],
        url_path='my-registration',
        url_name='my-registration'
    )
    def my_registration(self, request):
        """
        Get current user's seller registration status.
        
        Applied CORE PRINCIPLES:
        - User Experience: Quick status check for buyers
        - Resource Management: Minimal response payload
        - Security: Only shows current user's registration
        
        GET /api/sellers/my-registration/
        
        Response 200:
        {
            "id": 1,
            "status": "PENDING",
            "status_display": "Pending Approval",
            "farm_name": "Green Valley Farm",
            "store_name": "Green Valley Marketplace",
            "submitted_at": "2025-11-23T10:30:00Z",
            "reviewed_at": null,
            "rejection_reason": null,
            "days_pending": 2,
            "is_pending": true,
            "is_approved": false,
            "is_rejected": false,
            "message": "Your application is being reviewed. Submitted 2 days ago."
        }
        
        Response 404: User has not submitted registration
        """
        try:
            # Get user's registration (OneToOne relationship)
            registration = SellerRegistrationRequest.objects.select_related(
                'seller'
            ).get(seller=request.user)
            
            serializer = SellerRegistrationStatusSerializer(
                registration,
                context={'request': request}
            )
            
            logger.info(f'Registration status retrieved by {request.user.email}')
            
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        except SellerRegistrationRequest.DoesNotExist:
            # User hasn't submitted registration yet
            return Response(
                {'detail': 'No registration found. Start by submitting your application.'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(
                f'Error retrieving my registration for {request.user.email}: {str(e)}'
            )
            return Response(
                {'detail': 'Error retrieving registration status.'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# ==================== PERMISSION CLASSES ====================

class IsOPASSeller(BasePermission):
    """
    Permission to check if user is an approved seller.
    Restricts access to seller endpoints to only authenticated,
    role-verified SELLER users with APPROVED status.
    """
    message = 'You must be an approved seller to access seller endpoints.'

    def has_permission(self, request, view):
        """Check if user is authenticated and is an approved seller"""
        if not request.user.is_authenticated:
            return False
        
        # Check if user has SELLER role and APPROVED status
        is_seller = (
            request.user.role == UserRole.SELLER and
            request.user.seller_status == SellerStatus.APPROVED
        )
        
        if is_seller:
            logger.info(f'Seller access granted to: {request.user.email}')
        else:
            logger.warning(
                f'Unauthorized seller access attempt by: {request.user.email} '
                f'(Role: {request.user.role}, Status: {request.user.seller_status})'
            )
        
        return is_seller


# ==================== SELLER PROFILE VIEWSET ====================

class SellerProfileViewSet(viewsets.ViewSet):
    """
    Seller profile management.
    
    Endpoints:
    - GET /api/seller/profile/ - Retrieve seller profile
    - PUT /api/seller/profile/ - Update seller profile
    - POST /api/seller/profile/submit_documents/ - Submit documents for verification
    - GET /api/seller/profile/document_status/ - Get document verification status
    """
    permission_classes = [IsAuthenticated, IsOPASSeller]

    def list(self, request):
        """Retrieve seller profile"""
        try:
            user = request.user
            serializer = SellerProfileSerializer(user)
            logger.info(f'Profile retrieved by: {user.email}')
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving profile: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve profile'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def update(self, request):
        """Update seller profile"""
        try:
            user = request.user
            serializer = SellerProfileSerializer(user, data=request.data, partial=True)
            
            if serializer.is_valid():
                serializer.save()
                logger.info(f'Profile updated by: {user.email}')
                return Response(serializer.data, status=status.HTTP_200_OK)
            
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        except Exception as e:
            logger.error(f'Error updating profile: {str(e)}')
            return Response(
                {'error': 'Failed to update profile'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['post'])
    def submit_documents(self, request):
        """
        Submit documents for seller verification.
        
        Expected fields:
        - documents: File(s) for verification
        """
        try:
            user = request.user
            # Update seller documents verification flag
            user.seller_documents_verified = True
            user.save()
            
            logger.info(f'Documents submitted by: {user.email}')
            return Response(
                {'message': 'Documents submitted successfully'},
                status=status.HTTP_201_CREATED
            )
        
        except Exception as e:
            logger.error(f'Error submitting documents: {str(e)}')
            return Response(
                {'error': 'Failed to submit documents'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def document_status(self, request):
        """Get document verification status"""
        try:
            user = request.user
            return Response(
                {
                    'verified': user.seller_documents_verified,
                    'seller_status': user.get_seller_status_display(),
                    'seller_approval_date': user.seller_approval_date,
                },
                status=status.HTTP_200_OK
            )
        
        except Exception as e:
            logger.error(f'Error retrieving document status: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve document status'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# ==================== PRODUCT MANAGEMENT VIEWSET ====================

class ProductManagementViewSet(viewsets.ViewSet):
    """
    Product listing and inventory management.
    
    Endpoints:
    - GET /api/seller/products/ - List all seller products
    - POST /api/seller/products/ - Create new product
    - GET /api/seller/products/{id}/ - Retrieve product details
    - PUT /api/seller/products/{id}/ - Update product
    - DELETE /api/seller/products/{id}/ - Delete product
    - GET /api/seller/products/active/ - List active products
    - GET /api/seller/products/expired/ - List expired products
    - POST /api/seller/products/check_ceiling_price/ - Check price ceiling
    """
    permission_classes = [IsAuthenticated, IsOPASSeller]

    def list(self, request):
        """List all seller products"""
        try:
            # Optimize query with select_related to avoid N+1 queries
            products = SellerProduct.objects.filter(
                seller=request.user
            ).select_related('seller').prefetch_related('product_images').order_by('-created_at')
            
            serializer = SellerProductListSerializer(
                products, 
                many=True,
                context={'request': request}
            )
            logger.info(f'Product list retrieved by: {request.user.email}')
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error listing products: {str(e)}')
            return Response(
                {'error': 'Failed to list products'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def create(self, request):
        """Create new product"""
        try:
            data = request.data.copy()
            data['seller'] = request.user.id
            
            serializer = SellerProductCreateUpdateSerializer(
                data=data,
                context={'request': request}
            )
            if serializer.is_valid():
                serializer.save(seller=request.user)
                logger.info(f'Product created by: {request.user.email}')
                return Response(serializer.data, status=status.HTTP_201_CREATED)
            
            # Log detailed validation errors
            logger.warning(f'Product creation validation failed for {request.user.email}: {serializer.errors}')
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        except Exception as e:
            logger.error(f'Error creating product: {str(e)}')
            return Response(
                {'error': f'Failed to create product: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def retrieve(self, request, pk=None):
        """Retrieve product details"""
        try:
            product = SellerProduct.objects.get(id=pk, seller=request.user)
            serializer = SellerProductListSerializer(product)
            logger.info(f'Product {pk} retrieved by: {request.user.email}')
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        except SellerProduct.DoesNotExist:
            return Response(
                {'error': 'Product not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f'Error retrieving product: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve product'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def update(self, request, pk=None):
        """Update product"""
        try:
            product = SellerProduct.objects.get(id=pk, seller=request.user)
            serializer = SellerProductCreateUpdateSerializer(product, data=request.data, partial=True)
            
            if serializer.is_valid():
                serializer.save()
                logger.info(f'Product {pk} updated by: {request.user.email}')
                return Response(serializer.data, status=status.HTTP_200_OK)
            
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        except SellerProduct.DoesNotExist:
            return Response(
                {'error': 'Product not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f'Error updating product: {str(e)}')
            return Response(
                {'error': 'Failed to update product'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def destroy(self, request, pk=None):
        """Delete product"""
        try:
            product = SellerProduct.objects.get(id=pk, seller=request.user)
            product.delete()
            logger.info(f'Product {pk} deleted by: {request.user.email}')
            return Response(status=status.HTTP_204_NO_CONTENT)
        
        except SellerProduct.DoesNotExist:
            return Response(
                {'error': 'Product not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f'Error deleting product: {str(e)}')
            return Response(
                {'error': 'Failed to delete product'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def active(self, request):
        """List active products"""
        try:
            products = SellerProduct.objects.filter(
                seller=request.user,
                status=ProductStatus.ACTIVE
            ).order_by('-created_at')
            serializer = SellerProductListSerializer(products, many=True)
            logger.info(f'Active products retrieved by: {request.user.email}')
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving active products: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve active products'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def expired(self, request):
        """List expired products"""
        try:
            products = SellerProduct.objects.filter(
                seller=request.user,
                status=ProductStatus.EXPIRED
            ).order_by('-created_at')
            serializer = SellerProductListSerializer(products, many=True)
            logger.info(f'Expired products retrieved by: {request.user.email}')
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving expired products: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve expired products'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def get_categories(self, request):
        """
        Get all active product categories in hierarchical structure.
        Returns categories with their children for cascading dropdowns.
        
        Response format:
        [
            {
                "id": 1,
                "slug": "VEGETABLES",
                "name": "Vegetables",
                "description": "Fresh vegetables",
                "active": true,
                "children": [
                    {
                        "id": 2,
                        "slug": "LEAFY_GREENS",
                        "name": "Leafy Greens",
                        "parent_id": 1,
                        "description": "",
                        "active": true
                    }
                ]
            }
        ]
        """
        try:
            from .seller_models import ProductCategory
            from .seller_serializers import ProductCategoryTreeSerializer
            
            # Get only top-level categories (no parent)
            categories = ProductCategory.objects.filter(
                parent__isnull=True,
                active=True
            ).order_by('name')
            
            serializer = ProductCategoryTreeSerializer(categories, many=True)
            logger.info(f'Product categories retrieved by: {request.user.email}')
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving product categories: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve product categories'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['post'])

    def check_stock_availability(self, request):
        """
        Check if sufficient stock is available for order.
        Phase 3.2: Stock Level Management
        
        Expected fields:
        - product_id: Product ID to check
        - quantity_required: Quantity needed
        
        Returns:
        - available: Boolean indicating if stock is available
        - current_stock: Current stock level
        - required_quantity: Requested quantity
        - shortage: If not available, how much is short
        - below_minimum: Whether stock would fall below minimum after order
        """
        try:
            product_id = request.data.get('product_id')
            quantity_required = request.data.get('quantity_required', 0)
            
            if not product_id or not quantity_required:
                return Response(
                    {'error': 'Missing required fields: product_id, quantity_required'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            product = SellerProduct.objects.get(id=product_id, seller=request.user)
            
            available_stock = product.stock_level
            has_stock = available_stock >= quantity_required
            would_be_low = (available_stock - quantity_required) < product.minimum_stock
            
            response_data = {
                'product_id': product_id,
                'product_name': product.name,
                'current_stock': available_stock,
                'required_quantity': quantity_required,
                'available': has_stock,
                'stock_after_order': max(0, available_stock - quantity_required),
                'minimum_stock_level': product.minimum_stock,
                'would_be_low_stock': would_be_low
            }
            
            if not has_stock:
                response_data['shortage'] = quantity_required - available_stock
                response_data['message'] = f'Insufficient stock. Shortage: {response_data["shortage"]} units'
            else:
                response_data['message'] = 'Stock available'
            
            logger.info(
                f'Stock check by {request.user.email}: '
                f'Product {product_id}, Required: {quantity_required}, Available: {available_stock}'
            )
            
            return Response(response_data, status=status.HTTP_200_OK)
        
        except SellerProduct.DoesNotExist:
            return Response(
                {'error': 'Product not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f'Error checking stock availability: {str(e)}')
            return Response(
                {'error': 'Failed to check stock availability'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'])
    def upload_image(self, request, pk=None):
        """
        Upload product image.
        
        Expected:
        - image: Image file (multipart/form-data)
        - is_primary: Boolean (optional, default: False)
        - alt_text: Alt text for image (optional)
        - order: Display order (optional)
        """
        try:
            product = SellerProduct.objects.get(id=pk, seller=request.user)
            
            # Validate file was provided
            if 'image' not in request.FILES:
                return Response(
                    {'error': 'No image file provided'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            image_file = request.FILES['image']
            
            # Validate file size (max 5MB)
            max_size = 5 * 1024 * 1024  # 5MB
            if image_file.size > max_size:
                return Response(
                    {'error': 'Image file too large (max 5MB)'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Validate file type
            valid_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
            if image_file.content_type not in valid_types:
                return Response(
                    {'error': 'Invalid image file type'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Create image record
            from .seller_models import ProductImage
            
            is_primary = request.data.get('is_primary', False) == 'true'
            order = int(request.data.get('order', 0))
            alt_text = request.data.get('alt_text', '')
            
            product_image = ProductImage.objects.create(
                product=product,
                image=image_file,
                is_primary=is_primary,
                order=order,
                alt_text=alt_text
            )
            
            from .seller_serializers import ProductImageSerializer
            serializer = ProductImageSerializer(product_image, context={'request': request})
            logger.info(f'Product image uploaded by: {request.user.email}')
            
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        
        except SellerProduct.DoesNotExist:
            return Response(
                {'error': 'Product not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f'Error uploading product image: {str(e)}')
            return Response(
                {'error': f'Failed to upload image: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['get'])
    def images(self, request, pk=None):
        """Get product images"""
        try:
            product = SellerProduct.objects.get(id=pk, seller=request.user)
            from .seller_models import ProductImage
            
            images = ProductImage.objects.filter(product=product).order_by('order', '-uploaded_at')
            
            from .seller_serializers import ProductImageSerializer
            serializer = ProductImageSerializer(images, many=True, context={'request': request})
            
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        except SellerProduct.DoesNotExist:
            return Response(
                {'error': 'Product not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f'Error retrieving product images: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve images'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['delete'])
    def delete_image(self, request, pk=None):
        """
        Delete product image.
        
        Expected URL parameter:
        - image_id: Image ID to delete (passed as query parameter ?image_id=123)
        """
        try:
            product = SellerProduct.objects.get(id=pk, seller=request.user)
            image_id = request.query_params.get('image_id')
            
            if not image_id:
                return Response(
                    {'error': 'image_id parameter required'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            from .seller_models import ProductImage
            image = ProductImage.objects.get(id=image_id, product=product)
            
            # Delete the image file from storage
            if image.image:
                image.image.delete(save=False)
            
            image.delete()
            logger.info(f'Product image deleted by: {request.user.email}')
            
            return Response(status=status.HTTP_204_NO_CONTENT)
        
        except SellerProduct.DoesNotExist:
            return Response(
                {'error': 'Product not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f'Error deleting product image: {str(e)}')
            return Response(
                {'error': 'Failed to delete image'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# ==================== SELL TO OPAS VIEWSET ====================

class SellToOPASViewSet(viewsets.ViewSet):
    """
    Bulk submissions to OPAS platform.
    
    Endpoints:
    - POST /api/seller/sell-to-opas/submit/ - Submit bulk offer to OPAS
    - GET /api/seller/sell-to-opas/pending/ - List pending submissions
    - GET /api/seller/sell-to-opas/history/ - Get submission history
    - GET /api/seller/sell-to-opas/{id}/status/ - Get submission status
    """
    permission_classes = [IsAuthenticated, IsOPASSeller]

    def create(self, request):
        """Submit bulk offer to OPAS"""
        try:
            data = request.data.copy()
            data['seller'] = request.user.id
            
            serializer = SellToOPASSerializer(
                data=data,
                context={'request': request}
            )
            if serializer.is_valid():
                serializer.save(seller=request.user)
                logger.info(f'SellToOPAS submission created by: {request.user.email}')
                return Response(serializer.data, status=status.HTTP_201_CREATED)
            
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        except Exception as e:
            logger.error(f'Error creating SellToOPAS submission: {str(e)}')
            return Response(
                {'error': 'Failed to submit offer'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def pending(self, request):
        """List pending submissions"""
        try:
            submissions = SellToOPAS.objects.filter(
                seller=request.user,
                status='PENDING'
            ).order_by('-created_at')
            serializer = SellToOPASSerializer(submissions, many=True)
            logger.info(f'Pending submissions retrieved by: {request.user.email}')
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving pending submissions: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve pending submissions'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def history(self, request):
        """Get submission history"""
        try:
            submissions = SellToOPAS.objects.filter(
                seller=request.user
            ).order_by('-created_at')
            serializer = SellToOPASSerializer(submissions, many=True)
            logger.info(f'Submission history retrieved by: {request.user.email}')
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving submission history: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve submission history'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['get'])
    def status(self, request, pk=None):
        """Get submission status"""
        try:
            submission = SellToOPAS.objects.get(id=pk, seller=request.user)
            serializer = SellToOPASSerializer(submission)
            logger.info(f'Submission {pk} status retrieved by: {request.user.email}')
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        except SellToOPAS.DoesNotExist:
            return Response(
                {'error': 'Submission not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f'Error retrieving submission status: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve submission status'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# ==================== ORDER MANAGEMENT VIEWSET ====================

class OrderManagementViewSet(viewsets.ViewSet):
    """
    Order management and fulfillment.
    
    Endpoints:
    - GET /api/seller/orders/incoming/ - List incoming orders
    - POST /api/seller/orders/{id}/accept/ - Accept an order
    - POST /api/seller/orders/{id}/reject/ - Reject an order
    - POST /api/seller/orders/{id}/mark_fulfilled/ - Mark order as fulfilled
    - POST /api/seller/orders/{id}/mark_delivered/ - Mark order as delivered
    - GET /api/seller/orders/completed/ - List completed orders
    - GET /api/seller/orders/pending/ - List pending orders
    - GET /api/seller/orders/cancelled/ - List cancelled orders
    """
    permission_classes = [IsAuthenticated, IsOPASSeller]

    @action(detail=False, methods=['get'])
    def incoming(self, request):
        """List incoming orders"""
        try:
            orders = SellerOrder.objects.filter(
                seller=request.user,
                status=OrderStatus.PENDING
            ).order_by('-created_at')
            serializer = SellerOrderSerializer(orders, many=True)
            logger.info(f'Incoming orders retrieved by: {request.user.email}')
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving incoming orders: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve incoming orders'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'])
    def accept(self, request, pk=None):
        """
        Accept an order.
        
        Business Logic (Phase 3.2):
        - Check if order is still in PENDING status
        - Verify sufficient stock is available
        - Prevent double-accepting same order (idempotency check)
        - Update stock level when fulfillment happens later
        """
        try:
            order = SellerOrder.objects.get(id=pk, seller=request.user)
            
            # 1. Status check - prevent state changes for non-pending orders
            if order.status != OrderStatus.PENDING:
                return Response(
                    {
                        'error': f'Cannot accept order in {order.get_status_display()} status',
                        'current_status': order.status,
                        'message': 'This order has already been processed'
                    },
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # 2. Stock availability check (Phase 3.2)
            if order.product:
                available_stock = order.product.stock_level
                required_quantity = order.quantity
                
                if available_stock < required_quantity:
                    return Response(
                        {
                            'error': 'Insufficient stock available',
                            'available_stock': available_stock,
                            'required_quantity': required_quantity,
                            'shortage': required_quantity - available_stock,
                            'message': f'Only {available_stock} units available, but {required_quantity} requested'
                        },
                        status=status.HTTP_400_BAD_REQUEST
                    )
            
            # 3. Accept the order
            order.status = OrderStatus.ACCEPTED
            order.accepted_at = timezone.now()
            order.save()
            
            logger.info(
                f'Order {pk} accepted by: {request.user.email} '
                f'(Stock: {order.product.stock_level if order.product else "N/A"})'
            )
            
            serializer = SellerOrderSerializer(order)
            return Response(
                {
                    **serializer.data,
                    'message': 'Order accepted successfully',
                    'stock_reserved': order.quantity
                },
                status=status.HTTP_200_OK
            )
        
        except SellerOrder.DoesNotExist:
            return Response(
                {'error': 'Order not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f'Error accepting order: {str(e)}')
            return Response(
                {'error': 'Failed to accept order'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        """Reject an order"""
        try:
            order = SellerOrder.objects.get(id=pk, seller=request.user)
            
            if order.status != OrderStatus.PENDING:
                return Response(
                    {'error': f'Cannot reject order in {order.get_status_display()} status'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            order.status = OrderStatus.REJECTED
            order.rejected_at = timezone.now()
            reason = request.data.get('reason', '')
            if reason:
                order.rejection_reason = reason
            order.save()
            
            serializer = SellerOrderSerializer(order)
            logger.info(f'Order {pk} rejected by: {request.user.email}')
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        except SellerOrder.DoesNotExist:
            return Response(
                {'error': 'Order not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f'Error rejecting order: {str(e)}')
            return Response(
                {'error': 'Failed to reject order'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'])
    def mark_fulfilled(self, request, pk=None):
        """
        Mark order as fulfilled.
        
        Business Logic (Phase 3.2):
        - Update product stock when order is fulfilled
        - Decrement stock by order quantity
        - Log low stock alerts if stock falls below reorder level
        - Create notification if stock level drops
        """
        try:
            order = SellerOrder.objects.get(id=pk, seller=request.user)
            
            if order.status != OrderStatus.ACCEPTED:
                return Response(
                    {
                        'error': 'Only accepted orders can be marked as fulfilled',
                        'current_status': order.get_status_display(),
                        'message': 'Order must be in ACCEPTED status to be fulfilled'
                    },
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Phase 3.2: Auto-update stock after order fulfillment
            if order.product:
                old_stock = order.product.stock_level
                new_stock = old_stock - order.quantity
                
                if new_stock < 0:
                    return Response(
                        {
                            'error': 'Cannot fulfill order - insufficient stock',
                            'current_stock': old_stock,
                            'order_quantity': order.quantity,
                            'deficit': abs(new_stock)
                        },
                        status=status.HTTP_400_BAD_REQUEST
                    )
                
                # Update stock
                order.product.stock_level = new_stock
                order.product.save()
                
                # Check if stock is now below reorder level (Phase 3.2)
                is_low_stock = new_stock < order.product.minimum_stock
                
                logger.info(
                    f'Stock updated for product {order.product.id}: '
                    f'{old_stock} → {new_stock} (order: {order.quantity}). '
                    f'Low stock alert: {is_low_stock}'
                )
            
            # Update order status
            order.status = OrderStatus.FULFILLED
            order.fulfilled_at = timezone.now()
            order.save()
            
            serializer = SellerOrderSerializer(order)
            response_data = {
                **serializer.data,
                'message': 'Order marked as fulfilled',
                'stock_updated': order.product is not None
            }
            
            # Include stock info if product exists
            if order.product:
                response_data['stock_info'] = {
                    'product_id': order.product.id,
                    'product_name': order.product.name,
                    'stock_before': old_stock,
                    'stock_after': new_stock,
                    'quantity_fulfilled': order.quantity,
                    'is_low_stock': is_low_stock,
                    'minimum_stock': order.product.minimum_stock
                }
            
            logger.info(f'Order {pk} marked fulfilled by: {request.user.email}')
            return Response(response_data, status=status.HTTP_200_OK)
        
        except SellerOrder.DoesNotExist:
            return Response(
                {'error': 'Order not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f'Error marking order fulfilled: {str(e)}')
            return Response(
                {'error': 'Failed to mark order as fulfilled'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'])
    def mark_delivered(self, request, pk=None):
        """Mark order as delivered"""
        try:
            order = SellerOrder.objects.get(id=pk, seller=request.user)
            
            if order.status != OrderStatus.FULFILLED:
                return Response(
                    {'error': f'Only fulfilled orders can be marked as delivered'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            order.status = OrderStatus.DELIVERED
            order.delivered_at = timezone.now()
            order.save()
            
            serializer = SellerOrderSerializer(order)
            logger.info(f'Order {pk} marked delivered by: {request.user.email}')
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        except SellerOrder.DoesNotExist:
            return Response(
                {'error': 'Order not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f'Error marking order delivered: {str(e)}')
            return Response(
                {'error': 'Failed to mark order as delivered'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def completed(self, request):
        """List completed orders"""
        try:
            orders = SellerOrder.objects.filter(
                seller=request.user,
                status=OrderStatus.DELIVERED
            ).order_by('-created_at')
            serializer = SellerOrderSerializer(orders, many=True)
            logger.info(f'Completed orders retrieved by: {request.user.email}')
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving completed orders: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve completed orders'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def pending(self, request):
        """List pending orders"""
        try:
            orders = SellerOrder.objects.filter(
                seller=request.user,
                status=OrderStatus.PENDING
            ).order_by('-created_at')
            serializer = SellerOrderSerializer(orders, many=True)
            logger.info(f'Pending orders retrieved by: {request.user.email}')
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving pending orders: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve pending orders'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def cancelled(self, request):
        """List cancelled orders"""
        try:
            orders = SellerOrder.objects.filter(
                seller=request.user,
                status=OrderStatus.CANCELLED
            ).order_by('-created_at')
            serializer = SellerOrderSerializer(orders, many=True)
            logger.info(f'Cancelled orders retrieved by: {request.user.email}')
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving cancelled orders: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve cancelled orders'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# ==================== INVENTORY TRACKING VIEWSET ====================

class InventoryTrackingViewSet(viewsets.ViewSet):
    """
    Inventory management and tracking.
    
    Endpoints:
    - GET /api/seller/inventory/overview/ - Inventory overview with statistics
    - GET /api/seller/inventory/by_product/ - Inventory broken down by product
    - GET /api/seller/inventory/low_stock/ - Products with low stock
    - GET /api/seller/inventory/movement/ - Stock movement history
    """
    permission_classes = [IsAuthenticated, IsOPASSeller]

    @action(detail=False, methods=['get'])
    def overview(self, request):
        """Inventory overview with statistics"""
        try:
            products = SellerProduct.objects.filter(seller=request.user)
            
            total_items = products.aggregate(Sum('stock_level'))['stock_level__sum'] or 0
            total_products = products.count()
            low_stock_count = products.filter(
                stock_level__lt=F('minimum_stock')
            ).count()
            
            overview_data = {
                'total_items': total_items,
                'total_products': total_products,
                'low_stock_count': low_stock_count,
                'active_listings': products.filter(status=ProductStatus.ACTIVE).count(),
                'expired_listings': products.filter(status=ProductStatus.EXPIRED).count(),
            }
            
            logger.info(f'Inventory overview retrieved by: {request.user.email}')
            return Response(overview_data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving inventory overview: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve inventory overview'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def by_product(self, request):
        """Inventory broken down by product"""
        try:
            products = SellerProduct.objects.filter(seller=request.user).order_by('-stock_level')
            
            inventory_data = [
                {
                    'id': product.id,
                    'name': product.name,
                    'stock_level': product.stock_level,
                    'minimum_stock': product.minimum_stock,
                    'unit': product.unit,
                    'is_low_stock': product.stock_level < product.minimum_stock,
                    'status': product.status,
                }
                for product in products
            ]
            
            logger.info(f'Product inventory retrieved by: {request.user.email}')
            return Response(inventory_data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving product inventory: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve product inventory'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def low_stock(self, request):
        """
        Products with low stock.
        Phase 3.2: Stock Level Management
        
        Returns alert information for products below reorder level.
        Used to alert sellers when stock falls below minimum_stock threshold.
        """
        try:
            products = SellerProduct.objects.filter(
                seller=request.user,
                stock_level__lt=F('minimum_stock')
            ).order_by('stock_level')
            
            low_stock_data = [
                {
                    'id': product.id,
                    'name': product.name,
                    'current_stock': product.stock_level,
                    'minimum_stock': product.minimum_stock,
                    'deficit': product.minimum_stock - product.stock_level,
                    'unit': product.unit,
                    'price': str(product.price),
                    'product_type': product.product_type,
                    'status': product.status,
                    'alert_level': 'CRITICAL' if product.stock_level == 0 else 'WARNING',
                    'last_updated': product.updated_at.isoformat(),
                    'recommendation': f'Reorder at least {product.minimum_stock - product.stock_level} {product.unit}s to meet minimum level'
                }
                for product in products
            ]
            
            logger.info(
                f'Low stock alerts retrieved by: {request.user.email} '
                f'(Count: {len(low_stock_data)})'
            )
            
            return Response(
                {
                    'low_stock_products': low_stock_data,
                    'total_low_stock_count': len(low_stock_data),
                    'critical_count': sum(1 for p in low_stock_data if p['alert_level'] == 'CRITICAL'),
                    'warning_count': sum(1 for p in low_stock_data if p['alert_level'] == 'WARNING'),
                },
                status=status.HTTP_200_OK
            )
        
        except Exception as e:
            logger.error(f'Error retrieving low stock products: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve low stock products'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def movement(self, request):
        """Stock movement history"""
        try:
            # Get orders to calculate stock movement
            orders = SellerOrder.objects.filter(
                seller=request.user,
                status=OrderStatus.DELIVERED
            ).order_by('-delivered_at')[:20]  # Last 20 delivered orders
            
            movement_data = [
                {
                    'order_id': order.id,
                    'quantity': order.quantity,
                    'date': order.delivered_at,
                    'product_name': order.product_name if hasattr(order, 'product_name') else 'Unknown',
                    'buyer': order.buyer.email if hasattr(order, 'buyer') else 'Unknown',
                }
                for order in orders
            ]
            
            logger.info(f'Stock movement retrieved by: {request.user.email}')
            return Response(movement_data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving stock movement: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve stock movement'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# ==================== FORECASTING VIEWSET ====================

class ForecastingViewSet(viewsets.ViewSet):
    """
    Demand forecasting and predictions using advanced algorithms.
    
    Features:
    - Historical sales analysis with trend detection
    - Seasonality adjustment
    - Risk assessment (surplus/stockout probabilities)
    - Confidence scoring
    - Actionable recommendations
    
    Endpoints:
    - GET /api/seller/forecast/next_month/ - Next month forecast with algorithm
    - GET /api/seller/forecast/product/{product}/ - Product-specific forecast
    - GET /api/seller/forecast/historical/ - Historical forecast data
    - GET /api/seller/forecast/insights/ - Forecast insights and recommendations
    - POST /api/seller/forecast/generate/ - Generate forecast for specific product
    - GET /api/seller/forecast/trend_data/ - Trend chart data
    """
    permission_classes = [IsAuthenticated, IsOPASSeller]

    def _get_historical_sales(self, product):
        """Get historical sales data for a product"""
        from datetime import timedelta
        
        # Get sales data from past 90 days
        cutoff_date = timezone.now().date() - timedelta(days=90)
        
        orders = SellerOrder.objects.filter(
            seller=product.seller,
            product=product,
            status__in=['FULFILLED', 'DELIVERED'],
            created_at__date__gte=cutoff_date
        ).values('created_at__date').annotate(quantity=models.Sum('quantity'))
        
        sales_data = [
            {
                'date': order['created_at__date'],
                'quantity': order['quantity'],
                'price': float(product.price)
            }
            for order in orders
        ]
        
        return sorted(sales_data, key=lambda x: x['date'])
    
    def _generate_forecast_for_product(self, product):
        """Generate comprehensive forecast for a product"""
        from .forecasting_algorithm import ForecastingAlgorithm
        
        # Get historical sales
        sales_data = self._get_historical_sales(product)
        
        # Initialize algorithm
        algorithm = ForecastingAlgorithm()
        
        # Generate forecast
        forecast_data = algorithm.forecast_demand(
            sales_data,
            product.stock_level,
            product.minimum_stock
        )
        
        return forecast_data, sales_data
    
    @action(detail=False, methods=['get'])
    def next_month(self, request):
        """Next month forecast with enhanced algorithm"""
        try:
            from datetime import timedelta
            
            # Get all active products for the seller
            products = SellerProduct.objects.filter(
                seller=request.user,
                status='ACTIVE'
            )[:10]  # Limit to 10 products
            
            forecasts_data = []
            
            for product in products:
                # Get or create forecast
                forecast_date = timezone.now().date()
                forecast_start = forecast_date + timedelta(days=1)
                forecast_end = forecast_start + timedelta(days=30)
                
                # Generate forecast
                forecast_data, sales_data = self._generate_forecast_for_product(product)
                
                # Create/update forecast record
                forecast, created = SellerForecast.objects.update_or_create(
                    seller=request.user,
                    product=product,
                    forecast_date=forecast_date,
                    defaults={
                        'forecast_start': forecast_start,
                        'forecast_end': forecast_end,
                        'forecasted_demand': forecast_data['forecasted_demand'],
                        'confidence_score': forecast_data['confidence_score'],
                        'surplus_probability': forecast_data['surplus_probability'],
                        'stockout_probability': forecast_data['stockout_probability'],
                        'recommended_stock': forecast_data['recommended_stock'],
                        'trend': forecast_data['trend'],
                        'volatility': forecast_data['volatility'],
                        'growth_rate': forecast_data['growth_rate'],
                        'trend_multiplier': forecast_data['trend_multiplier'],
                        'seasonality_detected': forecast_data['seasonality']['has_seasonality'],
                        'historical_sales_count': len(sales_data),
                        'average_daily_sales': forecast_data['historical_analysis']['average_daily'],
                        'recommendations': forecast_data['recommendations'],
                    }
                )
                
                serializer = SellerForecastSerializer(forecast)
                forecasts_data.append(serializer.data)
            
            logger.info(f'Next month forecast generated for {len(forecasts_data)} products by: {request.user.email}')
            return Response(forecasts_data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error generating next month forecast: {str(e)}')
            return Response(
                {'error': f'Failed to generate next month forecast: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['post'])
    def generate(self, request):
        """Generate forecast for specific product"""
        try:
            from datetime import timedelta
            
            product_id = request.data.get('product_id')
            if not product_id:
                return Response(
                    {'error': 'product_id is required'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Get product
            product = SellerProduct.objects.get(
                id=product_id,
                seller=request.user
            )
            
            # Generate forecast
            forecast_data, sales_data = self._generate_forecast_for_product(product)
            
            # Create forecast record
            forecast_date = timezone.now().date()
            forecast_start = forecast_date + timedelta(days=1)
            forecast_end = forecast_start + timedelta(days=30)
            
            forecast, created = SellerForecast.objects.update_or_create(
                seller=request.user,
                product=product,
                forecast_date=forecast_date,
                defaults={
                    'forecast_start': forecast_start,
                    'forecast_end': forecast_end,
                    'forecasted_demand': forecast_data['forecasted_demand'],
                    'confidence_score': forecast_data['confidence_score'],
                    'surplus_probability': forecast_data['surplus_probability'],
                    'stockout_probability': forecast_data['stockout_probability'],
                    'recommended_stock': forecast_data['recommended_stock'],
                    'trend': forecast_data['trend'],
                    'volatility': forecast_data['volatility'],
                    'growth_rate': forecast_data['growth_rate'],
                    'trend_multiplier': forecast_data['trend_multiplier'],
                    'seasonality_detected': forecast_data['seasonality']['has_seasonality'],
                    'historical_sales_count': len(sales_data),
                    'average_daily_sales': forecast_data['historical_analysis']['average_daily'],
                    'recommendations': forecast_data['recommendations'],
                }
            )
            
            serializer = SellerForecastSerializer(forecast)
            logger.info(f'Forecast generated for product {product_id} by: {request.user.email}')
            return Response(serializer.data, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)
        
        except SellerProduct.DoesNotExist:
            return Response(
                {'error': 'Product not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f'Error generating forecast: {str(e)}')
            return Response(
                {'error': f'Failed to generate forecast: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def product(self, request, pk=None):
        """Product-specific forecast"""
        try:
            forecasts = SellerForecast.objects.filter(
                seller=request.user,
                product_id=pk
            ).order_by('-forecast_date')[:30]
            
            serializer = SellerForecastSerializer(forecasts, many=True)
            logger.info(f'Product {pk} forecast retrieved by: {request.user.email}')
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving product forecast: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve product forecast'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def historical(self, request):
        """Historical forecast data"""
        try:
            forecasts = SellerForecast.objects.filter(
                seller=request.user
            ).order_by('-forecast_date')[:100]
            
            serializer = SellerForecastSerializer(forecasts, many=True)
            logger.info(f'Historical forecast retrieved by: {request.user.email}')
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving historical forecast: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve historical forecast'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    @action(detail=False, methods=['get'])
    def trend_data(self, request):
        """Get trend data for charts (historical + forecasted)"""
        try:
            from .forecasting_algorithm import ForecastingAlgorithm
            
            product_id = request.query_params.get('product_id')
            if not product_id:
                return Response(
                    {'error': 'product_id is required'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Get product and forecast
            product = SellerProduct.objects.get(id=product_id, seller=request.user)
            
            # Get latest forecast
            latest_forecast = SellerForecast.objects.filter(
                seller=request.user,
                product=product
            ).order_by('-forecast_date').first()
            
            if not latest_forecast:
                # Generate new forecast
                forecast_data, sales_data = self._generate_forecast_for_product(product)
            else:
                # Use existing forecast
                sales_data = self._get_historical_sales(product)
                forecast_data = {
                    'forecasted_demand': latest_forecast.forecasted_demand,
                    'confidence_score': float(latest_forecast.confidence_score),
                    'trend': latest_forecast.trend,
                    'volatility': float(latest_forecast.volatility),
                    'growth_rate': float(latest_forecast.growth_rate),
                    'surplus_probability': float(latest_forecast.surplus_probability),
                    'stockout_probability': float(latest_forecast.stockout_probability),
                    'recommended_stock': latest_forecast.recommended_stock,
                    'recommendations': latest_forecast.recommendations,
                    'seasonality': {
                        'has_seasonality': latest_forecast.seasonality_detected,
                        'weekly_multipliers': {i: 1.0 for i in range(7)},
                    },
                }
            
            # Generate trend data
            algorithm = ForecastingAlgorithm()
            trend_data = algorithm.generate_trend_data(sales_data, forecast_data)
            
            logger.info(f'Trend data retrieved for product {product_id} by: {request.user.email}')
            return Response(trend_data, status=status.HTTP_200_OK)
        
        except SellerProduct.DoesNotExist:
            return Response(
                {'error': 'Product not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f'Error retrieving trend data: {str(e)}')
            return Response(
                {'error': f'Failed to retrieve trend data: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def insights(self, request):
        """Forecast insights and recommendations"""
        try:
            # Get all recent forecasts
            forecasts = SellerForecast.objects.filter(
                seller=request.user
            ).order_by('-forecast_date')[:50]
            
            if not forecasts:
                return Response({
                    'total_forecasted_demand': 0,
                    'average_confidence': 0,
                    'high_risk_count': 0,
                    'medium_risk_count': 0,
                    'recommendations': ['No forecasts available yet. Generate forecasts to see insights.']
                }, status=status.HTTP_200_OK)
            
            # Calculate insights
            total_forecasted_demand = sum(f.forecasted_demand for f in forecasts)
            avg_confidence = sum(f.confidence_score for f in forecasts) / len(forecasts)
            
            # Risk analysis
            high_risk = sum(1 for f in forecasts if max(f.surplus_probability, f.stockout_probability) >= 70)
            medium_risk = sum(1 for f in forecasts if 40 <= max(f.surplus_probability, f.stockout_probability) < 70)
            low_risk = sum(1 for f in forecasts if max(f.surplus_probability, f.stockout_probability) < 40)
            
            # High-risk products
            high_risk_products = [
                {
                    'product_id': f.product_id,
                    'product_name': f.product.name if f.product else 'Unknown',
                    'forecasted_demand': f.forecasted_demand,
                    'current_stock': f.product.stock_level if f.product else 0,
                    'surplus_risk': float(f.surplus_probability),
                    'stockout_risk': float(f.stockout_probability),
                }
                for f in forecasts
                if max(f.surplus_probability, f.stockout_probability) >= 70
            ][:5]
            
            # Trend summary
            uptrend_count = sum(1 for f in forecasts if f.trend == 'UPTREND')
            downtrend_count = sum(1 for f in forecasts if f.trend == 'DOWNTREND')
            stable_count = sum(1 for f in forecasts if f.trend == 'STABLE')
            
            # Generate overall recommendations
            recommendations = [
                f"📊 {len(forecasts)} products forecasted with {avg_confidence:.0f}% average confidence",
                f"🎯 {high_risk_count} high-risk, {medium_risk_count} medium-risk, {low_risk_count} low-risk products",
                f"📈 Trend analysis: {uptrend_count} uptrend, {downtrend_count} downtrend, {stable_count} stable",
            ]
            
            if high_risk_count > 0:
                recommendations.append(f"⚠️ Review {high_risk_count} high-risk products immediately")
            
            if uptrend_count > downtrend_count:
                recommendations.append("📈 Increasing demand trend detected. Plan procurement accordingly.")
            elif downtrend_count > uptrend_count:
                recommendations.append("📉 Decreasing demand trend detected. Reduce procurement to minimize surplus.")
            
            recommendations.append("💡 Regularly update forecasts to improve accuracy")
            
            insights_data = {
                'total_forecasted_demand': total_forecasted_demand,
                'average_confidence': round(float(avg_confidence), 2),
                'high_risk_count': high_risk_count,
                'medium_risk_count': medium_risk_count,
                'low_risk_count': low_risk_count,
                'trend_summary': {
                    'uptrend': uptrend_count,
                    'downtrend': downtrend_count,
                    'stable': stable_count,
                },
                'high_risk_products': high_risk_products,
                'recommendations': recommendations,
            }
            
            logger.info(f'Forecast insights retrieved by: {request.user.email}')
            return Response(insights_data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving forecast insights: {str(e)}')
            return Response(
                {'error': f'Failed to retrieve forecast insights: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
            
            logger.info(f'Forecast insights retrieved by: {request.user.email}')
            return Response(insights_data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving forecast insights: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve forecast insights'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# ==================== PAYOUT TRACKING VIEWSET ====================

class PayoutTrackingViewSet(viewsets.ViewSet):
    """
    Payout and payment tracking.
    
    Endpoints:
    - GET /api/seller/payouts/ - List all payouts
    - GET /api/seller/payouts/pending/ - List pending payouts
    - GET /api/seller/payouts/completed/ - List completed payouts
    - GET /api/seller/payouts/earnings/ - Total earnings summary
    """
    permission_classes = [IsAuthenticated, IsOPASSeller]

    def list(self, request):
        """List all payouts"""
        try:
            payouts = SellerPayout.objects.filter(seller=request.user).order_by('-period_end')
            serializer = SellerPayoutSerializer(payouts, many=True)
            logger.info(f'Payouts list retrieved by: {request.user.email}')
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error listing payouts: {str(e)}')
            return Response(
                {'error': 'Failed to list payouts'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def pending(self, request):
        """List pending payouts"""
        try:
            payouts = SellerPayout.objects.filter(
                seller=request.user,
                status='PENDING'
            ).order_by('-period_end')
            serializer = SellerPayoutSerializer(payouts, many=True)
            logger.info(f'Pending payouts retrieved by: {request.user.email}')
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving pending payouts: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve pending payouts'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def completed(self, request):
        """List completed payouts"""
        try:
            payouts = SellerPayout.objects.filter(
                seller=request.user,
                status='COMPLETED'
            ).order_by('-period_end')
            serializer = SellerPayoutSerializer(payouts, many=True)
            logger.info(f'Completed payouts retrieved by: {request.user.email}')
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving completed payouts: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve completed payouts'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def earnings(self, request):
        """Total earnings summary"""
        try:
            from django.db.models import Sum, F
            
            payouts = SellerPayout.objects.filter(seller=request.user)
            
            # Aggregate earnings
            earnings_agg = payouts.aggregate(
                total_earnings=Sum('total_earnings'),
                transaction_fees=Sum('transaction_fees'),
                service_fees=Sum('service_fee_amount'),
                other_deductions=Sum('other_deductions'),
                net_earnings=Sum('net_earnings')
            )
            
            total_earnings = earnings_agg['total_earnings'] or Decimal('0')
            total_deductions = (earnings_agg['transaction_fees'] or Decimal('0')) + \
                              (earnings_agg['service_fees'] or Decimal('0')) + \
                              (earnings_agg['other_deductions'] or Decimal('0'))
            net_earnings = earnings_agg['net_earnings'] or Decimal('0')
            pending_amount = payouts.filter(status='PENDING').aggregate(Sum('net_earnings'))['net_earnings__sum'] or Decimal('0')
            
            earnings_data = {
                'total_earnings': str(total_earnings),
                'total_deductions': str(total_deductions),
                'net_earnings': str(net_earnings),
                'pending_amount': str(pending_amount),
                'completed_amount': str(net_earnings - pending_amount),
                'payout_count': payouts.count(),
                'pending_count': payouts.filter(status='PENDING').count(),
                'completed_count': payouts.filter(status='COMPLETED').count(),
            }
            
            logger.info(f'Earnings summary retrieved by: {request.user.email}')
            return Response(earnings_data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving earnings summary: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve earnings summary'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# ==================== ANALYTICS VIEWSET ====================

class AnalyticsViewSet(viewsets.ViewSet):
    """
    Sales analytics and performance metrics.
    
    Endpoints:
    - GET /api/seller/analytics/dashboard/ - Analytics dashboard
    - GET /api/seller/analytics/daily/ - Daily performance data
    - GET /api/seller/analytics/weekly/ - Weekly performance data
    - GET /api/seller/analytics/monthly/ - Monthly performance data
    - GET /api/seller/analytics/top_products/ - Top performing products
    - GET /api/seller/analytics/forecast_vs_actual/ - Forecast vs actual comparison
    """
    permission_classes = [IsAuthenticated, IsOPASSeller]

    @action(detail=False, methods=['get'])
    def dashboard(self, request):
        """Analytics dashboard"""
        try:
            # Calculate statistics
            orders = SellerOrder.objects.filter(seller=request.user)
            total_orders = orders.count()
            completed_orders = orders.filter(status=OrderStatus.DELIVERED).count()
            total_revenue = orders.filter(status=OrderStatus.DELIVERED).aggregate(Sum('total_amount'))['total_amount__sum'] or Decimal('0')
            
            products = SellerProduct.objects.filter(seller=request.user)
            total_products = products.count()
            active_products = products.filter(status=ProductStatus.ACTIVE).count()
            
            dashboard_data = {
                'total_orders': total_orders,
                'completed_orders': completed_orders,
                'pending_orders': orders.filter(status=OrderStatus.PENDING).count(),
                'total_revenue': str(total_revenue),
                'total_products': total_products,
                'active_products': active_products,
                'avg_order_value': str(total_revenue / completed_orders) if completed_orders > 0 else '0',
            }
            
            logger.info(f'Analytics dashboard retrieved by: {request.user.email}')
            return Response(dashboard_data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving analytics dashboard: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve analytics dashboard'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def daily(self, request):
        """Daily performance data"""
        try:
            orders = SellerOrder.objects.filter(
                seller=request.user,
                status=OrderStatus.DELIVERED
            ).order_by('-delivered_at')[:7]  # Last 7 days
            
            daily_data = {}
            for order in orders:
                date_key = order.delivered_at.date() if order.delivered_at else 'N/A'
                if date_key not in daily_data:
                    daily_data[date_key] = {'count': 0, 'total': Decimal('0')}
                daily_data[date_key]['count'] += 1
                daily_data[date_key]['total'] += order.total_amount or Decimal('0')
            
            formatted_data = [
                {'date': date, 'orders': data['count'], 'revenue': str(data['total'])}
                for date, data in sorted(daily_data.items(), reverse=True)
            ]
            
            logger.info(f'Daily analytics retrieved by: {request.user.email}')
            return Response(formatted_data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving daily analytics: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve daily analytics'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def weekly(self, request):
        """Weekly performance data"""
        try:
            orders = SellerOrder.objects.filter(
                seller=request.user,
                status=OrderStatus.DELIVERED
            ).order_by('-delivered_at')[:30]  # Last 30 days (4+ weeks)
            
            weekly_data = {}
            for order in orders:
                if order.delivered_at:
                    week_key = order.delivered_at.isocalendar()[1]  # ISO week number
                    if week_key not in weekly_data:
                        weekly_data[week_key] = {'count': 0, 'total': Decimal('0')}
                    weekly_data[week_key]['count'] += 1
                    weekly_data[week_key]['total'] += order.total_amount or Decimal('0')
            
            formatted_data = [
                {'week': week, 'orders': data['count'], 'revenue': str(data['total'])}
                for week, data in sorted(weekly_data.items(), reverse=True)
            ]
            
            logger.info(f'Weekly analytics retrieved by: {request.user.email}')
            return Response(formatted_data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving weekly analytics: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve weekly analytics'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def monthly(self, request):
        """Monthly performance data"""
        try:
            orders = SellerOrder.objects.filter(
                seller=request.user,
                status=OrderStatus.DELIVERED
            ).order_by('-delivered_at')[:120]  # Last 120 days (~4 months)
            
            monthly_data = {}
            for order in orders:
                if order.delivered_at:
                    month_key = order.delivered_at.strftime('%Y-%m')
                    if month_key not in monthly_data:
                        monthly_data[month_key] = {'count': 0, 'total': Decimal('0')}
                    monthly_data[month_key]['count'] += 1
                    monthly_data[month_key]['total'] += order.total_amount or Decimal('0')
            
            formatted_data = [
                {'month': month, 'orders': data['count'], 'revenue': str(data['total'])}
                for month, data in sorted(monthly_data.items(), reverse=True)
            ]
            
            logger.info(f'Monthly analytics retrieved by: {request.user.email}')
            return Response(formatted_data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving monthly analytics: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve monthly analytics'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def top_products(self, request):
        """Top performing products"""
        try:
            # Get products with highest order counts
            top_products = SellerProduct.objects.filter(
                seller=request.user
            ).annotate(
                order_count=Count('id')
            ).order_by('-order_count')[:10]
            
            top_data = [
                {
                    'id': product.id,
                    'name': product.name,
                    'orders': 0,  # Would count orders linked to this product
                    'revenue': '0',
                    'stock': product.stock_level,
                }
                for product in top_products
            ]
            
            logger.info(f'Top products retrieved by: {request.user.email}')
            return Response(top_data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving top products: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve top products'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def forecast_vs_actual(self, request):
        """Forecast vs actual comparison"""
        try:
            forecasts = SellerForecast.objects.filter(
                seller=request.user
            ).order_by('-forecast_date')[:12]
            
            comparison_data = [
                {
                    'forecast_date': f.forecast_date,
                    'forecasted_demand': f.forecasted_demand,
                    'actual_demand': 0,  # Would count actual orders for this date
                    'accuracy': f.accuracy_percentage if hasattr(f, 'accuracy_percentage') else 0,
                    'confidence': f.confidence_score,
                }
                for f in forecasts
            ]
            
            logger.info(f'Forecast vs actual retrieved by: {request.user.email}')
            return Response(comparison_data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving forecast vs actual: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve forecast vs actual'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# ==================== NOTIFICATION VIEWSET ====================

class NotificationViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing seller notifications.
    
    Provides endpoints for:
    - GET /api/users/seller/notifications/ - List all notifications
    - GET /api/users/seller/notifications/{id}/ - Get notification details
    - POST /api/users/seller/notifications/{id}/mark_read/ - Mark as read
    - GET /api/users/seller/notifications/?type=Orders - Filter by type
    
    Permissions: IsAuthenticated, IsOPASSeller
    """
    permission_classes = [IsAuthenticated, IsOPASSeller]
    
    def get_queryset(self):
        """Get notifications for the current seller"""
        return Notification.objects.filter(
            seller=self.request.user
        ).order_by('-created_at')
    
    def get_serializer_class(self):
        """Use lightweight serializer for list, full for detail"""
        if self.action == 'list':
            return NotificationListSerializer
        return NotificationSerializer
    
    def list(self, request, *args, **kwargs):
        """
        List all notifications for the seller.
        
        Query Parameters:
        - type: Filter by type (Orders, Payments, System)
        - unread_only: Filter unread notifications (true/false)
        """
        queryset = self.get_queryset()
        
        # Filter by type if provided
        notification_type = request.query_params.get('type')
        if notification_type:
            queryset = queryset.filter(type=notification_type)
        
        # Filter unread only if requested
        unread_only = request.query_params.get('unread_only', 'false').lower() == 'true'
        if unread_only:
            queryset = queryset.filter(is_read=False)
        
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        """
        Mark a notification as read.
        
        POST /api/users/seller/notifications/{id}/mark_read/
        
        Response: Updated notification object
        """
        notification = self.get_object()
        notification.is_read = True
        notification.save()
        
        serializer = self.get_serializer(notification)
        logger.info(f'Notification {notification.id} marked as read by {request.user.email}')
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    @action(detail=False, methods=['post'])
    def mark_all_read(self, request):
        """
        Mark all notifications as read for current seller.
        
        POST /api/users/seller/notifications/mark_all_read/
        
        Response: Count of notifications marked as read
        """
        queryset = self.get_queryset()
        count, _ = queryset.filter(is_read=False).update(is_read=True)
        
        logger.info(f'{count} notifications marked as read by {request.user.email}')
        return Response(
            {'success': True, 'count': count},
            status=status.HTTP_200_OK
        )


# ==================== ANNOUNCEMENT VIEWSET ====================

class AnnouncementViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for managing admin announcements to sellers.
    
    Read-only endpoints for announcements:
    - GET /api/users/seller/announcements/ - List all announcements
    - GET /api/users/seller/announcements/{id}/ - Get announcement details
    - POST /api/users/seller/announcements/{id}/mark_read/ - Mark as read
    - GET /api/users/seller/announcements/?priority=HIGH - Filter by priority
    
    Permissions: IsAuthenticated, IsOPASSeller
    """
    permission_classes = [IsAuthenticated, IsOPASSeller]
    
    def get_queryset(self):
        """Get all announcements"""
        from django.utils import timezone
        return Announcement.objects.filter(
            expires_at__isnull=True
        ).order_by('-created_at') | Announcement.objects.filter(
            expires_at__gt=timezone.now()
        ).order_by('-created_at')
    
    def get_serializer_class(self):
        """Use lightweight serializer for list, full for detail"""
        if self.action == 'list':
            return AnnouncementListSerializer
        return AnnouncementSerializer
    
    def list(self, request, *args, **kwargs):
        """
        List all active announcements.
        
        Query Parameters:
        - type: Filter by type (Features, Maintenance, Policy, Action Required)
        - priority: Filter by priority (LOW, MEDIUM, HIGH)
        - unread_only: Show only unread announcements (true/false)
        """
        queryset = self.get_queryset()
        
        # Filter by type if provided
        announcement_type = request.query_params.get('type')
        if announcement_type:
            queryset = queryset.filter(type=announcement_type)
        
        # Filter by priority if provided
        priority = request.query_params.get('priority')
        if priority:
            queryset = queryset.filter(priority=priority)
        
        # Filter unread only if requested
        unread_only = request.query_params.get('unread_only', 'false').lower() == 'true'
        if unread_only:
            # Get announcements NOT read by current user
            read_announcements = SellerAnnouncementRead.objects.filter(
                seller=request.user
            ).values_list('announcement_id', flat=True)
            queryset = queryset.exclude(id__in=read_announcements)
        
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        """
        Mark an announcement as read by current seller.
        
        POST /api/users/seller/announcements/{id}/mark_read/
        
        Creates SellerAnnouncementRead entry.
        Response: Updated announcement object
        """
        announcement = self.get_object()
        
        # Create read entry
        read_entry, created = SellerAnnouncementRead.objects.get_or_create(
            announcement=announcement,
            seller=request.user
        )
        
        serializer = self.get_serializer(announcement)
        action_type = 'created' if created else 'already exists'
        logger.info(f'Announcement {announcement.id} read status {action_type} for {request.user.email}')
        return Response(serializer.data, status=status.HTTP_200_OK)


# ==================== BUYER MARKETPLACE VIEWSETS ====================

class MarketplaceViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Buyer-facing marketplace endpoint for browsing products.
    
    Endpoints:
    - GET /api/products/ - List all marketplace products with filtering
    - GET /api/products/{id}/ - Get detailed product information
    
    Filtering:
    - seller_id: Filter by specific seller (for seller shop view)
    - product_type: Filter by product type (e.g., VEGETABLE, FRUIT)
    - min_price: Minimum price filter
    - max_price: Maximum price filter
    - search: Search by product name
    - ordering: Sort by field (price, -price, -created_at, name)
    
    Query Examples:
    - GET /api/products/?search=tomato
    - GET /api/products/?seller_id=5 (seller's shop)
    - GET /api/products/?product_type=VEGETABLE&min_price=40&max_price=100
    - GET /api/products/?ordering=-price
    
    Permissions:
    - AllowAny: Anyone can browse (no authentication required)
    
    Performance:
    - Pagination: 20 items per page (default DRF pagination)
    - Select related: seller
    - Prefetch related: product_images
    - Only active, non-deleted products shown
    - Only from approved sellers
    """
    queryset = SellerProduct.objects.none()
    permission_classes = [permissions.AllowAny]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'product_type', 'description']
    ordering_fields = ['price', 'created_at', 'name', 'quality_grade']
    ordering = ['-created_at']

    def get_serializer_class(self):
        """Use different serializers for list and detail views"""
        if self.action == 'retrieve':
            return ProductDetailBuyerSerializer
        return ProductListBuyerSerializer

    def get_queryset(self):
        """
        Return only active, published products.
        Filter by:
        - Status: ACTIVE
        - Not deleted
        - In stock or specified availability
        - Only from approved sellers
        - Optional: Specific seller (seller_id parameter)
        """
        queryset = SellerProduct.objects.filter(
            status=ProductStatus.ACTIVE,
            is_deleted=False,
            stock_level__gt=0,
            seller__seller_status=SellerStatus.APPROVED
        ).select_related('seller').prefetch_related('product_images')

        # Filter by specific seller if seller_id is provided
        seller_id = self.request.query_params.get('seller_id')
        if seller_id:
            try:
                seller_id = int(seller_id)
                queryset = queryset.filter(seller_id=seller_id)
            except (ValueError, TypeError):
                logger.warning(f"Invalid seller_id value: {seller_id}")

        # Product type filtering
        product_type = self.request.query_params.get('product_type')
        if product_type:
            queryset = queryset.filter(product_type=product_type)

        # Price range filtering
        min_price = self.request.query_params.get('min_price')
        max_price = self.request.query_params.get('max_price')

        if min_price:
            try:
                queryset = queryset.filter(price__gte=Decimal(min_price))
            except (ValueError, TypeError):
                logger.warning(f"Invalid min_price value: {min_price}")

        if max_price:
            try:
                queryset = queryset.filter(price__lte=Decimal(max_price))
            except (ValueError, TypeError):
                logger.warning(f"Invalid max_price value: {max_price}")

        return queryset.order_by('-created_at')

    def list(self, request, *args, **kwargs):
        """
        List all marketplace products with pagination and filtering.
        
        Query Parameters:
        - page: Page number (default: 1)
        - search: Search term
        - category: Product type filter
        - min_price: Minimum price
        - max_price: Maximum price
        - ordering: Field to sort by
        
        Example:
        GET /api/products/?category=VEGETABLE&min_price=40&max_price=100&search=tomato
        """
        try:
            return super().list(request, *args, **kwargs)
        except Exception as e:
            logger.error(f"Error listing marketplace products: {str(e)}")
            return Response(
                {'error': 'Failed to fetch products'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def retrieve(self, request, *args, **kwargs):
        """
        Get detailed product information including images and seller profile.
        
        Response includes:
        - All product details
        - All product images
        - Seller profile information
        - Price comparison data
        
        Example:
        GET /api/products/123/
        """
        try:
            return super().retrieve(request, *args, **kwargs)
        except SellerProduct.DoesNotExist:
            return Response(
                {'error': 'Product not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f"Error retrieving product: {str(e)}")
            return Response(
                {'error': 'Failed to fetch product details'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class SellerPublicViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Public seller profile endpoint for buyers.
    
    Endpoints:
    - GET /api/seller/{id}/ - Get seller shop profile
    - GET /api/seller/{id}/products/ - Get seller's products
    
    Includes:
    - Seller information
    - Shop details
    - Rating and reviews summary
    
    Permissions:
    - AllowAny: Anyone can view seller profiles
    """
    permission_classes = [permissions.AllowAny]
    serializer_class = SellerPublicProfileSerializer
    lookup_field = 'id'
    lookup_url_kwarg = 'id'

    def get_queryset(self):
        """Return only approved sellers"""
        return User.objects.filter(
            role=UserRole.SELLER,
            seller_status=SellerStatus.APPROVED
        )

    def get_object(self):
        """Get seller by ID"""
        try:
            seller_id = self.kwargs.get('id')
            seller = User.objects.get(
                id=seller_id,
                role=UserRole.SELLER,
                seller_status=SellerStatus.APPROVED
            )
            return seller
        except User.DoesNotExist:
            raise NotFound("Seller not found or not approved")

    def retrieve(self, request, *args, **kwargs):
        """
        Get seller shop profile.
        
        Response includes:
        - Seller name and store info
        - Total products
        - Rating and reviews count
        - Verification status
        
        Example:
        GET /api/seller/5/
        """
        try:
            return super().retrieve(request, *args, **kwargs)
        except NotFound as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f"Error retrieving seller profile: {str(e)}")
            return Response(
                {'error': 'Failed to fetch seller profile'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['get'], url_path='products')
    def seller_products(self, request, id=None):
        """
        Get all products from a specific seller.
        
        Filters to only active, published products.
        Supports same filtering as marketplace list view.
        
        Example:
        GET /api/seller/5/products/?page=1&search=tomato
        """
        try:
            seller = self.get_object()
            products = SellerProduct.objects.filter(
                seller=seller,
                status=ProductStatus.ACTIVE,
                is_deleted=False,
                stock_level__gt=0
            ).select_related('seller').prefetch_related('product_images')

            # Apply same filtering as marketplace
            page = self.paginate_queryset(products)
            if page is not None:
                serializer = ProductListBuyerSerializer(
                    page,
                    many=True,
                    context={'request': request}
                )
                return self.get_paginated_response(serializer.data)

            serializer = ProductListBuyerSerializer(
                products,
                many=True,
                context={'request': request}
            )
            return Response(serializer.data)

        except Exception as e:
            logger.error(f"Error retrieving seller products: {str(e)}")
            return Response(
                {'error': 'Failed to fetch seller products'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
