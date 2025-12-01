from rest_framework import serializers
from apps.users.models import User

class SignUpSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ('id', 'username', 'first_name', 'last_name', 'password', 'phone_number', 'address', 
                  'municipality', 'barangay', 'role')
        extra_kwargs = {
            'password': {'write_only': True},
            'username': {'required': False, 'allow_blank': True},
        }

    def create(self, validated_data):
        password = validated_data.pop('password')
        # Auto-generate username from phone_number if not provided
        if not validated_data.get('username'):
            phone_number = validated_data.get('phone_number', '')
            # Use phone number without +63 prefix as username
            validated_data['username'] = phone_number.replace('+', '').replace(' ', '')
        # Set email to be the same as phone_number for compatibility
        validated_data['email'] = validated_data.get('phone_number', '')
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user

class LoginSerializer(serializers.Serializer):
    phone_number = serializers.CharField()
    password = serializers.CharField()

class UpgradeToSellerSerializer(serializers.Serializer):
    store_name = serializers.CharField(max_length=255)
    store_description = serializers.CharField(required=False, allow_blank=True)
    farm_municipality = serializers.CharField(max_length=50, required=False, allow_blank=True)
    farm_barangay = serializers.CharField(max_length=100, required=False, allow_blank=True)

    def update(self, instance, validated_data):
        instance.role = 'SELLER'
        instance.store_name = validated_data.get('store_name', instance.store_name)
        instance.store_description = validated_data.get('store_description', instance.store_description)
        instance.farm_municipality = validated_data.get('farm_municipality', instance.farm_municipality)
        instance.farm_barangay = validated_data.get('farm_barangay', instance.farm_barangay)
        instance.save()
        return instance


class LoginSerializer(serializers.Serializer):
    phone_number = serializers.CharField()
    password = serializers.CharField()

class UpgradeToSellerSerializer(serializers.Serializer):
    store_name = serializers.CharField(max_length=255)
    store_description = serializers.CharField(required=False, allow_blank=True)
    farm_municipality = serializers.CharField(max_length=50, required=False, allow_blank=True)
    farm_barangay = serializers.CharField(max_length=100, required=False, allow_blank=True)

    def update(self, instance, validated_data):
        instance.role = 'SELLER'
        instance.store_name = validated_data.get('store_name', instance.store_name)
        instance.store_description = validated_data.get('store_description', instance.store_description)
        instance.farm_municipality = validated_data.get('farm_municipality', instance.farm_municipality)
        instance.farm_barangay = validated_data.get('farm_barangay', instance.farm_barangay)
        instance.save()
        return instance
