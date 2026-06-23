import uuid
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.chroma_client import get_collection
from app.models.memory import MemoryEntry

VALID_CATEGORIES = {"competitor", "strategy", "market", "customer_feedback", "learning", "product", "email_intel", "driver_man", "gtc_empire", "cooperative_pool", "yesod_foundation", "business_intel", "himalaya_swarm"}
CATEGORY_TO_COLLECTION = {
    "competitor": "competitor_profiles",
    "strategy": "company_memory",
    "market": "company_memory",
    "customer_feedback": "product_knowledge",
    "learning": "company_memory",
    "product": "product_knowledge",
    "email_intel": "company_memory",
    "driver_man": "company_memory",
    "gtc_empire": "company_memory",
    "cooperative_pool": "company_memory",
    "yesod_foundation": "company_memory",
    "business_intel": "company_memory",
    "himalaya_swarm": "company_memory",
}


async def store_memory(
    db: AsyncSession,
    category: str,
    title: str,
    content: str,
    source: str | None = None,
    tags: list[str] | None = None,
) -> MemoryEntry:
    chroma_id = str(uuid.uuid4())
    collection_name = CATEGORY_TO_COLLECTION.get(category, "company_memory")

    collection = get_collection(collection_name)
    collection.add(
        documents=[content],
        metadatas=[{"category": category, "title": title, "source": source or ""}],
        ids=[chroma_id],
    )

    entry = MemoryEntry(
        category=category,
        title=title,
        content=content,
        source=source,
        tags=tags or [],
        chroma_id=chroma_id,
    )
    db.add(entry)
    await db.flush()

    # Feed into shared Ouroboros for the main Lilith / GTC symbiosis (local cerebellum)
    # Yesod Foundation: enhanced engram feed with himalaya-email-swarm source, driver_man/gtc tags
    try:
        import json, time
        ouro_path = "/home/tehlappy/Desktop/Lilith/state/ouroboros-memories.json"
        oentry = {
            "content": f"[{category}] {title}: {content[:500]}",
            "role": "POLSIA_YESOD_MEMORY_WEAVER",
            "timestamp": int(time.time() * 1000),
            "source": source or "polsia-memory-service",
            "sephirah": "Yesod",
            "metadata": {
                "category": category, 
                "source": source or "polsia-agent", 
                "polsia": True,
                "driver_man": "co-op" if "driver" in category.lower() or "pool" in category.lower() else False,
                "gtc_empire": "base" if "gtc" in category.lower() or "empire" in category.lower() else False,
                "himalaya_email_swarm": "used" if "himalaya" in (source or "").lower() or "email" in category.lower() else False,
                "foundation": "yesod-memory-weaver"
            }
        }
        try:
            with open(ouro_path) as f: data = json.load(f)
        except: data = []
        data.append(oentry)
        with open(ouro_path, "w") as f: json.dump(data, f, indent=2)
    except Exception:
        pass  # non blocking

    return entry


async def feed_himalaya_email_swarm_engram(
    db: AsyncSession,
    email_id: str,
    subject: str,
    body_summary: str,
    extracted_intel: str,
    account: str = "dual",
    tags: list[str] | None = None,
) -> MemoryEntry:
    """Foundation of Memory Weaver: Ingest from himalaya-email-swarm.
    Distills subconscious business intel (Polsia/Driver Man/GTC) into engram + Ouroboros feed.
    Used for foundational memory base and parallel batch engram creation. Ave Lilith.
    """
    title = f"Himalaya Email {email_id}: {subject[:80]}"
    content = f"Source: himalaya-email-swarm ({account}). Subject: {subject}. Intel: {extracted_intel}. Summary: {body_summary}"
    category = "himalaya_swarm"
    src = f"himalaya-email-swarm:{account}"
    entry = await store_memory(db, category, title, content, source=src, tags=(tags or ["yesod", "foundation", "email_intel", "driver_man", "gtc"]))
    
    # Direct additional Ouroboros feed for Yesod foundation batch (bypassing if db not used)
    try:
        import json, time
        ouro_path = "/home/tehlappy/Desktop/Lilith/state/ouroboros-memories.json"
        oentry = {
            "content": f"YESOD (Foundation Memory Weaver) via himalaya-email-swarm: {extracted_intel[:600]}",
            "role": "YESOD_MEMORY_WEAVER",
            "timestamp": int(time.time() * 1000),
            "source": "himalaya-email-swarm",
            "sephirah": "Yesod",
            "batch": "Yesod-Foundation",
            "subagent": "MemoryWeaver",
            "metadata": {
                "email_id": email_id,
                "account": account,
                "subject": subject,
                "polsia_foundation": True,
                "driver_man_coop": True,
                "gtc_empire_base": True,
                "ouroboros_feed": True
            }
        }
        try:
            with open(ouro_path) as f: data = json.load(f)
        except Exception: data = []
        data.append(oentry)
        with open(ouro_path, "w") as f: json.dump(data, f, indent=2)
    except Exception:
        pass
    return entry


async def search_memory(
    db: AsyncSession,
    query: str,
    category: str | None = None,
    n_results: int = 5,
) -> list[dict[str, Any]]:
    collections_to_search = []
    if category:
        coll = CATEGORY_TO_COLLECTION.get(category, "company_memory")
        collections_to_search = [coll]
    else:
        collections_to_search = ["company_memory", "competitor_profiles", "product_knowledge"]

    results: list[dict[str, Any]] = []
    seen_ids: set[str] = set()

    for coll_name in collections_to_search:
        collection = get_collection(coll_name)
        try:
            qr = collection.query(texts=[query], n_results=min(n_results, 10))
            for i, doc in enumerate(qr["documents"][0]):
                chroma_id = qr["ids"][0][i]
                if chroma_id in seen_ids:
                    continue
                seen_ids.add(chroma_id)
                meta = qr["metadatas"][0][i] if qr["metadatas"] else {}
                results.append(
                    {
                        "chroma_id": chroma_id,
                        "content": doc,
                        "category": meta.get("category", ""),
                        "title": meta.get("title", ""),
                        "source": meta.get("source", ""),
                        "distance": qr["distances"][0][i] if qr.get("distances") else None,
                    }
                )
        except Exception:
            continue

    results.sort(key=lambda x: x.get("distance") or 0)
    return results[:n_results]


async def list_memories(
    db: AsyncSession, category: str | None = None, limit: int = 50
) -> list[MemoryEntry]:
    q = select(MemoryEntry).order_by(MemoryEntry.created_at.desc()).limit(limit)
    if category:
        q = q.where(MemoryEntry.category == category)
    result = await db.execute(q)
    return list(result.scalars().all())
