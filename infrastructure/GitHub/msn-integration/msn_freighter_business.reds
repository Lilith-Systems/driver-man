module MSN.Storylines.SpaceCombat

import MSN.Core.*
import MSN.Telemetry.*

public class FreighterBusinessManager extends IScriptable {
    private static let instance: ref<FreighterBusinessManager>;

    public final static func GetInstance() -> ref<FreighterBusinessManager> {
        if (!IsDefined(FreighterBusinessManager.instance)) {
            FreighterBusinessManager.instance = new FreighterBusinessManager();
        }
        return FreighterBusinessManager.instance;
    }

    public final func ProcessFreighterLogistics(player: ref<PlayerPuppet>) -> Void {
        let ts = GameInstance.GetTransactionSystem(player.GetGame());
        let hasServerRack = ts.HasItem(player, ItemID.FromTDBID(t"Items.MSN_Freighter_ServerRack"));

        if hasServerRack {
            // Because the freighter is in orbit, it bypasses Earth's local network latency and local police heat.
            MSN_Log("Orbital_Business", "NSSP Freighter 'Leviathan' connection secure. Processing tax-free Abyssal Exchange batch.");
            MSN_Log("Business_Exchange", "MINT_SOUL_COIN | Cause: Orbital_Server_Farm | Value: 2500_SC");
            
            // Suppress all police heat because operations are happening in space
            MSN_Log("Heat_System", "NCPD Tracking nullified. Operations moved to low orbit.");
        }
    }
}

// Hook to simulate the orbital business processing whenever the player sleeps or waits
@wrapMethod(TimeSkipPopupGameController)
protected cb func OnTimeSkipFinished(skipTime: Float) -> Bool {
    let result = wrappedMethod(skipTime);
    
    let player = GetPlayer(this.GetPlayerControlledObject().GetGame());
    if IsDefined(player) {
        FreighterBusinessManager.GetInstance().ProcessFreighterLogistics(player);
    }
    
    return result;
}
