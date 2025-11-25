"""
Admin Views for OPAS Platform
Handles all admin panel operations including dashboard, user management,
price regulation, inventory, and announcements.

Includes 7 ViewSets and 1 Permission Class
"""

from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, BasePermission
from django.utils import timezone
from django.db.models import Q, Count
import logging

from .models import User, UserRole, SellerStatus, SellerApplication
from .admin_models import SellerRegistrationRequest, SellerRegistrationStatus
from .admin_serializers import (
    SellerListSerializer,
    ApproveSellerSerializer,
    SuspendUserSerializer,
    UserManagementSerializer,
    AnnouncementSerializer,
    DashboardStatsSerializer,
    SellerApplicationDetailSerializer,
)
from .seller_serializers import SellerRegistrationRequestSerializer

logger = logging.getLogger(__name__)


# ==================== PERMISSION CLASSES ====================

class IsOPASAdmin(BasePermission):
    """
    Permission to check if user is OPAS Admin or System Admin.
    Restricts access to admin endpoints to only authenticated admin users.
    """
    message = 'You do not have permission to access admin endpoints.'

    def has_permission(self, request, view):
        """Check if user is authenticated and has admin role"""
        if not request.user.is_authenticated:
            return False
        
        is_admin = request.user.role == UserRole.ADMIN
        
        if is_admin:
            logger.info(f'Admin access granted to: {request.user.email}')
        else:
            logger.warning(f'Unauthorized admin access attempt by: {request.user.email}')
        
        return is_admin


# ==================== DASHBOARD VIEWSET ====================

class AdminDashboardView(viewsets.ViewSet):
    """
    Admin dashboard with platform statistics and metrics.
    
    Endpoints:
    - GET /api/users/admin/dashboard/stats/ - Get dashboard statistics
    """
    permission_classes = [IsAuthenticated, IsOPASAdmin]

    @action(detail=False, methods=['get'])
    def stats(self, request):
        """
        Get comprehensive dashboard statistics.
        
        Returns:
            - total_users: Total number of registered users
            - active_sellers: Number of approved sellers
            - pending_approvals: Number of pending seller approvals
            - total_listings: Total product listings (to be implemented)
            - suspended_users: Number of suspended accounts
            - price_violations: Number of price violations (to be implemented)
        """
        try:
            # Get all statistics
            total_users = User.objects.count()
            active_sellers = User.objects.filter(
                role=UserRole.SELLER,
                seller_status=SellerStatus.APPROVED
            ).count()
            pending_approvals = User.objects.filter(
                seller_status=SellerStatus.PENDING
            ).count()
            suspended_users = User.objects.filter(
                seller_status=SellerStatus.SUSPENDED
            ).count()
            
            stats_data = {
                'total_users': total_users,
                'active_sellers': active_sellers,
                'pending_approvals': pending_approvals,
                'total_listings': 0,  # To be implemented with products model
                'suspended_users': suspended_users,
                'price_violations': 0,  # To be implemented with price monitoring
                'new_users_this_month': User.objects.filter(
                    created_at__year=timezone.now().year,
                    created_at__month=timezone.now().month
                ).count(),
                'active_orders_today': 0,  # To be implemented with orders model
            }
            
            serializer = DashboardStatsSerializer(stats_data)
            logger.info(f'Dashboard stats retrieved by: {request.user.email}')
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving dashboard stats: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve dashboard statistics'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# ==================== SELLER MANAGEMENT VIEWSET ====================

class SellerManagementViewSet(viewsets.ViewSet):
    """
    Manage seller registrations, approvals, and documents.
    
    Endpoints:
    - GET /api/users/admin/sellers/pending_approvals/ - List pending approvals
    - GET /api/users/admin/sellers/list_sellers/ - List all sellers
    - POST /api/users/admin/sellers/{id}/approve/ - Approve seller
    - POST /api/users/admin/sellers/{id}/suspend/ - Suspend seller
    - POST /api/users/admin/sellers/{id}/verify_documents/ - Verify documents
    """
    permission_classes = [IsAuthenticated, IsOPASAdmin]

    @action(detail=False, methods=['get'])
    def pending_approvals(self, request):
        """Get all sellers pending approval (from SellerRegistrationRequest model)"""
        try:
            applications = SellerRegistrationRequest.objects.filter(
                status=SellerRegistrationStatus.PENDING
            ).select_related('seller').order_by('-submitted_at')
            
            serializer = SellerRegistrationRequestSerializer(applications, many=True)
            logger.info(f'Retrieved {applications.count()} pending applications for: {request.user.email}')
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving pending applications: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve pending approvals'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'], name='applications')
    def pending_applications(self, request):
        """Get all pending seller applications (from SellerRegistrationRequest model)"""
        try:
            applications = SellerRegistrationRequest.objects.filter(
                status=SellerRegistrationStatus.PENDING
            ).select_related('seller').order_by('-submitted_at')
            
            serializer = SellerRegistrationRequestSerializer(applications, many=True)
            logger.info(f'Retrieved {applications.count()} pending applications for: {request.user.email}')
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving pending applications: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve pending applications'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'], name='approve-application')
    def approve_application(self, request, pk=None):
        """Approve a seller application"""
        try:
            application = SellerApplication.objects.get(id=pk)
            
            if application.status != 'PENDING':
                return Response(
                    {'message': f'Application is already {application.status}'},
                    status=status.HTTP_200_OK
                )
            
            # Approve application
            application.approve(admin_user=request.user)
            
            serializer = SellerApplicationDetailSerializer(application)
            logger.info(f'Application {pk} approved by: {request.user.email}')
            
            return Response(
                {
                    'message': f'Application for {application.user.email} approved successfully',
                    'application': serializer.data,
                },
                status=status.HTTP_200_OK
            )
        
        except SellerApplication.DoesNotExist:
            logger.warning(f'Application with ID {pk} not found')
            return Response(
                {'error': 'Application not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f'Error approving application: {str(e)}')
            return Response(
                {'error': f'Failed to approve application: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'], name='reject-application')
    def reject_application(self, request, pk=None):
        """Reject a seller application"""
        try:
            logger.info(f'Attempting to reject application with id: {pk}')
            application = SellerApplication.objects.get(id=pk)
            logger.info(f'Found application: {application.id}, status: {application.status}')
            
            if application.status != 'PENDING':
                return Response(
                    {'message': f'Application is already {application.status}'},
                    status=status.HTTP_200_OK
                )
            
            reason = request.data.get('reason', '')
            logger.info(f'Rejecting application with reason: {reason}')
            
            # Reject application
            application.reject(admin_user=request.user, reason=reason)
            logger.info(f'Application {pk} rejected successfully')
            
            serializer = SellerApplicationDetailSerializer(application)
            logger.info(f'Application {pk} rejected by: {request.user.email}')
            
            return Response(
                {
                    'message': f'Application for {application.user.email} rejected',
                    'application': serializer.data,
                },
                status=status.HTTP_200_OK
            )
        
        except SellerApplication.DoesNotExist:
            logger.warning(f'Application with ID {pk} not found')
            return Response(
                {'error': 'Application not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f'Error rejecting application: {str(e)}', exc_info=True)
            return Response(
                {'error': f'Failed to reject application: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def list_sellers(self, request):
        """Get all sellers with optional status filtering"""
        try:
            status_filter = request.query_params.get('status')
            sellers = User.objects.filter(role=UserRole.SELLER)
            
            if status_filter:
                sellers = sellers.filter(seller_status=status_filter)
            
            sellers = sellers.order_by('-created_at')
            serializer = SellerListSerializer(sellers, many=True)
            
            logger.info(f'Retrieved {sellers.count()} sellers for: {request.user.email}')
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving sellers: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve sellers list'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        """Approve a pending seller registration"""
        try:
            seller = User.objects.get(id=pk, role=UserRole.SELLER)
            
            if seller.seller_status == SellerStatus.APPROVED:
                return Response(
                    {'message': 'Seller is already approved'},
                    status=status.HTTP_200_OK
                )
            
            # Approve seller
            seller.seller_status = SellerStatus.APPROVED
            seller.is_seller_approved = True
            seller.seller_approval_date = timezone.now()
            seller.save()
            
            serializer = SellerListSerializer(seller)
            logger.info(f'Seller {seller.store_name} approved by: {request.user.email}')
            
            return Response(
                {
                    'message': f'Seller {seller.store_name} approved successfully',
                    'seller': serializer.data,
                },
                status=status.HTTP_200_OK
            )
        
        except User.DoesNotExist:
            logger.warning(f'Seller with ID {pk} not found')
            return Response(
                {'error': 'Seller not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f'Error approving seller: {str(e)}')
            return Response(
                {'error': 'Failed to approve seller'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        """Reject a pending seller registration"""
        try:
            seller = User.objects.get(id=pk, role=UserRole.SELLER)
            
            if seller.seller_status == SellerStatus.REJECTED:
                return Response(
                    {'message': 'Seller is already rejected'},
                    status=status.HTTP_200_OK
                )
            
            reason = request.data.get('reason', '')
            
            # Reject seller
            seller.seller_status = SellerStatus.REJECTED
            seller.save()
            
            serializer = SellerListSerializer(seller)
            logger.info(f'Seller {seller.store_name} rejected by: {request.user.email}')
            
            return Response(
                {
                    'message': f'Seller {seller.store_name} rejected successfully',
                    'seller': serializer.data,
                },
                status=status.HTTP_200_OK
            )
        
        except User.DoesNotExist:
            logger.warning(f'Seller with ID {pk} not found')
            return Response(
                {'error': 'Seller not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f'Error rejecting seller: {str(e)}')
            return Response(
                {'error': 'Failed to reject seller'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'])
    def suspend(self, request, pk=None):
        """Suspend a user/seller account"""
        try:
            user = User.objects.get(id=pk)
            serializer = SuspendUserSerializer(
                user,
                data=request.data,
                partial=True
            )
            
            if serializer.is_valid():
                serializer.save()
                logger.info(f'User {user.email} suspended by: {request.user.email}')
                
                return Response(
                    {
                        'message': f'User {user.email} suspended successfully',
                        'user': serializer.data,
                    },
                    status=status.HTTP_200_OK
                )
            
            logger.warning(f'Invalid data for suspending user: {serializer.errors}')
            return Response(
                serializer.errors,
                status=status.HTTP_400_BAD_REQUEST
            )
        
        except User.DoesNotExist:
            logger.warning(f'User with ID {pk} not found')
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f'Error suspending user: {str(e)}')
            return Response(
                {'error': 'Failed to suspend user'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'])
    def verify_documents(self, request, pk=None):
        """Mark seller documents as verified"""
        try:
            seller = User.objects.get(id=pk, role=UserRole.SELLER)
            
            if seller.seller_documents_verified:
                return Response(
                    {'message': 'Documents are already verified'},
                    status=status.HTTP_200_OK
                )
            
            seller.seller_documents_verified = True
            seller.save()
            
            serializer = SellerListSerializer(seller)
            logger.info(f'Documents verified for seller {seller.store_name} by: {request.user.email}')
            
            return Response(
                {
                    'message': 'Documents verified successfully',
                    'seller': serializer.data,
                },
                status=status.HTTP_200_OK
            )
        
        except User.DoesNotExist:
            logger.warning(f'Seller with ID {pk} not found')
            return Response(
                {'error': 'Seller not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f'Error verifying documents: {str(e)}')
            return Response(
                {'error': 'Failed to verify documents'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# ==================== USER MANAGEMENT VIEWSET ====================

class UserManagementViewSet(viewsets.ViewSet):
    """
    Manage all users on the platform with statistics and filtering.
    
    Endpoints:
    - GET /api/users/admin/users/list_users/ - List all users (with role filter)
    - GET /api/users/admin/users/statistics/ - Get user statistics
    """
    permission_classes = [IsAuthenticated, IsOPASAdmin]

    @action(detail=False, methods=['get'])
    def list_users(self, request):
        """Get all users with optional role filtering"""
        try:
            role_filter = request.query_params.get('role')
            users = User.objects.all()
            
            if role_filter:
                users = users.filter(role=role_filter)
            
            users = users.order_by('-created_at')
            serializer = UserManagementSerializer(users, many=True)
            
            logger.info(f'Retrieved {users.count()} users for: {request.user.email}')
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving users: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve users'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def statistics(self, request):
        """Get detailed user statistics breakdown"""
        try:
            total_users = User.objects.count()
            buyers = User.objects.filter(role=UserRole.BUYER).count()
            sellers = User.objects.filter(role=UserRole.SELLER).count()
            admins = User.objects.filter(
                role=UserRole.ADMIN
            ).count()
            approved_sellers = User.objects.filter(
                seller_status=SellerStatus.APPROVED
            ).count()
            suspended_users = User.objects.filter(
                seller_status=SellerStatus.SUSPENDED
            ).count()
            
            stats = {
                'total_users': total_users,
                'buyers': buyers,
                'sellers': sellers,
                'admins': admins,
                'approved_sellers': approved_sellers,
                'suspended_users': suspended_users,
            }
            
            logger.info(f'User statistics retrieved by: {request.user.email}')
            return Response(stats, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving user statistics: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve user statistics'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# ==================== PRICE REGULATION VIEWSET ====================

class PriceRegulationViewSet(viewsets.ViewSet):
    """
    Manage price ceilings and market price regulation.
    
    Endpoints:
    - POST /api/users/admin/pricing/set_ceiling_price/ - Set product ceiling price
    - POST /api/users/admin/pricing/post_advisory/ - Post price advisory
    - GET /api/users/admin/pricing/violations/ - Get price violations
    """
    permission_classes = [IsAuthenticated, IsOPASAdmin]

    @action(detail=False, methods=['post'])
    def set_ceiling_price(self, request):
        """Set ceiling price for a product"""
        try:
            product_name = request.data.get('product_name')
            ceiling_price = request.data.get('ceiling_price')
            unit = request.data.get('unit')
            
            if not all([product_name, ceiling_price, unit]):
                return Response(
                    {'error': 'Missing required fields: product_name, ceiling_price, unit'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            if float(ceiling_price) <= 0:
                return Response(
                    {'error': 'Ceiling price must be greater than 0'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Store in cache or database (to be implemented with products model)
            logger.info(f'Ceiling price set for {product_name}: {ceiling_price}/{unit} by: {request.user.email}')
            
            return Response(
                {
                    'message': 'Ceiling price set successfully',
                    'product': product_name,
                    'ceiling_price': ceiling_price,
                    'unit': unit,
                    'effective_date': timezone.now(),
                },
                status=status.HTTP_201_CREATED
            )
        
        except ValueError:
            return Response(
                {'error': 'Invalid ceiling price format'},
                status=status.HTTP_400_BAD_REQUEST
            )
        except Exception as e:
            logger.error(f'Error setting ceiling price: {str(e)}')
            return Response(
                {'error': 'Failed to set ceiling price'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['post'])
    def post_advisory(self, request):
        """Post price advisory to all users"""
        try:
            title = request.data.get('title')
            message = request.data.get('message')
            severity = request.data.get('severity', 'INFO')
            
            if not all([title, message]):
                return Response(
                    {'error': 'Missing required fields: title, message'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Send notification to all users (to be implemented)
            logger.info(f'Price advisory posted by: {request.user.email}')
            
            return Response(
                {
                    'message': 'Advisory posted successfully',
                    'title': title,
                    'severity': severity,
                    'timestamp': timezone.now(),
                },
                status=status.HTTP_201_CREATED
            )
        
        except Exception as e:
            logger.error(f'Error posting advisory: {str(e)}')
            return Response(
                {'error': 'Failed to post advisory'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def violations(self, request):
        """Get list of price violations"""
        try:
            # To be implemented with actual price monitoring
            violations = {
                'violations': [],
                'total_violations': 0,
            }
            
            logger.info(f'Price violations retrieved by: {request.user.email}')
            return Response(violations, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving violations: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve price violations'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# ==================== INVENTORY MANAGEMENT VIEWSET ====================

class InventoryManagementViewSet(viewsets.ViewSet):
    """
    Manage OPAS inventory stock and purchases.
    
    Endpoints:
    - GET /api/users/admin/inventory/current_stock/ - Get current stock
    - GET /api/users/admin/inventory/low_stock/ - Get low stock items
    - POST /api/users/admin/inventory/accept_sell_to_opas/ - Accept sell request
    """
    permission_classes = [IsAuthenticated, IsOPASAdmin]

    @action(detail=False, methods=['get'])
    def current_stock(self, request):
        """Get current inventory stock"""
        try:
            # To be implemented with actual inventory model
            inventory = {
                'items': [],
                'total_items': 0,
                'total_value': 0,
            }
            
            logger.info(f'Current inventory retrieved by: {request.user.email}')
            return Response(inventory, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving current stock: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve current stock'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def low_stock(self, request):
        """Get items with low stock levels"""
        try:
            threshold = request.query_params.get('threshold', 10)
            # To be implemented with actual inventory model
            low_stock = {
                'low_stock_items': [],
                'total_low_items': 0,
            }
            
            logger.info(f'Low stock items retrieved by: {request.user.email}')
            return Response(low_stock, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving low stock: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve low stock items'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['post'])
    def accept_sell_to_opas(self, request):
        """Accept a 'Sell to OPAS' request"""
        try:
            submission_id = request.data.get('submission_id')
            quantity = request.data.get('quantity')
            price_per_unit = request.data.get('price_per_unit')
            
            if not all([submission_id, quantity, price_per_unit]):
                return Response(
                    {'error': 'Missing required fields: submission_id, quantity, price_per_unit'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Process the request (to be implemented)
            logger.info(f'Sell-to-OPAS submission {submission_id} accepted by: {request.user.email}')
            
            return Response(
                {
                    'message': 'Submission accepted successfully',
                    'submission_id': submission_id,
                    'quantity': quantity,
                    'price_per_unit': price_per_unit,
                },
                status=status.HTTP_200_OK
            )
        
        except ValueError:
            return Response(
                {'error': 'Invalid quantity or price format'},
                status=status.HTTP_400_BAD_REQUEST
            )
        except Exception as e:
            logger.error(f'Error accepting sell-to-OPAS: {str(e)}')
            return Response(
                {'error': 'Failed to accept submission'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# ==================== ANNOUNCEMENT VIEWSET ====================

class AnnouncementViewSet(viewsets.ViewSet):
    """
    Manage platform announcements and notifications.
    
    Endpoints:
    - POST /api/users/admin/announcements/create_announcement/ - Create announcement
    - GET /api/users/admin/announcements/list_announcements/ - List announcements
    """
    permission_classes = [IsAuthenticated, IsOPASAdmin]

    @action(detail=False, methods=['post'])
    def create_announcement(self, request):
        """Create and send an announcement"""
        try:
            title = request.data.get('title')
            message = request.data.get('message')
            announcement_type = request.data.get('type', 'GENERAL')
            sent_to = request.data.get('sent_to', 'ALL')
            
            if not all([title, message]):
                return Response(
                    {'error': 'Title and message are required'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Create announcement (to be implemented with model)
            announcement_data = {
                'id': 1,
                'title': title,
                'message': message,
                'type': announcement_type,
                'sent_to': sent_to,
                'created_at': timezone.now(),
                'created_by': request.user.email,
            }
            
            logger.info(f'Announcement created by: {request.user.email} - Type: {announcement_type}, Sent to: {sent_to}')
            
            return Response(
                {
                    'message': 'Announcement sent successfully',
                    'announcement': announcement_data,
                },
                status=status.HTTP_201_CREATED
            )
        
        except Exception as e:
            logger.error(f'Error creating announcement: {str(e)}')
            return Response(
                {'error': 'Failed to create announcement'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def list_announcements(self, request):
        """Get recent announcements"""
        try:
            limit = request.query_params.get('limit', 10)
            # To be implemented with actual announcements model
            announcements = {
                'announcements': [],
                'total_announcements': 0,
            }
            
            logger.info(f'Announcements list retrieved by: {request.user.email}')
            return Response(announcements, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f'Error retrieving announcements: {str(e)}')
            return Response(
                {'error': 'Failed to retrieve announcements'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    """Admin dashboard with statistics."""
    permission_classes = [IsAuthenticated, IsOPASAdmin]
    
    @action(detail=False, methods=['get'])
    def stats(self, request):
        """Get dashboard statistics."""
        total_users = User.objects.count()
        active_sellers = User.objects.filter(
            role=UserRole.SELLER,
            is_seller_approved=True
        ).count()
        pending_approvals = User.objects.filter(
            seller_status=SellerStatus.PENDING
        ).count()
        suspended_users = User.objects.filter(
            seller_status=SellerStatus.SUSPENDED
        ).count()
        
        stats_data = {
            'total_users': total_users,
            'active_sellers': active_sellers,
            'pending_approvals': pending_approvals,
            'total_listings': 0,  # To be implemented with products
            'suspended_users': suspended_users,
            'price_violations': 0,  # To be implemented with price monitoring
        }
        
        serializer = DashboardStatsSerializer(stats_data)
        return Response(serializer.data, status=status.HTTP_200_OK)
