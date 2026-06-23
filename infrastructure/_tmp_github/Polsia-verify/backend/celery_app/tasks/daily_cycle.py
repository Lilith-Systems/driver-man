from datetime import date

from celery_app.worker import app


@app.task(bind=True, max_retries=2, default_retry_delay=120)
def morning_cycle(self):
    import asyncio
    from app.core.database import _get_session_factory
    from app.services.task_service import create_task
    from app.services.report_service import save_morning_plan
    from app.services.company_service import get_full_context
    from app.services.activity_service import log_activity
    from app.agents.crew_factory import run_agent_for_task

    async def _run():
        Session = _get_session_factory()
        async with Session() as db:
            context = await get_full_context(db)

            try:
                result = run_agent_for_task(
                    "orchestrator",
                    {"title": "Morning planning cycle", "description": "Generate today's task plan"},
                    context,
                )
                tasks_created = 0
                for t in result.get("tasks", []):
                    await create_task(
                        db, title=t["title"], agent_type=t["agent_type"],
                        description=t.get("description"), priority=t.get("priority", 3),
                        source="orchestrator",
                    )
                    tasks_created += 1

                await save_morning_plan(
                    db, date.today(),
                    plan=result.get("summary", ""),
                    tasks_planned=tasks_created,
                )
                await log_activity(
                    db, "orchestrator", "morning_cycle",
                    f"Morning cycle: planned {tasks_created} tasks",
                    {"tasks": result.get("tasks", []), "key_focus": result.get("key_focus")},
                )
            except Exception as e:
                await log_activity(
                    db, "orchestrator", "morning_cycle_failed",
                    f"Morning cycle failed: {e}", level="error",
                )

        # Enqueue sweep tasks
        run_social_sweep.delay()
        run_email_sweep.delay()

    asyncio.run(_run())


@app.task(bind=True, max_retries=2, default_retry_delay=120)
def evening_cycle(self):
    import asyncio
    from app.core.database import _get_session_factory
    from app.services.task_service import get_tasks_today_summary
    from app.services.report_service import save_evening_summary
    from app.services.company_service import get_full_context
    from app.services.activity_service import log_activity
    from app.agents.crew_factory import run_agent_for_task

    async def _run():
        Session = _get_session_factory()
        async with Session() as db:
            context = await get_full_context(db)
            tasks_today = await get_tasks_today_summary(db)

            try:
                result = run_agent_for_task(
                    "orchestrator",
                    {"title": "Evening review cycle", "description": "Review today's performance"},
                    context,
                )
                await save_evening_summary(
                    db, date.today(),
                    summary=result.get("summary", ""),
                    insights=result.get("insights", []),
                    tasks_completed=tasks_today.get("completed", 0),
                    tasks_failed=tasks_today.get("failed", 0),
                )
                await log_activity(
                    db, "orchestrator", "evening_cycle",
                    f"Evening cycle: {tasks_today.get('completed', 0)} completed, {tasks_today.get('failed', 0)} failed",
                    {"insights": result.get("insights"), "tomorrow_priorities": result.get("tomorrow_priorities")},
                )
            except Exception as e:
                await log_activity(
                    db, "orchestrator", "evening_cycle_failed",
                    f"Evening cycle failed: {e}", level="error",
                )

    asyncio.run(_run())


from celery_app.tasks.agent_tasks import run_social_sweep, run_email_sweep
