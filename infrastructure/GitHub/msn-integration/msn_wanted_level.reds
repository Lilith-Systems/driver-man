module MSN.Storylines.WantedLevel

import MSN.Core.*
import MSN.Telemetry.*

public class MSNWantedLevelManager extends IScriptable {
    private static let instance: ref<MSNWantedLevelManager>;

    public final static func GetInstance() -> ref<MSNWantedLevelManager> {
        if (!IsDefined(MSNWantedLevelManager.instance)) {
            MSNWantedLevelManager.instance = new MSNWantedLevelManager();
        }
        return MSNWantedLevelManager.instance;
    }

    public final func ProcessAssassination(player: ref<PlayerPuppet>, target: ref<ScriptedPuppet>) -> Void {
        let preventionSystem = GameInstance.GetPreventionSystem(player.GetGame());
        if IsDefined(preventionSystem) {
            MSN_Log("WantedLevel", "Abyssal Exchange target eliminated. Raising NCPD Heat to 4 stars.");
            
            let heatReq = new PreventionHeatActionRequest();
            heatReq.action = EPreventionHeatAction.SetHeatStage;
            heatReq.stage = 4;
            preventionSystem.QueueRequest(heatReq);

            // Log to Abyssal Exchange Telemetry
            MSN_Log("Business_Exchange", "ASSASSINATION_COMPLETE | Target Eliminated | Result: HEAT_LEVEL_4");
        }
    }
}

// Hook into NPC Death to check for Abyssal Exchange Assassinations
@wrapMethod(ScriptedPuppet)
protected cb func OnDeath(evt: ref<gameDeathEvent>) -> Bool {
    let result = wrappedMethod(evt);
    
    let player = evt.instigator as PlayerPuppet;
    if IsDefined(player) {
        // Checking if the dead NPC is an Abyssal Exchange target
        // We check for the specific TweakDB tag
        let isAbyssalTarget: Bool = this.GetRecord().TagsContains(n"AbyssalAssassinationTarget");
        
        if isAbyssalTarget {
            MSNWantedLevelManager.GetInstance().ProcessAssassination(player, this);
        }
    }
    
    return result;
}
