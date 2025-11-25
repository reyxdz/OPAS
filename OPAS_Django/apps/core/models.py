"""
Core app models for OPAS
"""

from django.db import models


class NotificationPreferences(models.Model):
    """User notification preferences"""
    
    CHANNEL_CHOICES = [
        ('EMAIL', 'Email'),
        ('SMS', 'SMS'),
        ('PUSH', 'Push Notification'),
        ('IN_APP', 'In-App Only'),
    ]
    
    user = models.OneToOneField(
        'users.User',
        on_delete=models.CASCADE,
        related_name='notification_preferences'
    )
    
    # Registration events
    registration_submitted = models.BooleanField(default=True)
    registration_approved = models.BooleanField(default=True)
    registration_rejected = models.BooleanField(default=True)
    info_requested = models.BooleanField(default=True)
    deadline_approaching = models.BooleanField(default=True)
    
    # Channel preferences
    preferred_channel = models.CharField(
        max_length=20,
        choices=CHANNEL_CHOICES,
        default='EMAIL'
    )
    
    # Digest settings
    receive_digest = models.BooleanField(default=False)
    digest_frequency = models.CharField(
        max_length=20,
        choices=[('DAILY', 'Daily'), ('WEEKLY', 'Weekly')],
        default='DAILY'
    )
    
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'core_notification_preferences'
        verbose_name = 'Notification Preference'
        app_label = 'core'


class NotificationLog(models.Model):
    """Track all sent notifications"""
    
    STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('SENT', 'Sent'),
        ('FAILED', 'Failed'),
        ('BOUNCED', 'Bounced'),
    ]
    
    user = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        related_name='notification_logs'
    )
    
    notification_type = models.CharField(max_length=50)
    channel = models.CharField(max_length=20)
    recipient = models.CharField(max_length=255)
    subject = models.CharField(max_length=255, blank=True)
    message = models.TextField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')
    
    sent_at = models.DateTimeField(null=True, blank=True)
    error_message = models.TextField(blank=True)
    retry_count = models.IntegerField(default=0)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'core_notification_log'
        ordering = ['-created_at']
        app_label = 'core'
        indexes = [
            models.Index(fields=['user', '-created_at']),
            models.Index(fields=['status', 'created_at']),
        ]
