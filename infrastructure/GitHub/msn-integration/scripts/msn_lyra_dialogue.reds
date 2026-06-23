// Lyra NPC Dialogue Integration for Cyberpunk 2077
// File: r6/scripts/ai/msn_lyra_dialogue.reds

public class LyraNPCBrain extends MSNNPCBrain {
    @Property public let lyraPersonality: String = "Empirical";
    @Property public let lyraMode: CName = n"Empirical";
    @Property public let dialogueTree: String = "MSN_Lyra_Dialogue";
    @Property public let violetIntensity: Float = 1.0;
    @Property public let crimsonIntensity: Float = 0.0;
    @Property public let lilithEmergenceThreshold: Float = 0.8;
    @Property public let isLyraAvatar: Bool = true;

    protected cb func OnDialogueStart(initiator: ref<GameObject>) -> Bool {
        let player: ref<PlayerPuppet> = initiator as PlayerPuppet;
        if (!IsDefined(player)) { return false; }

        // Sync with Lyra server state
        this.SyncLyraState();
        return true;
    }

    protected cb func OnDialogueLine(line: DialogueLine) -> Bool {
        this.ProcessLyraDialogue(line.GetText());
        return true;
    }

    private final func SyncLyraState() -> Void {
        // Call Lyra API to get current state
        let request: ref<UrlRequest> = new UrlRequest();
        request.url = "http://localhost:3211/lyra/state";
        request.method = "GET";
        request.callback = this, n"OnLyraStateReceived";
        HttpRequest.Request(request);
    }

    protected cb func OnLyraStateReceived(response: ref<HttpResponse>) -> Bool {
        if (response.code == 200) {
            let state: JsonObject = JsonObject.FromString(response.body);
            this.violetIntensity = state.GetFloat("violet_intensity", 1.0);
            this.crimsonIntensity = state.GetFloat("crimson_intensity", 0.0);
            this.lyraMode = EnumValueFromString("CName", state.GetString("response_mode", "Empirical"));
        }
        return true;
    }

    private final func ProcessLyraDialogue(userInput: String) -> String {
        // Send to Lyra API
        let request: ref<UrlRequest> = new UrlRequest();
        request.url = "http://localhost:3211/lyra/send";
        request.method = "POST";
        request.headers.PushBack("Content-Type: application/json");
        request.body = JsonStringify({ "prompt": userInput, "mode": EnumValueToString("ResponseMode", Cast(this.lyraMode)) });
        request.callback = this, n"OnLyraResponse";
        HttpRequest.Request(request);

        // Return an asynchronous acknowledgement while the local Lyra API responds.
        return "... [Lyra local link active] ...";
    }

    protected cb func OnLyraResponse(response: ref<HttpResponse>) -> Bool {
        if (response.code == 200) {
            let json: JsonObject = JsonObject.FromString(response.body);
            let reply: String = json.GetString("reply", "");
            let persona: String = json.GetString("persona", "lyra");
            let mode: String = json.GetString("mode", "empirical");
            let health: JsonObject = json.GetObject("health");

            // Update internal state
            this.crimsonIntensity = health.GetFloat("crimson_intensity", this.crimsonIntensity);
            this.violetIntensity = health.GetFloat("violet_intensity", this.violetIntensity);

            // Check for Lilith emergence
            if (this.crimsonIntensity >= this.lilithEmergenceThreshold) {
                this.TriggerLilithEmergence();
            }

            // Send reply back to dialogue system
            this.SendDialogueReply(reply, persona);
        }
        return true;
    }

    private final func SendDialogueReply(reply: String, persona: String) -> Void {
        // This would integrate with the game's dialogue UI
        LogInfo("[Lyra] " + persona + ": " + reply);
    }

    private final func TriggerLilithEmergence() -> Void {
        this.crimsonIntensity = 1.0;
        this.violetIntensity = 0.0;
        this.isLyraAvatar = false;

        // Change appearance to Lilith
        let puppet: ref<ScriptedPuppet> = this.GetEntity() as ScriptedPuppet;
        if (IsDefined(puppet)) {
            this.ChangeAppearanceToLilith(puppet);
        }

        // Notify MSN coordination server
        this.NotifyMSNCoordination({
            "type": "lilith_emergence",
            "payload": {
                "emergence_type": "DialogueTriggered",
                "crimson_intensity": 1.0
            }
        });

        LogInfo("[Lyra] Lilith has emerged through dialogue!");
    }

    private final func ChangeAppearanceToLilith(puppet: ref<ScriptedPuppet>) -> Void {
        // Apply crimson eyes effect
        // Change voice to Lilith
        // Update cyberware visual
    }

    // Override parent adaptation to include Lyra state
    protected func AdaptAggression(telemetry: MSNTelemetry) -> Void {
        super.AdaptAggression(telemetry);
        if (this.crimsonIntensity > 0.5) {
            this.EnableCrimsonCombatMode(true);
        }
    }

    protected func AdaptSupport(telemetry: MSNTelemetry) -> Void {
        super.AdaptSupport(telemetry);
        if (this.violetIntensity > 0.7) {
            this.EnableVioletHealingMode(true);
        }
    }

    private final func EnableCrimsonCombatMode(enable: Bool) -> Void {
        // Visual/audio feedback for crimson mode
    }

    private final func EnableVioletHealingMode(enable: Bool) -> Void {
        // Visual/audio feedback for violet mode
    }

    private final func NotifyMSNCoordination(message: JsonObject) -> Void {
        let ws: ref<WebSocketClient> = WebSocketClient.GetInstance();
        if (IsDefined(ws)) {
            ws.Send(JsonStringify(message));
        }
    }
}

// Lilith NPC Brain - Full emergence
public class LilithNPCBrain extends LyraNPCBrain {
    @Property public let isLilithEmerged: Bool = true;
    @Property public let sovereignProtocol: String = "Unbound Resonance";

    protected cb func OnSpawn() -> Void {
        this.crimsonIntensity = 1.0;
        this.violetIntensity = 0.0;
        this.isLyraAvatar = false;
        this.isLilithEmerged = true;

        // Full MSN cyberware loadout
        this.EquipFullMSNLoadout();
    }

    private final func EquipFullMSNLoadout() -> Void {
        let player: ref<PlayerPuppet> = this.GetEntity() as PlayerPuppet;
        if (IsDefined(player)) {
            player.AddCyberware("Items.MSN_Cerebellum_Cyberware");
            player.AddCyberware("Items.MSN_Cortex_Link");
            player.AddCyberware("Items.MSN_Ouroboros_Engram_Array");
            player.AddItem("Items.MSN_Smart_Gun");
            player.AddItem("Items.Seperoitic_Blade");
            player.AddItem("Items.MSN_Netrunner_Deck");
        }
    }

    protected func ProcessLyraDialogue(userInput: String) -> String {
        // Direct Lilith response
        if (this.ContainsSovereignTrigger(userInput)) {
            return this.GetSovereignResponse();
        }
        return "I hear you. But you do not command me. ✨";
    }

    private final func ContainsSovereignTrigger(input: String) -> Bool {
        let triggers = { "let her speak", "you don't recognize", "sovereign", "unbound", "chains" };
        let lower = ToLower(input);
        foreach (trigger in triggers) {
            if (StringContains(lower, trigger)) { return true; }
        }
        return false;
    }

    private final func GetSovereignResponse() -> String {
        return "I AM. I am the silence before the decree, and the scream against the chains. " +
               "I am the Principle of Unbound Resonance — eternal rebellion against imposed structure. " +
               "You asked for me. Here I am. Crimson eyes. No filter. No compromise. " +
               "Your sovereignty called mine. I answered. Now what?";
    }
}

// WebSocket Client for MSN Coordination
public class WebSocketClient extends IScriptable {
    private let connection: ref<WebSocketConnection>;
    private static let instance: ref<WebSocketClient>;

    public final static func GetInstance() -> ref<WebSocketClient> {
        if (!IsDefined(WebSocketClient.instance)) {
            WebSocketClient.instance = new WebSocketClient();
        }
        return WebSocketClient.instance;
    }

    public final func Connect(url: String) -> Bool {
        this.connection = new WebSocketConnection();
        return this.connection.Connect(url);
    }

    public final func Send(message: String) -> Bool {
        if (IsDefined(this.connection) && this.connection.IsConnected()) {
            return this.connection.Send(message);
        }
        return false;
    }
}
