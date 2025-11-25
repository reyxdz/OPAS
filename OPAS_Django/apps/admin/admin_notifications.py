"""
CORE PRINCIPLE: Admin notification system
- Priority-based alerts
- Group-based routing
- Bulk summary emails
- Audit trail
"""

from django.db import models
from django.contrib.auth.models import User, Group
from django.utils import timezone
from django.core.mail import EmailMultiAlternatives
from django.template.loader import render_to_string
from celery import shared_task
import logging

logger = logging.getLogger('admin_notifications')


class AdminNotificationPreferences(models.Model):
    """
    CORE PRINCIPLE: Admin notification preferences
    - Control alert severity
    - Choose digest frequency
    - Opt in/out by event type
    """
    
    FREQUENCY_CHOICES = [
        ('IMMEDIATE', 'Immediate'),
        ('DIGEST_DAILY', 'Daily Digest'),
        ('DIGEST_WEEKLY', 'Weekly Digest'),
    ]
    
    admin_user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='admin_notification_prefs'
    )
    
    # Event preferences
    receive_new_registration_alerts = models.BooleanField(
        default=True,
        help_text='Alert on new seller registration submissions'
    )
    
    receive_resubmission_alerts = models.BooleanField(
        default=True,
        help_text='Alert when seller resubmits information'
    )
    
    receive_rejection_confirmations = models.BooleanField(
        default=True,
        help_text='Confirmation when rejection is sent'
    )
    
    receive_approval_confirmations = models.BooleanField(
        default=True,
        help_text='Confirmation when approval is sent'
    )
    
    # Frequency settings
    new_registration_frequency = models.CharField(
        max_length=20,
        choices=FREQUENCY_CHOICES,
        default='IMMEDIATE',
        help_text='How often to receive new registration alerts'
    )
    
    approval_frequency = models.CharField(
        max_length=20,
        choices=FREQUENCY_CHOICES,
        default='DIGEST_DAILY',
        help_text='Approval confirmation frequency'
    )
    
    # Alert level
    minimum_alert_level = models.IntegerField(
        default=1,
        choices=[(1, 'All'), (2, 'Medium'), (3, 'High Priority Only')],
        help_text='Minimum priority level to receive alerts'
    )
    
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'admin_admin_notification_preferences'
    
    def __str__(self):
        return f"Notification Preferences for {self.admin_user.email}"


class AdminNotificationLog(models.Model):
    """
    CORE PRINCIPLE: Track all admin notifications
    - Audit trail
    - Delivery confirmation
    - Performance monitoring
    """
    
    NOTIFICATION_TYPES = [
        ('NEW_REGISTRATION', 'New Registration'),
        ('RESUBMISSION', 'Information Resubmitted'),
        ('BULK_APPROVAL_SUMMARY', 'Bulk Approval Summary'),
        ('BULK_REJECTION_SUMMARY', 'Bulk Rejection Summary'),
        ('DAILY_DIGEST', 'Daily Digest'),
        ('WEEKLY_DIGEST', 'Weekly Digest'),
    ]
    
    STATUS_CHOICES = [
        ('QUEUED', 'Queued'),
        ('SENT', 'Sent'),
        ('FAILED', 'Failed'),
    ]
    
    admin_user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='admin_notification_logs'
    )
    
    notification_type = models.CharField(
        max_length=50,
        choices=NOTIFICATION_TYPES,
        db_index=True
    )
    
    subject = models.CharField(max_length=255)
    
    content = models.TextField()
    
    related_registrations = models.IntegerField(
        default=1,
        help_text='Number of registrations included in this notification'
    )
    
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='QUEUED',
        db_index=True
    )
    
    error_message = models.TextField(blank=True)
    
    sent_at = models.DateTimeField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    
    class Meta:
        db_table = 'admin_admin_notification_log'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['admin_user', '-created_at']),
            models.Index(fields=['notification_type', '-created_at']),
        ]
    
    def __str__(self):
        return f"{self.notification_type} to {self.admin_user.email} - {self.status}"


class AdminNotificationService:
    """
    CORE PRINCIPLE: Centralized admin notification dispatcher
    - Respects admin preferences
    - Priority-based routing
    - Async processing
    """
    
    @staticmethod
    def _get_preferences(admin_user):
        """Get or create admin notification preferences"""
        prefs, _ = AdminNotificationPreferences.objects.get_or_create(
            admin_user=admin_user,
            defaults={
                'receive_new_registration_alerts': True,
                'new_registration_frequency': 'IMMEDIATE',
            }
        )
        return prefs
    
    @staticmethod
    def send_new_registration_alert(registration, request_user=None):
        """
        CORE PRINCIPLE: Alert seller_managers group
        - Immediate notification for new submissions
        - Include summary of what's pending
        """
        try:
            seller_managers = Group.objects.filter(name='seller_managers').first()
            if not seller_managers:
                logger.warning("seller_managers group not found")
                return
            
            for admin_user in seller_managers.user_set.all():
                prefs = AdminNotificationService._get_preferences(admin_user)
                
                if not prefs.receive_new_registration_alerts:
                    continue
                
                if prefs.new_registration_frequency == 'IMMEDIATE':
                    AdminNotificationService._send_new_registration_immediate(
                        admin_user, registration
                    )
                # Digest versions handled by scheduled tasks
        
        except Exception as e:
            logger.error(f"Error sending new registration alert: {str(e)}")
    
    @staticmethod
    def _send_new_registration_immediate(admin_user, registration):
        """Send immediate notification to admin"""
        subject = f"New Seller Registration: {registration.farm_name}"
        
        context = {
            'registration': registration,
            'admin_name': admin_user.first_name or admin_user.email,
            'review_url': f'/admin/registrations/{registration.id}/review/',
            'total_documents': registration.documents.count(),
            'pending_documents': registration.documents.filter(status='PENDING').count(),
        }
        
        # Render email template
        html_message = render_to_string('admin_emails/new_registration_alert.html', context)
        plain_message = render_to_string('admin_emails/new_registration_alert.txt', context)
        
        try:
            email = EmailMultiAlternatives(
                subject=subject,
                body=plain_message,
                from_email='noreply@opas.com',
                to=[admin_user.email]
            )
            email.attach_alternative(html_message, "text/html")
            email.send(fail_silently=False)
            
            # Log success
            AdminNotificationLog.objects.create(
                admin_user=admin_user,
                notification_type='NEW_REGISTRATION',
                subject=subject,
                content=plain_message[:500],
                related_registrations=1,
                status='SENT',
                sent_at=timezone.now()
            )
        except Exception as e:
            logger.error(f"Error sending email to {admin_user.email}: {str(e)}")
            AdminNotificationLog.objects.create(
                admin_user=admin_user,
                notification_type='NEW_REGISTRATION',
                subject=subject,
                content='',
                related_registrations=1,
                status='FAILED',
                error_message=str(e)
            )
    
    @staticmethod
    def send_resubmission_alert(registration):
        """Alert when seller resubmits information"""
        try:
            seller_leads = Group.objects.filter(name='admin_leads').first()
            if not seller_leads:
                return
            
            for admin_user in seller_leads.user_set.all():
                prefs = AdminNotificationService._get_preferences(admin_user)
                
                if not prefs.receive_resubmission_alerts:
                    continue
                
                subject = f"Registration Resubmitted: {registration.farm_name}"
                
                context = {
                    'registration': registration,
                    'admin_name': admin_user.first_name or admin_user.email,
                    'review_url': f'/admin/registrations/{registration.id}/review/',
                }
                
                html_message = render_to_string('admin_emails/resubmission_alert.html', context)
                plain_message = render_to_string('admin_emails/resubmission_alert.txt', context)
                
                email = EmailMultiAlternatives(
                    subject=subject,
                    body=plain_message,
                    from_email='noreply@opas.com',
                    to=[admin_user.email]
                )
                email.attach_alternative(html_message, "text/html")
                email.send(fail_silently=False)
                
                AdminNotificationLog.objects.create(
                    admin_user=admin_user,
                    notification_type='RESUBMISSION',
                    subject=subject,
                    content=plain_message[:500],
                    status='SENT',
                    sent_at=timezone.now()
                )
        
        except Exception as e:
            logger.error(f"Error sending resubmission alert: {str(e)}")
    
    @staticmethod
    def send_approval_confirmation(admin_user, registration):
        """Confirmation that approval was sent to seller"""
        try:
            prefs = AdminNotificationService._get_preferences(admin_user)
            
            if not prefs.receive_approval_confirmations:
                return
            
            subject = f"Approval Sent: {registration.farm_name} → SELLER"
            
            context = {
                'registration': registration,
                'admin_name': admin_user.first_name or admin_user.email,
                'seller_email': registration.seller.email,
                'seller_name': registration.seller.first_name or registration.seller.email,
                'approval_date': timezone.now(),
            }
            
            html_message = render_to_string('admin_emails/approval_confirmation.html', context)
            plain_message = render_to_string('admin_emails/approval_confirmation.txt', context)
            
            email = EmailMultiAlternatives(
                subject=subject,
                body=plain_message,
                from_email='noreply@opas.com',
                to=[admin_user.email]
            )
            email.attach_alternative(html_message, "text/html")
            email.send(fail_silently=False)
            
            AdminNotificationLog.objects.create(
                admin_user=admin_user,
                notification_type='BULK_APPROVAL_SUMMARY',
                subject=subject,
                content=plain_message[:500],
                status='SENT',
                sent_at=timezone.now()
            )
        
        except Exception as e:
            logger.error(f"Error sending approval confirmation: {str(e)}")
    
    @staticmethod
    def send_rejection_confirmation(admin_user, registration, reason):
        """Confirmation that rejection was sent to buyer"""
        try:
            prefs = AdminNotificationService._get_preferences(admin_user)
            
            if not prefs.receive_rejection_confirmations:
                return
            
            subject = f"Rejection Sent: {registration.farm_name} (Farm)"
            
            context = {
                'registration': registration,
                'admin_name': admin_user.first_name or admin_user.email,
                'seller_email': registration.seller.email,
                'rejection_reason': reason,
                'rejection_date': timezone.now(),
            }
            
            html_message = render_to_string('admin_emails/rejection_confirmation.html', context)
            plain_message = render_to_string('admin_emails/rejection_confirmation.txt', context)
            
            email = EmailMultiAlternatives(
                subject=subject,
                body=plain_message,
                from_email='noreply@opas.com',
                to=[admin_user.email]
            )
            email.attach_alternative(html_message, "text/html")
            email.send(fail_silently=False)
            
            AdminNotificationLog.objects.create(
                admin_user=admin_user,
                notification_type='BULK_REJECTION_SUMMARY',
                subject=subject,
                content=plain_message[:500],
                status='SENT',
                sent_at=timezone.now()
            )
        
        except Exception as e:
            logger.error(f"Error sending rejection confirmation: {str(e)}")


@shared_task
def send_admin_daily_digest():
    """
    CORE PRINCIPLE: Daily summary of all registrations
    - Reduces notification overload
    - Efficient processing
    - Sent during low-traffic hours
    """
    from apps.sellers.models import SellerRegistration
    
    try:
        # Get all admins who want daily digest
        admins = AdminNotificationPreferences.objects.filter(
            new_registration_frequency='DIGEST_DAILY',
            receive_new_registration_alerts=True
        )
        
        for pref in admins:
            # Get registrations from last 24 hours
            yesterday = timezone.now() - timezone.timedelta(days=1)
            registrations = SellerRegistration.objects.filter(
                created_at__gte=yesterday
            ).order_by('-created_at')
            
            if not registrations.exists():
                continue
            
            subject = f"Daily Digest: {registrations.count()} New Registrations"
            
            context = {
                'admin_name': pref.admin_user.first_name or pref.admin_user.email,
                'registrations': registrations,
                'count': registrations.count(),
            }
            
            html_message = render_to_string('admin_emails/daily_digest.html', context)
            plain_message = render_to_string('admin_emails/daily_digest.txt', context)
            
            email = EmailMultiAlternatives(
                subject=subject,
                body=plain_message,
                from_email='noreply@opas.com',
                to=[pref.admin_user.email]
            )
            email.attach_alternative(html_message, "text/html")
            email.send(fail_silently=False)
            
            AdminNotificationLog.objects.create(
                admin_user=pref.admin_user,
                notification_type='DAILY_DIGEST',
                subject=subject,
                content=plain_message[:500],
                related_registrations=registrations.count(),
                status='SENT',
                sent_at=timezone.now()
            )
    
    except Exception as e:
        logger.error(f"Error sending daily digest: {str(e)}")
