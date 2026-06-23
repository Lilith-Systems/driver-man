module MSN.Storylines.BusinessEmployees

import MSN.Core.*
import MSN.Telemetry.*

// =========================================================
// BUSINESS EMPLOYEE MANAGEMENT
// =========================================================

public class BusinessManager extends IScriptable {
    private static let instance: ref<BusinessManager>;

    public final static func GetInstance() -> ref<BusinessManager> {
        if (!IsDefined(BusinessManager.instance)) {
            BusinessManager.instance = new BusinessManager();
        }
        return BusinessManager.instance;
    }

    public final func ProcessPayrollEffects(player: ref<PlayerPuppet>) -> Void {
        let ts = GameInstance.GetTransactionSystem(player.GetGame());
        
        let goodGuysCount = 0;
        let badGuysCount = 0;
        
        // Check Good Guys
        if ts.HasItem(player, ItemID.FromTDBID(t"Items.MSN_Employee_NCPD")) { goodGuysCount += 1; }
        if ts.HasItem(player, ItemID.FromTDBID(t"Items.MSN_Employee_CorpoSec")) { goodGuysCount += 1; }
        
        // Check Bad Guys
        if ts.HasItem(player, ItemID.FromTDBID(t"Items.MSN_Employee_RogueMerc")) { badGuysCount += 1; }
        if ts.HasItem(player, ItemID.FromTDBID(t"Items.MSN_Employee_Scavenger")) { badGuysCount += 1; }
        
        // Apply Telemetry and Buffs
        if goodGuysCount > 0 {
            // Good guys lower the "heat" and provide armor buffs
            let defenseBuff = ToString(goodGuysCount * 15);
            MSN_Log("Syndicate_Employees", "GOOD_GUY_PAYROLL | Heat Reduced | Armor Buff Active: +" + defenseBuff);
            
            // In a full implementation, we'd apply a TweakDB status effect. 
            // For now, we simulate the backend economy event:
            MSN_Log("PreventionSystem", "NCPD Retainer Active. Bribes successfully routed.");
        }
        
        if badGuysCount > 0 {
            // Bad guys drastically increase revenue but generate heat
            let revenueSpike = ToString(badGuysCount * 120);
            MSN_Log("Syndicate_Employees", "BAD_GUY_PAYROLL | Extortion Successful | Revenue Spike: +" + revenueSpike + "_SC");
            
            // Scavenger specific bonus (free components)
            if ts.HasItem(player, ItemID.FromTDBID(t"Items.MSN_Employee_Scavenger")) {
                MSN_Log("Crafting", "Scavenger Chop-Shop delivered spare cyberware parts.");
                // Here we would use ts.GiveItem to grant raw crafting materials
                // ts.GiveItem(player, ItemID.FromTDBID(t"Items.LegendaryMaterial1"), 5);
            }
        }
    }
}

// Hook into the same Player update loop as the gang system
@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
    let result = wrappedMethod();
    
    // Process employee payroll effects immediately on load/refresh
    BusinessManager.GetInstance().ProcessPayrollEffects(this);
    
    return result;
}
