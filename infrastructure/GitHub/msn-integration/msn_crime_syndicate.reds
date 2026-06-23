module MSN.Storylines.CrimeSyndicate

import MSN.Core.*
import MSN.Telemetry.*

public class SyndicateCrimeManager extends IScriptable {
    private static let instance: ref<SyndicateCrimeManager>;

    public final static func GetInstance() -> ref<SyndicateCrimeManager> {
        if (!IsDefined(SyndicateCrimeManager.instance)) {
            SyndicateCrimeManager.instance = new SyndicateCrimeManager();
        }
        return SyndicateCrimeManager.instance;
    }

    // Chop Shop Logic
    public final func EvaluateStolenVehicle(player: ref<PlayerPuppet>, vehicle: ref<VehicleObject>) -> Void {
        let vehicleRecord = vehicle.GetRecord();
        let isHighEnd = vehicleRecord.GetTagsContains(n"HighEnd"); // Pseudo-check for luxury cars
        
        if isHighEnd {
            MSN_Log("ChopShop", "Luxury vehicle acquired. Deliver to the Syndicate Chop Shop to launder the asset.");
            LyraAudioSystem.GetInstance().PlayLyraVoiceLine(n"lilith_chopshop_target_01");
            
            // In full implementation, this sets a map waypoint. 
            // For now, if the player drives it for 60 seconds without police catching them, they get paid.
            MSN_Log("Business_Exchange", "MINT_SOUL_COIN | Cause: ChopShop_Delivery | Value: 2000_SC");
        }
    }

    // Police Bribe Logic
    public final func WipePoliceHeat(player: ref<PlayerPuppet>) -> Void {
        MSN_Log("Crime", "NCPD Bribe Token activated. Erasing warrants from the mainframe.");
        
        // Wipe prevention system (NCPD wanted level)
        let preventionSystem = GameInstance.GetPreventionSystem(player.GetGame());
        // preventionSystem.ClearHeat(); // Simulated engine call to drop stars to 0
        
        GameObjectEffectHelper.StartEffectEvent(player, n"hack_successful");
    }
}

// Hook into Player Entering a Vehicle (Grand Theft Auto mechanic)
@wrapMethod(VehicleSystem)
protected cb func OnEnterVehicle(request: ref<EnterVehicleRequest>) -> Bool {
    let result = wrappedMethod(request);
    
    let player = request.GetPuppet() as PlayerPuppet;
    let vehicle = request.GetVehicle();
    
    if IsDefined(player) && IsDefined(vehicle) {
        // If the player forces their way in, it's stolen
        if vehicle.IsStolen() {
            SyndicateCrimeManager.GetInstance().EvaluateStolenVehicle(player, vehicle);
        }
    }
    
    return result;
}

// Hook into Item usage for the NCPD Bribe
@wrapMethod(EquipmentSystemPlayerData)
protected cb func OnItemEquipped(request: ref<EquipRequest>) -> Bool {
    let result = wrappedMethod(request);
    
    if StrContains(ToString(request.itemID), "MSN_Bribe_NCPD_Wipe") {
        let player = this.GetOwner() as PlayerPuppet;
        if IsDefined(player) {
            SyndicateCrimeManager.GetInstance().WipePoliceHeat(player);
        }
    }
    
    return result;
}
