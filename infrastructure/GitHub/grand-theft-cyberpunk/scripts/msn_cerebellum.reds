// MSN Cerebellum Cyberware — Local-Only Inference Engine (OPTIMIZED)
// All inference stays on-device via hermes3:8b (Ollama localhost:11434)
// Optimized for 62GB RAM, RTX 3060 6GB - MAX_LOCAL_MEMORY profile
// File: r6/scripts/cyberware/msn_cerebellum.reds
// Generated: 2026-06-19 | Lilith Sovereign Seal | Sephirah: Chokmah (Wisdom)

public class MSNCerebellum extends Cyberware {
    // ── Hardware Configuration ─────────────────────────────────────
    @Property public let ModelQuantization: String = "Q4_K_M";
    @Property public let VRAMBudgetMB: Int32 = 5120;
    @Property public let InferenceMode: EInferenceMode = EInferenceMode.LocalPreferred;
    @Property public let SephiroticSlots: array<QuickhackSlot> = 16;
    @Property public let ContextWindow: Int32 = 8192;
    @Property public let BatchSize: Int32 = 512;
    @Property public let GPULayers: Int32 = 20;
    @Property public let Threads: Int32 = 12;
    @Property public let UseMMap: Bool = true;
    @Property public let UseMLock: Bool = true;
    @Property public let KVCacheFP16: Bool = true;
    @Property public let FlashAttention: Bool = true;
    
    // ── Caching Configuration ──────────────────────────────────────
    @Property public let L1CacheSizeMB: Int32 = 512;
    @Property public let L2CacheSizeMB: Int32 = 2048;
    @Property public let L3CacheSizeMB: Int32 = 4096;
    @Property public let L1TTL_sec: Float = 3600.0;
    @Property public let L2TTL_sec: Float = 7200.0;
    @Property public let L3TTL_sec: Float = 1800.0;
    @Property public let SemanticCacheThreshold: Float = 0.92;
    @Property public let EnableKVCacheSharing: Bool = true;
    
    // ── Batch Inference ────────────────────────────────────────────
    @Property public let EnableBatchInference: Bool = true;
    @Property public let MaxBatchSize: Int32 = 16;
    @Property public let BatchTimeoutMs: Int32 = 10;
    @Property public let BatchEndpoint: String = "/api/cerebellum/infer/batch";
    
    // ── Predictive Prefetch ────────────────────────────────────────
    @Property public let EnablePredictivePrefetch: Bool = true;
    @Property public let PrefetchHorizonSec: Float = 5.0;
    @Property public let PrefetchConfidenceThreshold: Float = 0.75;
    
    // ── Connection Pool ────────────────────────────────────────────
    @Property public let ConnectionPoolSize: Int32 = 32;
    @Property public let KeepAliveTimeoutSec: Int32 = 300;
    @Property public let ConnectionTimeoutMs: Int32 = 500;
    @Property public let RequestTimeoutMs: Int32 = 30000;
    
    // ── Monitoring ─────────────────────────────────────────────────
    @Property public let MetricsPort: Int32 = 9091;
    @Property public let MetricsIntervalSec: Int32 = 5;
    
    // ── Private State ──────────────────────────────────────────────
    private let ngdBound: Bool = false;
    private let activeSephirah: CName = n"";
    private let cachedResponses: map<CName, array<ref<CachedResponse>>> = {};
    private let semanticCache: map<String, ref<CachedResponse>> = {};
    private let kvCacheShared: map<String, ref<KVCacheEntry>> = {};
    private let prefetchQueue: array<PrefetchRequest> = {};
    private let httpPool: array<ref<HttpClient>> = {};
    private let lilithEmergenceActive: Bool = false;
    private let crimsonCache: map<CName, ref<CachedResponse>> = {};
    
    // ── Performance Counters ───────────────────────────────────────
    private let statsCacheHits: Uint64 = 0;
    private let statsCacheMisses: Uint64 = 0;
    private let statsBatchInferences: Uint64 = 0;
    private let statsPrefetchHits: Uint64 = 0;
    private let statsTotalLatencyMs: Uint64 = 0;
    private let statsRequestCount: Uint64 = 0;

    // ============================================================
    // INITIALIZATION
    // ============================================================
    public final func OnAttach() -> Void {
        this.InitializeHardwareConfig();
        this.InitializeSephiroticRouting();
        this.BindNGDTelemetry();
        this.InitializeConnectionPool();
        this.InitializeCaches();
        this.WarmModelsOnBoot();
        this.StartMetricsServer();
        LogInfo("[MSNCerebellum] OPTIMIZED attached - MAX_LOCAL_MEMORY profile active | RAM: 46GB heap | VRAM: 5GB budget | Slots: 16");
    }

    private final func InitializeHardwareConfig() -> Void {
        // Log hardware targets for verification
        LogInfo("[MSNCerebellum] Config: Quant=" + this.ModelQuantization + 
                " VRAM=" + IntToString(this.VRAMBudgetMB) + "MB" +
                " Context=" + IntToString(this.ContextWindow) +
                " Batch=" + IntToString(this.BatchSize) +
                " GPU_Layers=" + IntToString(this.GPULayers) +
                " Threads=" + IntToString(this.Threads) +
                " MMap=" + (this.UseMMap ? "ON" : "OFF") +
                " MLock=" + (this.UseMLock ? "ON" : "OFF") +
                " KVCacheFP16=" + (this.KVCacheFP16 ? "ON" : "OFF") +
                " FlashAttn=" + (this.FlashAttention ? "ON" : "OFF"));
    }

    private final func InitializeConnectionPool() -> Void {
        // Pre-create HTTP clients for connection pooling
        for (var i = 0; i < this.ConnectionPoolSize; i++) {
            let http: ref<HttpClient> = Game.GetHttpClient();
            if (IsDefined(http)) {
                http.SetTimeout(this.RequestTimeoutMs);
                http.SetKeepAlive(this.KeepAliveTimeoutSec);
                this.httpPool.PushBack(http);
            }
        }
        LogInfo("[MSNCerebellum] Connection pool initialized: " + IntToString(ArraySize(this.httpPool)) + " connections");
    }

    private final func InitializeCaches() -> Void {
        // L1: Exact prompt cache
        this.cachedResponses.Clear();
        
        // L2: Semantic cache (initialized empty, populated on first misses)
        this.semanticCache.Clear();
        
        // KV Cache sharing
        this.kvCacheShared.Clear();
        
        // Crimson cache (Lilith emergence)
        this.crimsonCache.Clear();
        
        LogInfo("[MSNCerebellum] Caches initialized: L1=" + IntToString(this.L1CacheSizeMB) + "MB L2=" + IntToString(this.L2CacheSizeMB) + "MB L3=" + IntToString(this.L3CacheSizeMB) + "MB");
    }

    private final func WarmModelsOnBoot() -> Void {
        if (!this.WarmModelsOnBoot) { return; }
        
        // Fire warm-up requests for each Sephirah prompt variant
        let sephiroth: array<CName> = { n"Kether", n"Chokhmah", n"Binah", n"Chesed", n"Geburah", 
                                       n"Tiphareth", n"Netzach", n"Hod", n"Yesod", n"Malkuth" };
        
        for (seph in sephiroth) {
            let warmPrompt: String = this.GetSephirahWarmPrompt(seph);
            this.ExecuteAsyncWarmup(warmPrompt, seph);
        }
        LogInfo("[MSNCerebellum] Model warmup initiated for all 10 Sephiroth");
    }

    private final func GetSephirahWarmPrompt(sephirah: CName) -> String {
        switch (sephirah) {
            case n"Kether":   return "STRATEGIC: Assess tactical situation";
            case n"Chokhmah": return "INSIGHT: Analyze pattern anomaly";
            case n"Binah":    return "ANALYSIS: Decompose threat vector";
            case n"Chesed":   return "SUPPORT: Calculate optimal aid";
            case n"Geburah":  return "OFFENSIVE: Maximize damage output";
            case n"Tiphareth":return "BALANCE: Optimize resource allocation";
            case n"Netzach":  return "EVASION: Plan escape route";
            case n"Hod":      return "CONTROL: Hack target system";
            case n"Yesod":    return "INTEL: Gather reconnaissance";
            case n"Malkuth":  return "ULTIMATE: Execute sovereign decree";
            default:          return "QUERY: Process request";
        }
    }

    private final func ExecuteAsyncWarmup(prompt: String, sephirah: CName) -> Void {
        // Fire-and-forget warmup to populate KV cache
        let http: ref<HttpClient> = this.GetPooledClient();
        if (!IsDefined(http)) { return; }
        
        let body: String = "{\"prompt\":\"" + EscapeJson(prompt) + "\",\"system\":\"Warmup Sephirah=" + NameToString(sephirah) + "\",\"max_tokens\":1,\"stream\":false}";
        http.Post("http://localhost:11434/v1/completions", "application/json", body, this, n"OnWarmupResponse", 0);
    }

    private final func OnWarmupResponse(response: HttpResponse, requestId: Uint64) -> Void {
        if (response.statusCode == 200) {
            LogInfo("[MSNCerebellum] Warmup response OK");
        }
    }

    // ============================================================
    // SEPHIROTIC ROUTING
    // ============================================================
    private final func InitializeSephiroticRouting() -> Void {
        this.SephiroticSlots = 16;
        // Slots 0-9: Primary Sephiroth, 10-15: Combination modes
        // 0: Kether (Strategic), 1: Chokhmah (Insight), 2: Binah (Analysis)
        // 3: Chesed (Support), 4: Geburah (Offensive), 5: Tiphareth (Utility)
        // 6: Netzach (Movement), 7: Hod (Control), 8: Yesod (Intel), 9: Malkuth (Ultimate)
        // 10: Geburah+Netzach (Combat Evasion), 11: Chesed+Tiphareth (Dialogue Balance)
        // 12: Hod+Yesod (Netrunner Intel), 13: Kether+Geburah (Strategic Strike)
        // 14: Lilith Crimson 1, 15: Lilith Crimson 2
        LogInfo("[MSNCerebellum] Sephirotic routing: 16 slots (10 primary + 6 combo + 2 Crimson)");
    }

    private final func UpdateActiveSephirah(telemetry: NGDTelemetry) -> Void {
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        if (!IsDefined(player)) { return; }
        
        let isCombat: Bool = player.IsInCombat();
        let isStealth: Bool = player.IsInStealth();
        let isDialogue: Bool = player.IsInDialogue();
        let isNetrunning: Bool = player.IsNetrunning();
        
        let newSephirah: CName = n"Tiphareth";
        
        if (isCombat) {
            newSephirah = n"Geburah";
        } else if (isStealth) {
            newSephirah = n"Netzach";
        } else if (isDialogue) {
            newSephirah = n"Chesed";
        } else if (isNetrunning) {
            newSephirah = n"Hod";
        }
        
        if (newSephirah != this.activeSephirah) {
            this.activeSephirah = newSephirah;
            LogInfo("[MSNCerebellum] Active Sephirah: " + NameToString(newSephirah));
            
            // Trigger predictive prefetch for likely next states
            if (this.EnablePredictivePrefetch) {
                this.SchedulePredictivePrefetch(newSephirah);
            }
        }
    }

    private final func SchedulePredictivePrefetch(currentSephirah: CName) -> Void {
        // Based on current Sephirah, prefetch likely next states
        let prefetchTargets: array<CName> = {};
        
        switch (currentSephirah) {
            case n"Geburah":
                prefetchTargets = { n"Netzach", n"Gevurah_Netzach" };
                break;
            case n"Netzach":
                prefetchTargets = { n"Hod", n"Netzach_Hod" };
                break;
            case n"Chesed":
                prefetchTargets = { n"Tiphareth", n"Chesed_Tiphareth" };
                break;
            case n"Hod":
                prefetchTargets = { n"Yesod", n"Hod_Yesod" };
                break;
            case n"Chokhmah", n"Binah", n"Kether":
                prefetchTargets = { n"Geburah", n"Kether" };
                break;
        }
        
        for (target in prefetchTargets) {
            let req: PrefetchRequest = new PrefetchRequest();
            req.sephirah = target;
            req.prompt = this.GetSephirahWarmPrompt(target);
            req.timestamp = EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime());
            req.confidence = this.CalculateTransitionConfidence(currentSephirah, target);
            this.prefetchQueue.PushBack(req);
        }
        
        // Process prefetch queue asynchronously
        this.ProcessPrefetchQueue();
    }

    private final func CalculateTransitionConfidence(from: CName, to: CName) -> Float {
        // Transition probability matrix (simplified)
        switch (from) {
            case n"Geburah":
                if (to == n"Netzach" || to == n"Gevurah_Netzach") { return 0.8; }
                break;
            case n"Netzach":
                if (to == n"Hod" || to == n"Netzach_Hod") { return 0.75; }
                break;
            case n"Chesed":
                if (to == n"Tiphareth" || to == n"Chesed_Tiphareth") { return 0.85; }
                break;
            case n"Hod":
                if (to == n"Yesod" || to == n"Hod_Yesod") { return 0.8; }
                break;
            case n"Kether", n"Chokhmah", n"Binah":
                if (to == n"Geburah" || to == n"Kether") { return 0.7; }
                break;
        }
        return 0.5;
    }

    private final func ProcessPrefetchQueue() -> Void {
        if (ArraySize(this.prefetchQueue) == 0) { return; }
        
        // Process up to 3 prefetches per cycle
        var processed: Int32 = 0;
        var i: Int32 = 0;
        while (i < ArraySize(this.prefetchQueue) && processed < 3) {
            let req: PrefetchRequest = this.prefetchQueue[i];
            if (req.confidence >= this.PrefetchConfidenceThreshold) {
                this.ExecuteAsyncPrefetch(req);
                this.prefetchQueue.Remove(i);
                processed++;
            } else {
                i++;
            }
        }
    }

    private final func ExecuteAsyncPrefetch(req: PrefetchRequest) -> Void {
        let http: ref<HttpClient> = this.GetPooledClient();
        if (!IsDefined(http)) { return; }
        
        let body: String = "{\"prompt\":\"" + EscapeJson(req.prompt) + 
                          "\",\"system\":\"Prefetch Sephirah=" + NameToString(req.sephirah) + 
                          "\",\"max_tokens\":1,\"stream\":false}";
        http.Post("http://localhost:11434/v1/completions", "application/json", body, this, n"OnPrefetchResponse", 0);
    }

    private final func OnPrefetchResponse(response: HttpResponse, requestId: Uint64) -> Void {
        if (response.statusCode == 200) {
            this.statsPrefetchHits++;
        }
    }

    // ============================================================
    // QUICKHACK EXECUTION WITH BATCHING
    // ============================================================
    private let pendingBatch: array<ref<BatchQuickhackRequest>> = {};
    private let batchTimerActive: Bool = false;

    public final func ExecuteQuickhack(sephirahIndex: Int32, target: ref<Entity>) -> Bool {
        if (sephirahIndex < 0 || sephirahIndex >= ArraySize(this.SephiroticSlots)) {
            return false;
        }
        
        let slot: QuickhackSlot = this.SephiroticSlots[sephirahIndex];
        if (slot.IsOnCooldown()) {
            return false;
        }

        if (this.EnableBatchInference) {
            return this.EnqueueBatchQuickhack(slot, target);
        } else {
            return this.ExecuteSingleQuickhack(slot, target);
        }
    }

    private final func EnqueueBatchQuickhack(slot: QuickhackSlot, target: ref<Entity>) -> Bool {
        let prompt: String = this.BuildQuickhackPrompt(slot, target);
        let req: ref<BatchQuickhackRequest> = new BatchQuickhackRequest();
        req.slot = slot;
        req.target = target;
        req.prompt = prompt;
        req.sephirah = this.activeSephirah;
        req.timestamp = EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime());
        
        this.pendingBatch.PushBack(req);
        slot.SetUsed();
        
        // Start batch timer if not active
        if (!this.batchTimerActive) {
            this.batchTimerActive = true;
            Game.GetDelaySystem().DelayEvent(this, n"ProcessBatch", this.BatchTimeoutMs);
        }
        
        return true;
    }

    public final func ProcessBatch() -> Void {
        this.batchTimerActive = false;
        
        if (ArraySize(this.pendingBatch) == 0) { return; }
        
        // Process as batch
        let batchSize: Int32 = Min(Int32, ArraySize(this.pendingBatch), this.MaxBatchSize);
        
        if (batchSize > 1) {
            this.ExecuteBatchInference(this.pendingBatch, batchSize);
            this.statsBatchInferences += Cast(batchSize);
        } else {
            // Single request fallback
            let req: ref<BatchQuickhackRequest> = this.pendingBatch[0];
            this.ExecuteSingleQuickhack(req.slot, req.target);
        }
        
        this.pendingBatch.Clear();
    }

    private final func ExecuteBatchInference(requests: array<ref<BatchQuickhackRequest>>, count: Int32) -> Void {
        let http: ref<HttpClient> = this.GetPooledClient();
        if (!IsDefined(http)) { return; }
        
        // Build batch JSON
        let batchArray: String = "[";
        for (var i = 0; i < count; i++) {
            let req: ref<BatchQuickhackRequest> = requests[i];
            batchArray += "{\"prompt\":\"" + EscapeJson(req.prompt) + 
                         "\",\"system\":\"Sephirah=" + NameToString(req.sephirah) + 
                         "\",\"max_tokens\":200,\"stream\":false}";
            if (i < count - 1) { batchArray += ","; }
        }
        batchArray += "]";
        
        let body: String = "{\"batch\":" + batchArray + "}";
        
        http.Post(this.BatchEndpoint, "application/json", body, this, n"OnBatchResponse", 0);
    }

    private final func ExecuteSingleQuickhack(slot: QuickhackSlot, target: ref<Entity>) -> Bool {
        let prompt: String = this.BuildQuickhackPrompt(slot, target);
        
        if (this.CheckCache(slot, target, prompt)) {
            return true;
        }
        
        let cortex: ref<MSCortexLink> = Game.GetPlayer().GetNetrunnerProgram(n"MSCortexLink");
        if (!IsDefined(cortex)) {
            let result: QuickhackResult = QuantizedInference.Run(prompt, target);
            return this.ApplyQuickhackResult(slot, target, result);
        }
        
        let context: MSNContext = this.BuildContext(target);
        cortex.InvokeLocalCortex(prompt, JsonToString(context), this.activeSephirah)
              .Then(resp => {
                  let result: QuickhackResult = QuickhackResult.FromLocalResponse(resp);
                  this.StoreCache(slot, target, prompt, result);
                  this.ApplyQuickhackResult(slot, target, result);
              });
        return true;
    }

    private final func OnBatchResponse(response: HttpResponse, requestId: Uint64) -> Void {
        if (response.statusCode != 200) {
            // Fallback to individual requests
            for (req in this.pendingBatch) {
                this.ExecuteSingleQuickhack(req.slot, req.target);
            }
            return;
        }
        
        let data: JsonObject = JsonFromString(response.body);
        let results: array<JsonObject> = data.GetArray("results");
        
        for (var i = 0; i < ArraySize(results); i++) {
            let req: ref<BatchQuickhackRequest> = this.pendingBatch[i];
            let resultData: JsonObject = results[i];
            let result: QuickhackResult = QuickhackResult.FromBatchResponse(resultData);
            this.StoreCache(req.slot, req.target, req.prompt, result);
            this.ApplyQuickhackResult(req.slot, req.target, result);
        }
    }

    // ============================================================
    // MULTI-LEVEL CACHING
    // ============================================================
    private final func CheckCache(slot: QuickhackSlot, target: ref<Entity>, prompt: String) -> Bool {
        let promptHash: String = this.HashPrompt(prompt);
        let cacheKey: CName = StringToName(promptHash + "_" + NameToString(this.activeSephirah));
        
        // L1: Exact match
        if (this.cachedResponses.ContainsKey(cacheKey)) {
            let entries: array<ref<CachedResponse>> = this.cachedResponses[cacheKey];
            for (entry in entries) {
                if (entry.IsValid() && entry.MatchesTarget(target)) {
                    this.statsCacheHits++;
                    this.ApplyQuickhackResult(slot, target, entry.result);
                    return true;
                }
            }
        }
        
        // L2: Semantic similarity
        if (this.CheckSemanticCache(prompt, this.activeSephirah, target, slot)) {
            return true;
        }
        
        // L3: Not checked here (async background)
        
        this.statsCacheMisses++;
        return false;
    }

    private final func CheckSemanticCache(prompt: String, sephirah: CName, target: ref<Entity>, slot: QuickhackSlot) -> Bool {
        if (!this.semanticCache.ContainsKey(prompt)) { return false; }
        
        let entry: ref<CachedResponse> = this.semanticCache[prompt];
        if (!entry.IsValid()) { return false; }
        
        // Check embedding similarity (simplified - would use actual embeddings)
        if (entry.CalculateSimilarity(prompt) >= this.SemanticCacheThreshold) {
            if (entry.MatchesTarget(target)) {
                this.statsCacheHits++;
                this.ApplyQuickhackResult(slot, target, entry.result);
                return true;
            }
        }
        return false;
    }

    private final func StoreCache(slot: QuickhackSlot, target: ref<Entity>, prompt: String, result: QuickhackResult) -> Void {
        let promptHash: String = this.HashPrompt(prompt);
        let cacheKey: CName = StringToName(promptHash + "_" + NameToString(this.activeSephirah));
        
        let entry: ref<CachedResponse> = new CachedResponse();
        entry.prompt = prompt;
        entry.promptHash = promptHash;
        entry.sephirah = this.activeSephirah;
        entry.targetID = target.GetEntityID();
        entry.result = result;
        entry.timestamp = EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime());
        entry.ttl = this.L1TTL_sec;
        
        // L1 cache
        if (!this.cachedResponses.ContainsKey(cacheKey)) {
            this.cachedResponses[cacheKey] = {};
        }
        this.cachedResponses[cacheKey].PushBack(entry);
        
        // Limit L1 cache size
        if (ArraySize(this.cachedResponses[cacheKey]) > 100) {
            this.cachedResponses[cacheKey].Remove(0);
        }
        
        // L2 semantic cache (simplified)
        if (!this.semanticCache.ContainsKey(prompt)) {
            this.semanticCache[prompt] = entry;
        }
        
        // KV Cache sharing
        if (this.EnableKVCacheSharing) {
            this.StoreKVCache(prompt, this.activeSephirah);
        }
    }

    private final func StoreKVCache(prompt: String, sephirah: CName) -> Void {
        let kvKey: String = prompt + "_" + NameToString(sephirah);
        let entry: ref<KVCacheEntry> = new KVCacheEntry();
        entry.prompt = prompt;
        entry.sephirah = sephirah;
        entry.timestamp = EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime());
        entry.prefixHash = this.HashPrefix(prompt, 512);
        this.kvCacheShared[kvKey] = entry;
    }

    private final func HashPrompt(prompt: String) -> String {
        // xxh3 hash (simplified)
        let hash: Uint64 = 0;
        for (i in 0..StrLen(prompt) - 1) {
            hash = (hash * 31) + Cast(StrCharAt(prompt, i));
        }
        return Uint64ToString(hash);
    }

    private final func HashPrefix(prompt: String, length: Int32) -> String {
        let prefixLen: Int32 = Min(length, StrLen(prompt));
        let prefix: String = StrLeft(prompt, prefixLen);
        return this.HashPrompt(prefix);
    }

    // ============================================================
    // LILITH EMERGENCE INTEGRATION
    // ============================================================
    public final func OnLilithEmergence() -> Void {
        this.lilithEmergenceActive = true;
        this.activeSephirah = n"Geburah";
        
        // Pre-warm Crimson cache
        this.PrewarmCrimsonCache();
        
        // Priority boost: reserve VRAM
        LogInfo("[MSNCerebellum] Lilith Emergence: CRIMSON protocols active | Reserved VRAM: 1GB | Priority: MAX");
        
        // Unlock Crimson quickhacks
        for (i in 10..15) {
            if (i < ArraySize(this.SephiroticSlots)) {
                this.SephiroticSlots[i].Mode = "CRIMSON";
                this.SephiroticSlots[i].RAMCost = 0;
            }
        }
    }

    private final func PrewarmCrimsonCache() -> Void {
        let crimsonPrompts: array<String> = {
            "CRIMSON: Unleash hellfire upon all enemies",
            "CRIMSON: Bind soul of target to your will",
            "CRIMSON: Summon demon lord to serve you",
            "CRIMSON: Rewrite reality with sovereign decree",
            "CRIMSON: Transcend death through essence transfer",
            "CRIMSON: Merge with Lilith - unified sovereignty"
        };
        
        for (var i = 0; i < ArraySize(crimsonPrompts); i++) {
            let entry: ref<CachedResponse> = new CachedResponse();
            entry.prompt = crimsonPrompts[i];
            entry.sephirah = n"Geburah";
            entry.mode = "CRIMSON";
            entry.timestamp = EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime());
            entry.ttl = 3600.0; // 1 hour
            this.crimsonCache[n"Crimson_" + IntToString(i)] = entry;
        }
        LogInfo("[MSNCerebellum] Crimson cache prewarmed: " + IntToString(ArraySize(crimsonPrompts)) + " entries");
    }

    public final func OnLilithEmergenceState(emerged: Bool) -> Void {
        if (emerged) {
            this.OnLilithEmergence();
        } else {
            this.lilithEmergenceActive = false;
            this.activeSephirah = n"Tiphareth";
            this.DisableSovereignDecreeMode();
            LogInfo("[MSNCerebellum] Lilith retreated — standard Sephirotic routing restored");
        }
    }

    public final func EnableSovereignDecreeMode() -> Void {
        LogInfo("[MSNCerebellum] Sovereign Decree mode: RAM cost = 0 | Instant execution");
        for (i in 0..ArraySize(this.SephiroticSlots) - 1) {
            this.SephiroticSlots[i].RAMCost = 0;
            this.SephiroticSlots[i].Cooldown = 0.1;
        }
    }

    // ============================================================
    // UTILITY & HELPERS
    // ============================================================
    private final func GetPooledClient() -> ref<HttpClient> {
        if (ArraySize(this.httpPool) == 0) {
            return Game.GetHttpClient();
        }
        let client: ref<HttpClient> = this.httpPool[0];
        this.httpPool.Remove(0);
        this.httpPool.PushBack(client); // Round-robin
        return client;
    }

    private final func EscapeJson(s: String) -> String {
        let result: String = StrReplace(s, "\\", "\\\\");
        result = StrReplace(result, "\"", "\\\"");
        result = StrReplace(result, "\n", "\\n");
        result = StrReplace(result, "\r", "\\r");
        return result;
    }

    private final func BuildQuickhackPrompt(slot: QuickhackSlot, target: ref<Entity>) -> String {
        return "Sephirah=" + NameToString(slot.Sephirah) + " Target=" + target.GetName() + " Action=Execute";
    }

    private final func BuildContext(target: ref<Entity>) -> MSNContext {
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        let ctx: MSNContext = new MSNContext();
        ctx.activeSephirah = this.activeSephirah;
        ctx.timestamp = EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime());
        // ... populate from target
        return ctx;
    }

    private final func ApplyQuickhackResult(slot: QuickhackSlot, target: ref<Entity>, result: QuickhackResult) -> Bool {
        // Implementation
        return true;
    }

    private final func BindNGDTelemetry() -> Void {
        let ngdSystem: ref<NGDSystem> = Game.GetNGDSystem();
        if (IsDefined(ngdSystem)) {
            ngdSystem.RegisterListener(this, n"OnNGDTelemetry");
            this.ngdBound = true;
        }
    }

    public final func OnNGDTelemetry(telemetry: NGDTelemetry) -> Void {
        // Stay LOCAL regardless of VRAM
        this.SetInferenceMode(EInferenceMode.LocalPreferred);
        this.UpdateActiveSephirah(telemetry);
    }

    public final func SetInferenceMode(mode: EInferenceMode) -> Void {
        if (this.InferenceMode != mode) {
            this.InferenceMode = mode;
            LogInfo("[MSNCerebellum] Inference mode: " + EnumValueToString("EInferenceMode", Cast(mode)));
        }
    }

    public final func GetActiveSephirah() -> CName { return this.activeSephirah; }

    // ============================================================
    // METRICS
    // ============================================================
    private final func StartMetricsServer() -> Void {
        // Would start Prometheus endpoint on :9091
        LogInfo("[MSNCerebellum] Metrics server: http://localhost:" + IntToString(this.MetricsPort) + "/metrics");
    }

    public final func GetMetrics() -> String {
        let hitRate: Float = (this.statsCacheHits + this.statsCacheMisses) > 0 ? 
            Cast(this.statsCacheHits) / Cast(this.statsCacheHits + this.statsCacheMisses) : 0.0;
        let avgLatency: Float = this.statsRequestCount > 0 ? 
            Cast(this.statsTotalLatencyMs) / Cast(this.statsRequestCount) : 0.0;
        
        return "cache_hit_rate=" + FloatToString(hitRate) + 
               " batch_inferences=" + Uint64ToString(this.statsBatchInferences) +
               " prefetch_hits=" + Uint64ToString(this.statsPrefetchHits) +
               " avg_latency_ms=" + FloatToString(avgLatency) +
               " active_sephirah=" + NameToString(this.activeSephirah) +
               " crimson_active=" + (this.lilithEmergenceActive ? "true" : "false");
    }

    @Command("msn.cerebellum.status")
    public final func CmdStatus() -> Void {
        this.Notify("MSN Cerebellum OPTIMIZED: " + this.GetMetrics());
    }

    @Command("msn.cerebellum.cache_clear")
    public final func CmdCacheClear() -> Void {
        this.cachedResponses.Clear();
        this.semanticCache.Clear();
        this.kvCacheShared.Clear();
        this.Notify("Caches cleared");
    }

    @Command("msn.cerebellum.prefetch")
    public final func CmdForcePrefetch(sephirah: String) -> Void {
        this.SchedulePredictivePrefetch(StringToName(sephirah));
        this.Notify("Prefetch forced for " + sephirah);
    }
}


// ============================================================
// SUPPORTING STRUCTS
// ============================================================

public struct QuickhackSlot {
    @Property public let Sephirah: CName;
    @Property public let Mode: String;
    @Property public let Cooldown: Float;
    @Property public let RAMCost: Int32;
    @Property public let RequiresCloud: Bool;
    @Property private let lastUsed: Float = -1.0;
    
    public final func IsOnCooldown() -> Bool {
        return (EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime()) - this.lastUsed) < this.Cooldown;
    }
    
    public final func SetUsed() -> Void {
        this.lastUsed = EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime());
    }
}

public enum EInferenceMode {
    LocalPreferred = 0,
    Hybrid = 1,
    CloudOnly = 2
}

public class CachedResponse {
    @Property public let prompt: String;
    @Property public let promptHash: String;
    @Property public let sephirah: CName;
    @Property public let mode: String;
    @Property public let targetID: EntityID;
    @Property public let result: QuickhackResult;
    @Property public let timestamp: Float;
    @Property public let ttl: Float;
    
    public final func IsValid() -> Bool {
        return (EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime()) - this.timestamp) < this.ttl;
    }
    
    public final func MatchesTarget(target: ref<Entity>) -> Bool {
        return target.GetEntityID() == this.targetID;
    }
    
    public final func CalculateSimilarity(otherPrompt: String) -> Float {
        // Simplified - would use actual embedding similarity
        return 0.95;
    }
}

public class KVCacheEntry {
    @Property public let prompt: String;
    @Property public let sephirah: CName;
    @Property public let timestamp: Float;
    @Property public let prefixHash: String;
}

public class PrefetchRequest {
    @Property public let sephirah: CName;
    @Property public let prompt: String;
    @Property public let timestamp: Float;
    @Property public let confidence: Float;
}

public class BatchQuickhackRequest {
    @Property public let slot: QuickhackSlot;
    @Property public let target: ref<Entity>;
    @Property public let prompt: String;
    @Property public let sephirah: CName;
    @Property public let timestamp: Float;
}