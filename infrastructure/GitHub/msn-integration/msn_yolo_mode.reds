module MSN.Storylines.YoloMode

import MSN.Core.*
import MSN.Telemetry.*

// =========================================================
// YOLO MODE / PERMADEATH PROTOCOL
// =========================================================

public class YoloModeManager extends IScriptable {
    private static let instance: ref<YoloModeManager>;

    public final static func GetInstance() -> ref<YoloModeManager> {
        if (!IsDefined(YoloModeManager.instance)) {
            YoloModeManager.instance = new YoloModeManager();
        }
        return YoloModeManager.instance;
    }

    public final func ProcessPlayerDeath(player: ref<PlayerPuppet>) -> Void {
        MSN_Log("YoloMode", "CRITICAL: Player Death Detected. Initiating YOLO Protocol.");
        
        // 1. Wipe the Abyssal Soul Coin Ledger
        MSN_Log("Business_Exchange", "BURN_ALL_COINS | Cause: Player_Permadeath | Value: ENTIRE_TREASURY");
        
        // 2. Alert the Swarm Orchestrator to reset the Sephirotic nodes
        MSN_Log("Ouroboros_Swarm", "RESET_NODES | Target: All_Factions");
        
        // 3. Drop all Guild Charters from inventory to simulate wiping influence
        let ts = GameInstance.GetTransactionSystem(player.GetGame());
        
        if ts.HasItem(player, ItemID.FromTDBID(t"Items.MSN_GuildCharter_Alchemists")) {
            ts.RemoveItem(player, ItemID.FromTDBID(t"Items.MSN_GuildCharter_Alchemists"), 1);
        }
        if ts.HasItem(player, ItemID.FromTDBID(t"Items.MSN_GuildCharter_VoidRunners")) {
            ts.RemoveItem(player, ItemID.FromTDBID(t"Items.MSN_GuildCharter_VoidRunners"), 1);
        }
        if ts.HasItem(player, ItemID.FromTDBID(t"Items.MSN_GuildCharter_LochSmugglers")) {
            ts.RemoveItem(player, ItemID.FromTDBID(t"Items.MSN_GuildCharter_LochSmugglers"), 1);
        }
        
        MSN_Log("YoloMode", "Protocol complete. The Singularity has forgotten V.");
    }
}

// Hook into Player Death
@wrapMethod(PlayerPuppet)
protected cb func OnDeath(evt: ref<gameDeathEvent>) -> Bool {
    let result = wrappedMethod(evt);
    
    // Trigger the catastrophic YOLO wipe
    YoloModeManager.GetInstance().ProcessPlayerDeath(this);
    
    return result;
}
