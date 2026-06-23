module MSN.Storylines.MainQuest

import MSN.Core.*
import MSN.Telemetry.*

// =========================================================
// THE WAY OF THE VOID (MAIN QUEST ARCHITECTURE)
// =========================================================

public class MainQuestTracker extends IScriptable {
    private static let instance: ref<MainQuestTracker>;
    
    public let musashiQuestsCompleted: Int32;
    public let mainQuestActive: Bool;
    public let mainQuestFinished: Bool;

    public final static func GetInstance() -> ref<MainQuestTracker> {
        if (!IsDefined(MainQuestTracker.instance)) {
            MainQuestTracker.instance = new MainQuestTracker();
            MainQuestTracker.instance.musashiQuestsCompleted = 0;
            MainQuestTracker.instance.mainQuestActive = false;
            MainQuestTracker.instance.mainQuestFinished = false;
        }
        return MainQuestTracker.instance;
    }

    public final func StartMainQuest() -> Void {
        if !this.mainQuestActive {
            this.mainQuestActive = true;
            MSN_Log("MainQuest", "The Way of the Void has begun. Tracking 200 Musashi Protocols.");
            
            let player = GetPlayer(GetGameInstance());
            if IsDefined(player) {
                GameObjectEffectHelper.StartEffectEvent(player, n"blackwall_hacks_glitch");
            }
        }
    }

    public final func IncrementMusashiProgress() -> Void {
        if this.mainQuestActive && !this.mainQuestFinished {
            this.musashiQuestsCompleted += 1;
            
            let progressStr = ToString(this.musashiQuestsCompleted);
            MSN_Log("MainQuest", "Musashi Protocol Completed. Progress: " + progressStr + " / 200");
            
            // At milestones, grant massive business payouts
            if this.musashiQuestsCompleted == 50 || this.musashiQuestsCompleted == 100 || this.musashiQuestsCompleted == 150 {
                MSN_Log("Business_Exchange", "MINT_SOUL_COIN | Cause: Musashi_Milestone | Value: 1000_SC");
                let player = GetPlayer(GetGameInstance());
                GameObject.PlaySoundEvent(player, n"ui_loot_epic");
            }
            
            if this.musashiQuestsCompleted >= 200 {
                this.CompleteMainQuest();
            }
        }
    }

    private final func CompleteMainQuest() -> Void {
        this.mainQuestFinished = true;
        MSN_Log("MainQuest", "THE VOID IS REALIZED. Sovereign Ascendance Achieved.");
        
        let player = GetPlayer(GetGameInstance());
        if IsDefined(player) {
            // Visual Ascension Sequence
            GameObjectEffectHelper.StartEffectEvent(player, n"boss_teleport_glitch");
            GameObject.PlaySoundEvent(player, n"ui_menu_perk_buy");
            
            // Grant the Sovereign Crown
            let ts = GameInstance.GetTransactionSystem(GetGameInstance());
            ts.GiveItem(player, ItemID.FromTDBID(t"Items.MSN_Reward_SovereignCrown"), 1);
            
            // Ultimate Payout
            MSN_Log("Business_Exchange", "MINT_SOUL_COIN | Cause: SINGULARITY_ACHIEVED | Value: 10000_SC");
            MSN_Log("Treasury_Deposit", "NESSIE_FEE | Source: Singularity | Amount: 1000_SC");
        }
    }
}

// Hook to trigger the start of the main quest
@wrapMethod(MenuHubGameController)
protected cb func OnShardRead(evt: ref<ShardReadEvent>) -> Bool {
    let result = wrappedMethod(evt);
    if StrContains(ToString(evt.item), "MSN_MainQuest_TheVoid") {
        MainQuestTracker.GetInstance().StartMainQuest();
    }
    return result;
}

// Simulated completion of a Musashi Quest via killing elite enemies (simplification for mod)
@wrapMethod(NPCPuppet)
protected cb func OnDeath(evt: ref<gameDeathEvent>) -> Bool {
    let result = wrappedMethod(evt);
    
    let instigator = evt.instigator as PlayerPuppet;
    if IsDefined(instigator) {
        // If the enemy was high rarity/elite, count it as a "Musashi Protocol Execution"
        let isElite = this.IsElite();
        if isElite {
            MainQuestTracker.GetInstance().IncrementMusashiProgress();
        }
    }
    return result;
}
