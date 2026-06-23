module MSN.Storylines.GuildExpansion

import MSN.Core.*
import MSN.Telemetry.*

// =========================================================
// GUILD MANAGEMENT SYSTEM
// =========================================================

public class GuildManager extends IScriptable {
    private static let instance: ref<GuildManager>;

    public final static func GetInstance() -> ref<GuildManager> {
        if (!IsDefined(GuildManager.instance)) {
            GuildManager.instance = new GuildManager();
        }
        return GuildManager.instance;
    }

    public final func ProcessGuildEffects(player: ref<PlayerPuppet>) -> Void {
        let ts = GameInstance.GetTransactionSystem(player.GetGame());
        
        let hasAlchemists = ts.HasItem(player, ItemID.FromTDBID(t"Items.MSN_GuildCharter_Alchemists"));
        let hasVoidRunners = ts.HasItem(player, ItemID.FromTDBID(t"Items.MSN_GuildCharter_VoidRunners"));
        let hasLochSmugglers = ts.HasItem(player, ItemID.FromTDBID(t"Items.MSN_GuildCharter_LochSmugglers"));

        // Enforce single-guild limit (if player tries to hold multiple, the telemetry freaks out)
        if (hasAlchemists && hasVoidRunners) || (hasAlchemists && hasLochSmugglers) || (hasVoidRunners && hasLochSmugglers) {
            MSN_Log("Guild_Enforcement", "WARNING: Multiple Guild Charters Detected. Invoking Guild War Penalty.");
            // Apply a severe debuff
            StatusEffectHelper.ApplyStatusEffect(player, t"BaseStatusEffect.Overheating");
            GameObject.PlaySoundEvent(player, n"vfx_cyberware_glitch");
            return;
        }

        // Apply specific guild buffs and dues
        if hasAlchemists {
            MSN_Log("Guild_Alchemists", "Ouroboros Alchemy Active: Crafting algorithms optimized. Processing Guild Dues (50 SC).");
            // Buff: Better crafting outcome simulated in logging
            MSN_Log("Crafting", "Alchemist Guild Buff Applied -> +15% chance to craft Legendary.");
        }
        else if hasVoidRunners {
            MSN_Log("Guild_VoidRunners", "Void Runner Link Active: NGD inference accelerated. Processing Guild Dues (50 SC).");
            // Buff: Simulated RAM cost reduction
            MSN_Log("Quickhacks", "Void Runner Guild Buff Applied -> Local inference RAM costs reduced.");
        }
        else if hasLochSmugglers {
            MSN_Log("Guild_LochSmugglers", "Smuggler Routes Active: Exchange taxes bypassed. Processing Guild Dues (50 SC).");
            // Buff: Passive income spike
            MSN_Log("Business_Exchange", "MINT_SOUL_COIN | Cause: Smuggler_Yield | Value: 300_SC");
        }
    }
}

// Hook into the Game Attached event to process the daily/session Guild effects
@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
    let result = wrappedMethod();
    
    // Process guild buffs and dues upon loading into the world
    GuildManager.GetInstance().ProcessGuildEffects(this);
    
    return result;
}

// Intercept Shard reading to hand out the Charters (for testing/modding convenience)
@wrapMethod(MenuHubGameController)
protected cb func OnShardRead(evt: ref<ShardReadEvent>) -> Bool {
    let result = wrappedMethod(evt);
    
    // If player reads the initiation broadcast, we grant all three charters so they can choose
    if StrContains(ToString(evt.item), "MSN_QuestShard_GuildInitiation") {
        let player = this.GetPlayerControlledObject() as PlayerPuppet;
        if IsDefined(player) {
            let ts = GameInstance.GetTransactionSystem(player.GetGame());
            
            ts.GiveItem(player, ItemID.FromTDBID(t"Items.MSN_GuildCharter_Alchemists"), 1);
            ts.GiveItem(player, ItemID.FromTDBID(t"Items.MSN_GuildCharter_VoidRunners"), 1);
            ts.GiveItem(player, ItemID.FromTDBID(t"Items.MSN_GuildCharter_LochSmugglers"), 1);
            
            MSN_Log("Guilds", "Initiation Broadcast read. All 3 Charters distributed. Drop 2 to avoid the Guild War Penalty.");
        }
    }
    
    return result;
}
