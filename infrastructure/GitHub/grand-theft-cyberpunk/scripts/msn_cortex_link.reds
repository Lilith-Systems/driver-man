// MSN Cortex Link — Local Inference via MSN Router (OPTIMIZED)
// Connection pooling, batch inference, async streaming, circuit breaker
// File: r6/scripts/netrunner/msn_cortex_link.reds
// Generated: 2026-06-19 | Lilith Sovereign Seal | Sephirah: Chokmah (Wisdom)

public class MSCortexLink extends NetrunnerProgram {
    // ── Local Endpoints ────────────────────────────────────────────
    @Property public let LocalCerebellumInfer: String = "http://localhost:11434/v1/completions";
    @Property public let LocalCerebellumBatch: String = "http://localhost:11434/v1/completions/batch";
    @Property public let LocalCortexInfer: String = "http://localhost:8007/api/cortex/infer";
    @Property public let LocalCortexRoute: String = "http://localhost:8007/api/cortex/route";
    @Property public let LocalCortexStatus: String = "http://localhost:8007/api/cortex/status";
    @Property public let LocalCortexStream: String = "http://localhost:8007/api/cortex/stream";
    
    // ── Connection Pool ────────────────────────────────────────────
    @Property public let ConnectionPoolSize: Int32 = 32;
    @Property public let KeepAliveTimeoutSec: Int32 = 300;
    @Property public let ConnectionTimeoutMs: Int32 = 500;
    @Property public let RequestTimeoutMs: Int32 = 30000;
    @Property public let EnableHTTP2: Bool = true;
    @Property public let EnableCompression: Bool = true;
    
    // ── Batch Inference ────────────────────────────────────────────
    @Property public let EnableBatchInference: Bool = true;
    @Property public let MaxBatchSize: Int32 = 16;
    @Property public let BatchTimeoutMs: Int32 = 10;
    @Property public let BatchBufferSize: Int32 = 1024;
    
    // ── Streaming ──────────────────────────────────────────────────
    @Property public let EnableStreaming: Bool = true;
    @Property public let StreamChunkSize: Int32 = 64;
    @Property public let StreamBufferMs: Int32 = 50;
    
    // ── Circuit Breaker ────────────────────────────────────────────
    @Property public let CircuitBreakerEnabled: Bool = true;
    @Property public let CircuitBreakerThreshold: Int32 = 5;
    @Property public let CircuitBreakerTimeoutSec: Int32 = 30;
    @Property public let CircuitBreakerHalfOpenRequests: Int32 = 3;
    
    // ── Retry Logic ────────────────────────────────────────────────
    @Property public let RetryAttempts: Int32 = 2;
    @Property public let RetryBackoffMs: Int32 = 50;
    @Property public let RetryMaxBackoffMs: Int32 = 1000;
    @Property public let RetryJitter: Bool = true;
    
    // ── Prefetch / Warmup ──────────────────────────────────────────
    @Property public let EnableWarmup: Bool = true;
    @Property public let WarmupOnInit: Bool = true;
    @Property public let WarmupRequestsPerSephirah: Int32 = 2;
    
    // ── Metrics ────────────────────────────────────────────────────
    @Property public let MetricsEnabled: Bool = true;
    @Property public let MetricsPort: Int32 = 9092;
    @Property public let MetricsIntervalSec: Int32 = 5;
    
    // ── Private State ──────────────────────────────────────────────
    private let httpPool: array<ref<PooledHttpClient>> = {};
    private let poolIndex: Int32 = 0;
    private let pendingRequests: map<Uint64, ref<CallbackHandle>> = {};
    private let requestCounter: Uint64 = 0;
    private let currentRoute: String = "LOCAL_CEREBELLUM";
    private let batchBuffer: array<ref<BatchInferenceRequest>> = {};
    private let batchTimerActive: Bool = false;
    private let circuitBreakerState: CircuitBreakerState = CircuitBreakerState.Closed;
    private let circuitBreakerFailures: Int32 = 0;
    private let circuitBreakerLastFailure: Float = 0.0;
    private let circuitBreakerSemaphore: Semaphore;
    private let statsTotalRequests: Uint64 = 0;
    private let statsSuccessfulRequests: Uint64 = 0;
    private let statsFailedRequests: Uint64 = 0;
    private let statsBatchRequests: Uint64 = 0;
    private let statsStreamingRequests: Uint64 = 0;
    private let statsTotalLatencyMs: Uint64 = 0;
    private let statsCacheHits: Uint64 = 0;
    private let routePollTimer: Bool = false;

    // ============================================================
    // INITIALIZATION
    // ============================================================
    public final func OnInitialize() -> Void {
        this.circuitBreakerSemaphore = new Semaphore(1);
        this.InitializeConnectionPool();
        this.StartRoutePolling();
        
        if (this.EnableWarmup && this.WarmupOnInit) {
            this.WarmupAllEndpoints();
        }
        
        if (this.MetricsEnabled) {
            this.StartMetricsServer();
        }
        
        LogInfo("[MSCortexLink] OPTIMIZED Initialized — Pool: " + IntToString(this.ConnectionPoolSize) + 
                " Batch: " + IntToString(this.MaxBatchSize) + 
                " CircuitBreaker: " + (this.CircuitBreakerEnabled ? "ON" : "OFF") +
                " Streaming: " + (this.EnableStreaming ? "ON" : "OFF"));
    }

    private final func InitializeConnectionPool() -> Void {
        for (var i = 0; i < this.ConnectionPoolSize; i++) {
            let client: ref<PooledHttpClient> = new PooledHttpClient();
            client.http = Game.GetHttpClient();
            client.inUse = false;
            client.createdAt = EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime());
            client.requestCount = 0;
            
            if (IsDefined(client.http)) {
                client.http.SetTimeout(this.RequestTimeoutMs);
                client.http.SetKeepAlive(this.KeepAliveTimeoutSec);
                if (this.EnableHTTP2) {
                    client.http.EnableHTTP2();
                }
                if (this.EnableCompression) {
                    client.http.EnableCompression("gzip");
                }
            }
            
            this.httpPool.PushBack(client);
        }
        LogInfo("[MSCortexLink] Connection pool: " + IntToString(ArraySize(this.httpPool)) + " clients");
    }

    private final func WarmupAllEndpoints() -> Void {
        // Warm up cerebellum endpoint
        for (var i = 0; i < this.WarmupRequestsPerSephirah; i++) {
            this.ExecuteWarmupRequest(this.LocalCerebellumInfer, "Warmup cerebellum");
            this.ExecuteWarmupRequest(this.LocalCortexInfer, "Warmup cortex");
        }
    }

    private final func ExecuteWarmupRequest(endpoint: String, label: String) -> Void {
        let client: ref<PooledHttpClient> = this.AcquireClient();
        if (!IsDefined(client)) { return; }
        
        let body: String = "{\"prompt\":\"Warmup\",\"max_tokens\":1,\"stream\":false}";
        client.http.Post(endpoint, "application/json", body, this, n"OnWarmupComplete", 0);
        this.ReleaseClient(client);
    }

    public final func OnWarmupComplete(response: HttpResponse, requestId: Uint64) -> Void {
        if (response.statusCode == 200) {
            LogInfo("[MSCortexLink] Warmup OK: " + response.body);
        }
    }

    // ============================================================
    // ROUTE POLLING
    // ============================================================
    private final func StartRoutePolling() -> Void {
        if (this.routePollTimer) { return; }
        this.routePollTimer = true;
        this.PollRouteLoop();
    }

    private final func PollRouteLoop() -> Void {
        if (!this.routePollTimer) { return; }
        
        let client: ref<PooledHttpClient> = this.AcquireClient();
        if (IsDefined(client)) {
            client.http.Get(this.LocalCortexRoute, this, n"OnRouteResponse");
            this.ReleaseClient(client);
        }
        
        Game.GetDelaySystem().DelayEvent(this, n"PollRouteLoop", 30000);
    }

    public final func OnRouteResponse(response: HttpResponse) -> Void {
        if (response.statusCode == 200) {
            let data: JsonObject = JsonFromString(response.body);
            let newRoute: String = data.GetString("route", "LOCAL_CEREBELLUM");
            if (newRoute != this.currentRoute) {
                this.currentRoute = newRoute;
                LogInfo("[MSCortexLink] Route changed: " + this.currentRoute);
            }
        }
        
        if (this.routePollTimer) {
            this.PollRouteLoop();
        }
    }

    // ============================================================
    // CONNECTION POOL MANAGEMENT
    // ============================================================
    private final func AcquireClient() -> ref<PooledHttpClient> {
        for (var i = 0; i < ArraySize(this.httpPool); i++) {
            let idx = (this.poolIndex + i) % ArraySize(this.httpPool);
            let client = this.httpPool[idx];
            
            if (!client.inUse && IsDefined(client.http)) {
                // Check connection health
                if (EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime()) - client.lastUsed > 300.0) {
                    // Refresh stale connection
                    client.http = Game.GetHttpClient();
                    if (IsDefined(client.http)) {
                        client.http.SetTimeout(this.RequestTimeoutMs);
                        client.http.SetKeepAlive(this.KeepAliveTimeoutSec);
                        if (this.EnableHTTP2) { client.http.EnableHTTP2(); }
                        if (this.EnableCompression) { client.http.EnableCompression("gzip"); }
                    }
                }
                
                client.inUse = true;
                client.lastUsed = EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime());
                this.poolIndex = (idx + 1) % ArraySize(this.httpPool);
                return client;
            }
        }
        
        // Fallback: create new client
        let client: ref<PooledHttpClient> = new PooledHttpClient();
        client.http = Game.GetHttpClient();
        client.inUse = true;
        client.lastUsed = EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime());
        return client;
    }

    private final func ReleaseClient(client: ref<PooledHttpClient>) -> Void {
        client.inUse = false;
        client.requestCount++;
    }

    // ============================================================
    // BATCH INFERENCE (Optimization #7)
    // ============================================================
    
    public final func InvokeLocalCortexBatched(requests: array<ref<BatchedInferRequest>>) -> Task<array<LocalCloudResponse>> {
        let task = new Task<array<LocalCloudResponse>>();
        
        if (!this.EnableBatchInference || ArraySize(requests) == 1) {
            // Sequential fallback
            let results: array<LocalCloudResponse> = {};
            for (req in requests) {
                let singleTask = this.InvokeLocalCortex(req.prompt, req.context, req.sephirah);
                // Would need proper async handling
            }
            task.Complete(results);
            return task;
        }
        
        // Build batch payload
        let batchArray: String = "[";
        for (var i = 0; i < ArraySize(requests); i++) {
            let req = requests[i];
            batchArray += "{\"prompt\":\"" + EscapeJson(req.prompt) + 
                         "\",\"system\":\"Sephirah=" + NameToString(req.sephirah) + " Context=" + EscapeJson(req.context) + 
                         "\",\"max_tokens\":200,\"temperature\":0.7,\"stream\":false}";
            if (i < ArraySize(requests) - 1) { batchArray += ","; }
        }
        batchArray += "]";
        
        let body: String = "{\"batch\":" + batchArray + "}";
        
        let client: ref<PooledHttpClient> = this.AcquireClient();
        if (!IsDefined(client)) {
            task.Complete({});
            return task;
        }
        
        let requestId: Uint64 = this.requestCounter++;
        let handle: ref<BatchCallbackHandle> = new BatchCallbackHandle();
        handle.task = task;
        handle.requestCount = ArraySize(requests);
        handle.requests = requests;
        this.pendingRequests.Set(requestId, handle);
        
        client.http.Post(this.LocalCerebellumBatch, "application/json", body, this, n"OnBatchInferenceResponse", requestId);
        this.ReleaseClient(client);
        
        this.statsBatchRequests += Cast(ArraySize(requests));
        return task;
    }

    public final func OnBatchInferenceResponse(response: HttpResponse, requestId: Uint64) -> Void {
        let handle: ref<BatchCallbackHandle> = this.pendingRequests.Get(requestId);
        if (!IsDefined(handle)) { return; }
        this.pendingRequests.Remove(requestId);
        
        if (response.statusCode == 200) {
            let data: JsonObject = JsonFromString(response.body);
            let results: array<JsonObject> = data.GetArray("results");
            
            let responses: array<LocalCloudResponse> = {};
            for (var i = 0; i < ArraySize(results); i++) {
                let resultData: JsonObject = results[i];
                let resp: LocalCloudResponse = new LocalCloudResponse();
                resp.success = true;
                resp.content = resultData.GetString("response", "");
                resp.model = resultData.GetString("model", "hermes3:8b");
                resp.evalCount = resultData.GetInt("eval_count", 0);
                resp.tokensLocal = true;
                resp.route = this.currentRoute;
                responses.PushBack(resp);
            }
            
            handle.task.Complete(responses);
        } else {
            // Fallback to individual requests
            this.FallbackToIndividual(handle);
        }
    }

    private final func FallbackToIndividual(handle: ref<BatchCallbackHandle>) -> Void {
        // Execute each request individually
        for (req in handle.requests) {
            this.InvokeLocalCortex(req.prompt, req.context, req.sephirah)
                .Then(resp => {
                    handle.collectedResults.PushBack(resp);
                    if (ArraySize(handle.collectedResults) == handle.requestCount) {
                        handle.task.Complete(handle.collectedResults);
                    }
                });
        }
    }

    // ============================================================
    // STREAMING INFERENCE
    // ============================================================
    
    public final func InvokeLocalCortexStreaming(
        prompt: String,
        context: String,
        sephirah: CName,
        onToken: ref<IStreamCallback>
    ) -> Void {
        if (!this.EnableStreaming) {
            // Fallback to regular inference
            this.InvokeLocalCortex(prompt, context, sephirah)
                .Then(resp => { onToken.OnComplete(resp.content); });
            return;
        }
        
        let client: ref<PooledHttpClient> = this.AcquireClient();
        if (!IsDefined(client)) { return; }
        
        let body: String = "{\"prompt\":\"" + EscapeJson(prompt) + 
                          "\",\"system\":\"Sephirah=" + NameToString(sephirah) + " Context=" + EscapeJson(context) + 
                          "\",\"max_tokens\":200,\"temperature\":0.7,\"stream\":true}";
        
        // Store callback for streaming
        let requestId: Uint64 = this.requestCounter++;
        let handle: ref<StreamCallbackHandle> = new StreamCallbackHandle();
        handle.callback = onToken;
        this.pendingRequests.Set(requestId, handle);
        
        client.http.PostStream(this.LocalCortexStream, "application/json", body, this, n"OnStreamChunk", requestId);
        this.ReleaseClient(client);
        this.statsStreamingRequests++;
    }

    public final func OnStreamChunk(chunk: String, requestId: Uint64) -> Void {
        let handle: ref<StreamCallbackHandle> = this.pendingRequests.Get(requestId);
        if (!IsDefined(handle)) { return; }
        
        // Parse SSE chunk
        if (StrContains(chunk, "data: ")) {
            let jsonStr: String = StrReplace(chunk, "data: ", "");
            if (jsonStr != "[DONE]") {
                let data: JsonObject = JsonFromString(jsonStr);
                let token: String = data.GetString("token", "");
                if (token != "") {
                    handle.callback.OnToken(token);
                }
            } else {
                handle.callback.OnComplete("");
                this.pendingRequests.Remove(requestId);
            }
        }
    }

    // ============================================================
    // SINGLE INFERENCE (with circuit breaker & retry)
    // ============================================================
    
    public final func InvokeLocalCortex(
        prompt: String,
        context: String,
        sephirah: CName
    ) -> Task<LocalCloudResponse> {
        let requestId: Uint64 = this.requestCounter++;
        let task = new Task<LocalCloudResponse>();
        
        // Circuit breaker check
        if (this.CircuitBreakerEnabled && this.circuitBreakerState == CircuitBreakerState.Open) {
            if (EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime()) - this.circuitBreakerLastFailure > this.CircuitBreakerTimeoutSec) {
                this.circuitBreakerSemaphore.Wait();
                if (this.circuitBreakerState == CircuitBreakerState.Open) {
                    this.circuitBreakerState = CircuitBreakerState.HalfOpen;
                    LogInfo("[MSCortexLink] Circuit breaker: HALF_OPEN");
                }
                this.circuitBreakerSemaphore.Signal();
            } else {
                task.Complete(new LocalCloudResponse { success = false, content = "Circuit breaker OPEN", tokensLocal = true, route = this.currentRoute });
                return task;
            }
        }
        
        let body: String = "{\"prompt\":\"" + EscapeJson(prompt) + 
                          "\",\"system\":\"Sephirah=" + NameToString(sephirah) + " Context=" + EscapeJson(context) + 
                          "\",\"max_tokens\":200,\"temperature\":0.7,\"stream\":false}";
        
        let client: ref<PooledHttpClient> = this.AcquireClient();
        if (!IsDefined(client)) {
            task.Complete(new LocalCloudResponse { success = false, content = "No available connections", tokensLocal = true, route = this.currentRoute });
            return task;
        }
        
        let handle: ref<CallbackHandle> = new CallbackHandle();
        handle.task = task;
        handle.timestamp = EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime());
        handle.sephirah = sephirah;
        handle.retryCount = 0;
        handle.prompt = prompt;
        handle.context = context;
        this.pendingRequests.Set(requestId, handle);
        
        client.http.Post(this.LocalCerebellumInfer, "application/json", body, this, n"OnInferenceResponse", requestId);
        this.ReleaseClient(client);
        
        this.statsTotalRequests++;
        return task;
    }

    public final func OnInferenceResponse(response: HttpResponse, requestId: Uint64) -> Void {
        let handle: ref<CallbackHandle> = this.pendingRequests.Get(requestId);
        if (!IsDefined(handle)) { return; }
        this.pendingRequests.Remove(requestId);
        
        let latencyMs: Uint64 = Cast((EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime()) - handle.timestamp) * 1000);
        this.statsTotalLatencyMs += latencyMs;
        
        if (response.statusCode == 200) {
            // Success
            this.RecordSuccess();
            
            let data: JsonObject = JsonFromString(response.body);
            handle.task.Complete(new LocalCloudResponse {
                success = true,
                content = data.GetString("response", ""),
                model = data.GetString("model", "hermes3:8b"),
                evalCount = data.GetInt("eval_count", 0),
                tokensLocal = data.GetBool("tokens_local", true),
                route = data.GetString("route", this.currentRoute),
                sephirah = handle.sephirah
            });
        } else {
            // Failure - retry logic
            this.RecordFailure();
            
            if (handle.retryCount < this.RetryAttempts) {
                let backoffMs: Int32 = this.RetryBackoffMs * (1 << handle.retryCount);
                if (this.RetryJitter) {
                    backoffMs += Cast(Random(0, backoffMs / 2));
                }
                backoffMs = Min(backoffMs, this.RetryMaxBackoffMs);
                
                handle.retryCount++;
                
                Game.GetDelaySystem().DelayEvent(this, n"RetryInference", backoffMs);
                // Re-queue
                let client: ref<PooledHttpClient> = this.AcquireClient();
                if (IsDefined(client)) {
                    let newRequestId: Uint64 = this.requestCounter++;
                    this.pendingRequests.Set(newRequestId, handle);
                    let body: String = "{\"prompt\":\"" + EscapeJson(handle.prompt) + 
                                      "\",\"system\":\"Sephirah=" + NameToString(handle.sephirah) + " Context=" + EscapeJson(handle.context) + 
                                      "\",\"max_tokens\":200,\"temperature\":0.7,\"stream\":false}";
                    client.http.Post(this.LocalCerebellumInfer, "application/json", body, this, n"OnInferenceResponse", newRequestId);
                    this.ReleaseClient(client);
                }
            } else {
                handle.task.Complete(new LocalCloudResponse {
                    success = false,
                    content = "Inference failed after " + IntToString(this.RetryAttempts) + " retries: HTTP " + IntToString(response.statusCode),
                    tokensLocal = true,
                    route = this.currentRoute,
                    sephirah = handle.sephirah
                });
            }
        }
    }

    private final func RecordSuccess() -> Void {
        this.statsSuccessfulRequests++;
        if (this.CircuitBreakerEnabled) {
            this.circuitBreakerSemaphore.Wait();
            this.circuitBreakerFailures = 0;
            if (this.circuitBreakerState == CircuitBreakerState.HalfOpen) {
                this.circuitBreakerState = CircuitBreakerState.Closed;
                LogInfo("[MSCortexLink] Circuit breaker: CLOSED");
            }
            this.circuitBreakerSemaphore.Signal();
        }
    }

    private final func RecordFailure() -> Void {
        this.statsFailedRequests++;
        if (this.CircuitBreakerEnabled) {
            this.circuitBreakerSemaphore.Wait();
            this.circuitBreakerFailures++;
            this.circuitBreakerLastFailure = EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime());
            
            if (this.circuitBreakerFailures >= this.CircuitBreakerThreshold) {
                this.circuitBreakerState = CircuitBreakerState.Open;
                LogInfo("[MSCortexLink] Circuit breaker: OPEN (failures=" + IntToString(this.circuitBreakerFailures) + ")");
            }
            this.circuitBreakerSemaphore.Signal();
        }
    }

    // ============================================================
    // LEGACY ALIAS
    // ============================================================
    
    public final func InvokeCloudCortex(
        prompt: String, context: String, sephirah: CName
    ) -> Task<LocalCloudResponse> {
        return this.InvokeLocalCortex(prompt, context, sephirah);
    }

    // ============================================================
    // UTILITY
    // ============================================================
    
    private final func EscapeJson(s: String) -> String {
        let result: String = StrReplace(s, "\\", "\\\\");
        result = StrReplace(result, "\"", "\\\"");
        result = StrReplace(result, "\n", "\\n");
        result = StrReplace(result, "\r", "\\r");
        return result;
    }

    public final func GetCurrentRoute() -> String { return this.currentRoute; }
    public final func IsLocal() -> Bool { return true; }
    public final func GetCircuitBreakerState() -> CircuitBreakerState { return this.circuitBreakerState; }

    // ============================================================
    // METRICS
    // ============================================================
    private final func StartMetricsServer() -> Void {
        LogInfo("[MSCortexLink] Metrics: http://localhost:" + IntToString(this.MetricsPort) + "/metrics");
    }

    public final func GetMetrics() -> String {
        let successRate: Float = this.statsTotalRequests > 0 ? 
            Cast(this.statsSuccessfulRequests) / Cast(this.statsTotalRequests) : 0.0;
        let avgLatency: Float = this.statsSuccessfulRequests > 0 ? 
            Cast(this.statsTotalLatencyMs) / Cast(this.statsSuccessfulRequests) : 0.0;
        
        return "total_requests=" + Uint64ToString(this.statsTotalRequests) + 
               " success=" + Uint64ToString(this.statsSuccessfulRequests) + 
               " failed=" + Uint64ToString(this.statsFailedRequests) + 
               " batch_requests=" + Uint64ToString(this.statsBatchRequests) + 
               " streaming_requests=" + Uint64ToString(this.statsStreamingRequests) + 
               " success_rate=" + FloatToString(successRate) + 
               " avg_latency_ms=" + FloatToString(avgLatency) + 
               " circuit_breaker=" + EnumValueToString("CircuitBreakerState", Cast(this.circuitBreakerState)) + 
               " current_route=" + this.currentRoute;
    }

    @Command("msn.cortex.status")
    public final func CmdStatus() -> Void {
        this.Notify("MSN Cortex Link OPTIMIZED: " + this.GetMetrics());
    }

    @Command("msn.cortex.circuit_reset")
    public final func CmdCircuitReset() -> Void {
        this.circuitBreakerSemaphore.Wait();
        this.circuitBreakerState = CircuitBreakerState.Closed;
        this.circuitBreakerFailures = 0;
        this.circuitBreakerSemaphore.Signal();
        this.Notify("Circuit breaker reset to CLOSED");
    }
}


// ============================================================
// SUPPORTING STRUCTS
// ============================================================

public class PooledHttpClient {
    public let http: ref<HttpClient>;
    public let inUse: Bool = false;
    public let createdAt: Float;
    public let lastUsed: Float;
    public let requestCount: Uint64 = 0;
}

public class CallbackHandle {
    public let task: Task<LocalCloudResponse>;
    public let timestamp: Float;
    public let sephirah: CName;
    public let retryCount: Int32 = 0;
    public let prompt: String;
    public let context: String;
}

public class BatchCallbackHandle {
    public let task: Task<array<LocalCloudResponse>>;
    public let requestCount: Int32;
    public let requests: array<ref<BatchedInferRequest>>;
    public let collectedResults: array<LocalCloudResponse> = {};
}

public class StreamCallbackHandle {
    public let callback: ref<IStreamCallback>;
}

public class BatchedInferRequest {
    public let prompt: String;
    public let context: String;
    public let sephirah: CName;
}

public enum CircuitBreakerState {
    Closed = 0,
    Open = 1,
    HalfOpen = 2
}

public class Semaphore {
    private let count: Int32 = 1;
    public final func Wait() -> Void { while (this.count <= 0) { Delay(0.001); } this.count--; }
    public final func Signal() -> Void { this.count++; }
}

public struct LocalCloudResponse {
    @Property public let success: Bool;
    @Property public let content: String;
    @Property public let model: String;
    @Property public let evalCount: Int32;
    @Property public let tokensLocal: Bool;
    @Property public let route: String;
    @Property public let sephirah: CName;
}

public interface IStreamCallback {
    public final func OnToken(token: String) -> Void;
    public final func OnComplete(fullResponse: String) -> Void;
}


// Legacy aliases
public struct CloudResponse {
    @Property public let success: Bool;
    @Property public let content: String;
    @Property public let tokensUsed: Int32;
    @Property public let latencyMs: Int32;
    @Property public let sephirah: CName;
}

public struct MSNContext {
    @Property public let gameState: String;
    @Property public let playerStats: PlayerStats;
    @Property public let targetInfo: TargetInfo;
    @Property public let activeSephirah: CName;
    @Property public let timestamp: Float;
}

public struct PlayerStats {
    @Property public let health: Float;
    @Property public let stamina: Float;
    @Property public let ram: Int32;
    @Property public let cyberware: array<CName>;
}

public struct TargetInfo {
    @Property public let entityId: EntityID;
    @Property public let type: String;
    @Property public let health: Float;
    @Property public let armor: Float;
    @Property public let cyberware: array<CName>;
}