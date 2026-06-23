module MSN.Storylines.OrbitalTravel

import MSN.Core.*
import MSN.Telemetry.*

public class AbyssalNavigationSystem extends IScriptable {
    private static let instance: ref<AbyssalNavigationSystem>;

    public final static func GetInstance() -> ref<AbyssalNavigationSystem> {
        if (!IsDefined(AbyssalNavigationSystem.instance)) {
            AbyssalNavigationSystem.instance = new AbyssalNavigationSystem();
        }
        return AbyssalNavigationSystem.instance;
    }

    public final func TeleportToOrbit(player: ref<PlayerPuppet>) -> Void {
        MSN_Log("Orbital_Transit", "Quantum Nav Shard engaged. Initiating low-orbit transport to The Leviathan.");
        
        // Glitch VFX and Sound to simulate hyper-transit
        GameObjectEffectHelper.StartEffectEvent(player, n"boss_teleport_glitch");
        GameObject.PlaySoundEvent(player, n"ui_menu_perk_buy");

        // In a full implementation, this uses TeleportationFacility.Teleport() to move the player 
        // to a specific coordinate high above the map or into a hidden interior cell.
        // For the mod, we simulate the coordinate shift:
        let position = new Vector4(0.0, 0.0, 9999.0, 1.0); // Z=9999 to simulate space altitude
        let rotation = new EulerAngles(0.0, 0.0, 0.0);
        
        GameInstance.GetTeleportationFacility(player.GetGame()).Teleport(player, position, rotation);
        
        MSN_Log("Orbital_Transit", "Arrival successful. Welcome to the NSSP Freighter.");
    }
}

// Hook into item consumption to intercept the Quantum Nav Shard
@wrapMethod(EquipmentSystemPlayerData)
protected cb func OnItemEquipped(request: ref<EquipRequest>) -> Bool {
    let result = wrappedMethod(request);
    
    // Check if the item is our specific Teleport Shard
    if StrContains(ToString(request.itemID), "MSN_QuantumNav_Shard") {
        let player = this.GetOwner() as PlayerPuppet;
        if IsDefined(player) {
            AbyssalNavigationSystem.GetInstance().TeleportToOrbit(player);
        }
    }
    
    return result;
}
