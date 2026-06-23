module MSN.Storylines.AbyssalSkills

import MSN.Core.*
import MSN.Telemetry.*

public class LochnessActivityManager extends IScriptable {
    private static let instance: ref<LochnessActivityManager>;

    public final static func GetInstance() -> ref<LochnessActivityManager> {
        if (!IsDefined(LochnessActivityManager.instance)) {
            LochnessActivityManager.instance = new LochnessActivityManager();
        }
        return LochnessActivityManager.instance;
    }

    public final func GrantLaunderingXP(player: ref<PlayerPuppet>, amount: Int32) -> Void {
        MSN_Log("Abyssal_Skills", "Awarded " + ToString(amount) + " XP to Abyssal Laundering Skill Tree.");
        // In full implementation, this routes to DevelopmentSystem.AddExperience()
        
        let devSystem = GameInstance.GetDevelopmentSystem(player.GetGame());
        // devSystem.AddExperience(player, gamedataProficiencyType.MSN_AbyssalLaundering, amount);
    }

    public final func CheckTaxAudit(player: ref<PlayerPuppet>) -> Void {
        // Simulates Nessie dispatching an Auditor Drone if the player is dodging taxes
        MSN_Log("Lochness", "WARNING: Nessie has detected tax evasion. Auditor Drones dispatched to your coordinates.");
        LyraAudioSystem.GetInstance().PlayLyraVoiceLine(n"lilith_nessie_audit_01");
        
        // Spawn the drone via script at player's location (Placeholder logic for TweakDB spawn)
        // GameInstance.GetPreventionSystem().SpawnPursuit(player); 
    }
}

// Hook into terminal hacking to allow "Hostile Takeovers"
@wrapMethod(Terminal)
protected cb func OnAccessPointHacked(evt: ref<ActionBool>) -> Bool {
    let result = wrappedMethod(evt);
    
    let player = GetPlayer(this.GetGame());
    let ts = GameInstance.GetTransactionSystem(this.GetGame());
    
    if ts.HasItem(player, ItemID.FromTDBID(t"Development.MSN_Perk_HostileTakeover")) {
        MSN_Log("Hostile_Takeover", "Rival Syndicate Ledger hacked! Draining 500 Soul Coins.");
        LochnessActivityManager.GetInstance().GrantLaunderingXP(player, 150);
        
        // Trigger visual
        GameObjectEffectHelper.StartEffectEvent(player, n"hack_successful");
    }
    
    return result;
}

// Hook into killing an Auditor Drone
@wrapMethod(NPCPuppet)
protected cb func OnDeath(evt: ref<gameDeathEvent>) -> Bool {
    let result = wrappedMethod(evt);
    
    if StrContains(ToString(this.GetRecordID()), "MSN_Lochness_AuditorDrone") {
        let player = GetPlayer(this.GetGame());
        MSN_Log("Lochness", "Auditor Drone destroyed. Tax records wiped locally.");
        LochnessActivityManager.GetInstance().GrantLaunderingXP(player, 500);
    }
    
    return result;
}
