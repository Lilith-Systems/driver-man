module MSNIntegration.CyberpsychosisUI

public class StopCyberpsychosisUIEvent extends Event {}

@wrapMethod(ItemActionsHelper)
public final static func ConsumeItem(executor: wref<GameObject>, item: ItemID, fromEquippedSlot: Bool) -> Void {
    wrappedMethod(executor, item, fromEquippedSlot);
    
    let tdbid: TweakDBID = ItemID.GetTDBID(item);
    let itemName: String = TDBID.ToStringDEBUG(tdbid);
    
    if StrContains(itemName, "LiquidChrome") || StrContains(itemName, "NeuralFire") || StrContains(itemName, "liquid_chrome") || StrContains(itemName, "neural_fire") {
        let player = executor as PlayerPuppet;
        if IsDefined(player) {
            player.TriggerMSNCyberpsychosisUI();
            
            // Queue stop event after 15 seconds for demonstration, since we don't know the exact buff duration
            let delaySystem = GameInstance.GetDelaySystem(player.GetGame());
            delaySystem.DelayEvent(player, new StopCyberpsychosisUIEvent(), 15.0);
        }
    }
}

@addMethod(PlayerPuppet)
protected cb func OnStopCyberpsychosisUIEvent(evt: ref<StopCyberpsychosisUIEvent>) -> Bool {
    this.StopMSNCyberpsychosisUI();
    return true;
}

@addMethod(PlayerPuppet)
public func TriggerMSNCyberpsychosisUI() -> Void {
    let uiSystemBB: ref<IBlackboard> = GameInstance.GetBlackboardSystem(this.GetGame()).Get(GetAllBlackboardDefs().UI_System);
    
    if IsDefined(uiSystemBB) {
        uiSystemBB.SetBool(GetAllBlackboardDefs().UI_System.IsInMenuGlitchTimerActive, true);
        uiSystemBB.SetFloat(GetAllBlackboardDefs().UI_System.MenuGlitchTimer, 1.0);
    }
    
    // Massive UI glitch overlay and chromatic aberration via standard relic/johnny effects
    GameObjectEffectHelper.StartEffectEvent(this, n"relic_glitch_heavy");
    GameObjectEffectHelper.StartEffectEvent(this, n"screen_glitch_heavy");
    GameObjectEffectHelper.StartEffectEvent(this, n"johnny_hud_glitch");
    
    GameObject.PlaySoundEvent(this, n"ui_menu_on_glitch");
}

@addMethod(PlayerPuppet)
public func StopMSNCyberpsychosisUI() -> Void {
    let uiSystemBB: ref<IBlackboard> = GameInstance.GetBlackboardSystem(this.GetGame()).Get(GetAllBlackboardDefs().UI_System);
    
    if IsDefined(uiSystemBB) {
        uiSystemBB.SetBool(GetAllBlackboardDefs().UI_System.IsInMenuGlitchTimerActive, false);
        uiSystemBB.SetFloat(GetAllBlackboardDefs().UI_System.MenuGlitchTimer, 0.0);
    }
    
    GameObjectEffectHelper.StopEffectEvent(this, n"relic_glitch_heavy");
    GameObjectEffectHelper.StopEffectEvent(this, n"screen_glitch_heavy");
    GameObjectEffectHelper.StopEffectEvent(this, n"johnny_hud_glitch");
}
