module MSN.CraftingOverhaul

import MSN.Core.*
import MSN.Telemetry.*

// =========================================================
// CRAFTING OVERHAUL: SEPHIROTIC BOOSTS
// =========================================================

@wrapMethod(CraftingSystem)
private final func ProcessCraftItem(request: ref<CraftItemRequest>) -> Void {
    // Let the base game process the crafting event first
    wrappedMethod(request);
    
    // MSN Override: Apply massive RNG bonuses if crafted during Sephirotic Overdrive
    let player = this.GetGameInstance().GetPlayerSystem().GetLocalPlayerControlledGameObject() as PlayerPuppet;
    let craftedItem = request.itemRecord;
    
    if IsDefined(player) && MSN_IsNodeActive("DAAT") {
        // Pseudo-logic to simulate injecting a random modifier into the newly crafted item
        MSN_Log("Crafting", "Da'at Node Active. Applying Abyssal multiplier to crafted item.");
        
        // Example: Add a custom hidden status effect or stat bonus to the crafted item ID
        // (In REDscript, applying raw stats directly to a crafted instance requires accessing the itemData)
        // This is a representative overhaul hook.
        GameObjectEffectHelper.StartEffectEvent(player, n"hack_glitch");
        GameObject.PlaySoundEvent(player, n"ui_loot_legendary");
    }
    
    // =========================================================
    // ABYSSAL BUSINESS INTEGRATION (THE LOCH EXCHANGE)
    // =========================================================
    if IsDefined(player) {
        let itemName = ToString(craftedItem.GetId());
        
        // 1. Mint Abyssal Soul Coins for high tier crafts
        let isLegendary = Equals(craftedItem.Quality().Name(), n"Legendary");
        if isLegendary || StrContains(itemName, "MSN") {
            // Log telemetry which the NGD python bridge intercepts to update localhost:8000
            MSN_Log("Business_Exchange", "MINT_SOUL_COIN | Cause: Legendary_Craft | Item: " + itemName);
            GameObject.PlaySoundEvent(player, n"ui_loot_iconic");
            
            // 2. Auto-list the crafted asset on the local CLOB (Abyssal Exchange)
            MSN_Log("Market_Listing", "CREATE_ASK | Asset: " + itemName + " | Origin: V_Workshop");
            
            // 3. Pay 2% Design Fee to Nessie's Treasury
            MSN_Log("Treasury_Deposit", "NESSIE_FEE | Source: Crafting_Tax | Amount: 2.0_SC");
        }
    }
}

// =========================================================
// CUSTOMIZATION OVERHAUL: MULTIPLICATIVE MODS
// =========================================================

@wrapMethod(ItemModificationSystem)
private final func InstallItemPart(obj: ref<GameObject>, itemID: ItemID, partItemID: ItemID, slotID: TweakDBID) -> Bool {
    let result = wrappedMethod(obj, itemID, partItemID, slotID);
    
    if result {
        // When a weapon attachment is installed, multiply its effect by the Eidolon budget!
        let budget = MSN_GetEidolonBudget();
        if budget > 50.0 {
            MSN_Log("Customization", "Attachment installed with High Eidolon Budget. Overclocking weapon.");
            GameObjectEffectHelper.StartEffectEvent(obj, n"emp_hit");
            
            // BUSINESS INTEGRATION: Sell weapon tuning telemetry to the market
            MSN_Log("Business_Exchange", "SELL_DATA | Type: Weapon_Tuning_Telemetry | Revenue: 1.5_SC");
            MSN_Log("Treasury_Deposit", "NESSIE_FEE | Source: Telemetry_Tax | Amount: 0.15_SC");
        }
    }
    
    return result;
}
