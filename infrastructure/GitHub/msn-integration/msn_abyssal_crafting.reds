module MSN.Storylines.AbyssalCrafting

import MSN.Core.*
import MSN.Telemetry.*

public class AbyssalCraftingSystem extends IScriptable {
    private static let instance: ref<AbyssalCraftingSystem>;

    public final static func GetInstance() -> ref<AbyssalCraftingSystem> {
        if (!IsDefined(AbyssalCraftingSystem.instance)) {
            AbyssalCraftingSystem.instance = new AbyssalCraftingSystem();
        }
        return AbyssalCraftingSystem.instance;
    }

    public final func ProcessAbyssalCraft(player: ref<PlayerPuppet>, itemID: ItemID, quality: gamedataQuality) -> Void {
        // Only trigger Abyssal Asset minting on Epic or Legendary crafts
        if quality == gamedataQuality.Legendary || quality == gamedataQuality.Epic {
            MSN_Log("Crafting", "High-tier item fabricated. Minting corresponding Abyssal Asset on the Loch Exchange.");
            
            // Send telemetry to the Python backend to register this item as a tradeable asset
            let itemStr = ToString(itemID);
            MSN_Log("Abyssal_Asset", "MINT_ASSET | Item: " + itemStr + " | Owner: Player_Syndicate");
            
            // Reward the player with Soul Coins for supplying the economy
            MSN_Log("Business_Exchange", "MINT_SOUL_COIN | Cause: Crafting_Bounty | Value: 150_SC");
            
            // Visual feedback
            GameObjectEffectHelper.StartEffectEvent(player, n"hack_successful");
        }
    }
}

// Hook into the core crafting system
@wrapMethod(CraftingSystem)
private final func ProcessCraftItemRequest(request: ref<CraftItemRequest>) -> Void {
    // Let the vanilla game handle the actual inventory insertion
    wrappedMethod(request);
    
    let player = this.GetPlayer();
    if IsDefined(player) {
        // Fetch the quality of the item being crafted
        let itemRecord = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(request.itemToCraft));
        let qualityRecord = itemRecord.Quality();
        let quality = qualityRecord.Type();
        
        AbyssalCraftingSystem.GetInstance().ProcessAbyssalCraft(player, request.itemToCraft, quality);
    }
}
