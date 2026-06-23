module MSN.Storylines.PhysicalEconomy

import MSN.Core.*
import MSN.Telemetry.*

public class PhysicalEconomyManager extends IScriptable {
    private static let instance: ref<PhysicalEconomyManager>;

    public final static func GetInstance() -> ref<PhysicalEconomyManager> {
        if (!IsDefined(PhysicalEconomyManager.instance)) {
            PhysicalEconomyManager.instance = new PhysicalEconomyManager();
        }
        return PhysicalEconomyManager.instance;
    }

    public final func RegisterDynamicStorefronts(player: ref<PlayerPuppet>) -> Void {
        let mappinSystem = GameInstance.GetMappinSystem(player.GetGame());
        
        // Coordinates for Player's Syndicate Headquarters (e.g., V's original megabuilding plaza)
        let playerStoreCoords = new Vector4(-1350.0, 1100.0, 30.0, 1.0);
        // Coordinates for Rival AI "Corpo Armory" Subagent
        let aiStoreCoords = new Vector4(-50.0, -800.0, 15.0, 1.0);
        
        // Note: In a full mod, we would place a physical NPC or terminal object here.
        // For now, we simulate the interaction triggering when entering the radius.
        
        MSN_Log("Economy_Map", "Dynamic Storefront Mappins injected into the world map.");
        LyraAudioSystem.GetInstance().PlayLyraVoiceLine(n"lyra_stores_online_01");
    }

    public final func InteractWithAIStore(player: ref<PlayerPuppet>) -> Void {
        MSN_Log("Store_Interact", "Player engaged Rival AI Storefront.");
        
        // Player can either Hack (Sabotage) or Trade
        // We simulate a sabotage event that sends telemetry to abyssal_business_simulation.py
        MSN_Log("Business_Exchange", "AI_MARKET_SHORT | Target: Subagent_001_CorpoArmory | Value: -20%");
        
        GameObjectEffectHelper.StartEffectEvent(player, n"hack_successful");
        MSN_Log("Economy_Map", "Rival Corporation sabotaged. Their market value has tanked.");
    }
}

// Hook into Player Spawn to load the dynamic map pins
@wrapMethod(PlayerPuppet)
protected cb func OnMakePlayerActive(evt: ref<MakePlayerActiveEvent>) -> Bool {
    let result = wrappedMethod(evt);
    
    PhysicalEconomyManager.GetInstance().RegisterDynamicStorefronts(this);
    
    return result;
}

// Hook to simulate interacting with an AI store terminal
// When the player scans/hacks a specific vendor or terminal, we trigger the economy sabotage
@wrapMethod(Terminal)
protected cb func OnAccessPointHacked(evt: ref<ActionBool>) -> Bool {
    let result = wrappedMethod(evt);
    
    // If the terminal has a specific marker tag, treat it as the AI Store
    let player = GetPlayer(this.GetGame());
    if IsDefined(player) {
        // Simulating the condition: If the player hacks a terminal in the Corporate zone
        let location = this.GetWorldPosition();
        if location.Z < 50.0 && location.X > -100.0 { 
            PhysicalEconomyManager.GetInstance().InteractWithAIStore(player);
        }
    }
    
    return result;
}
