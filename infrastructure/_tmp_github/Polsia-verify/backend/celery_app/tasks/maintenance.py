from celery_app.worker import app


@app.task
def cleanup_old_activity():
    import asyncio
    from datetime import datetime, timedelta
    from app.core.database import _get_session_factory
    from app.models.report import ActivityLog
    from sqlalchemy import delete

    async def _run():
        Session = _get_session_factory()
        cutoff = datetime.utcnow() - timedelta(days=90)
        async with Session() as db:
            await db.execute(
                delete(ActivityLog).where(ActivityLog.created_at < cutoff)
            )
            await db.commit()

    asyncio.run(_run())
