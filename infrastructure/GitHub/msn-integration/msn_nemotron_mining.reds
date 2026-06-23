module MSN.Nemotron.Mining

import AI.commands.*
import AI.base.*

@addField(NPCPuppet)
protected let m_msnLastRigCheckTime: Float;

@wrapMethod(NPCPuppet)
protected cb func OnUpdate(deltaTime: Float) -> Bool {
    let result = wrappedMethod(deltaTime);
    
    // Only affect civilians/crowd NPCs
    if this.IsCivilian() || this.IsCrowd() {
        let simTime: Float = EngineTime.ToFloat(GameInstance.GetSimTime(this.GetGame()));
        
        // Throttled check: evaluate every 3 seconds to preserve performance
        if (simTime - this.m_msnLastRigCheckTime) > 3.0 {
            this.m_msnLastRigCheckTime = simTime;
            this.MSN_EvaluateMiningRigProximity();
        }
    }
    return result;
}

@addMethod(NPCPuppet)
private func MSN_EvaluateMiningRigProximity() -> Void {
    let aiComponent: ref<AIHumanComponent> = this.GetAIControllerComponent();
    if !IsDefined(aiComponent) {
        return;
    }

    let msnRegistry: ref<MSNRegistrySystem> = MSNRegistrySystem.GetInstance(this.GetGame());
    if !IsDefined(msnRegistry) {
        return;
    }

    let searchRadius: Float = 20.0;
    let myPos: Vector4 = this.GetWorldPosition();
    let rigs: array<ref<GameObject>> = msnRegistry.GetActiveRigs();
    
    let i: Int32 = 0;
    while i < ArraySize(rigs) {
        let rig: ref<GameObject> = rigs[i];
        if IsDefined(rig) {
            let rigPos: Vector4 = rig.GetWorldPosition();
            let dist: Float = Vector4.Distance(myPos, rigPos);
            
            if dist < searchRadius {
                this.MSN_CommandInspectRig(rig, aiComponent);
                break; // Only inspect one rig at a time
            }
        }
        i += 1;
    }
}

@addMethod(NPCPuppet)
private func MSN_CommandInspectRig(rig: ref<GameObject>, aiComponent: ref<AIHumanComponent>) -> Void {
    // Issue AI Move Command to walk to the rig
    let moveAction: ref<AIMoveToCommand> = new AIMoveToCommand();
    moveAction.target = rig;
    moveAction.movementType = moveMovementType.Walk;
    moveAction.ignoreNavigation = false;
    
    // Issue LookAt Command to inspect the rig once close
    let lookAction: ref<AILookAtCommand> = new AILookAtCommand();
    lookAction.target = rig;
    lookAction.duration = 15.0; // Stare at it for 15 seconds
    
    aiComponent.SendCommand(moveAction);
    aiComponent.SendCommand(lookAction);
}

// --------------------------------------------------------
// MSN Registry System for tracking Abyssal Mining Rigs
// --------------------------------------------------------
public class MSNRegistrySystem extends ScriptableSystem {
    private let activeRigs: array<ref<GameObject>>;

    public static func GetInstance(game: GameInstance) -> ref<MSNRegistrySystem> {
        let system: ref<MSNRegistrySystem> = GameInstance.GetScriptableSystemsContainer(game).Get(n"MSNRegistrySystem") as MSNRegistrySystem;
        return system;
    }

    public func GetActiveRigs() -> array<ref<GameObject>> {
        return this.activeRigs;
    }
    
    public func RegisterRig(rig: ref<GameObject>) -> Void {
        if !ArrayContains(this.activeRigs, rig) {
            ArrayPush(this.activeRigs, rig);
        }
    }
    
    public func UnregisterRig(rig: ref<GameObject>) -> Void {
        ArrayRemove(this.activeRigs, rig);
    }
    
    private func OnAttach() -> Void {
        // Init logic
    }
    
    private func OnDetach() -> Void {
        ArrayClear(this.activeRigs);
    }
}
