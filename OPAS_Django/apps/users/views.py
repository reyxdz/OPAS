from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from apps.authentication.serializers import UpgradeToSellerSerializer
from apps.users.models import User, SellerApplication
from apps.users.admin_serializers import SellerApplicationSerializer

class UpgradeToSellerView(APIView):
    permission_classes = [AllowAny]  # Temporarily allow all to test

    def post(self, request):
        print(f"DEBUG: Request reached the view!")
        print(f"DEBUG: Request user: {request.user}")
        print(f"DEBUG: Is authenticated: {request.user.is_authenticated}")
        print(f"DEBUG: Request auth: {request.auth}")
        print(f"DEBUG: Auth header: {request.META.get('HTTP_AUTHORIZATION', 'NO AUTH HEADER')}")
        
        # Check if user is authenticated
        if not request.user or not request.user.is_authenticated:
            print("DEBUG: User is not authenticated!")
            return Response({'error': 'User not authenticated'}, status=status.HTTP_401_UNAUTHORIZED)
        
        serializer = UpgradeToSellerSerializer(data=request.data)
        if not serializer.is_valid():
            print(f"DEBUG: Serializer errors: {serializer.errors}")
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        # Update the user with seller information
        user = request.user
        user = serializer.update(user, serializer.validated_data)

        return Response({
            'message': 'Successfully upgraded to seller',
            'role': user.role,
            'store_name': user.store_name,
            'store_description': user.store_description,
        }, status=status.HTTP_200_OK)


class SellerApplicationView(APIView):
    """
    Handle seller applications from buyers.
    
    POST /api/users/seller-application/
    - Accept: farm_name, farm_location, store_name, store_description
    - Response: Application created with status PENDING
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        """Submit a new seller application or update a rejected one"""
        print(f"DEBUG: Seller application request from {request.user.email}")
        
        # Validate input
        serializer = SellerApplicationSerializer(data=request.data)
        if not serializer.is_valid():
            print(f"DEBUG: Validation errors: {serializer.errors}")
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if user already has an application
        existing_app = SellerApplication.objects.filter(user=request.user).first()
        
        if existing_app:
            if existing_app.status == 'PENDING':
                return Response(
                    {'error': 'You already have a pending application. Please wait for admin review.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            elif existing_app.status == 'APPROVED':
                return Response(
                    {'error': 'Your application has already been approved. You are now a seller!'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            elif existing_app.status == 'REJECTED':
                # Allow resubmission of rejected application
                print(f"DEBUG: Updating rejected application {existing_app.id}")
                existing_app.farm_name = serializer.validated_data['farm_name']
                existing_app.farm_location = serializer.validated_data['farm_location']
                existing_app.store_name = serializer.validated_data['store_name']
                existing_app.store_description = serializer.validated_data['store_description']
                existing_app.status = 'PENDING'
                existing_app.reviewed_at = None
                existing_app.reviewed_by = None
                existing_app.rejection_reason = None
                existing_app.save()
                
                # Update user seller_status to PENDING
                request.user.seller_status = 'PENDING'
                request.user.save()
                
                print(f"DEBUG: Application {existing_app.id} resubmitted successfully")
                
                return Response({
                    'application_id': existing_app.id,
                    'status': 'PENDING',
                    'message': 'Your application has been resubmitted. Please wait for admin review.',
                    'farm_name': existing_app.farm_name,
                    'farm_location': existing_app.farm_location,
                    'store_name': existing_app.store_name,
                }, status=status.HTTP_201_CREATED)
        
        # Create new application
        try:
            application = SellerApplication.objects.create(
                user=request.user,
                farm_name=serializer.validated_data['farm_name'],
                farm_location=serializer.validated_data['farm_location'],
                store_name=serializer.validated_data['store_name'],
                store_description=serializer.validated_data['store_description'],
                status='PENDING'
            )
            
            # Update user seller_status to PENDING
            request.user.seller_status = 'PENDING'
            request.user.save()
            
            print(f"DEBUG: Application created with ID {application.id}")
            
            return Response({
                'application_id': application.id,
                'status': 'PENDING',
                'message': 'Application submitted successfully. Please wait for admin review.',
                'farm_name': application.farm_name,
                'farm_location': application.farm_location,
                'store_name': application.store_name,
            }, status=status.HTTP_201_CREATED)
            
        except Exception as e:
            print(f"DEBUG: Error creating application: {str(e)}")
            return Response(
                {'error': f'Failed to submit application: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

