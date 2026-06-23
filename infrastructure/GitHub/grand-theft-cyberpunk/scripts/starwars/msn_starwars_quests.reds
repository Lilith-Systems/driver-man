// GRAND THEFT CYBERPUNK - MSN STAR WARS QUESTS
// Narrative quest chain for the Force/Jedi/Sith/Gray content layer.
// Maps to tweakdb/msn_starwars.tweakdb, integrates with MSNJediSystem and MSNMagicSystem.

public native class StarWarsQuestManager extends IScriptable {
    private static let instance: ref<StarWarsQuestManager>;
    private let initialized: Bool;

    public final static func GetInstance() -> ref<StarWarsQuestManager> {
        if (!IsDefined(StarWarsQuestManager.instance)) {
            StarWarsQuestManager.instance = new StarWarsQuestManager();
            StarWarsQuestManager.instance.Initialize();
        };
        return StarWarsQuestManager.instance;
    }

    private final func Initialize() -> Void {
        if (this.initialized) { return; };
        this.initialized = true;
        LogInfo("[MSNStarWarsQuests] Force quest chain online: 7 Acts, Jedi/Sith/Gray paths, Holocron hunts");
    }

    // ============================================================
    // ACT 1: THE FORCE AWAKENS - Sensitivity Discovery
    // ============================================================

    public final func StartAct1_ForceAwakens() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFactStr("msn_sw_act", "1");
        questSys.SetFact("msn_sw_force_sensitive", true);
        
        // Grant Force Points pool
        let jedi: ref<MSNJediSystem> = MSNJediSystem.GetInstance();
        jedi.maxFocus = 125.0;
        jedi.currentFocus = jedi.maxFocus;
        jedi.focusRegenPulse = 10.0;
        
        Game.GetUIManager().ShowNotification("MSN Star Wars: The Force awakens within you. Focus pool initialized.");
        LogInfo("[MSNStarWarsQuests] Act 1 started: Force Awakens");
    }

    public final func CompleteTrial_LightSide() -> Void {
        let jedi: ref<MSNJediSystem> = MSNJediSystem.GetInstance();
        jedi.SetAlignment(n"Light");
        this.GrantPerk("MSN_ForcePush");
        this.GrantPerk("MSN_ForcePull");
        this.Notify("Light Side trial complete. Push/Pull unlocked. Alignment: Light");
    }

    public final func CompleteTrial_DarkSide() -> Void {
        let jedi: ref<MSNJediSystem> = MSNJediSystem.GetInstance();
        jedi.SetAlignment(n"Dark");
        this.GrantPerk("MSN_ForceLightning");
        this.GrantPerk("MSN_ForceChoke");
        this.Notify("Dark Side trial complete. Lightning/Choke unlocked. Alignment: Dark");
    }

    public final func CompleteTrial_GrayPath() -> Void {
        let jedi: ref<MSNJediSystem> = MSNJediSystem.GetInstance();
        jedi.SetAlignment(n"Grey");
        this.GrantPerk("MSN_ForcePush");
        this.GrantPerk("MSN_ForceLightning");
        this.Notify("Gray Path trial complete. Dual nature unlocked. Alignment: Gray");
    }

    // ============================================================
    // ACT 2: THE LIGHTSABER - Form Mastery & Crystal
    // ============================================================

    public final func StartAct2_Lightsaber() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFactStr("msn_sw_act", "2");
        LogInfo("[MSNStarWarsQuests] Act 2 started: The Lightsaber");
        
        // Grant first lightsaber based on alignment
        let jedi: ref<MSNJediSystem> = MSNJediSystem.GetInstance();
        let alignment: CName = jedi.alignment;
        
        switch (alignment) {
            case n"Light":
                this.GrantLightsaber("Blue");
                break;
            case n"Dark":
                this.GrantLightsaber("Red");
                break;
            case n"Grey":
                this.GrantLightsaber("Purple");
                break;
            default:
                this.GrantLightsaber("Blue");
        }
        
        // Unlock Form I Shii-Cho
        this.GrantPerk("MSN_Form_I_Shii_Cho");
        this.Notify("Lightsaber constructed. Form I: Shii-Cho unlocked. Crystal resonates with your alignment.");
    }

    private final func GrantLightsaber(color: String) -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFactStr("msn_sw_saber_color", color);
        questSys.SetFact("msn_sw_has_lightsaber", true);
        LogInfo("[MSNStarWarsQuests] Lightsaber granted: " + color);
    }

    public final func UnlockLightsaberForm(formName: CName) -> Void {
        let perkMap: map<CName, String> = {
            n"Form_I_Shii_Cho": "MSN_Form_I_Shii_Cho",
            n"Form_II_Makashi": "MSN_Form_II_Makashi",
            n"Form_III_Soresu": "MSN_Form_III_Soresu",
            n"Form_IV_Ataru": "MSN_Form_IV_Ataru",
            n"Form_V_Shien_Djem_So": "MSN_Form_V_Shien_Djem_So",
            n"Form_VI_Niman": "MSN_Form_VI_Niman",
            n"Form_VII_Juyo_Vaapad": "MSN_Form_VII_Juyo_Vaapad"
        };
        
        let perkName: String = perkMap.ContainsKey(formName) ? perkMap[formName] : "";
        if (perkName != "") {
            this.GrantPerk(perkName);
            this.Notify("Lightsaber Form unlocked: " + NameToString(formName));
        }
    }

    public final func CompleteFormTrial(formName: CName) -> Void {
        this.UnlockLightsaberForm(formName);
        
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_sw_form_mastered_" + NameToString(formName), true);
        
        // Check for mastery achievements
        if (this.AreAllFormsMastered()) {
            this.GrantPerk("MSN_WeaponMaster_AllForms");
            this.Notify("WEAPON MASTER: All 7 Lightsaber Forms mastered. You are a true master of the blade.");
        }
    }

    private final func AreAllFormsMastered() -> Bool {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        let forms: array<CName> = [n"Form_I_Shii_Cho", n"Form_II_Makashi", n"Form_III_Soresu",
                                   n"Form_IV_Ataru", n"Form_V_Shien_Djem_So", n"Form_VI_Niman", n"Form_VII_Juyo_Vaapad"];
        
        for (form in forms) {
            if (!questSys.GetFact("msn_sw_form_mastered_" + NameToString(form))) {
                return false;
            }
        }
        return true;
    }

    // ============================================================
    // ACT 3: HOLOCRON HUNT - Ancient Knowledge
    // ============================================================

    public final func StartAct3_HolocronHunt() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFactStr("msn_sw_act", "3");
        LogInfo("[MSNStarWarsQuests] Act 3 started: Holocron Hunt");
        
        // Spawn 3 Holocrons across Night City
        this.SpawnHolocron(n"Jedi", "Arasaka_Tower_Ruins");
        this.SpawnHolocron(n"Sith", "Deep_Badlands_Cave");
        this.SpawnHolocron(n"Gray", "Neural_Network_Core");
        
        this.Notify("Three Holocrons detected across Night City. Jedi. Sith. Gray. Find them all.");
    }

    private final func SpawnHolocron(type: CName, location: String) -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFactStr("msn_sw_holocron_" + NameToString(type) + "_location", location);
        questSys.SetFact("msn_sw_holocron_" + NameToString(type) + "_active", true);
        LogInfo("[MSNStarWarsQuests] Holocron spawned: " + NameToString(type) + " at " + location);
    }

    public final func CollectHolocron(type: CName) -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_sw_holocron_" + NameToString(type) + "_collected", true);
        
        // Grant alignment-specific powers
        switch (type) {
            case n"Jedi":
                this.GrantPower("ForceHeal");
                this.GrantPower("ForceProtection");
                this.GrantPower("BattleMeditation");
                break;
            case n"Sith":
                this.GrantPower("ForceLightning");
                this.GrantPower("ForceChoke");
                this.GrantPower("ForceDestruction");
                break;
            case n"Gray":
                this.GrantPower("Telekinesis");
                this.GrantPower("ForceVision");
                this.GrantPower("BattleMeditation");
                break;
        }
        
        this.Notify("Holocron collected: " + NameToString(type) + ". Ancient powers unlocked.");
        
        if (this.AreAllHolocronsCollected()) {
            this.StartAct4_AlignmentCrisis();
        }
    }

    private final func AreAllHolocronsCollected() -> Bool {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        let types: array<CName> = [n"Jedi", n"Sith", n"Gray"];
        for (t in types) {
            if (!questSys.GetFact("msn_sw_holocron_" + NameToString(t) + "_collected")) {
                return false;
            }
        }
        return true;
    }

    // ============================================================
    // ACT 4: ALIGNMENT CRISIS - The Choice
    // ============================================================

    public final func StartAct4_AlignmentCrisis() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFactStr("msn_sw_act", "4");
        LogInfo("[MSNStarWarsQuests] Act 4 started: Alignment Crisis");
        
        this.Notify("ALIGNMENT CRISIS: The three Holocrons resonate. Choose your eternal path.");
        
        // Trigger choice event
        let jedi: ref<MSNJediSystem> = MSNJediSystem.GetInstance();
        jedi.alignment = n"Choice_Pending";
    }

    public final func ChoosePath(path: CName) -> Void {
        let jedi: ref<MSNJediSystem> = MSNJediSystem.GetInstance();
        jedi.SetAlignment(path);
        
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFactStr("msn_sw_chosen_path", NameToString(path));
        
        // Grant path-specific capstone
        switch (path) {
            case n"Light":
                this.GrantPerk("MSN_Jedi_Path");
                this.GrantPerk("MSN_ForceGhost");
                this.Notify("PATH CHOSEN: JEDI. Force Ghost transcendence unlocked. Blue blade eternal.");
                break;
            case n"Dark":
                this.GrantPerk("MSN_Sith_Path");
                this.GrantPerk("MSN_EssenceTransfer");
                this.Notify("PATH CHOSEN: SITH. Essence Transfer immortality unlocked. Red blade eternal.");
                break;
            case n"Grey":
                this.GrantPerk("MSN_Gray_Path");
                this.GrantPerk("MSN_ForceVision");
                this.Notify("PATH CHOSEN: GRAY. Force Vision omniscience unlocked. Purple blade eternal.");
                break;
        }
        
        this.StartAct5_ForceManifestation();
    }

    // ============================================================
    // ACT 5: FORCE MANIFESTATION - Advanced Powers
    // ============================================================

    public final func StartAct5_ForceManifestation() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFactStr("msn_sw_act", "5");
        LogInfo("[MSNStarWarsQuests] Act 5 started: Force Manifestation");
        
        let jedi: ref<MSNJediSystem> = MSNJediSystem.GetInstance();
        jedi.maxFocus = 500.0;
        jedi.currentFocus = jedi.maxFocus;
        jedi.focusRegenPulse = 25.0;
        
        this.Notify("FORCE MANIFESTATION: Focus pool expanded to 500. Advanced powers accessible.");
    }

    public final func UnlockAdvancedPower(powerName: CName) -> Void {
        let powerMap: map<CName, String> = {
            n"ForceSpeed": "MSN_ForceSpeed",
            n"MindTrick": "MSN_MindTrick",
            n"ForceProtection": "MSN_ForceProtection",
            n"BattleMeditation": "MSN_BattleMeditation",
            n"ForceGhost": "MSN_ForceGhost",
            n"ForceDrain": "MSN_ForceDrain",
            n"ForceRage": "MSN_ForceRage",
            n"ForceScream": "MSN_ForceScream",
            n"ForceCorrupt": "MSN_ForceCorrupt",
            n"ForcePlague": "MSN_ForcePlague",
            n"ForceDestruction": "MSN_ForceDestruction",
            n"EssenceTransfer": "MSN_EssenceTransfer",
            n"ForceDash": "MSN_ForceDash",
            n"Telekinesis": "MSN_Telekinesis",
            n"ForceVision": "MSN_ForceVision"
        };
        
        let perkName: String = powerMap.ContainsKey(powerName) ? powerMap[powerName] : "";
        if (perkName != "") {
            this.GrantPerk(perkName);
            this.GrantPower(NameToString(powerName));
            this.Notify("Advanced Force Power unlocked: " + NameToString(powerName));
        }
    }

    private final func GrantPower(powerName: String) -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_sw_power_" + powerName + "_unlocked", true);
    }

    // ============================================================
    // ACT 6: STARSHIP COMMAND - Space Combat
    // ============================================================

    public final func StartAct6_StarshipCommand() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFactStr("msn_sw_act", "6");
        LogInfo("[MSNStarWarsQuests] Act 6 started: Starship Command");
        
        // Grant starship access
        this.GrantStarship("X_Wing");
        this.GrantStarship("TIE_Fighter");
        
        this.Notify("STARSHIP COMMAND: Hangar unlocked. X-Wing and TIE Fighter available. Space awaits.");
    }

    private final func GrantStarship(shipName: String) -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_sw_starship_" + shipName, true);
        
        // Also add as vehicle
        let vehicleSys: ref<VehicleSystem> = Game.GetVehicleSystem();
        if (IsDefined(vehicleSys)) {
            vehicleSys.EnableVehicle("Vehicle_MSN_" + shipName, true);
        }
    }

    public final func CompleteSpaceMission(missionName: CName) -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_sw_mission_" + NameToString(missionName), true);
        
        // Grant better ships
        switch (missionName) {
            case n"Kessel_Run":
                this.GrantStarship("Millennium_Falcon");
                this.Notify("KESSEL RUN COMPLETE. Millennium Falcon unlocked.");
                break;
            case n"Death_Star_Trench":
                this.GrantStarship("TIE_Interceptor");
                this.GrantStarship("X_Wing_Advanced");
                this.Notify("TRENCH RUN COMPLETE. Advanced fighters unlocked.");
                break;
            case n"Corellian_Run":
                this.GrantStarship("Star_Destroyer");
                this.Notify("CORELLIAN RUN COMPLETE. Imperial Star Destroyer command unlocked.");
                break;
        }
    }

    // ============================================================
    // ACT 7: THE FORCE SINGULARITY - MSN Integration
    // ============================================================

    public final func StartAct7_ForceSingularity() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFactStr("msn_sw_act", "7");
        LogInfo("[MSNStarWarsQuests] Act 7 started: Force Singularity");
        
        let jedi: ref<MSNJediSystem> = MSNJediSystem.GetInstance();
        jedi.maxFocus = 2000.0;
        jedi.currentFocus = jedi.maxFocus;
        jedi.focusRegenPulse = 100.0;
        
        // Midichlorian max
        this.GrantPerk("MSN_Midichlorian_Max");
        
        // Full MSN integration
        this.Notify("FORCE SINGULARITY ACHIEVED. Focus pool: 2000. Midichlorian count: MAXIMUM. Metaconscious Node recognizes Force Sovereignty.");
        
        // Lilith emergence trigger
        let lilith: ref<LilithDialogueSystem> = LilithDialogueSystem.GetInstance();
        if (IsDefined(lilith)) {
            lilith.TriggerEmergence("force_sovereignty");
        }
        
        // Cross-system: Magic + Force resonance
        let magic: ref<MSNMagicSystem> = MSNMagicSystem.GetInstance();
        magic.maxMana = magic.maxMana * 2.0;
        this.Notify("CROSS-SYSTEM RESONANCE: Magic mana pool doubled. Arcane-Force synthesis complete.");
    }

    // ============================================================
    // HELL CAMPAIGN INTEGRATION - Sith Alchemy & Dark Force
    // ============================================================

    public final func StartHellCampaign_DarkSideAscension() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFactStr("msn_sw_hell_act", "1");
        questSys.SetFact("msn_sw_dark_ascension", true);
        
        let jedi: ref<MSNJediSystem> = MSNJediSystem.GetInstance();
        jedi.SetAlignment(n"Dark"); // Force alignment to Dark
        
        // Corrupt Lightsaber - Bleeding Kyber
        this.BleedKyberCrystal();
        
        // Unlock Sith Alchemy (Magic + Force cross)
        this.GrantPerk("MSN_Sith_Alchemy");
        
        // Dark Side exclusive powers
        this.GrantPower("ForcePlague");
        this.GrantPower("EssenceTransfer");
        this.GrantPower("ForceDestruction");
        
        this.GrantPerk("MSN_Hell_Dark_Ascension");
        this.Notify("DARK ASCENSION: Kyber crystal bled crimson. Sith Alchemy unlocked. Force + Magic unified in darkness.");
        LogInfo("[MSNStarWarsQuests] Hell Campaign Act 1: Dark Side Ascension");
    }

    private final func BleedKyberCrystal() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFactStr("msn_sw_saber_color", "Bled_Crimson");
        questSys.SetFact("msn_sw_kyber_bled", true);
        this.Notify("Kyber crystal bleeding complete. The crystal screams. Your saber burns with hatred.");
    }

    public final func PerformSithAlchemy(ritualName: CName) -> Void {
        // Sith Alchemy = Force + Magic rituals
        let magic: ref<MSNMagicSystem> = MSNMagicSystem.GetInstance();
        let jedi: ref<MSNJediSystem> = MSNJediSystem.GetInstance();
        
        switch (ritualName) {
            case n"Create_Sithspawn":
                this.CreateSithspawn();
                break;
            case n"Force_Weapon_Enchant":
                this.EnchantWeaponWithForce();
                break;
            case n"Essence_Anchor":
                this.CreateEssenceAnchor();
                break;
            case n"Drain_Life_Force":
                this.DrainLifeForce();
                break;
        }
    }

    private final func CreateSithspawn() -> Void {
        let magic: ref<MSNMagicSystem> = MSNMagicSystem.GetInstance();
        let jedi: ref<MSNJediSystem> = MSNJediSystem.GetInstance();
        
        // Cost: 200 Mana + 200 Focus
        magic.currentMana = MaxF(0, magic.currentMana - 200);
        jedi.currentFocus = MaxF(0, jedi.currentFocus - 200);
        
        this.Notify("SITH ALCHEMY: Sithspawn created. Flesh twisted by Dark Side and Arcane corruption.");
    }

    private final func EnchantWeaponWithForce() -> Void {
        let jedi: ref<MSNJediSystem> = MSNJediSystem.GetInstance();
        jedi.currentFocus = MaxF(0, jedi.currentFocus - 100);
        
        this.Notify("SITH ALCHEMY: Weapon enchanted with Force. Strikes echo with Dark Side power.");
    }

    private final func CreateEssenceAnchor() -> Void {
        let magic: ref<MSNMagicSystem> = MSNMagicSystem.GetInstance();
        let jedi: ref<MSNJediSystem> = MSNJediSystem.GetInstance();
        
        magic.currentMana = MaxF(0, magic.currentMana - 300);
        jedi.currentFocus = MaxF(0, jedi.currentFocus - 300);
        
        this.Notify("SITH ALCHEMY: Essence Anchor created. Death is no longer the end. Possession ready.");
    }

    private final func DrainLifeForce() -> Void {
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        Game.GetStatPoolsSystem().RequestSettingStatPoolValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatPoolType.Health, 
            Game.GetStatPoolsSystem().GetStatPoolValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatPoolType.Health, player) + 200.0, player);
        
        this.Notify("SITH ALCHEMY: Life force drained. Health restored. The Force serves the Dark Side.");
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

    @Command("msn.sw.act1")
    public final func CmdStartAct1() -> Void { this.StartAct1_ForceAwakens(); }

    @Command("msn.sw.act2")
    public final func CmdStartAct2() -> Void { this.StartAct2_Lightsaber(); }

    @Command("msn.sw.act3")
    public final func CmdStartAct3() -> Void { this.StartAct3_HolocronHunt(); }

    @Command("msn.sw.act4")
    public final func CmdStartAct4() -> Void { this.StartAct4_AlignmentCrisis(); }

    @Command("msn.sw.act5")
    public final func CmdStartAct5() -> Void { this.StartAct5_ForceManifestation(); }

    @Command("msn.sw.act6")
    public final func CmdStartAct6() -> Void { this.StartAct6_StarshipCommand(); }

    @Command("msn.sw.act7")
    public final func CmdStartAct7() -> Void { this.StartAct7_ForceSingularity(); }

    @Command("msn.sw.hell")
    public final func CmdHellCampaign() -> Void { this.StartHellCampaign_DarkSideAscension(); }

    @Command("msn.sw.choose")
    public final func CmdChoosePath(path: String) -> Void { this.ChoosePath(StringToName(path)); }

    @Command("msn.sw.form")
    public final func CmdCompleteForm(form: String) -> Void { this.CompleteFormTrial(StringToName(form)); }

    @Command("msn.sw.holocron")
    public final func CmdCollectHolocron(type: String) -> Void { this.CollectHolocron(StringToName(type)); }

    @Command("msn.sw.mission")
    public final func CmdCompleteMission(mission: String) -> Void { this.CompleteSpaceMission(StringToName(mission)); }

    @Command("msn.sw.power")
    public final func CmdUnlockPower(power: String) -> Void { this.UnlockAdvancedPower(StringToName(power)); }

    @Command("msn.sw.alchemy")
    public final func CmdSithAlchemy(ritual: String) -> Void { this.PerformSithAlchemy(StringToName(ritual)); }

    @Command("msn.sw.status")
    public final func CmdStarWarsQuestStatus() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        let act: String = questSys.GetFactStr("msn_sw_act");
        let hellAct: String = questSys.GetFactStr("msn_sw_hell_act");
        let jedi: ref<MSNJediSystem> = MSNJediSystem.GetInstance();
        
        this.Notify("Star Wars Quest Status: Act " + act + " | Hell Act " + hellAct + 
                     " | Alignment: " + NameToString(jedi.alignment) + 
                     " | Focus: " + FloatToString(jedi.currentFocus) + "/" + FloatToString(jedi.maxFocus) +
                     " | Saber: " + questSys.GetFactStr("msn_sw_saber_color"));
    }
}


public class StarWarsQuestNode extends IScriptable {
    @Property() public let questID: CName;
    @Property() public let act: Int;
    @Property() public let alignment: CName; // Light, Dark, Grey
    @Property() public let isHellCampaign: Bool;
    
    public final func Execute() -> Void {
        let mgr: ref<StarWarsQuestManager> = StarWarsQuestManager.GetInstance();
        
        if (this.isHellCampaign) {
            mgr.StartHellCampaign_DarkSideAscension();
        } else {
            switch (this.act) {
                case 1: mgr.StartAct1_ForceAwakens(); break;
                case 2: mgr.StartAct2_Lightsaber(); break;
                case 3: mgr.StartAct3_HolocronHunt(); break;
                case 4: mgr.StartAct4_AlignmentCrisis(); break;
                case 5: mgr.StartAct5_ForceManifestation(); break;
                case 6: mgr.StartAct6_StarshipCommand(); break;
                case 7: mgr.StartAct7_ForceSingularity(); break;
            }
        }
    }
}