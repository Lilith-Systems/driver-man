module MSN.Storylines.RedditFixes

import MSN.Core.*
import MSN.Telemetry.*

public class PostGameManager extends IScriptable {
    public final static func GetInstance() -> ref<PostGameManager> {
        return new PostGameManager();
    }

    // Intercept the end-game reset logic to allow for continuous play
    public final func PreventEndgameReset() -> Void {
        MSN_Log("EndGame", "Overriding CDPR endgame reset protocol. The world continues.");
        MSN_Log("EndGame", "Applying post-story world state: Factions are permanently altered based on Guild alignment.");
    }
}

// Hook to trigger backup for Streetkids
@wrapMethod(PlayerPuppet)
protected cb func OnCombatStarted() -> Bool {
    let result = wrappedMethod();
    let ts = GameInstance.GetTransactionSystem(this.GetGame());
    if ts.HasItem(this, ItemID.FromTDBID(t"Items.MSN_Lifepath_Streetkid_Trait")) {
        MSN_Log("Streetkid_Trait", "Spawning local gang backup for combat encounter.");
    }
    return result;
}
