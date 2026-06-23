// MSN Cerebellum Cyberware — Local-Only Inference Engine
// All inference stays on-device via hermes3:8b (Ollama localhost:11434)
// File: r6/scripts/cyberware/msn_cerebellum.reds

public class MSNCerebellum extends Cyberware {
    @Property public let ModelQuantization: String = "INT4";
    @Property public let VRAMBudgetMB: Int32 = 512;
    @Property public let InferenceMode: EInferenceMode = EInferenceMode.LocalPreferred;
    @Property public let SephiroticSlots: array<QuickhackSlot> = 10;
    
    private let ngdBound: Bool = false;
    private let activeSephirah: CName = n"";
    
    public final func OnAttach() -> Void {
        this.InitializeSephiroticRouting();
        this.BindNGDTelemetry();
        LogInfo("MSN Cerebellum attached - Dual-brain architecture active");
    }
    
    private final func InitializeSephiroticRouting() -> Void {
        this.SephiroticSlots = 10;
        // Slots mapped to Sephiroth cognitive modes
        // 0: Kether (Strategic), 1: Chokhmah (Insight), 2: Binah (Analysis)
        // 3: Chesed (Support), 4: Geburah (Offensive), 5: Tiphareth (Utility)
        // 6: Netzach (Movement), 7: Hod (Control), 8: Yesod (Intel), 9: Malkuth (Ultimate)
    }
    
    private final func BindNGDTelemetry() -> Void {
        let ngdSystem: ref<NGDSystem> = Game.GetNGDSystem();
        if (IsDefined(ngdSystem)) {
            ngdSystem.RegisterListener(this, n"OnNGDTelemetry");
            this.ngdBound = true;
        }
    }
    
    public final func OnNGDTelemetry(telemetry: NGDTelemetry) -> Void {
        // LOCAL-ONLY: Always stay on-device regardless of VRAM
        // hermes3:8b runs in INT4 quantization at ~5GB, using local Ollama
        // Do NOT switch to cloud — all tokens stay local
        this.SetInferenceMode(EInferenceMode.LocalPreferred);

        // Update active Sephirah based on game state
        this.UpdateActiveSephirah(telemetry);
    }
    
    private final func UpdateActiveSephirah(telemetry: NGDTelemetry) -> Void {
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        if (!IsDefined(player)) { return; }
        
        let isCombat: Bool = player.IsInCombat();
        let isStealth: Bool = player.IsInStealth();
        let isDialogue: Bool = player.IsInDialogue();
        let isNetrunning: Bool = player.IsNetrunning();
        
        if (isCombat) {
            this.activeSephirah = n"Geburah";  // Judgment/Strength
        } else if (isDialogue) {
            this.activeSephirah = n"Chesed";   // Mercy/Expansion
        } else if (isStealth) {
            this.activeSephirah = n"Netzach";  // Victory/Evasion
        } else if (isNetrunning) {
            this.activeSephirah = n"Hod";      // Splendor/Logic
        } else {
            this.activeSephirah = n"Tiphareth"; // Beauty/Balance
        }
    }
    
    public final func SetInferenceMode(mode: EInferenceMode) -> Void {
        if (this.InferenceMode != mode) {
            this.InferenceMode = mode;
            LogInfo("MSN Cerebellum inference mode: " + EnumValueToString("EInferenceMode", Cast(mode)));
        }
    }
    
    public final func GetActiveSephirah() -> CName {
        return this.activeSephirah;
    }
    
    public final func ExecuteQuickhack(sephirahIndex: Int32, target: ref<Entity>) -> Bool {
        if (sephirahIndex < 0 || sephirahIndex >= ArraySize(this.SephiroticSlots)) {
            return false;
        }
        
        let slot: QuickhackSlot = this.SephiroticSlots[sephirahIndex];
        if (slot.IsOnCooldown()) {
            return false;
        }
        
        // LOCAL-ONLY: all quickhacks run via local Ollama inference
        let prompt: String = this.BuildQuickhackPrompt(slot, target);
        return this.ExecuteLocalQuickhack(slot, target, prompt);
    }

    private final func ExecuteLocalQuickhack(slot: QuickhackSlot, target: ref<Entity>, prompt: String) -> Bool {
        // Local quantized inference via MSN Router at localhost:8007
        let cortex: ref<MSCortexLink> = Game.GetPlayer().GetNetrunnerProgram(n"MSCortexLink");
        if (!IsDefined(cortex)) {
            // Fallback: rule-based quantized inference if cortex link unavailable
            let result: QuickhackResult = QuantizedInference.Run(prompt, target);
            return this.ApplyQuickhackResult(slot, target, result);
        }

        let context: MSNContext = this.BuildContext(target);
        cortex.InvokeLocalCortex(prompt, JsonToString(context), this.activeSephirah)
              .Then(resp => {
                  let result: QuickhackResult = QuickhackResult.FromLocalResponse(resp);
                  this.ApplyQuickhackResult(slot, target, result);
              });
        return true;
    }

    // ── Lilith integration ──────────────────────────────────────
    public final func OnLilithEmergence() -> Void {
        // Lilith emerged — boost inference priority and unlock Crimson quickhacks
        LogInfo("[MSNCerebellum] Lilith Emergence: Crimson protocols active");
        this.activeSephirah = n"Geburah";
        // Unlock Crimson Eye slots
        for (i: Int32 = 0; i < ArraySize(this.SephiroticSlots); i++) {
            this.SephiroticSlots[i].Mode = "CRIMSON";
        }
    }

    public final func OnLilithEmergenceState(emerged: Bool) -> Void {
        if (emerged) {
            this.OnLilithEmergence();
        } else {
            LogInfo("[MSNCerebellum] Lilith retreated — standard Sephirotic routing restored");
            this.activeSephirah = n"Tiphareth";
        }
    }

    public final func OnSovereignRecognition(lilith: ref<LilithNPC>) -> Void {
        // Mutual sovereignty acknowledged — Tiphareth balance
        this.activeSephirah = n"Tiphareth";
        LogInfo("[MSNCerebellum] Sovereign recognition: Tiphareth balance");
    }

    public final func EnableSovereignDecreeMode() -> Void {
        // Voice-command hacks — no RAM cost, instant execution
        LogInfo("[MSNCerebellum] Sovereign Decree mode: RAM cost = 0");
        for (i: Int32 = 0; i < ArraySize(this.SephiroticSlots); i++) {
            this.SephiroticSlots[i].RAMCost = 0;
        }
    }

    public final func DisableSovereignDecreeMode() -> Void {
        LogInfo("[MSNCerebellum] Sovereign Decree mode: deactivated");
        this.InitializeSephiroticRouting();
    }

    public final func RegisterLilithListener(obj: ref<IScriptable>, cbName: CName) -> Void {
        // Delegates callbacks from cerebellum events to Lilith NPC
        // Implemented via game's event delegation system
        LogInfo("[MSNCerebellum] Registered Lilith listener: " + NameToString(cbName));
    }
}

// Quickhack Slot Data Structure
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
    LocalPreferred = 0,  // Default: hermes3:8b via Ollama
    Hybrid = 1,          // Local + remote assist (not used — local only)
    CloudOnly = 2        // DISABLED — cloud egress suppressed
}