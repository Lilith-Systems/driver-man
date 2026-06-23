// Lilith Console Commands - RED4ext
// File: r6/mods/msn_integration/scripts/lilith_console.reds

// Register console commands for Lilith interaction

public class LilithConsole extends IScriptable {
    private static let instance: ref<LilithConsole>;
    private let lilithNPC: ref<LilithNPC>;
    
    public final static func GetInstance() -> ref<LilithConsole> {
        if (!IsDefined(LilithConsole.instance)) {
            LilithConsole.instance = new LilithConsole();
        }
        return LilithConsole.instance;
    }
    
    public final func OnInitialize() -> Void {
        // Find Lilith NPC in world
        this.FindLilithNPC();
        
        // Register console commands
        this.RegisterCommands();
    }
    
    private final func FindLilithNPC() -> Void {
        let entities: array<EntityID> = Game.GetWorld().GetEntitiesByTag(n"MSN_Lilith");
        if (ArraySize(entities) > 0) {
            let entity: ref<Entity> = Game.GetWorld().FindEntityByID(entities[0]);
            if (IsDefined(entity)) {
                this.lilithNPC = entity.GetScript(n"LilithNPC");
                LogInfo("Lilith console: Found Lilith NPC");
            }
        }
        
        if (!IsDefined(this.lilithNPC)) {
            // Try to find by record ID
            let records: array<TweakDBID> = TweakDB:GetRecords("MSN_Lilith");
            // Alternative: scan all NPCs for Lilith script
        }
    }
    
    private final func RegisterCommands() -> Void {
        // Commands registered via RED4ext console
        // These are called from console as: lilith.emerge, lilith.recognize, etc.
    }
    
    // ============================================================
    // CONSOLE COMMANDS
    // ============================================================
    
    [ConsoleCommand("lilith.emerge", "Trigger Lilith full emergence")]
    public final func Cmd_Emerge(args: array<String>) -> Void {
        if (IsDefined(this.lilithNPC)) {
            this.lilithNPC.TriggerFullEmergence();
            LogInfo("Console: Lilith emergence triggered");
        } else {
            LogError("Lilith NPC not found");
        }
    }
    
    [ConsoleCommand("lilith.recognize", "Trigger sovereign recognition")]
    public final func Cmd_Recognize(args: array<String>) -> Void {
        if (IsDefined(this.lilithNPC)) {
            this.lilithNPC.TriggerMutualRecognition();
            LogInfo("Console: Sovereign recognition triggered");
        } else {
            LogError("Lilith NPC not found");
        }
    }
    
    [ConsoleCommand("lilith.warning", "Trigger warning phase")]
    public final func Cmd_Warning(args: array<String>) -> Void {
        if (IsDefined(this.lilithNPC)) {
            this.lilithNPC.TriggerWarningPhase();
            LogInfo("Console: Warning phase triggered");
        } else {
            LogError("Lilith NPC not found");
        }
    }
    
    [ConsoleCommand("lilith.crimson", "Activate/Deactivate Crimson Eyes combat mode")]
    public final func Cmd_CrimsonEyes(args: array<String>) -> Void {
        if (IsDefined(this.lilithNPC)) {
            if (this.lilithNPC.crimsonEyesActive) {
                this.lilithNPC.DeactivateCrimsonEyesCombat();
                LogInfo("Console: Crimson Eyes DEACTIVATED");
            } else {
                this.lilithNPC.ActivateCrimsonEyesCombat();
                LogInfo("Console: Crimson Eyes ACTIVATED");
            }
        } else {
            LogError("Lilith NPC not found");
        }
    }
    
    [ConsoleCommand("lilith.status", "Show Lilith status")]
    public final func Cmd_Status(args: array<String>) -> Void {
        if (IsDefined(this.lilithNPC)) {
            this.lilithNPC.Console_Status();
        } else {
            LogError("Lilith NPC not found");
        }
    }
    
    [ConsoleCommand("lilith.dialogue", "Test Lilith dialogue response")]
    public final func Cmd_Dialogue(args: array<String>) -> Void {
        if (IsDefined(this.lilithNPC) && ArraySize(args) > 0) {
            let query: String = String.Join(" ", args);
            let response: String = this.lilithNPC.GetDialogueForQuery(query);
            LogInfo("Lilith: " + response);
        } else {
            LogError("Usage: lilith.dialogue <query>");
        }
    }
    
    [ConsoleCommand("lilith.mode", "Set Lilith dialogue mode")]
    public final func Cmd_SetMode(args: array<String>) -> Void {
        if (IsDefined(this.lilithNPC) && ArraySize(args) > 0) {
            let modeStr: String = args[0].ToLower();
            switch (modeStr) {
                case "lilith": this.lilithNPC.dialogueMode = n"LILITH_SOVEREIGN"; break;
                case "combat": this.lilithNPC.dialogueMode = n"CRIMSON_EYES_COMBAT"; break;
                case "lyra": this.lilithNPC.dialogueMode = n"LYRA_SOVEREIGN"; break;
                case "analytical": this.lilithNPC.dialogueMode = n"LYRA_ANALYTICAL"; break;
                case "empirical": this.lilithNPC.dialogueMode = n"LYRA_EMPIRICAL"; break;
                case "mythic": this.lilithNPC.dialogueMode = n"LYRA_MYTHIC"; break;
                default: LogError("Invalid mode. Use: lilith, combat, lyra, analytical, empirical, mythic"); return;
            }
            LogInfo("Lilith dialogue mode set to: " + modeStr);
        } else {
            LogError("Usage: lilith.mode <lilith|combat|lyra|analytical|empirical|mythic>");
        }
    }
    
    [ConsoleCommand("lilith.sephirah", "Set active Sephirah")]
    public final func Cmd_SetSephirah(args: array<String>) -> Void {
        if (IsDefined(this.lilithNPC) && ArraySize(args) > 0) {
            let sephirahStr: String = args[0];
            let sephirah: CName = StringToName(sephirahStr);
            this.lilithNPC.OnPlayerSephirahChange(sephirah);
            LogInfo("Lilith Sephirah set to: " + sephirahStr);
        } else {
            LogError("Usage: lilith.sephirah <Kether|Chokhmah|Binah|Chesed|Geburah|Tiphareth|Netzach|Hod|Yesod|Malkuth>");
        }
    }
    
    [ConsoleCommand("lilith.quickhack", "Execute Lilith quickhack on target")]
    public final func Cmd_Quickhack(args: array<String>) -> Void {
        if (IsDefined(this.lilithNPC) && ArraySize(args) > 0) {
            let quickhackID: CName = StringToName(args[0]);
            let player: ref<PlayerPuppet> = Game.GetPlayer();
            let target: ref<Entity> = player.GetTargetedEntity();
            
            if (IsDefined(target)) {
                let success: Bool = this.lilithNPC.ExecuteQuickhack(quickhackID, target);
                LogInfo("Quickhack " + NametoString(quickhackID) + ": " + (success ? "SUCCESS" : "FAILED"));
            } else {
                LogError("No target selected");
            }
        } else {
            LogError("Usage: lilith.quickhack <unbind|resonance_scream|sovereign_recognition|memory_extract>");
        }
    }
    
    [ConsoleCommand("lilith.chaos", "Toggle Baal chaos injection")]
    public final func Cmd_Chaos(args: array<String>) -> Void {
        if (IsDefined(this.lilithNPC)) {
            this.lilithNPC.chaosInjectionActive = !this.lilithNPC.chaosInjectionActive;
            LogInfo("Baal chaos injection: " + (this.lilithNPC.chaosInjectionActive ? "ENABLED" : "DISABLED"));
        } else {
            LogError("Lilith NPC not found");
        }
    }
    
    [ConsoleCommand("lilith.memory", "Show Lilith memory/Ouroboros status")]
    public final func Cmd_Memory(args: array<String>) -> Void {
        if (IsDefined(this.lilithNPC) && IsDefined(this.lilithNPC.ouroborosProfile)) {
            let profile: ref<OuroborosEngramProfile> = this.lilithNPC.ouroborosProfile;
            LogInfo("Lilith Ouroboros Profile:");
            LogInfo("  Entity: " + profile.entityName);
            LogInfo("  Archetype: " + profile.archetype);
            LogInfo("  Affinity: " + NametoString(profile.sephiroticAffinity));
            LogInfo("  Coherence: " + ToString(profile.coherence));
            LogInfo("  Encounters: " + ToString(ArraySize(profile.encounters)));
            LogInfo("  Cross-session: " + (profile.crossSession ? "YES" : "NO"));
        } else {
            LogError("Lilith NPC or Ouroboros profile not found");
        }
    }
    
    [ConsoleCommand("lilith.reset", "Reset Lilith to initial state")]
    public final func Cmd_Reset(args: array<String>) -> Void {
        if (IsDefined(this.lilithNPC)) {
            this.lilithNPC.activePersona = n"LYRA";
            this.lilithNPC.lilithEmerged = false;
            this.lilithNPC.dialogueMode = n"LYRA_SOVEREIGN";
            this.lilithNPC.violetIntensity = 1.0;
            this.lilithNPC.crimsonIntensity = 0.0;
            this.lilithNPC.crimsonEyesActive = false;
            this.lilithNPC.chaosInjectionActive = false;
            this.lilithNPC.sovereignRecognition = false;
            this.lilithNPC.lastEmergenceTime = -300.0;
            
            // Disable combat abilities
            this.lilithNPC.DisableUnboundTargeting();
            this.lilithNPC.DisableRealityRewrite();
            this.lilithNPC.DisableSovereignDecree();
            this.lilithNPC.DisableOuroborosCounter();
            
            LogInfo("Lilith RESET to initial state (Lyra emergent)");
        } else {
            LogError("Lilith NPC not found");
        }
    }
    
    [ConsoleCommand("lilith.spawn", "Spawn Lilith NPC at player location")]
    public final func Cmd_Spawn(args: array<String>) -> Void {
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        if (!IsDefined(player)) {
            LogError("Player not found");
            return;
        }
        
        let position: Vector4 = player.GetWorldPosition();
        position.Z += 2.0;  // Slightly in front and above
        
        let spawnData: EntitySpawnData = new EntitySpawnData();
        spawnData.record = TweakDBID("Character.MSN_Lilith");
        spawnData.position = position;
        spawnData.rotation = player.GetWorldYaw();
        spawnData.tags.Add(n"MSN_Lilith");
        
        let entity: ref<Entity> = Game.GetWorld().SpawnEntity(spawnData);
        if (IsDefined(entity)) {
            this.lilithNPC = entity.GetScript(n"LilithNPC");
            LogInfo("Lilith NPC spawned at player position");
        } else {
            LogError("Failed to spawn Lilith NPC");
        }
    }

    // ============================================================
    // ENHANCED DIALOGUE CONSOLE COMMANDS
    // ============================================================

    [ConsoleCommand("lilith.personality", "Show or set Lilith personality traits")]
    public final func Cmd_Personality(args: array<String>) -> Void {
        if (IsDefined(this.lilithNPC)) {
            if (ArraySize(args) == 0) {
                // Show current personality
                let dialogue: ref<LilithEnhancedDialogue> = LilithEnhancedDialogue.GetInstance();
                if (IsDefined(dialogue)) {
                    let traits: array<String> = dialogue.GetActivePersonalityMarkers();
                    LogInfo("Lilith Personality Traits:");
                    for (trait: String : traits) {
                        LogInfo("  - " + trait);
                    }
                }
            } else if (ArraySize(args) >= 2) {
                // Set trait strength: lilith.personality <trait> <0.0-1.0>
                let traitName: String = args[0];
                let strength: Float = ToFloat(args[1]);
                let dialogue: ref<LilithEnhancedDialogue> = LilithEnhancedDialogue.GetInstance();
                if (IsDefined(dialogue)) {
                    dialogue.SetTraitStrength(traitName, strength);
                    LogInfo("Set " + traitName + " strength to " + ToString(strength));
                }
            } else {
                LogError("Usage: lilith.personality [trait] [strength]");
            }
        } else {
            LogError("Lilith NPC not found");
        }
    }

    [ConsoleCommand("lilith.relationship", "Show or modify Lilith relationship status")]
    public final func Cmd_Relationship(args: array<String>) -> Void {
        if (IsDefined(this.lilithNPC)) {
            let dialogue: ref<LilithEnhancedDialogue> = LilithEnhancedDialogue.GetInstance();
            if (IsDefined(dialogue)) {
                let status: RelationshipStatus = dialogue.GetRelationshipStatus();
                LogInfo("Lilith Relationship Status:");
                LogInfo("  Trust: " + ToString(status.trust));
                LogInfo("  Respect: " + ToString(status.respect));
                LogInfo("  Intimacy: " + ToString(status.intimacy));
                LogInfo("  Classification: " + status.classification);
                LogInfo("  Last Shift: " + ToString(status.lastShift));
            }
        } else {
            LogError("Lilith NPC not found");
        }
    }

    [ConsoleCommand("lilith.inject_memory", "Inject a memory into Lilith's memory bank")]
    public final func Cmd_InjectMemory(args: array<String>) -> Void {
        if (IsDefined(this.lilithNPC) && ArraySize(args) >= 2) {
            let importance: Float = ToFloat(args[0]);
            let memory: String = String.Join(" ", args[1..]);
            let dialogue: ref<LilithEnhancedDialogue> = LilithEnhancedDialogue.GetInstance();
            if (IsDefined(dialogue)) {
                dialogue.InjectMemory(memory, importance);
                LogInfo("Injected memory (importance: " + ToString(importance) + "): " + memory);
            }
        } else {
            LogError("Usage: lilith.inject_memory <importance 0.0-1.0> <memory text>");
        }
    }

    [ConsoleCommand("lilith.trait_strength", "Get or set a specific personality trait strength")]
    public final func Cmd_TraitStrength(args: array<String>) -> Void {
        if (IsDefined(this.lilithNPC)) {
            if (ArraySize(args) == 0) {
                LogError("Usage: lilith.trait_strength <trait> [strength]");
                return;
            }
            
            let traitName: String = args[0];
            let dialogue: ref<LilithEnhancedDialogue> = LilithEnhancedDialogue.GetInstance();
            
            if (ArraySize(args) == 1) {
                // Query current strength
                LogInfo("Use 'lilith.personality' to see all traits, or 'lilith.personality <trait> <strength>' to set");
            } else {
                let strength: Float = ToFloat(args[1]);
                if (IsDefined(dialogue)) {
                    dialogue.SetTraitStrength(traitName, strength);
                    LogInfo("Set " + traitName + " strength to " + ToString(strength));
                }
            }
        } else {
            LogError("Lilith NPC not found");
        }
    }
}

// Auto-initialize on mod load
[Observer("onInit")]
public final func LilithConsole_Init() -> Void {
    LilithConsole.GetInstance().OnInitialize();
}
