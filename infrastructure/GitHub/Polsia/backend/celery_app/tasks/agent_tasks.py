import asyncio

from celery_app.worker import app
from app.core.database import _get_session_factory
from app.services.task_service import get_task, update_task_status, create_agent_run, finish_agent_run
from app.services.company_service import get_full_context
from app.services.activity_service import log_activity
from app.agents.crew_factory import run_agent_for_task

VALID_TASK_TYPES = {
    "social_media": "Social media content creation and posting sweep",
    "customer_support": "Support inbox sweep and reply generation",
    "ads_management": "Ad performance check and optimization sweep",
    "finance": "Stripe sync and revenue snapshot generation",
}

_celery_loop: asyncio.AbstractEventLoop | None = None


def _get_loop() -> asyncio.AbstractEventLoop:
    global _celery_loop
    if _celery_loop is None or _celery_loop.is_closed():
        _celery_loop = asyncio.new_event_loop()
        asyncio.set_event_loop(_celery_loop)
    return _celery_loop


@app.task(bind=True, max_retries=3, default_retry_delay=60)
def run_agent_task(self, task_id: int):
    async def _run():
        Session = _get_session_factory()
        async with Session() as db:
            task = await get_task(db, task_id)
            if not task:
                return

            await update_task_status(db, task_id, "in_progress")

            run = await create_agent_run(
                db, agent_type=task.agent_type, task_id=task_id,
                input_context={"title": task.title, "description": task.description},
            )

            context = await get_full_context(db)

            try:
                result = run_agent_for_task(
                    task.agent_type,
                    {"id": task.id, "title": task.title, "description": task.description},
                    context,
                )
                await finish_agent_run(
                    db, run.id, status="completed", output=result,
                    duration_secs=result.get("duration_secs"),
                )
                await update_task_status(
                    db, task_id, "completed",
                    result_summary=result.get("summary", str(result)[:500]),
                )
                await log_activity(
                    db, task.agent_type, "task_completed",
                    result.get("summary", "Task completed successfully"),
                    {"task_id": task_id, "result": result},
                )
                await db.commit()
            except Exception as e:
                await db.rollback()
                await finish_agent_run(db, run.id, status="failed", raw_log=str(e))
                await update_task_status(db, task_id, "failed", error_message=str(e))
                await log_activity(
                    db, task.agent_type, "task_failed",
                    f"Task failed: {e}", level="error",
                )
                try:
                    await db.commit()
                except Exception:
                    pass

    _get_loop().run_until_complete(_run())


@app.task
def run_social_sweep():
    _create_and_run("social_media", "Social media content creation and posting sweep")


@app.task
def run_email_sweep():
    _create_and_run("customer_support", "Support inbox sweep and reply generation")


@app.task
def run_ads_stripe_sync():
    _create_and_run("ads_management", "Ad performance check and optimization sweep")
    _create_and_run("finance", "Stripe sync and revenue snapshot generation")


def _create_and_run(agent_type: str, title: str):
    from app.core.database import _get_session_factory
    from app.services.task_service import create_task

    async def _inner():
        Session = _get_session_factory()
        async with Session() as db:
            task = await create_task(db, title=title, agent_type=agent_type, source="scheduler")
            task_id = task.id
        run_agent_task.delay(task_id)

    _get_loop().run_until_complete(_inner())
