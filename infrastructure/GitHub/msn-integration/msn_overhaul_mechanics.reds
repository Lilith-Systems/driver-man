module MSN.OverhaulMechanics

import MSN.Core.*
import MSN.Telemetry.*

// =========================================================
// SEPHIROTIC OVERDRIVE & IMMERSIVE FEEDBACK
// =========================================================

@wrapMethod(PlayerPuppet)
protected cb func OnAction(action: ListenerAction, consumer: ListenerActionConsumer) -> Bool {
    let result = wrappedMethod(action, consumer);
    let actionName: CName = ListenerAction.GetName(action);
    
    // Listen for the Cyberware activation key (e.g. Sandevistan/Berserk)
    if Equals(actionName, n"Vision") || Equals(actionName, n"UseCyberware") {
        if MSN_IsNodeActive("KETER") || MSN_IsNodeActive("DAAT") {
            this.TriggerSephiroticOverdrive();
        }
    }
    return result;
}

@addMethod(PlayerPuppet)
public func TriggerSephiroticOverdrive() -> Void {
    // 1. Time Dilation (Sandevistan base)
    StatusEffectHelper.ApplyStatusEffect(this, t"BaseStatusEffect.SandevistanPlayer");
    
    // 2. Sephirotic Aura & VFX
    let activeNode = MSN_GetActiveNode();
    if Equals(activeNode, "GEVURAH") {
        // Red/Aggressive Glitch
        GameObjectEffectHelper.StartEffectEvent(this, n"glitch_heavy");
        GameObject.PlaySoundEvent(this, n"vfx_cyberware_glitch");
    } else if Equals(activeNode, "CHESED") {
        // Blue/Healing Glitch
        GameObjectEffectHelper.StartEffectEvent(this, n"healing_glitch");
    } else {
        // Standard Da'at Violet/Abyssal VFX
        GameObjectEffectHelper.StartEffectEvent(this, n"blackwall_hacks_glitch");
    }
    
    // 3. Screen Tearing (Immersive Feedback)
    let psmEvent: ref<PSMAddOnDemandStateMachine> = new PSMAddOnDemandStateMachine();
    psmEvent.stateMachineName = n"RelicMalfunction";
    this.QueueEvent(psmEvent);
    
    MSN_Log("Overhaul", "Sephirotic Overdrive Triggered. Node: " + activeNode);
}

// =========================================================
// ABYSSAL GRAVITY WELL (MOVEMENT OVERHAUL)
// =========================================================

@wrapMethod(PlayerPuppet)
protected cb func OnJump(evt: ref<JumpEvent>) -> Bool {
    let result = wrappedMethod(evt);
    
    // Mid-air directional hover if Antigravity is active
    if MSN_IsNodeActive("ANTIGRAVITY") || MSN_IsNodeActive("DAAT") {
        // Apply micro-levitation status effect
        StatusEffectHelper.ApplyStatusEffect(this, t"BaseStatusEffect.HoverJump");
        
        // Spawn void particles at feet
        GameObjectEffectHelper.StartEffectEvent(this, n"custom_abyssal_jump_fx");
    }
    return result;
}

// =========================================================
// IMMERSIVE WEAPON RECOIL & SENSORY DISTORTION
// =========================================================

@wrapMethod(WeaponObject)
protected cb func OnShoot(event: ref<ShootEvent>) -> Bool {
    let result = wrappedMethod(event);
    let owner = this.GetInstigator() as PlayerPuppet;
    
    if IsDefined(owner) {
        // If firing an MSN Ouroboros or Sephirotic weapon
        if StrContains(ToString(this.GetWeaponRecord().ItemType().Type()), "MSN") {
            // Apply heavy camera shake
            let recoilEvent = new RecoilEvent();
            owner.QueueEvent(recoilEvent);
            
            // Random chance for HUD glitch to simulate computational stress
            if RandF() < 0.15 {
                GameObjectEffectHelper.StartEffectEvent(owner, n"hack_glitch");
            }
        }
    }
    return result;
}

// =========================================================
// METACONSCIOUS HACKING (EIDOLON BUDGETS)
// =========================================================

@wrapMethod(ScriptedPuppet)
protected cb func OnQuickHackTriggered(evt: ref<QuickHackEvent>) -> Bool {
    let result = wrappedMethod(evt);
    
    // Override Quickhack mechanics to use MSN Eidolon points instead of standard RAM
    let eidolonBudget = MSN_GetEidolonBudget();
    
    if eidolonBudget > 20.0 {
        // Convert enemy to AI Swarm (Cyberpsychosis variant with friendly fire turned off)
        StatusEffectHelper.ApplyStatusEffect(this, t"BaseStatusEffect.Cyberpsychosis");
        
        // Change attitude to friendly
        this.GetAttitudeAgent().SetAttitudeGroup(n"player");
        
        // Deduct Budget
        MSN_DeductEidolonBudget(20.0);
        
        GameObjectEffectHelper.StartEffectEvent(this, n"blackwall_upload");
    } else {
        MSN_Log("Hacking", "Insufficient Eidolon Budget for Swarm Conversion.");
    }
    
    return result;
}
