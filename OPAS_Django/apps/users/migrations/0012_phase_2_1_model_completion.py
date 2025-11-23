# Generated migration for Phase 2.1: Model Review & Completion
# Adds missing fields and immutability to critical models

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0011_admin_models_enhancements'),
    ]

    operations = [
        # Add rejection_reason to SellerRegistrationRequest
        migrations.AddField(
            model_name='sellerregistrationrequest',
            name='rejection_reason',
            field=models.TextField(blank=True, help_text='Reason for rejection (if rejected)', null=True),
        ),
        
        # Add target_id to AdminAuditLog for generic resource tracking
        migrations.AddField(
            model_name='adminauditlog',
            name='target_id',
            field=models.CharField(blank=True, help_text='Generic target ID for the affected resource (flexible for any model)', max_length=255, null=True),
        ),
    ]
