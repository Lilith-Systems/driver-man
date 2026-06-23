/**
 * MSN Abyssal Skills Integration
 * Maps Abyssal Assets 24-skills system to Cyberpunk 2077 perk trees
 * Integrates with Guild Charters: Ouroboros Alchemists, Void Runners, Loch Smugglers
 */

public class MSNAbyssalSkillSystem extends IScriptable {

    // Guild alignment enum
    public enum EGuildAlignment {
        Unaligned = 0,
        OuroborosAlchemists = 1,  // Binah - Structure/Crafting
        VoidRunners = 2,          // Chokhmah - Insight/Netrunning
        LochSmugglers = 3         // Netzach - Victory/Economy
    }

    // Skill categories mapping to Cyberpunk attributes
    public enum EAbyssalCategory {
        Gathering = 0,       // -> BODY / TECHNICAL
        Processing = 1,      // -> TECHNICAL / INTELLECT
        Crafting = 2,        // -> TECHNICAL / INTELLECT
        Knowledge = 3,       // -> INTELLECT / COOL
        SocialEconomic = 4,  // -> REFLEXES / COOL
        CombatSurvival = 5   // -> BODY / REFLEXES
    }

    // 24 Abyssal skill IDs
    public const StrAbyssalSkillIDs: array<String> = {
        // Gathering (5)
        "dredging", "salvaging", "foraging", "hunting", "navigation",
        // Processing (4)
        "salvage_processing", "fiber_working", "bone_carving", "metallurgy",
        // Crafting (5)
        "haberdashery", "enchanting", "alchemy", "runecrafting", "masterwork",
        // Knowledge (3)
        "lore", "sonar_tuning", "scholarship",
        // Social/Economic (3)
        "trading", "negotiation", "guild_management",
        // Combat/Survival (3)
        "evasion", "harpooning", "survival"
    }

    @Property
    public let skillData: array<SAbyssalSkillData>;

    @Property
    public let playerGuild: EGuildAlignment = EGuildAlignment.Unaligned;

    @Property
    public let guildPoints: Int32 = 0;

    // Initialize all 24 skills with Guild affiliations
    public final func Initialize() -> Void {
        this.skillData = this.GenerateAllSkills();
        this.RegisterGuildCallbacks();
    }

    private final func GenerateAllSkills() -> array<SAbyssalSkillData> {
        let skills: array<SAbyssalSkillData>;

        // ===== GUILD: OUROBOROS ALCHEMISTS (Binah) =====
        // Primary: Crafting, Processing, Knowledge
        // Synergy: Alchemy, Runecrafting, Enchanting, Masterwork, Metallurgy

        // Alchemy - CORE OUROBOROS SKILL
        skills.Push(SAbyssalSkillData("alchemy", "Alchemy", EAbyssalCategory.Crafting,
            EGuildAlignment.OuroborosAlchemists, 130, 1.13,
            { "transmute_materials", "essence_extraction", "potion_brewing", "legendary_catalyst" }));

        // Runecrafting - CORE OUROBOROS SKILL
        skills.Push(SAbyssalSkillData("runecrafting", "Runecrafting", EAbyssalCategory.Crafting,
            EGuildAlignment.OuroborosAlchemists, 150, 1.12,
            { "reality_inscription", "brim_enchantment", "law_rewriting", "mythic_sigil" }));

        // Enchanting - CORE OUROBOROS SKILL
        skills.Push(SAbyssalSkillData("enchanting", "Enchanting", EAbyssalCategory.Crafting,
            EGuildAlignment.OuroborosAlchemists, 120, 1.14,
            { "weave_magic", "fate_binding", "destiny_threading", "living_stitch" }));

        // Masterwork - CORE OUROBOROS SKILL
        skills.Push(SAbyssalSkillData("masterwork", "Masterwork", EAbyssalCategory.Crafting,
            EGuildAlignment.OuroborosAlchemists, 200, 1.10,
            { "mythic_construction", "history_making", "perfect_form", "eternal_brim" }));

        // Metallurgy - OUROBOROS PROCESSING
        skills.Push(SAbyssalSkillData("metallurgy", "Metallurgy", EAbyssalCategory.Processing,
            EGuildAlignment.OuroborosAlchemists, 140, 1.13,
            { "abyssal_smelting", "meteoritic_iron", "sunken_alloys", "orichalcum_processing" }));

        // Scholarship - OUROBOROS KNOWLEDGE
        skills.Push(SAbyssalSkillData("scholarship", "Scholarship", EAbyssalCategory.Knowledge,
            EGuildAlignment.OuroborosAlchemists, 120, 1.13,
            { "ancient_texts", "fate_weaving", "magic_mathematics", "akashic_access" }));

        // Lore - OUROBOROS KNOWLEDGE
        skills.Push(SAbyssalSkillData("lore", "Lore", EAbyssalCategory.Knowledge,
            EGuildAlignment.OuroborosAlchemists, 80, 1.18,
            { "cryptid_memory", "current_knowledge", "secret_archives", "loch_remembrance" }));

        // ===== GUILD: VOID RUNNERS (Chokhmah) =====
        // Primary: Knowledge, Combat, Processing
        // Synergy: Sonar_Tuning, Evasion, Hacking, Quickhack_RAM, Netrunning

        // Sonar Tuning - CORE VOID RUNNER SKILL (maps to Netrunning/Quickhacking)
        skills.Push(SAbyssalSkillData("sonar_tuning", "Sonar Tuning", EAbyssalCategory.Knowledge,
            EGuildAlignment.VoidRunners, 90, 1.16,
            { "frequency_mastery", "deep_vision", "auto_hit_resonance", "angle_memory" }));

        // Evasion - CORE VOID RUNNER SKILL
        skills.Push(SAbyssalSkillData("evasion", "Evasion", EAbyssalCategory.CombatSurvival,
            EGuildAlignment.VoidRunners, 120, 1.14,
            { "phase_shift", "optics_glitch", "reposition", "not_being_there" }));

        // Navigation - VOID RUNNER SUPPORT (maps to movement/traversal)
        skills.Push(SAbyssalSkillData("navigation", "Navigation", EAbyssalCategory.Gathering,
            EGuildAlignment.VoidRunners, 80, 1.17,
            { "chart_uncharted", "find_unfindable", "traversal_mastery", "never_lost" }));

        // Salvage Processing - VOID RUNNER PROCESSING (maps to component extraction)
        skills.Push(SAbyssalSkillData("salvage_processing", "Salvage Processing", EAbyssalCategory.Processing,
            EGuildAlignment.VoidRunners, 110, 1.15,
            { "wreckage_breakdown", "component_extraction", "pure_materials", "data_recovery" }));

        // Bone Carving - VOID RUNNER PROCESSING (maps to cyberware modding)
        skills.Push(SAbyssalSkillData("bone_carving", "Bone Carving", EAbyssalCategory.Processing,
            EGuildAlignment.VoidRunners, 130, 1.14,
            { "cyberware_shaping", "chitin_modding", "ivory_tools", "skeletal_weave" }));

        // ===== GUILD: LOCH SMUGGLERS (Netzach) =====
        // Primary: Social/Economic, Gathering, Combat
        // Synergy: Trading, Negotiation, Dredging, Hunting, Harpooning

        // Trading - CORE SMUGGLER SKILL
        skills.Push(SAbyssalSkillData("trading", "Trading", EAbyssalCategory.SocialEconomic,
            EGuildAlignment.LochSmugglers, 70, 1.20,
            { "market_manipulation", "buy_low_sell_high", "liquidity_provision", "arbitrage_mastery" }));

        // Negotiation - CORE SMUGGLER SKILL
        skills.Push(SAbyssalSkillData("negotiation", "Negotiation", EAbyssalCategory.SocialEconomic,
            EGuildAlignment.LochSmugglers, 80, 1.18,
            { "words_as_weapons", "price_suggestion", "pacify_threats", "everything_negotiable" }));

        // Guild Management - CORE SMUGGLER SKILL
        skills.Push(SAbyssalSkillData("guild_management", "Guild Management", EAbyssalCategory.SocialEconomic,
            EGuildAlignment.LochSmugglers, 100, 1.15,
            { "crew_leadership", "fortress_building", "loyalty_compounding", "shared_liquidity" }));

        // Dredging - SMUGGLER GATHERING (resource acquisition)
        skills.Push(SAbyssalSkillData("dredging", "Dredging", EAbyssalCategory.Gathering,
            EGuildAlignment.LochSmugglers, 100, 1.15,
            { "depth_extraction", "sonar_guided", "party_dredge", "trench_access" }));

        // Hunting - SMUGGLER GATHERING (loot acquisition)
        skills.Push(SAbyssalSkillData("hunting", "Hunting", EAbyssalCategory.Gathering,
            EGuildAlignment.LochSmugglers, 150, 1.13,
            { "cryptid_tracking", "trophy_collection", "weak_point_mastery", "apex_predator" }));

        // Harpooning - SMUGGLER COMBAT
        skills.Push(SAbyssalSkillData("harpooning", "Harpooning", EAbyssalCategory.CombatSurvival,
            EGuildAlignment.LochSmugglers, 130, 1.13,
            { "one_shot_kill", "part_targeting", "perfect_throw", "reposition_throw" }));

        // Survival - SMUGGLER COMBAT
        skills.Push(SAbyssalSkillData("survival", "Survival", EAbyssalCategory.CombatSurvival,
            EGuildAlignment.LochSmugglers, 110, 1.15,
            { "oxygen_management", "pressure_resistance", "sanity_preservation", "deep_endurance" }));

        // ===== CROSS-GUILD / UNALIGNED =====
        skills.Push(SAbyssalSkillData("salvaging", "Salvaging", EAbyssalCategory.Gathering,
            EGuildAlignment.Unaligned, 120, 1.14,
            { "artifact_recovery", "wreck_exploration", "metal_recovery", "mystery_recovery" }));

        skills.Push(SAbyssalSkillData("foraging", "Foraging", EAbyssalCategory.Gathering,
            EGuildAlignment.Unaligned, 90, 1.16,
            { "kelp_harvest", "bioluminescent_flora", "abyssal_fungi", "cryptid_silk" }));

        skills.Push(SAbyssalSkillData("fiber_working", "Fiber Working", EAbyssalCategory.Processing,
            EGuildAlignment.Unaligned, 100, 1.15,
            { "kelp_spinning", "abyssal_silk", "thread_of_power", "haberdashery_supply" }));

        skills.Push(SAbyssalSkillData("haberdashery", "Haberdashery", EAbyssalCategory.Crafting,
            EGuildAlignment.Unaligned, 100, 1.15,
            { "perfect_fit", "signature_style", "living_stitch", "essence_regen" }));

        return skills;
    }

    // Grant all three Guild Charters on shard read
    public final func OnShardRead(player: Player, shardID: String) -> Void {
        if (shardID == "PUBLIC_BROADCAST_Call_to_the_Guilds") {
            this.GrantAllCharters(player);
            this.TriggerGuildChoiceUI(player);
        }
    }

    private final func GrantAllCharters(player: Player) -> Void {
        // Add all three charters to inventory
        player.AddItem("Items.GuildCharter_OuroborosAlchemists", 1);
        player.AddItem("Items.GuildCharter_VoidRunners", 1);
        player.AddItem("Items.GuildCharter_LochSmugglers", 1);

        // Start 60-second choice timer
        this.StartGuildChoiceTimer(player, 60.0);
    }

    private final func StartGuildChoiceTimer(player: Player, duration: Float) -> Void {
        // Timer handled in game - if >1 charter after duration, apply penalty
        Game.GetDelaySystem().DelayEvent(player, this, "OnGuildChoiceTimeout", duration, false);
    }

    public final func OnGuildChoiceTimeout(player: Player) -> Void {
        let charters = this.CountGuildCharters(player);
        if (charters > 1) {
            this.ApplyGuildWarPenalty(player);
        }
    }

    private final func CountGuildCharters(player: Player) -> Int32 {
        let count: Int32 = 0;
        count += player.GetItemCount("Items.GuildCharter_OuroborosAlchemists");
        count += player.GetItemCount("Items.GuildCharter_VoidRunners");
        count += player.GetItemCount("Items.GuildCharter_LochSmugglers");
        return count;
    }

    private final func ApplyGuildWarPenalty(player: Player) -> Void {
        // Severe Overheating + Optics Glitch
        player.ApplyStatusEffect("Overheating_Critical", 60.0);
        player.ApplyStatusEffect("OpticsGlitch_Severe", 120.0);
        player.GetAudioSystem().PlaySound("guild_war_penalty", player.GetWorldPosition());

        // Akashic log
        this.LogAkashic("GUILD_WAR: " + player.GetName() + " violated single-allegiance pact");
    }

    // Guild alignment choice
    public final func ChooseGuild(player: Player, guild: EGuildAlignment) -> Void {
        // Remove other charters
        player.RemoveItem("Items.GuildCharter_OuroborosAlchemists", 99);
        player.RemoveItem("Items.GuildCharter_VoidRunners", 99);
        player.RemoveItem("Items.GuildCharter_LochSmugglers", 99);

        // Grant chosen charter permanently
        switch (guild) {
            case EGuildAlignment.OuroborosAlchemists:
                player.AddItem("Items.GuildCharter_OuroborosAlchemists_Permanent", 1);
                this.playerGuild = EGuildAlignment.OuroborosAlchemists;
                this.UnlockGuildSpecializations(player, EGuildAlignment.OuroborosAlchemists);
                break;
            case EGuildAlignment.VoidRunners:
                player.AddItem("Items.GuildCharter_VoidRunners_Permanent", 1);
                this.playerGuild = EGuildAlignment.VoidRunners;
                this.UnlockGuildSpecializations(player, EGuildAlignment.VoidRunners);
                break;
            case EGuildAlignment.LochSmugglers:
                player.AddItem("Items.GuildCharter_LochSmugglers_Permanent", 1);
                this.playerGuild = EGuildAlignment.LochSmugglers;
                this.UnlockGuildSpecializations(player, EGuildAlignment.LochSmugglers);
                break;
        }

        // Grant guild-specific starter buff
        this.ApplyGuildBuff(player, guild);
    }

    private final func UnlockGuildSpecializations(player: Player, guild: EGuildAlignment) -> Void {
        // Unlock specialization branches for guild skills
        for (skill in this.skillData) {
            if (skill.guildAlignment == guild || skill.guildAlignment == EGuildAlignment.Unaligned) {
                this.UnlockSpecializationBranches(player, skill.id);
            }
        }
    }

    private final func UnlockSpecializationBranches(player: Player, skillID: String) -> Void {
        // Override Cyberpunk perk tree to unlock Abyssal specializations
        let perkTree = player.GetPerkTree("Abyssal_" + skillID);
        if (perkTree != null) {
            perkTree.UnlockSpecializations();
        }
    }

    private final func ApplyGuildBuff(player: Player, guild: EGuildAlignment) -> Void {
        switch (guild) {
            case EGuildAlignment.OuroborosAlchemists:
                // +15% Legendary craft RNG, Reality bending access
                player.AddStatModifier("LegendaryCraftRNG", 15);
                player.UnlockAbility("RealityBending_Craft");
                break;
            case EGuildAlignment.VoidRunners:
                // -50% Quickhack RAM, Local Cerebellum bridge
                player.AddStatModifier("QuickhackRAMReduction", 50);
                player.UnlockAbility("LocalCerebellum_Bridge");
                break;
            case EGuildAlignment.LochSmugglers:
                // Treasury tax bypass, +300 soul_coins/session
                player.AddStatModifier("TreasuryTaxBypass", 100);
                player.AddStatModifier("PassiveIncomePerSession", 300);
                break;
        }
    }

    // XP Granting from Abyssal activities
    public final func GrantSkillXP(player: Player, skillID: String, baseXP: Float, context: SXPContext) -> Void {
        let skill = this.GetSkillData(skillID);
        if (skill == null) return;

        // Apply synergies
        let multiplier = this.CalculateSynergyMultiplier(player, skill);

        // Guild affinity bonus
        if (skill.guildAlignment == this.playerGuild) {
            multiplier *= 1.25; // 25% bonus for aligned guild
        } else if (skill.guildAlignment == EGuildAlignment.Unaligned) {
            multiplier *= 1.10; // 10% for unaligned
        } else {
            multiplier *= 0.75; // 25% penalty for off-guild
        }

        // Activity multipliers
        multiplier *= context.activityMultiplier;

        let finalXP = RoundF(baseXP * multiplier);
        player.AddAbyssalSkillXP(skillID, finalXP);

        // Check level ups
        this.CheckLevelUp(player, skillID);
    }

    private final func CalculateSynergyMultiplier(player: Player, skill: SAbyssalSkillData) -> Float {
        let mult: Float = 1.0;
        for (synergy in skill.synergies) {
            let otherLevel = player.GetAbyssalSkillLevel(synergy.skill_id);
            let thisLevel = player.GetAbyssalSkillLevel(skill.id);
            if (this.EvaluateCondition(synergy.condition, thisLevel, otherLevel)) {
                mult += synergy.value / 100.0;
            }
        }
        return mult;
    }

    private final func EvaluateCondition(condition: String, thisLevel: Int32, otherLevel: Int32) -> Bool {
        switch (condition) {
            case "both_above_30": return thisLevel >= 30 && otherLevel >= 30;
            case "both_above_50": return thisLevel >= 50 && otherLevel >= 50;
            case "both_above_70": return thisLevel >= 70 && otherLevel >= 70;
            case "both_above_90": return thisLevel >= 90 && otherLevel >= 90;
            default: return false;
        }
    }

    private final func CheckLevelUp(player: Player, skillID: String) -> Void {
        let newLevel = player.GetAbyssalSkillLevel(skillID);
        let skill = this.GetSkillData(skillID);
        if (skill == null) return;

        // Unlock perks at milestone levels
        for (unlock in skill.unlocks) {
            if (unlock.level == newLevel) {
                this.GrantUnlock(player, skillID, unlock);
            }
        }

        // Specialization branch unlock at level 10
        if (newLevel == 10) {
            this.UnlockSpecializationChoice(player, skillID);
        }

        // Virtual levels beyond 99
        if (newLevel >= 99) {
            this.HandleVirtualLevels(player, skillID);
        }
    }

    private final func GrantUnlock(player: Player, skillID: String, unlock: SAbyssalUnlock) -> Void {
        switch (unlock.type) {
            case "ability":
                player.UnlockAbility(unlock.data.action);
                break;
            case "recipe":
                player.UnlockRecipe(unlock.data.item);
                break;
            case "zone":
                player.UnlockZone(unlock.data.zone);
                break;
            case "technique":
                player.GrantTechnique(unlock.data);
                break;
            case "passive":
                player.AddPassive(unlock.data);
                break;
            case "cosmetic":
                player.UnlockCosmetic(unlock.data.cape);
                break;
        }
    }

    private final func HandleVirtualLevels(player: Player, skillID: String) -> Void {
        let virtualLevel = player.GetAbyssalVirtualLevel(skillID);
        // Virtual levels 100-120 grant diminishing returns but infinite progression
        let bonusPerVirtual = 0.5; // 0.5% per virtual level
        player.AddStatModifier(skillID + "_virtual_bonus", virtualLevel * bonusPerVirtual);
    }

    // Logging
    private final func LogAkashic(message: String) -> Void {
        // Send to Ouroboros WAL via MSN
        let ws = Game.GetWebSocketSystem().GetConnection("msn_coordination");
        if (ws != null) {
            ws.SendJson({
                "type": "akashic_log",
                "payload": { "message": message, "timestamp": DateTime.Now() }
            });
        }
    }

    // Console commands
    @Command("abyssal.skill.level")
    public final func CmdSetSkillLevel(player: Player, skillID: String, level: Int32) -> Void {
        player.SetAbyssalSkillLevel(skillID, level);
        this.CheckLevelUp(player, skillID);
    }

    @Command("abyssal.guild.choose")
    public final func CmdChooseGuild(player: Player, guild: String) -> Void {
        let alignment: EGuildAlignment;
        switch (guild) {
            case "alchemists": alignment = EGuildAlignment.OuroborosAlchemists; break;
            case "void": alignment = EGuildAlignment.VoidRunners; break;
            case "smugglers": alignment = EGuildAlignment.LochSmugglers; break;
            default: return;
        }
        this.ChooseGuild(player, alignment);
    }

    @Command("abyssal.skill.xp")
    public final func CmdGrantXP(player: Player, skillID: String, amount: Int32) -> Void {
        this.GrantSkillXP(player, skillID, amount, SXPContext{activityMultiplier: 1.0});
    }

    private final func RegisterGuildCallbacks() -> Void {
        // Register for shard read events
        Game.GetEventSystem().Register("OnShardRead", this, "OnShardRead");
        // Register for zone changes (dredging/hunting XP)
        Game.GetEventSystem().Register("OnZoneEnter", this, "OnZoneEnter");
        // Register for combat events (hunting/harpooning/evasion/survival XP)
        Game.GetEventSystem().Register("OnCombatEnd", this, "OnCombatEnd");
        // Register for market events (trading/negotiation XP)
        Game.GetEventSystem().Register("OnTradeComplete", this, "OnTradeComplete");
        // Register for crafting events (crafting/processing XP)
        Game.GetEventSystem().Register("OnCraftComplete", this, "OnCraftComplete");
    }

    // Activity event handlers
    public final func OnZoneEnter(player: Player, zone: String) -> Void {
        let context = SXPContext{activityMultiplier: 1.0};
        // Dredging zones
        if (zone == "standard" || zone == "deep" || zone == "abyssal" || zone == "trench") {
            this.GrantSkillXP(player, "dredging", 50.0, context);
            this.GrantSkillXP(player, "navigation", 20.0, context);
        }
        // Hunting zones
        if (zone == "trench" || zone == "throne_room") {
            this.GrantSkillXP(player, "hunting", 100.0, context);
        }
    }

    public final func OnCombatEnd(player: Player, target: Entity, won: Bool) -> Void {
        if (!won) return;
        let context = SXPContext{activityMultiplier: 1.5};
        this.GrantSkillXP(player, "hunting", 200.0, context);
        this.GrantSkillXP(player, "evasion", 150.0, context);
        this.GrantSkillXP(player, "survival", 100.0, context);
        // Check if harpoon used
        if (player.LastWeaponUsed() == "Harpoon") {
            this.GrantSkillXP(player, "harpooning", 250.0, context);
        }
    }

    public final func OnTradeComplete(player: Player, profit: Float, isPlayerBuy: Bool) -> Void {
        let context = SXPContext{activityMultiplier: 1.0};
        this.GrantSkillXP(player, "trading", profit * 0.1, context);
        this.GrantSkillXP(player, "negotiation", 50.0, context);
    }

    public final func OnCraftComplete(player: Player, item: Item, quality: String) -> Void {
        let context = SAbyssalContext{activityMultiplier: 1.0};
        let xpBase = 200.0;
        if (quality == "Legendary") xpBase = 500.0;
        if (quality == "Mythic") xpBase = 1000.0;

        // Determine crafting skill
        let craftSkill = this.GetCraftingSkillForItem(item);
        if (craftSkill != "") {
            this.GrantSkillXP(player, craftSkill, xpBase, context);
        }
        // Always grant haberdashery for hats
        if (item.Type() == "Hat") {
            this.GrantSkillXP(player, "haberdashery", xpBase, context);
        }
    }

    private final func GetCraftingSkillForItem(item: Item) -> String {
        let name = item.GetName();
        if (name.Contains("Potion") || name.Contains("Elixir") || name.Contains("Catalyst")) return "alchemy";
        if (name.Contains("Rune") || name.Contains("Sigil") || name.Contains("Inscribed")) return "runecrafting";
        if (name.Contains("Enchanted") || name.Contains("Cursed") || name.Contains("Blessed")) return "enchanting";
        if (name.Contains("Masterwork") || name.Contains("Mythic")) return "masterwork";
        return "";
    }

    // Data queries
    private final func GetSkillData(skillID: String) -> SAbyssalSkillData {
        for (skill in this.skillData) {
            if (skill.id == skillID) return skill;
        }
        return null;
    }
}

// Data structures
public struct SAbyssalSkillData {
    public let id: String;
    public let name: String;
    public let category: EAbyssalCategory;
    public let guildAlignment: EGuildAlignment;
    public let baseXP: Float;
    public let curveFactor: Float;
    public let unlocks: array<SAbyssalUnlock>;
    public let synergies: array<SAbyssalSynergy>;

    public final func constructor(id_: String, name_: String, cat: EAbyssalCategory,
                                  guild: EGuildAlignment, baseXP_: Float, curve: Float,
                                  unlockNames: array<String>) -> Void {
        this.id = id_;
        this.name = name_;
        this.category = cat;
        this.guildAlignment = guild;
        this.baseXP = baseXP_;
        this.curveFactor = curve;
        this.unlocks = this.GenerateUnlocks(unlockNames);
        this.synergies = this.GenerateSynergies(id_);
    }

    private final func GenerateUnlocks(names: array<String>) -> array<SAbyssalUnlock> {
        let unlocks: array<SAbyssalUnlock>;
        // Generate standard milestone unlocks
        let milestones = {1, 10, 20, 30, 40, 50, 60, 70, 80, 90, 99};
        let i = 0;
        for (level in milestones) {
            if (i < names.Size()) {
                unlocks.Push(SAbyssalUnlock(level, "ability", names[i], {}));
                i++;
            }
        }
        return unlocks;
    }

    private final func GenerateSynergies(skillID: String) -> array<SAbyssalSynergy> {
        // Simplified - in practice loaded from shared/types/skills.ts
        let synergies: array<SAbyssalSynergy>;
        // Add based on predefined synergy table
        return synergies;
    }
}

public struct SAbyssalUnlock {
    public let level: Int32;
    public let type: String;
    public let description: String;
    public let data: map<String, Variant>;

    public final func constructor(l: Int32, t: String, d: String, dat: map<String, Variant>) -> Void {
        this.level = l;
        this.type = t;
        this.description = d;
        this.data = dat;
    }
}

public struct SAbyssalSynergy {
    public let skill_id: String;
    public let bonus_type: String;
    public let value: Float;
    public let condition: String;
}

public struct SXPContext {
    public let activityMultiplier: Float;
    public let isGuildActivity: Bool;
    public let partySize: Int32;
}

// Global instance
public let MSNAbyssalSkillSystemInstance: MSNAbyssalSkillSystem;

public final func Game_OnInit() -> Void {
    MSNAbyssalSkillSystemInstance = new MSNAbyssalSkillSystem();
    MSNAbyssalSkillSystemInstance.Initialize();
}
