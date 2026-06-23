from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import verify_api_key
from app.schemas.memory import MemoryEntryCreate, MemoryEntryOut
from app.services.memory_service import list_memories, search_memory, store_memory, feed_himalaya_email_swarm_engram

router = APIRouter(prefix="/memory", tags=["memory"])


@router.get("", response_model=list[MemoryEntryOut])
async def get_memory(
    q: str | None = Query(None, description="Semantic search query"),
    category: str | None = Query(None),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    _: str = Depends(verify_api_key),
):
    if q:
        results = await search_memory(db, q, category=category, n_results=limit)
        return [
            MemoryEntryOut(
                id=0,
                category=r["category"],
                title=r["title"],
                content=r["content"],
                source=r["source"],
                tags=[],
                chroma_id=r["chroma_id"],
                created_at=__import__("datetime").datetime.utcnow(),
            )
            for r in results
        ]
    return await list_memories(db, category=category, limit=limit)


@router.post("", response_model=MemoryEntryOut, status_code=201)
async def create_memory(
    entry: MemoryEntryCreate,
    db: AsyncSession = Depends(get_db),
    _: str = Depends(verify_api_key),
):
    return await store_memory(
        db,
        category=entry.category,
        title=entry.title,
        content=entry.content,
        source=entry.source,
        tags=entry.tags,
    )


@router.post("/himalaya-feed", response_model=MemoryEntryOut, status_code=201)
async def himalaya_email_swarm_feed(
    email_id: str,
    subject: str,
    body_summary: str,
    extracted_intel: str,
    account: str = "dual",
    db: AsyncSession = Depends(get_db),
    _: str = Depends(verify_api_key),
):
    """Yesod Foundation Memory Weaver endpoint: feed himalaya-email-swarm intel directly into Polsia memory + Ouroboros.
    Builds base subconscious business memory for Driver Man co-op and GTC empire. Parallel batch engram creation.
    """
    return await feed_himalaya_email_swarm_engram(
        db, email_id, subject, body_summary, extracted_intel, account=account
    )
