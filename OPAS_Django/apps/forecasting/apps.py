from django.apps import AppConfig


class ForecastingConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.forecasting'
    verbose_name = 'Forecasting'

    def ready(self):
        """
        Import signal handlers when the app is ready.
        This ensures signals are registered with Django.
        """
        import apps.forecasting.signals  # noqa
