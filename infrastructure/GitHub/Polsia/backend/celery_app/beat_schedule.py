from celery.schedules import crontab
from app.config import settings

beat_schedule = {
    "morning-cycle": {
        "task": "celery_app.tasks.daily_cycle.morning_cycle",
        "schedule": crontab(hour=settings.morning_cycle_hour, minute=0),
    },
    "evening-cycle": {
        "task": "celery_app.tasks.daily_cycle.evening_cycle",
        "schedule": crontab(hour=settings.evening_cycle_hour, minute=0),
    },
    "social-mentions-sweep": {
        "task": "celery_app.tasks.agent_tasks.run_social_sweep",
        "schedule": crontab(minute="0", hour="*/2"),
    },
    "email-inbox-sweep": {
        "task": "celery_app.tasks.agent_tasks.run_email_sweep",
        "schedule": crontab(minute="30", hour="*/3"),
    },
    "ads-stripe-sync": {
        "task": "celery_app.tasks.agent_tasks.run_ads_stripe_sync",
        "schedule": crontab(minute="0", hour="*/6"),
    },
}
