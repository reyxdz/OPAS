from django.apps import AppConfig


class UsersConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.users'
    verbose_name = 'Users & Products'

    def ready(self):
        """Import signals when app is ready"""
        import apps.users.opas_signals  # noqa
