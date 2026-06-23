-- corpus-backed TW / unified_tracker binding views + heartbeat upsert
-- Grounded in the actual corpus.db schema:
--   nyx_records(id, kind, timestamp, content, meta)
--   dedup_log(duplicate_id, kind, rel, status, touched_at)
--
-- Produce stable, queryable priority surfaces the RNN retrain loop and
-- tracker sync can consume directly instead of ad-hoc SQL.

-- 1) High-quality candidate pool (TW manual seed pool): top 16 per kind
--    by meta quality_score when present, then content length, newest first.
--    Exposes a fixed, bounded corpus slice the manual can label or veto.
CREATE VIEW IF NOT EXISTS corpus_hp_seeds AS
WITH scored AS (
  SELECT *,
         json_extract(meta, '$.quality_score') AS qval,
         length(content) AS content_len
  FROM nyx_records
)
SELECT id, kind, timestamp, content, meta, qval, content_len
FROM (
  SELECT *,
         ROW_NUMBER() OVER (
           PARTITION BY kind
           ORDER BY coalesce(qval, 0) DESC, content_len DESC, timestamp DESC
         ) AS rn
  FROM scored
)
WHERE rn <= 16;

-- 2) Cycle trajectory budget (unified_tracker staging buffer): oldest-accessed
--    32 per kind by raw epoch timestamp, so each cycle moves the window
--    forward naturally as new records land.
CREATE VIEW IF NOT EXISTS corpus_cycle_budget AS
WITH ranked AS (
  SELECT *,
         ROW_NUMBER() OVER (
           PARTITION BY kind
           ORDER BY timestamp ASC,
                    coalesce(json_extract(meta, '$.quality_score'), 0) DESC
         ) AS rn
  FROM nyx_records
)
SELECT id, kind, timestamp, content, meta
FROM ranked
WHERE rn <= 32;

-- 3) Kind-level registry replacing scatter-shot COUNT(*) calls.
CREATE VIEW IF NOT EXISTS corpus_kind_map AS
SELECT kind,
       COUNT(*) AS total_records,
       MIN(timestamp) AS oldest_ms,
       MAX(timestamp) AS newest_ms,
       AVG(coalesce(json_extract(meta, '$.quality_score'), 0)) AS avg_quality,
       AVG(length(content)) AS avg_chars
FROM nyx_records
GROUP BY kind;

-- 4) Heartbeat: idempotent set-rship over duplicate_id=0, no ON CONFLICT.
--    Retrain loops can probe this single row in one indexed lookup:
--      SELECT touched_at FROM dedup_log WHERE duplicate_id=0
INSERT INTO dedup_log (duplicate_id, kind, rel, status, touched_at)
SELECT 0, 'meta', 'corpus_tracker_heartbeat', 'latest', datetime('now')
WHERE NOT EXISTS (SELECT 1 FROM dedup_log WHERE duplicate_id=0);

UPDATE dedup_log
SET kind      = 'meta',
    rel       = 'corpus_tracker_heartbeat',
    status    = 'latest',
    touched_at= datetime('now')
WHERE duplicate_id = 0;
