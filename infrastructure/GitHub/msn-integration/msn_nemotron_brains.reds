module MSN.Storylines.DynamicBrains

import MSN.Core.*
import MSN.Telemetry.*

public class NemotronBrainManager extends IScriptable {
    private static let instance: ref<NemotronBrainManager>;

    public final static func GetInstance() -> ref<NemotronBrainManager> {
        if (!IsDefined(NemotronBrainManager.instance)) {
            NemotronBrainManager.instance = new NemotronBrainManager();
        }
        return NemotronBrainManager.instance;
    }

    public final func RequestBrainRewrite(npc: ref<NPCPuppet>) -> Void {
        let npcStr = ToString(npc.GetEntityID());
        MSN_Log("Nemotron", "Pinging Nemotron server for dynamic behavior tree. Target: " + npcStr);
        
        // In a real mod, the Python backend would return JSON determining patrol points or aggression levels.
        // We simulate the application of this intelligence by buffing their threat level.
        if npc.IsAggressive() {
            MSN_Log("Nemotron_Apply", "Nemotron intelligence injected. NPC aggression and tactical flanking increased.");
            StatusEffectHelper.ApplyStatusEffect(npc, t"BaseStatusEffect.CombatStim");
        }
    }
}

// Hook into NPC spawning
@wrapMethod(NPCPuppet)
protected cb func OnSpawned(data: ref<EntityResolveComponentsInterface>) -> Bool {
    let result = wrappedMethod(data);
    
    // Request a Nemotron brain for every NPC that spawns into the world
    NemotronBrainManager.GetInstance().RequestBrainRewrite(this);
    
    return result;
}
