from celery import Celery

app = Celery("polsia")
app.config_from_object("celery_app.celery_config")

# Explicit imports to register tasks
from celery_app.tasks import agent_tasks  # noqa: F401

app.autodiscover_tasks(["celery_app.tasks"])
