from rest_framework import serializers
from apps.users.models import User
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.permissions import AllowAny
from .serializers import SignUpSerializer, LoginSerializer
import logging

logger = logging.getLogger(__name__)

class SignUpView(APIView):
    permission_classes = [AllowAny]
    
    def post(self, request):
        try:
            logger.info(f"SignUp request data: {request.data}")
            serializer = SignUpSerializer(data=request.data)
            if serializer.is_valid():
                logger.info("Serializer is valid, creating user...")
                user = serializer.save()
                logger.info(f"User created: {user.username}")
                
                logger.info("Generating JWT tokens...")
                refresh = RefreshToken.for_user(user)
                logger.info("Tokens generated successfully")
                
                return Response({
                    'refresh': str(refresh),
                    'access': str(refresh.access_token),
                    'user': SignUpSerializer(user).data
                }, status=status.HTTP_201_CREATED)
            
            logger.error(f"Serializer validation failed: {serializer.errors}")
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        except Exception as e:
            logger.exception(f"SignUp exception: {str(e)}")
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class LoginView(APIView):
    permission_classes = [AllowAny]
    
    def post(self, request):
        print("DEBUG login request.data:", request.data)   # <--- add this line
        serializer = LoginSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        phone_number = serializer.validated_data['phone_number']
        password = serializer.validated_data['password']

        try:
            user = User.objects.get(phone_number=phone_number)
        except User.DoesNotExist:
            return Response({'error': 'Invalid credentials'}, status=status.HTTP_401_UNAUTHORIZED)

        if not user.check_password(password):
            return Response({'error': 'Invalid credentials'}, status=status.HTTP_401_UNAUTHORIZED)

        refresh = RefreshToken.for_user(user)
        return Response({
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'phone_number': user.phone_number,
            'email': user.email,
            'first_name': user.first_name,
            'last_name': user.last_name,
            'address': user.address,
            'municipality': user.municipality,
            'barangay': user.barangay,
            'store_name': user.store_name or '',
            'store_description': user.store_description or '',
            'farm_municipality': user.farm_municipality or '',
            'farm_barangay': user.farm_barangay or '',
            'role': user.role,
            'admin_role': user.admin_role if user.role == 'ADMIN' else None,
        }, status=status.HTTP_200_OK)
