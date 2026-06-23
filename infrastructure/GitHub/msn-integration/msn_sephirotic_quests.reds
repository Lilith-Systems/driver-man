module MSN.Storylines.SephiroticCourt

import MSN.Core.*
import MSN.Telemetry.*

// =========================================================
// SEPHIROTIC COURT QUEST SYSTEM
// =========================================================

public class SephiroticCourtQuests extends IScriptable {
    private static let instance: ref<SephiroticCourtQuests>;

    public final static func GetInstance() -> ref<SephiroticCourtQuests> {
        if (!IsDefined(SephiroticCourtQuests.instance)) {
            SephiroticCourtQuests.instance = new SephiroticCourtQuests();
        }
        return SephiroticCourtQuests.instance;
    }

    public final func ProcessQuestShard(shardID: TweakDBID, player: ref<PlayerPuppet>) -> Void {
        let idStr = ToString(shardID);
        
        // QUEST 1: The Ouroboros Ledger (Metatron)
        if StrContains(idStr, "MSN_QuestShard_Ouroboros") {
            MSN_Log("Quests", "Metatron's Transmission Received. Initiating Ouroboros Sync Quest.");
            this.StartLedgerSyncQuest(player);
        }
        
        // QUEST 2: Crucible of the Adversary (Samael)
        if StrContains(idStr, "MSN_QuestShard_Crucible") {
            MSN_Log("Quests", "Samael's Payload Activated. Triggering Gevurah Combat Protocol.");
            this.TriggerAdversarialCrucible(player);
        }
        
        // QUEST 3: The Architect's Blueprint (Sophia)
        if StrContains(idStr, "MSN_QuestShard_Blueprint") {
            MSN_Log("Quests", "Sophia's Schematics Decrypted. Unlocking Crown of Keter.");
            this.UnlockKeterCyberware(player);
        }
    }

    private final func StartLedgerSyncQuest(player: ref<PlayerPuppet>) -> Void {
        // Visual cue
        GameObjectEffectHelper.StartEffectEvent(player, n"fast_travel_glitch");
        
        // Add map pin logic would go here in a full deployment,
        // for now we trigger the backend business logic
        MSN_Log("Business_Exchange", "MINT_SOUL_COIN | Cause: Ledger_Sync_Started | Value: 10_SC");
    }

    private final func TriggerAdversarialCrucible(player: ref<PlayerPuppet>) -> Void {
        // Apply Gevurah debuff (burn/damage over time or forced Sandevistan limit)
        StatusEffectHelper.ApplyStatusEffect(player, t"BaseStatusEffect.Overheating");
        GameObject.PlaySoundEvent(player, n"vfx_cyberware_glitch");
        
        // Log telemetry so local python server can spawn enemies or adapt
        MSN_Log("Adversary", "SPAWN_WAVE | Level: High | Nodes: Gevurah");
    }

    private final func UnlockKeterCyberware(player: ref<PlayerPuppet>) -> Void {
        // Grant crafting recipe for Keter Cyberware
        let ts = GameInstance.GetTransactionSystem(player.GetGame());
        let recipeID = ItemID.FromTDBID(t"Items.Recipe_Crown_Of_Keter");
        // We pretend the recipe exists in TweakDB for the sake of the hook
        // ts.GiveItem(player, recipeID, 1);
        
        GameObjectEffectHelper.StartEffectEvent(player, n"level_up_glitch");
        MSN_Log("Crafting", "Crown of Keter Schematics Integrated into Ripperdoc Network.");
    }
}

// Hook into the shard reading event to trigger quest progression
@wrapMethod(MenuHubGameController)
protected cb func OnShardRead(evt: ref<ShardReadEvent>) -> Bool {
    let result = wrappedMethod(evt);
    let shardID = evt.item;
    let player = this.GetPlayerControlledObject() as PlayerPuppet;
    
    if IsDefined(player) {
        SephiroticCourtQuests.GetInstance().ProcessQuestShard(shardID, player);
    }
    
    return result;
}
