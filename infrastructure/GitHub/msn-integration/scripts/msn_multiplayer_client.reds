// MSN Multiplayer Client Integration
// File: r6/scripts/msn/msn_multiplayer_client.reds
// Connects Cyberpunk 2077 to MSN Coordination Server

public class MSNMultiplayerClient extends GameSystem {
    @Property public let ServerURL: String = "ws://localhost:8768";
    @Property public let PlayerID: String = "";
    @Property public let AutoConnect: Bool = true;
    @Property public let ReconnectAttempts: Int32 = 5;
    @Property public let ReconnectDelay: Float = 2.0;
    @Property public let SendRate: Int32 = 60;  // Hz
    @Property public let EnablePrediction: Bool = true;
    @Property public let EnableSpeculative: Bool = true;
    
    private let ws: ref<WebSocket>;
    private let connected: Bool = false;
    private let connecting: Bool = false;
    private let myPlayerID: String = "";
    private let isHost: Bool = false;
    private let sessionID: String = "";
    private let sequence: Int32 = 0;
    private let lastSendTime: Float = 0.0;
    private let sendInterval: Float = 1.0 / 60.0;
    
    // Remote players
    private let remotePlayers: map<String, ref<RemotePlayer>> = {};
    
    // Speculative
    private let speculativeCerebellum: ref<MSNSpeculativeCerebellum>;
    private let pendingInputs: array<InputFrame> = {};
    private let serverReconciliation: Bool = true;
    
    // NGD Fleet
    private let fleetStatus: NGDFleetStatus;
    
    // Lilith Federation
    private let lilithFederationMode: String = "Federated";
    
    public final func OnInit() -> Void {
        this.speculativeCerebellum = Game.GetSystem(n"MSNSpeculativeCerebellum");
        this.fleetStatus = new NGDFleetStatus();
        
        if (this.AutoConnect) {
            this.Connect();
        }
        
        LogInfo("MSN Multiplayer Client initialized");
    }
    
    public final func Connect(playerID: String = "") -> Void {
        if (this.connected || this.connecting) { return; }
        
        this.connecting = true;
        this.myPlayerID = playerID != "" ? playerID : "msn_player_" + ToString(RandomInt(10000));
        
        let url: String = this.ServerURL + "?player_id=" + this.myPlayerID;
        
        this.ws = new WebSocket();
        this.ws.SetURL(url);
        
        this.ws.OnOpen = this, n"OnWebSocketOpen";
        this.ws.OnMessage = this, n"OnWebSocketMessage";
        this.ws.OnClose = this, n"OnWebSocketClose";
        this.ws.OnError = this, n"OnWebSocketError";
        
        this.ws.Connect();
        LogInfo("Connecting to MSN Coordination Server: " + url);
    }
    
    public final func Disconnect() -> Void {
        if (this.ws) {
            this.ws.Close();
            this.ws = null;
        }
        this.connected = false;
        this.connecting = false;
        this.remotePlayers.Clear();
        LogInfo("Disconnected from MSN Coordination Server");
    }
    
    public final func OnWebSocketOpen() -> Void {
        this.connecting = false;
        this.connected = true;
        LogInfo("Connected to MSN Coordination Server");
        
        // Send join
        this.Send({
            "type": "join",
            "player_id": this.myPlayerID
        });
    }
    
    public final func OnWebSocketMessage(message: String) -> Void {
        let data: JsonData = JsonData.Parse(message);
        if (!data) { return; }
        
        let msgType: String = data.GetString("type", "");
        
        switch msgType {
            case "join_confirmed":
                this.OnJoinConfirmed(data);
                break;
            case "player_list":
                this.OnPlayerList(data);
                break;
            case "state_sync":
                this.OnStateSync(data);
                break;
            case "authoritative_state":
                this.OnAuthoritativeState(data);
                break;
            case "ngd_fleet_status":
                this.OnNGDFleetStatus(data);
                break;
            case "lilith_emergence_sync":
                this.OnLilithEmergenceSync(data);
                break;
            case "host_migrated":
                this.OnHostMigrated(data);
                break;
            case "fleet_alert":
                this.OnFleetAlert(data);
                break;
            case "speculative_rollback":
                this.OnSpeculativeRollback(data);
                break;
            case "heartbeat_ack":
                // Latency measurement
                break;
        }
    }
    
    public final func OnWebSocketClose(code: Int32, reason: String) -> Void {
        this.connected = false;
        LogWarning("Disconnected from server: " + reason + " (code: " + ToString(code) + ")");
        
        // Attempt reconnect
        if (this.ReconnectAttempts > 0) {
            this.ScheduleReconnect();
        }
    }
    
    public final func OnWebSocketError(error: String) -> Void {
        LogError("WebSocket error: " + error);
    }
    
    private final func OnJoinConfirmed(data: JsonData) -> Void {
        this.myPlayerID = data.GetString("player_id", this.myPlayerID);
        this.isHost = data.GetBool("is_host", false);
        this.sessionID = data.GetString("session_id", "");
        
        LogInfo("Joined session: " + this.sessionID + " as " + this.myPlayerID + " (host: " + ToString(this.isHost) + ")");
        
        // Initialize remote players
        let players: JsonArray = data.GetArray("players");
        if (players) {
            for (var i = 0; i < players.Size(); i++) {
                let pData: JsonData = players.Get(i);
                let pid: String = pData.GetString("player_id", "");
                if (pid != this.myPlayerID) {
                    this.CreateRemotePlayer(pid, pData);
                }
            }
        }
        
        // Initialize fleet status
        let fleetData: JsonData = data.GetObject("fleet_status");
        if (fleetData) {
            this.UpdateFleetStatus(fleetData);
        }
    }
    
    private final func OnPlayerList(data: JsonData) -> Void {
        let players: JsonArray = data.GetArray("players");
        if (!players) { return; }
        
        let seenIDs: Set<String> = {};
        
        for (var i = 0; i < players.Size(); i++) {
            let pData: JsonData = players.Get(i);
            let pid: String = pData.GetString("player_id", "");
            seenIDs.Add(pid);
            
            if (pid == this.myPlayerID) { continue; }
            
            if (this.remotePlayers.Contains(pid)) {
                this.UpdateRemotePlayer(pid, pData);
            } else {
                this.CreateRemotePlayer(pid, pData);
            }
        }
        
        // Remove disconnected players
        for (pid in this.remotePlayers.Keys()) {
            if (!seenIDs.Contains(pid)) {
                this.RemoveRemotePlayer(pid);
            }
        }
    }
    
    private final func CreateRemotePlayer(pid: String, data: JsonData) -> Void {
        let remote: ref<RemotePlayer> = new RemotePlayer();
        remote.playerID = pid;
        remote.position = Vector4(
            data.GetFloat("position[0]", 0.0),
            data.GetFloat("position[1]", 0.0),
            data.GetFloat("position[2]", 0.0),
            1.0
        );
        remote.rotation = EulerAngles(
            data.GetFloat("rotation[0]", 0.0),
            data.GetFloat("rotation[1]", 0.0),
            data.GetFloat("rotation[2]", 0.0)
        );
        remote.health = data.GetFloat("health", 100.0);
        remote.activeSephirah = data.GetString("active_sephirah", "Tiphareth");
        remote.lastUpdate = EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime());
        
        this.remotePlayers.Set(pid, remote);
        LogInfo("Remote player added: " + pid);
    }
    
    private final func UpdateRemotePlayer(pid: String, data: JsonData) -> Void {
        if (!this.remotePlayers.Contains(pid)) { return; }
        
        let remote: ref<RemotePlayer> = this.remotePlayers.Get(pid);
        remote.position = Vector4(
            data.GetFloat("position[0]", remote.position.X),
            data.GetFloat("position[1]", remote.position.Y),
            data.GetFloat("position[2]", remote.position.Z),
            1.0
        );
        remote.rotation = EulerAngles(
            data.GetFloat("rotation[0]", remote.rotation.Yaw),
            data.GetFloat("rotation[1]", remote.rotation.Pitch),
            data.GetFloat("rotation[2]", remote.rotation.Roll)
        );
        remote.health = data.GetFloat("health", remote.health);
        remote.activeSephirah = data.GetString("active_sephirah", remote.activeSephirah);
        remote.lastUpdate = EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime());
    }
    
    private final func RemoveRemotePlayer(pid: String) -> Void {
        this.remotePlayers.Remove(pid);
        LogInfo("Remote player removed: " + pid);
    }
    
    private final func OnStateSync(data: JsonData) -> Void {
        let sender: String = data.GetString("sender", "");
        let payload: JsonData = data.GetObject("payload");
        
        if (!payload) { return; }
        
        if (!this.remotePlayers.Contains(sender)) {
            this.CreateRemotePlayer(sender, JsonData.Create());
        }
        
        let remote: ref<RemotePlayer> = this.remotePlayers.Get(sender);
        if (!IsDefined(remote)) { return; }
        
        // Interpolate position for smooth movement
        let targetPos: Vector4 = Vector4(
            payload.GetFloat("position[0]", remote.position.X),
            payload.GetFloat("position[1]", remote.position.Y),
            payload.GetFloat("position[2]", remote.position.Z),
            1.0
        );
        
        // Smooth interpolation
        remote.targetPosition = targetPos;
        remote.targetRotation = EulerAngles(
            payload.GetFloat("rotation[0]", remote.rotation.Yaw),
            payload.GetFloat("rotation[1]", remote.rotation.Pitch),
            payload.GetFloat("rotation[2]", remote.rotation.Roll)
        );
        remote.health = payload.GetFloat("health", remote.health);
        remote.activeSephirah = payload.GetString("active_sephirah", remote.activeSephirah);
        
        // Quickhack cooldowns
        let cooldowns: JsonData = payload.GetObject("quickhack_cooldowns");
        if (cooldowns) {
            remote.quickhackCooldowns.Clear();
            for (key in cooldowns.Keys()) {
                remote.quickhackCooldowns.Set(key, cooldowns.GetFloat(key, 0.0));
            }
        }
    }
    
    private final func OnAuthoritativeState(data: JsonData) -> Void {
        if (!this.serverReconciliation) { return; }
        
        let payload: JsonData = data.GetObject("payload");
        if (!payload) { return; }
        
        // Reconcile local prediction with server state
        for (pid in payload.Keys()) {
            if (pid == this.myPlayerID) {
                let serverState: JsonData = payload.GetObject(pid);
                this.ReconcileLocalState(serverState);
            }
        }
    }
    
    private final func ReconcileLocalState(serverState: JsonData) -> Void {
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        if (!IsDefined(player)) { return; }
        
        // Check for significant desync
        let serverPos: Vector4 = Vector4(
            serverState.GetFloat("position[0]", 0.0),
            serverState.GetFloat("position[1]", 0.0),
            serverState.GetFloat("position[2]", 0.0),
            1.0
        );
        
        let localPos: Vector4 = player.GetWorldPosition();
        let distance: Float = Vector4.Distance(localPos, serverPos);
        
        if (distance > 2.0) {  // 2 meter threshold
            LogWarning("Desync detected: " + ToString(distance) + "m - Reconciling");
            player.SetWorldPosition(serverPos);
            
            // Clear pending inputs that were wrong
            this.pendingInputs.Clear();
        }
    }
    
    private final func OnNGDFleetStatus(data: JsonData) -> Void {
        let payload: JsonData = data.GetObject("payload");
        if (!payload) { return; }
        
        this.UpdateFleetStatus(payload);
        
        // Adjust local inference based on fleet status
        this.AdjustLocalInference();
    }
    
    private final func UpdateFleetStatus(data: JsonData) -> Void {
        this.fleetStatus.totalVRAM = data.GetInt("total_vram_mb", 0);
        this.fleetStatus.usedVRAM = data.GetInt("used_vram_mb", 0);
        this.fleetStatus.fleetRoute = data.GetString("fleet_route", "LOCAL_CEREBELLUM");
        this.fleetStatus.lastUpdate = data.GetFloat("last_update", 0.0);
        
        let nodes: JsonArray = data.GetArray("nodes");
        if (nodes) {
            this.fleetStatus.nodes.Clear();
            for (var i = 0; i < nodes.Size(); i++) {
                let nData: JsonData = nodes.Get(i);
                let node: NGDFleetNode = new NGDFleetNode();
                node.playerID = nData.GetString("player_id", "");
                node.vramFreeMB = nData.GetFloat("vram_free_mb", 0.0);
                node.vramUsedMB = nData.GetFloat("vram_used_mb", 0.0);
                node.route = nData.GetString("route", "UNKNOWN");
                node.gpuTemp = nData.GetFloat("gpu_temp", 0.0);
                node.gpuUtil = nData.GetFloat("gpu_util", 0.0);
                this.fleetStatus.nodes.PushBack(node);
            }
        }
    }
    
    private final func AdjustLocalInference() -> Void {
        let msnCere: ref<MSNCerebellum> = this.GetMSNCerebellum();
        if (!IsDefined(msnCere)) { return; }
        
        // If fleet is in CLOUD_CORTEX, force local to cloud
        if (this.fleetStatus.fleetRoute == "CLOUD_CORTEX") {
            msnCere.SetInferenceMode("CloudOnly");
        } else if (this.fleetStatus.fleetRoute == "HYBRID") {
            msnCere.SetInferenceMode("Hybrid");
        } else {
            msnCere.SetInferenceMode("LocalPreferred");
        }
    }
    
    private final func OnLilithEmergenceSync(data: JsonData) -> Void {
        let payload: JsonData = data.GetObject("payload");
        if (!payload) { return; }
        
        let triggerPlayer: String = payload.GetString("trigger_player", "");
        let emergenceType: String = payload.GetString("emergence_type", "Manual");
        let crimsonIntensity: Float = payload.GetFloat("crimson_intensity", 0.5);
        let shared: Bool = payload.GetBool("shared", false);
        
        LogInfo("Lilith emergence synced from " + triggerPlayer + ": " + emergenceType);
        
        if (shared && triggerPlayer != this.myPlayerID) {
            // Trigger local Lilith emergence
            this.TriggerLocalLilithEmergence(emergenceType, crimsonIntensity);
        }
    }
    
    private final func TriggerLocalLilithEmergence(emergenceType: String, intensity: Float) -> Void {
        // Call Lilith API
        let lilithAPI: ref<LilithAPI> = Game.GetSystem(n"LilithAPI");
        if (IsDefined(lilithAPI)) {
            lilithAPI.TriggerEmergence(emergenceType, intensity);
        }
    }
    
    private final func OnHostMigrated(data: JsonData) -> Void {
        let newHost: String = data.GetString("new_host", "");
        this.isHost = (newHost == this.myPlayerID);
        LogInfo("Host migrated to: " + newHost + " (I am host: " + ToString(this.isHost) + ")");
    }
    
    private final func OnFleetAlert(data: JsonData) -> Void {
        let payload: JsonData = data.GetObject("payload");
        if (!payload) { return; }
        
        let level: String = payload.GetString("level", "info");
        let message: String = payload.GetString("message", "");
        
        if (level == "warning") {
            LogWarning("FLEET ALERT: " + message);
            // Show in-game notification
            Game.GetUIManager().ShowNotification(message, "MSN Fleet", 10.0);
        }
    }
    
    private final func OnSpeculativeRollback(data: JsonData) -> Void {
        if (!this.EnableSpeculative) { return; }
        
        let payload: JsonData = data.GetObject("payload");
        let correctedState: JsonData = payload.GetObject("corrected_state");
        let reason: String = payload.GetString("reason", "desync");
        
        LogWarning("Speculative rollback: " + reason);
        
        if (correctedState && this.speculativeCerebellum) {
            this.speculativeCerebellum.Reconcile(correctedState);
        }
    }
    
    // Main tick - send state updates
    public final func OnTick(deltaTime: Float) -> Void {
        if (!this.connected) { return; }
        
        let now: Float = EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime());
        if (now - this.lastSendTime < this.sendInterval) { return; }
        
        this.SendStateUpdate();
        this.SendHeartbeat();
        this.lastSendTime = now;
        
        // Update remote player interpolation
        this.UpdateRemoteInterpolation(deltaTime);
    }
    
    private final func SendStateUpdate() -> Void {
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        if (!IsDefined(player)) { return; }
        
        let pos: Vector4 = player.GetWorldPosition();
        let rot: EulerAngles = player.GetWorldOrientation();
        
        let msnCere: ref<MSNCerebellum> = this.GetMSNCerebellum();
        let activeSephirah: String = "Tiphareth";
        if (IsDefined(msnCere)) {
            activeSephirah = msnCere.GetActiveSephirah();
        }
        
        let payload: JsonData = JsonData.Create();
        payload.SetFloat("position[0]", pos.X);
        payload.SetFloat("position[1]", pos.Y);
        payload.SetFloat("position[2]", pos.Z);
        payload.SetFloat("rotation[0]", rot.Yaw);
        payload.SetFloat("rotation[1]", rot.Pitch);
        payload.SetFloat("rotation[2]", rot.Roll);
        payload.SetFloat("health", player.GetHealthPercentage() * 100.0);
        payload.SetString("active_sephirah", activeSephirah);
        
        // MSN state
        if (IsDefined(msnCere)) {
            let msnData: JsonData = JsonData.Create();
            msnData.SetString("inference_mode", msnCere.GetInferenceMode());
            msnData.SetInt("sephiroth_slots", msnCere.GetSephirothSlots());
            payload.SetObject("msn_state", msnData);
        }
        
        // Quickhack cooldowns
        let cooldowns: JsonData = JsonData.Create();
        // ... populate from player's quickhack system
        payload.SetObject("quickhack_cooldowns", cooldowns);
        
        this.Send({
            "type": "state_sync",
            "sequence": this.sequence,
            "payload": payload
        });
        this.sequence++;
    }
    
    private final func SendHeartbeat() -> Void {
        this.Send({
            "type": "heartbeat",
            "timestamp": EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime())
        });
    }
    
    private final func UpdateRemoteInterpolation(deltaTime: Float) -> Void {
        for (pid, remote in this.remotePlayers) {
            if (remote.targetPosition.IsZero()) { continue; }
            
            // Smooth interpolation
            let lerpFactor: Float = 1.0 - Pow(0.001, deltaTime * 10.0);
            remote.position = Vector4.Lerp(remote.position, remote.targetPosition, lerpFactor);
            remote.rotation = EulerAngles.Lerp(remote.rotation, remote.targetRotation, lerpFactor);
            
            // Update visual representation
            this.UpdateRemoteVisual(pid, remote);
        }
    }
    
    private final func UpdateRemoteVisual(pid: String, remote: ref<RemotePlayer>) -> Void {
        // Spawn/update visual representation of remote player
        // This would create/update an NPC/entity for the remote player
    }
    
    private final func Send(data: variant) -> Void {
        if (!this.ws || !this.connected) { return; }
        
        let jsonStr: String;
        if (data.IsString()) {
            jsonStr = data.GetString();
        } else {
            // Convert to JSON
            jsonStr = JsonData.Stringify(data);
        }
        
        this.ws.Send(jsonStr);
    }
    
    private final func ScheduleReconnect() -> Void {
        this.ReconnectAttempts--;
        Delay(this.ReconnectDelay);
        this.Connect(this.myPlayerID);
    }
    
    private final func GetMSNCerebellum() -> ref<MSNCerebellum> {
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        if (IsDefined(player)) {
            return player.GetCyberware(n"MSNCerebellum");
        }
        return null;
    }
}

// Supporting classes
public class RemotePlayer {
    public let playerID: String;
    public let position: Vector4;
    public let targetPosition: Vector4;
    public let rotation: EulerAngles;
    public let targetRotation: EulerAngles;
    public let health: Float = 100.0;
    public let activeSephirah: String = "Tiphareth";
    public let quickhackCooldowns: map<String, Float> = {};
    public let lastUpdate: Float = 0.0;
}

public struct NGDFleetStatus {
    public let totalVRAM: Int32 = 0;
    public let usedVRAM: Int32 = 0;
    public let fleetRoute: String = "LOCAL_CEREBELLUM";
    public let nodes: array<NGDFleetNode> = {};
    public let lastUpdate: Float = 0.0;
}

public struct NGDFleetNode {
    public let playerID: String;
    public let vramFreeMB: Float;
    public let vramUsedMB: Float;
    public let route: String;
    public let gpuTemp: Float;
    public let gpuUtil: Float;
}