// Lilith NGD Integration - Frame Pacing & DLSS Control
// File: r6/mods/msn_integration/scripts/lilith_ngd_control.reds

public class LilithNGDControl extends IScriptable {
    private static let instance: ref<LilithNGDControl>;
    private let ngdStatus: NGDStatus;
    private let framePacingActive: Bool;
    private let dlssMode: String;
    private let fpsCap: Int32;
    private let lastOptimization: Float;
    
    public final static func GetInstance() -> ref<LilithNGDControl> {
        if (!IsDefined(LilithNGDControl.instance)) {
            LilithNGDControl.instance = new LilithNGDControl();
            LilithNGDControl.instance.Initialize();
        }
        return LilithNGDControl.instance;
    }
    
    private final func Initialize() -> Void {
        this.framePacingActive = false;
        this.dlssMode = "Quality";
        this.fpsCap = 60;
        this.lastOptimization = 0.0;
        
        // Register for NGD telemetry updates
        let ngd: ref<NGDSystem> = Game.GetNGDSystem();
        if (IsDefined(ngd)) {
            ngd.RegisterListener(this, n"OnNGDTelemetryUpdate");
        }
        
        LogInfo("Lilith NGD Control initialized - Frame pacing & DLSS management active");
    }
    
    // ============================================================
    // CONSOLE COMMANDS
    // ============================================================
    
    [ConsoleCommand("msn.framepacing.enable", "Enable frame pacing with FPS cap")]
    public static final func Cmd_EnableFramePacing(args: array<String>) -> Void {
        let self: ref<LilithNGDControl> = LilithNGDControl.GetInstance();
        let cap: Int32 = ArraySize(args) > 0 ? ToInt(args[0]) : 58;
        self.EnableFramePacing(cap);
    }
    
    [ConsoleCommand("msn.framepacing.disable", "Disable frame pacing")]
    public static final func Cmd_DisableFramePacing(args: array<String>) -> Void {
        let self: ref<LilithNGDControl> = LilithNGDControl.GetInstance();
        self.DisableFramePacing();
    }
    
    [ConsoleCommand("msn.dlss.set", "Set DLSS quality mode (quality/balanced/performance/ultra_performance)")]
    public static final func Cmd_SetDLSS(args: array<String>) -> Void {
        let self: ref<LilithNGDControl> = LilithNGDControl.GetInstance();
        if (ArraySize(args) > 0) {
            self.SetDLSSMode(args[0]);
        } else {
            LogError("Usage: msn.dlss.set <quality|balanced|performance|ultra_performance>");
        }
    }
    
    [ConsoleCommand("msn.optimize.auto", "Run automatic optimization based on current telemetry")]
    public static final func Cmd_AutoOptimize(args: array<String>) -> Void {
        let self: ref<LilithNGDControl> = LilithNGDControl.GetInstance();
        self.RunAutoOptimization();
    }
    
    [ConsoleCommand("msn.ngd.status", "Show NGD status and recommendations")]
    public static final func Cmd_NGDStatus(args: array<String>) -> Void {
        let self: ref<LilithNGDControl> = LilithNGDControl.GetInstance();
        self.PrintNGDStatus();
    }
    
    // ============================================================
    // FRAME PACING
    // ============================================================
    
    public final func EnableFramePacing(fpsCap: Int32) -> Void {
        this.fpsCap = fpsCap;
        this.framePacingActive = true;
        
        // Apply FPS cap via game settings
        let settingsSystem: ref<SettingsSystem> = Game.GetSettingsSystem();
        if (IsDefined(settingsSystem)) {
            settingsSystem.SetVar("Graphics.FPSCap", fpsCap, "Int32");
            settingsSystem.SetVar("Graphics.FramePacing", true, "Bool");
            settingsSystem.SetVar("Graphics.VSync", false, "Bool"); // Disable vsync when frame pacing is active
            LogInfo("Frame pacing ENABLED - FPS capped at " + ToString(fpsCap));
        }
        
        // Notify coordination server
        let ws: ref<WebSocketClient> = Game.GetWebSocketClient();
        if (IsDefined(ws)) {
            let data: JsonValue = JsonValue();
            data.Set("type", "frame_pacing");
            data.Set("enabled", true);
            data.Set("fps_cap", fpsCap);
            ws.Send(data);
        }
    }
    
    public final func DisableFramePacing() -> Void {
        this.framePacingActive = false;
        
        let settingsSystem: ref<SettingsSystem> = Game.GetSettingsSystem();
        if (IsDefined(settingsSystem)) {
            settingsSystem.SetVar("Graphics.FramePacing", false, "Bool");
            settingsSystem.SetVar("Graphics.VSync", true, "Bool"); // Re-enable vsync
            LogInfo("Frame pacing DISABLED - VSync restored");
        }
        
        let ws: ref<WebSocketClient> = Game.GetWebSocketClient();
        if (IsDefined(ws)) {
            let data: JsonValue = JsonValue();
            data.Set("type", "frame_pacing");
            data.Set("enabled", false);
            ws.Send(data);
        }
    }
    
    // ============================================================
    // DLSS QUALITY CONTROL
    // ============================================================
    
    public final func SetDLSSMode(mode: String) -> Void {
        let validModes: array<String> = ["quality", "balanced", "performance", "ultra_performance", "auto"];
        let modeLower: String = mode.ToLower();
        
        if (!ArrayContains(validModes, modeLower)) {
            LogError("Invalid DLSS mode. Valid: quality, balanced, performance, ultra_performance, auto");
            return;
        }
        
        this.dlssMode = modeLower;
        
        let settingsSystem: ref<SettingsSystem> = Game.GetSettingsSystem();
        if (IsDefined(settingsSystem)) {
            settingsSystem.SetVar("Graphics.DLSSMode", modeLower, "String");
            LogInfo("DLSS mode set to: " + modeLower);
        }
        
        let ws: ref<WebSocketClient> = Game.GetWebSocketClient();
        if (IsDefined(ws)) {
            let data: JsonValue = JsonValue();
            data.Set("type", "dlss_mode");
            data.Set("mode", modeLower);
            ws.Send(data);
        }
    }
    
    // ============================================================
    // AUTO OPTIMIZATION
    // ============================================================
    
    public final func RunAutoOptimization() -> Void {
        let ngd: ref<NGDSystem> = Game.GetNGDSystem();
        if (!IsDefined(ngd)) {
            LogError("NGD System not available");
            return;
        }
        
        let status: NGDStatus = ngd.GetStatus();
        let telemetry: GameTelemetry = ngd.GetGameTelemetry();
        
        if (!IsDefined(status) || !IsDefined(telemetry)) {
            LogError("No telemetry available");
            return;
        }
        
        let vramFree: Float = status.vram_free_mb;
        let gpuUtil: Float = telemetry.gpu_util_percent;
        let fps: Float = telemetry.fps;
        let temp: Float = telemetry.gpu_temp_c;
        
        LogInfo("Running auto-optimization: VRAM=" + ToString(vramFree) + "MB free, GPU=" + ToString(gpuUtil) + "%, FPS=" + ToString(fps) + ", Temp=" + ToString(temp) + "°C");
        
        // VRAM optimization
        if (vramFree < 500.0) {
            LogInfo("CRITICAL: VRAM critical - " + ToString(vramFree) + "MB free");
            this.SetDLSSMode("performance");
            this.EnableFramePacing(55);
            LogInfo("Applied: DLSS Performance + Frame Pacing @ 55 FPS");
        } else if (vramFree < 1000.0) {
            LogInfo("WARNING: VRAM low - " + ToString(vramFree) + "MB free");
            this.SetDLSSMode("balanced");
            if (!this.framePacingActive) {
                this.EnableFramePacing(58);
            }
            LogInfo("Applied: DLSS Balanced + Frame Pacing @ 58 FPS");
        } else if (vramFree > 3000.0 && fps > 70.0) {
            LogInfo("VRAM healthy - " + ToString(vramFree) + "MB free, FPS headroom available");
            if (this.dlssMode != "quality" && this.dlssMode != "auto") {
                this.SetDLSSMode("quality");
                LogInfo("Applied: DLSS Quality");
            }
            if (this.framePacingActive) {
                this.DisableFramePacing();
                LogInfo("Applied: Frame pacing disabled");
            }
        }
        
        // GPU utilization
        if (gpuUtil > 95.0) {
            LogInfo("GPU maxed - " + ToString(gpuUtil) + "%");
            if (!this.framePacingActive) {
                this.EnableFramePacing(55);
            } else if (this.fpsCap > 55) {
                this.EnableFramePacing(55);
            }
        }
        
        // Thermal
        if (temp > 80.0) {
            LogInfo("THERMAL WARNING - " + ToString(temp) + "°C");
            this.EnableFramePacing(50);
            this.SetDLSSMode("performance");
        }
        
        // FPS
        if (fps < 50.0) {
            LogInfo("FPS low - " + ToString(fps));
            this.SetDLSSMode("performance");
            this.EnableFramePacing(55);
        }
        
        this.lastOptimization = EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime());
        LogInfo("Auto-optimization complete");
    }
    
    // ============================================================
    // NGD TELEMETRY LISTENER
    // ============================================================
    
    public final func OnNGDTelemetryUpdate(telemetry: NGDTelemetry) -> Void {
        // Only run auto-optimization every 30 seconds
        let now: Float = EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime());
        if (now - this.lastOptimization > 30.0) {
            this.RunAutoOptimization();
        }
    }
    
    // ============================================================
    // STATUS REPORTING
    // ============================================================
    
    public final func PrintNGDStatus() -> Void {
        let ngd: ref<NGDSystem> = Game.GetNGDSystem();
        if (!IsDefined(ngd)) {
            LogError("NGD System not available");
            return;
        }
        
        let status: NGDStatus = ngd.GetStatus();
        let telemetry: GameTelemetry = ngd.GetGameTelemetry();
        
        LogInfo("=== NGD / LILITH STATUS ===");
        LogInfo("Route: " + status.route);
        LogInfo("VRAM: " + ToString(status.vram_free_mb) + "MB free / " + ToString(status.vram_used_mb) + "MB used");
        LogInfo("Smoothed VRAM: " + ToString(status.smoothed_vram_free_mb) + "MB");
        LogInfo("Cooldown: " + (status.cooldown_active ? "ACTIVE (" + ToString(status.cooldown_remaining) + "s)" : "INACTIVE"));
        LogInfo("");
        LogInfo("GPU: " + ToString(telemetry.gpu_util_percent) + "% util | " + ToString(telemetry.gpu_temp_c) + "°C | " + ToString(telemetry.gpu_power_w) + "W");
        LogInfo("VRAM: " + ToString(telemetry.gpu_vram_mb) + "MB used");
        LogInfo("Game: " + ToString(telemetry.fps) + " FPS | DLSS: " + telemetry.dlss_mode);
        LogInfo("");
        LogInfo("Frame Pacing: " + (this.framePacingActive ? "ENABLED (cap: " + ToString(this.fpsCap) + " FPS)" : "DISABLED"));
        LogInfo("DLSS Mode: " + this.dlssMode);
    }
}

// ============================================================
// DATA STRUCTURES
// ============================================================

struct NGDStatus {
    route: String;
    vram_free_mb: Float;
    vram_used_mb: Float;
    smoothed_vram_free_mb: Float;
    cooldown_active: Bool;
    cooldown_remaining: Float;
    gpu_temp_c: Float;
    gpu_util_pct: Float;
}

struct NGDTelemetry {
    frame_time_ms: Float;
    fps: Float;
    gpu_vram_mb: Float;
    gpu_util_percent: Float;
    gpu_temp_c: Float;
    gpu_power_w: Float;
    dlss_mode: String;
    fsr_mode: String;
}

struct GameTelemetry {
    pid: Int32;
    cpu_percent: Float;
    memory_mb: Float;
    gpu_vram_mb: Float;
    gpu_util_percent: Float;
    gpu_temp_c: Float;
    gpu_power_w: Float;
    frame_time_ms: Float;
    fps: Float;
    dlss_mode: String;
    fsr_mode: String;
}