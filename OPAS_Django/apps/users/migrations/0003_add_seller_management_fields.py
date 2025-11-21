"""
Migration 0003: Add Seller Management Fields

This migration adds seller management and approval workflow fields to the User model.
These fields are essential for the OPAS Admin Panel to manage seller registrations,
approvals, and account suspensions.

Fields Added:
- seller_status: Enum field with choices (PENDING, APPROVED, SUSPENDED, REJECTED)
- seller_approval_date: DateTime for when seller was approved
- seller_documents_verified: Boolean flag for document verification
- suspension_reason: Text field for suspension reasons
- suspended_at: DateTime for when account was suspended

Status: Ready for production use
"""

from django.db import migrations, models


class Migration(migrations.Migration):
    """
    Adds seller management and approval workflow fields to User model.
    Supports role-based admin operations for seller registration and account management.
    """

    dependencies = [
        ('users', '0002_user_is_seller_approved_user_store_description_and_more'),
    ]

    operations = [
        # Seller Status Enum Field
        migrations.AddField(
            model_name='user',
            name='seller_status',
            field=models.CharField(
                blank=True,
                choices=[
                    ('PENDING', 'Pending Approval'),
                    ('APPROVED', 'Approved'),
                    ('SUSPENDED', 'Suspended'),
                    ('REJECTED', 'Rejected'),
                ],
                default='PENDING',
                help_text='Current approval status of seller account',
                max_length=20,
                null=True,
            ),
        ),
        
        # Seller Approval Date
        migrations.AddField(
            model_name='user',
            name='seller_approval_date',
            field=models.DateTimeField(
                blank=True,
                null=True,
                help_text='Date when seller was approved by admin'
            ),
        ),
        
        # Document Verification Flag
        migrations.AddField(
            model_name='user',
            name='seller_documents_verified',
            field=models.BooleanField(
                default=False,
                help_text='Whether seller documents have been verified'
            ),
        ),
        
        # Suspension Reason
        migrations.AddField(
            model_name='user',
            name='suspension_reason',
            field=models.TextField(
                blank=True,
                null=True,
                help_text='Reason for account suspension'
            ),
        ),
        
        # Suspension DateTime
        migrations.AddField(
            model_name='user',
            name='suspended_at',
            field=models.DateTimeField(
                blank=True,
                null=True,
                help_text='Date when account was suspended'
            ),
        ),
        
        # Add database index on seller_status for query performance
        migrations.AddIndex(
            model_name='user',
            index=models.Index(fields=['seller_status'], name='seller_status_idx'),
        ),
    ]
