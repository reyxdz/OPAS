from rest_framework import serializers
from apps.users.models import User

class SignUpSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ('id', 'email', 'username', 'first_name', 'last_name', 'password', 'phone_number', 'address', 'role')
        extra_kwargs = {'password': {'write_only': True}}

    def create(self, validated_data):
        password = validated_data.pop('password')
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

    def update(self, instance, validated_data):
        instance.role = 'SELLER'
        instance.store_name = validated_data.get('store_name', instance.store_name)
        instance.store_description = validated_data.get('store_description', instance.store_description)
        instance.save()
        return instance
