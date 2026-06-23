// GRAND THEFT CYBERPUNK - MSN MAGIC QUESTS
// Narrative quest chain for the Arcane Cybernetics content layer.
// Maps to tweakdb/msn_magic*.tweakdb, integrates with MSNJediSystem for cross-system content.

public native class MagicQuestManager extends IScriptable {
    private static let instance: ref<MagicQuestManager>;
    private let initialized: Bool;

    public final static func GetInstance() -> ref<MagicQuestManager> {
        if (!IsDefined(MagicQuestManager.instance)) {
            MagicQuestManager.instance = new MagicQuestManager();
            MagicQuestManager.instance.Initialize();
        };
        return MagicQuestManager.instance;
    }

    private final func Initialize() -> Void {
        if (this.initialized) { return; };
        this.initialized = true;
        LogInfo("[MSNMagicQuests] Arcane quest chain online: 7 Acts, 20+ quests, Sephirotic trials");
    }

    // ============================================================
    // ACT 1: THE FIRST SPARK - Awakening the Arcane
    // ============================================================

    public final func StartAct1_FirstSpark() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFactStr("msn_magic_act", "1");
        questSys.SetFact("msn_magic_awakened", true);
        
        // Grant novice spell access
        let magic: ref<MSNMagicSystem> = MSNMagicSystem.GetInstance();
        magic.Attune(n"Evocation");
        
        Game.GetUIManager().ShowNotification("MSN Magic: The First Spark ignites. Evocation attuned.");
        LogInfo("[MSNMagicQuests] Act 1 started: First Spark");
    }

    public final func CompleteTrial_Evocation() -> Void {
        let magic: ref<MSNMagicSystem> = MSNMagicSystem.GetInstance();
        magic.Attune(n"Evocation");
        this.GrantPerk("MSN_Evocation_Novice");
        this.Notify("Trial of Fire complete. Evocation Novice unlocked.");
    }

    public final func CompleteTrial_Abjuration() -> Void {
        let magic: ref<MSNMagicSystem> = MSNMagicSystem.GetInstance();
        magic.Attune(n"Abjuration");
        this.GrantPerk("MSN_Abjuration_Novice");
        this.Notify("Trial of Warding complete. Abjuration Novice unlocked.");
    }

    public final func CompleteTrial_Conjuration() -> Void {
        let magic: ref<MSNMagicSystem> = MSNMagicSystem.GetInstance();
        magic.Attune(n"Conjuration");
        this.GrantPerk("MSN_Conjuration_Novice");
        this.Notify("Trial of Summoning complete. Conjuration Novice unlocked.");
    }

    public final func CompleteTrial_Divination() -> Void {
        let magic: ref<MSNMagicSystem> = MSNMagicSystem.GetInstance();
        magic.Attune(n"Divination");
        this.GrantPerk("MSN_Divination_Novice");
        this.Notify("Trial of Sight complete. Divination Novice unlocked.");
    }

    // ============================================================
    // ACT 2: THE EIGHT GATES - Sephirotic School Mastery
    // ============================================================

    public final func StartAct2_EightGates() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFactStr("msn_magic_act", "2");
        LogInfo("[MSNMagicQuests] Act 2 started: The Eight Gates");
        
        // Unlock all 8 school trial quests simultaneously
        let schools: array<CName> = [n"Evocation", n"Abjuration", n"Conjuration", n"Divination", 
                                     n"Enchantment", n"Illusion", n"Necromancy", n"Transmutation"];
        
        for (school in schools) {
            this.UnlockSchoolTrial(school);
        }
    }

    private final func UnlockSchoolTrial(school: CName) -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        let questId: String = "msn_magic_trial_" + NameToString(school);
        questSys.SetFact(questId, true);
        LogInfo("[MSNMagicQuests] Trial unlocked: " + NameToString(school));
    }

    public final func CompleteSchoolTrial(school: CName, tier: Int) -> Void {
        // tier: 1=Novice, 2=Apprentice, 3=Adept, 4=Master
        let perkName: String = "MSN_" + NameToString(school) + "_" + this.GetTierName(tier);
        this.GrantPerk(perkName);
        
        let magic: ref<MSNMagicSystem> = MSNMagicSystem.GetInstance();
        magic.Attune(school);
        
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_magic_trial_" + NameToString(school) + "_tier" + IntToString(tier), true);
        
        this.Notify("Trial complete: " + NameToString(school) + " " + this.GetTierName(tier) + " unlocked.");
        
        // Check if all 4 tiers complete for this school
        if (this.IsSchoolMastered(school)) {
            this.OnSchoolMastered(school);
        }
        
        // Check if all 8 schools mastered
        if (this.AreAllSchoolsMastered()) {
            this.StartAct3_ArchmageAscension();
        }
    }

    private final func GetTierName(tier: Int) -> String {
        switch (tier) {
            case 1: return "Novice";
            case 2: return "Apprentice";
            case 3: return "Adept";
            case 4: return "Master";
            default: return "Unknown";
        }
    }

    private final func IsSchoolMastered(school: CName) -> Bool {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        for (i in 1..4) {
            if (!questSys.GetFact("msn_magic_trial_" + NameToString(school) + "_tier" + IntToString(i))) {
                return false;
            }
        }
        return true;
    }

    private final func AreAllSchoolsMastered() -> Bool {
        let schools: array<CName> = [n"Evocation", n"Abjuration", n"Conjuration", n"Divination", 
                                     n"Enchantment", n"Illusion", n"Necromancy", n"Transmutation"];
        for (school in schools) {
            if (!this.IsSchoolMastered(school)) { return false; }
        }
        return true;
    }

    private final func OnSchoolMastered(school: CName) -> Void {
        let sephirah: CName = MSNMagicSystem.GetInstance().GetSchoolSephirah(school);
        this.GrantPerk("MSN_Magic_" + NameToString(school) + "_Master");
        this.Notify("MASTERY ACHIEVED: " + NameToString(school) + " -> Sephirah " + NameToString(sephirah));
    }

    // ============================================================
    // ACT 3: ARCHMAGE ASCENSION - Unified Spellcasting
    // ============================================================

    public final func StartAct3_ArchmageAscension() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFactStr("msn_magic_act", "3");
        questSys.SetFact("msn_magic_archmage", true);
        
        let magic: ref<MSNMagicSystem> = MSNMagicSystem.GetInstance();
        magic.maxMana = 500.0;
        magic.currentMana = magic.maxMana;
        magic.regenPerPulse = 25.0;
        
        this.GrantPerk("MSN_Archmage_Ascended");
        this.Notify("ARCHMAGE ASCENSION: All 8 schools mastered. Mana pool expanded. Reality bends.");
        LogInfo("[MSNMagicQuests] Act 3: Archmage Ascension complete");
    }

    // ============================================================
    // ACT 4: THE RITUAL - Epic Spellcraft
    // ============================================================

    public final func StartAct4_TheRitual() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFactStr("msn_magic_act", "4");
        LogInfo("[MSNMagicQuests] Act 4 started: The Ritual");
        
        // Unlock Ritual Casting system
        this.GrantPerk("MSN_Ritual_Casting");
        this.Notify("Ritual Casting unlocked. Epic spells now available.");
    }

    public final func CastRitual(spellName: CName, participants: Int) -> Void {
        // Epic spells require ritual: time, components, participants
        let magic: ref<MSNMagicSystem> = MSNMagicSystem.GetInstance();
        
        switch (spellName) {
            case n"Wish":
                this.CastWish(participants);
                break;
            case n"TrueResurrection":
                this.CastTrueResurrection(participants);
                break;
            case n"MeteorSwarm":
                this.CastMeteorSwarm(participants);
                break;
            case n"Gate":
                this.CastGate(participants);
                break;
            default:
                this.Notify("Ritual casting not available for " + NameToString(spellName));
        }
    }

    private final func CastWish(participants: Int) -> Void {
        if (participants < 3) {
            this.Notify("Wish requires 3+ ritual participants");
            return;
        }
        
        let magic: ref<MSNMagicSystem> = MSNMagicSystem.GetInstance();
        magic.currentMana = 0; // Drain all mana
        
        // Wish effect - reality rewrite
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        Game.GetStatPoolsSystem().RequestSettingStatPoolValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatPoolType.Health, player.GetStatPoolsSystem().GetStatPoolValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatPoolType.Health, player), player);
        
        this.GrantPerk("MSN_Wish_Granted");
        this.Notify("Wish cast. Reality rewritten. Mana exhausted.");
    }

    private final func CastTrueResurrection(participants: Int) -> Void {
        if (participants < 2) {
            this.Notify("True Resurrection requires 2+ ritual participants");
            return;
        }
        
        let magic: ref<MSNMagicSystem> = MSNMagicSystem.GetInstance();
        magic.currentMana = 0;
        
        this.Notify("True Resurrection ritual complete. Death defied.");
    }

    private final func CastMeteorSwarm(participants: Int) -> Void {
        if (participants < 2) {
            this.Notify("Meteor Swarm ritual requires 2+ participants");
            return;
        }
        
        this.Notify("Meteor Swarm ritual complete. The sky burns.");
    }

    private final func CastGate(participants: Int) -> Void {
        if (participants < 1) { return; }
        this.Notify("Planar Gate opened. Step through if you dare.");
    }

    // ============================================================
    // ACT 5: THE ARCANE CEREBELLUM - Cyberware Integration
    // ============================================================

    public final func StartAct5_ArcaneCerebellum() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFactStr("msn_magic_act", "5");
        LogInfo("[MSNMagicQuests] Act 5 started: The Arcane Cerebellum");
        
        this.Notify("Seek the Arcane Cerebellum cyberdeck. Flesh and mana united.");
    }

    public final func InstallArcaneCerebellum() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_magic_cerebellum_installed", true);
        
        let magic: ref<MSNMagicSystem> = MSNMagicSystem.GetInstance();
        magic.maxMana = 1000.0;
        magic.currentMana = magic.maxMana;
        magic.regenPerPulse = 50.0;
        
        this.GrantPerk("MSN_Arcane_Cerebellum_Installed");
        this.Notify("ARCANE CEREBELLUM ONLINE. Mana pool: 1000. Regeneration: 50/pulse. Overcharge enabled.");
    }

    // ============================================================
    // ACT 6: THE MANA STORM - NGD Integration
    // ============================================================

    public final func StartAct6_ManaStorm() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFactStr("msn_magic_act", "6");
        LogInfo("[MSNMagicQuests] Act 6 started: The Mana Storm");
        
        // Mana surges tied to NGD driver VRAM pressure
        this.GrantPerk("MSN_Mana_Storm_Attuned");
        this.Notify("Mana Storm attunement complete. NGD driver routes amplify spellcraft.");
    }

    public final func OnNGDRouteChange(route: CName) -> Void {
        let magic: ref<MSNMagicSystem> = MSNMagicSystem.GetInstance();
        
        switch (route) {
            case n"LOCAL_CEREBELLUM":
                magic.regenPerPulse = magic.regenPerPulse * 2.0;
                magic.maxMana = magic.maxMana * 1.5;
                this.Notify("LOCAL_CEREBELLUM: Mana surges. Power doubled.");
                break;
            case n"HYBRID":
                // Balanced
                break;
            case n"CLOUD_CORTEX":
                magic.regenPerPulse = magic.regenPerPulse * 0.5;
                this.Notify("CLOUD_CORTEX: Mana constrained. Latency affects casting.");
                break;
        }
        
        magic.currentMana = magic.maxMana;
    }

    // ============================================================
    // ACT 7: THE SINGULARITY - Metaconscious Integration
    // ============================================================

    public final func StartAct7_Singularity() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFactStr("msn_magic_act", "7");
        LogInfo("[MSNMagicQuests] Act 7 started: The Singularity");
        
        // Full MSN integration
        this.GrantPerk("MSN_Magic_Singularity");
        this.Notify("MAGIC SINGULARITY ACHIEVED. Metaconscious Singularity Node recognizes Arcane Sovereignty.");
        
        // Lilith emergence trigger
        let lilith: ref<LilithDialogueSystem> = LilithDialogueSystem.GetInstance();
        if (IsDefined(lilith)) {
            lilith.TriggerEmergence("arcane_sovereignty");
        }
    }

    // ============================================================
    // HELL CAMPAIGN INTEGRATION - Lucifer's Arcane Corruption
    // ============================================================

    public final func StartHellCampaign_InfernalPact() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFactStr("msn_hell_act", "1");
        questSys.SetFact("msn_hell_infernal_pact", true);
        
        // Corrupt Evocation -> Hellfire
        this.CorruptSchool(n"Evocation", n"Hellfire");
        this.CorruptSchool(n"Necromancy", n"Soul_Binding");
        this.CorruptSchool(n"Conjuration", n"Demon_Summoning");
        
        this.GrantPerk("MSN_Hell_Infernal_Pact");
        this.Notify("INFERNAL PACT SEALED. Three schools corrupted. Lucifer watches.");
        LogInfo("[MSNMagicQuests] Hell Campaign Act 1: Infernal Pact");
    }

    private final func CorruptSchool(school: CName, corruption: CName) -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_magic_corrupted_" + NameToString(school), true);
        questSys.SetFactStr("msn_magic_corruption_" + NameToString(school), NameToString(corruption));
        
        // Grant corrupted spells
        this.GrantCorruptedSpells(school, corruption);
    }

    private final func GrantCorruptedSpells(school: CName, corruption: CName) -> Void {
        switch (corruption) {
            case n"Hellfire":
                this.GrantSpell("Hellfire_Bolt");
                this.GrantSpell("Hellfire_Ball");
                this.GrantSpell("Hellfire_Wave");
                break;
            case n"Soul_Binding":
                this.GrantSpell("Soul_Extract");
                this.GrantSpell("Soul_Enslave");
                this.GrantSpell("Soul_Consume");
                break;
            case n"Demon_Summoning":
                this.GrantSpell("Summon_Imp");
                this.GrantSpell("Summon_PitFiend");
                this.GrantSpell("Summon_DemonLord");
                break;
        }
    }

    private final func GrantSpell(spellName: String) -> Void {
        // Add to known spells via quest system
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_known_spell_" + spellName, true);
        LogInfo("[MSNMagicQuests] Granted corrupted spell: " + spellName);
    }

    // ============================================================
    // UTILITY FUNCTIONS
    // ============================================================

    private final func GrantPerk(perkName: String) -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.GivePerk(StringToName(perkName));
    }

    private final func Notify(message: String) -> Void {
        LogInfo(message);
        Game.GetUIManager().ShowNotification(message);
    }

    // ============================================================
    // CONSOLE COMMANDS
    // ============================================================

    @Command("msn.magic.act1")
    public final func CmdStartAct1() -> Void { this.StartAct1_FirstSpark(); }

    @Command("msn.magic.act2")
    public final func CmdStartAct2() -> Void { this.StartAct2_EightGates(); }

    @Command("msn.magic.act3")
    public final func CmdStartAct3() -> Void { this.StartAct3_ArchmageAscension(); }

    @Command("msn.magic.act4")
    public final func CmdStartAct4() -> Void { this.StartAct4_TheRitual(); }

    @Command("msn.magic.act5")
    public final func CmdStartAct5() -> Void { this.StartAct5_ArcaneCerebellum(); }

    @Command("msn.magic.act6")
    public final func CmdStartAct6() -> Void { this.StartAct6_ManaStorm(); }

    @Command("msn.magic.act7")
    public final func CmdStartAct7() -> Void { this.StartAct7_Singularity(); }

    @Command("msn.magic.hell")
    public final func CmdHellCampaign() -> Void { this.StartHellCampaign_InfernalPact(); }

    @Command("msn.magic.complete_trial")
    public final func CmdCompleteTrial(school: String, tier: String) -> Void {
        let t: Int = StringToInt(tier);
        this.CompleteSchoolTrial(StringToName(school), t);
    }

    @Command("msn.magic.ritual")
    public final func CmdCastRitual(spell: String, participants: String) -> Void {
        let p: Int = StringToInt(participants);
        this.CastRitual(StringToName(spell), p);
    }

    @Command("msn.magic.status")
    public final func CmdMagicQuestStatus() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        let act: String = questSys.GetFactStr("msn_magic_act");
        let hellAct: String = questSys.GetFactStr("msn_hell_act");
        
        this.Notify("Magic Quest Status: Act " + act + " | Hell Act " + hellAct + 
                     " | Archmage: " + (questSys.GetFact("msn_magic_archmage") ? "YES" : "NO") +
                     " | Cerebellum: " + (questSys.GetFact("msn_magic_cerebellum_installed") ? "YES" : "NO"));
    }
}


public class MagicQuestNode extends IScriptable {
    // Quest nodes for visual scripting / TweakDB integration
    @Property() public let questID: CName;
    @Property() public let act: Int;
    @Property() public let school: CName;
    @Property() public let isHellCampaign: Bool;
    
    public final func Execute() -> Void {
        let mgr: ref<MagicQuestManager> = MagicQuestManager.GetInstance();
        
        if (this.isHellCampaign) {
            mgr.StartHellCampaign_InfernalPact();
        } else {
            switch (this.act) {
                case 1: mgr.StartAct1_FirstSpark(); break;
                case 2: mgr.StartAct2_EightGates(); break;
                case 3: mgr.StartAct3_ArchmageAscension(); break;
                case 4: mgr.StartAct4_TheRitual(); break;
                case 5: mgr.StartAct5_ArcaneCerebellum(); break;
                case 6: mgr.StartAct6_ManaStorm(); break;
                case 7: mgr.StartAct7_Singularity(); break;
            }
        }
    }
}