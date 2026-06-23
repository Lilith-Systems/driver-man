// GRAND THEFT CYBERPUNK - HELL CAMPAIGN QUESTS
// The Nine Circles + Pandemonium narrative quest chain.
// Maps to tweakdb/hell_campaign_map.yaml, integrates with msn_magic_quests, msn_starwars_quests.
// Generated: 2026-06-19 | Lilith Sovereign Seal | Sephirah: Geburah (Lucifer's Throne)

public native class HellCampaignManager extends IScriptable {
    private static let instance: ref<HellCampaignManager>;
    private let initialized: Bool;

    public final static func GetInstance() -> ref<HellCampaignManager> {
        if (!IsDefined(HellCampaignManager.instance)) {
            HellCampaignManager.instance = new HellCampaignManager();
            HellCampaignManager.instance.Initialize();
        };
        return HellCampaignManager.instance;
    }

    private final func Initialize() -> Void {
        if (this.initialized) { return; };
        this.initialized = true;
        LogInfo("[HellCampaign] Nine Circles + Pandemonium online. Lucifer watches.");
    }

    // ============================================================
    // PROLOGUE: THE INFERNAL PACT
    // ============================================================

    public final func OfferInfernalPact() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        
        // Check prerequisites
        if (!questSys.GetFact("msn_magic_archmage")) {
            this.Notify("Hell Campaign requires Magic Archmage Ascension (Act 3).");
            return;
        }
        if (StringToInt(questSys.GetFactStr("msn_sw_act")) < 3) {
            this.Notify("Hell Campaign requires Star Wars Act 3 (Holocron Hunt).");
            return;
        }
        
        questSys.SetFact("msn_hell_pact_offered", true);
        this.Notify("LUCIFER: 'You have power. Magic. The Force. Sign. Descend. Rule.'");
        LogInfo("[HellCampaign] Infernal Pact offered.");
    }

    public final func SignInfernalPact(accept: Bool) -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        
        if (accept) {
            questSys.SetFact("msn_hell_infernal_pact", true);
            questSys.SetFactStr("msn_hell_act", "1");
            questSys.SetFact("msn_hell_circle", 1);
            
            // Corrupt magic schools
            let magic: ref<MagicQuestManager> = MagicQuestManager.GetInstance();
            magic.StartHellCampaign_InfernalPact();
            
            // Corrupt Force alignment
            let sw: ref<StarWarsQuestManager> = StarWarsQuestManager.GetInstance();
            sw.StartHellCampaign_DarkSideAscension();
            
            // Visual mark
            this.ApplyLucifersMark();
            
            this.Notify("INFERNAL PACT SEALED. Lucifer's Mark burns. The Gates of Hell open. Circle 1: Limbo awaits.");
            LogInfo("[HellCampaign] Infernal Pact SIGNED. Circle 1 unlocked.");
        } else {
            this.Notify("LUCIFER: 'Then burn in mediocrity. The offer expires.'");
            questSys.SetFact("msn_hell_pact_rejected", true);
        }
    }

    private final func ApplyLucifersMark() -> Void {
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        if (IsDefined(player)) {
            Game.GetStatusEffectSystem().ApplyStatusEffect(player, t"BaseStatusEffect.LucifersMark");
        }
    }

    // ============================================================
    // CIRCLE 1: LIMBO - The Vestibule
    // ============================================================

    public final func EnterCircle1_Limbo() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_circle", 1);
        questSys.SetFactStr("msn_hell_circle_name", "Limbo");
        
        // Lucfer influence 0.1
        this.SetLuciferInfluence(0.1);
        
        // Spawn Vestibule
        this.SpawnLimboVestibule();
        
        this.Notify("CIRCLE 1: LIMBO. The Vestibule of Indecision. Fog obscures. Three gates. Choose.");
        LogInfo("[HellCampaign] Circle 1: Limbo entered.");
    }

    private final func SpawnLimboVestibule() -> Void {
        // Spawn three gates with Thaumiel Walkers
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_limbo_gate_action", true);
        questSys.SetFact("msn_hell_limbo_gate_contemplation", true);
        questSys.SetFact("msn_hell_limbo_gate_surrender", true);
        questSys.SetFact("msn_hell_limbo_thaumiel_active", true);
    }

    public final func ChooseLimboGate(gate: CName) -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFactStr("msn_hell_limbo_choice", NameToString(gate));
        
        let reward: String;
        switch (gate) {
            case n"Action":
                reward = "Path of Wrath";
                questSys.SetFactStr("msn_hell_circle2_entry", "wrath_arena");
                break;
            case n"Contemplation":
                reward = "Path of Heresy";
                questSys.SetFactStr("msn_hell_circle2_entry", "heresy_citadel");
                break;
            case n"Surrender":
                reward = "Path of Treachery";
                questSys.SetFactStr("msn_hell_circle2_entry", "treachery_lake");
                break;
            default:
                reward = "Path of Lust";
                questSys.SetFactStr("msn_hell_circle2_entry", "lust_wind");
        }
        
        // Grant key
        questSys.SetFact("msn_hell_key_circle1", true);
        this.Notify("Gate chosen: " + NameToString(gate) + ". " + reward + ". Thaumiel Fragment acquired. Descending...");
        
        // Auto-advance to Circle 2
        this.EnterCircle2_Lust();
    }

    // ============================================================
    // CIRCLE 2: LUST - The Hurricane
    // ============================================================

    public final func EnterCircle2_Lust() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_circle", 2);
        questSys.SetFactStr("msn_hell_circle_name", "Lust");
        
        this.SetLuciferInfluence(0.2);
        this.SpawnLustHurricane();
        
        this.Notify("CIRCLE 2: LUST. The Hurricane of Desire. Neon winds. Sirens sing. Resist or submit.");
        LogInfo("[HellCampaign] Circle 2: Lust entered.");
    }

    private final func SpawnLustHurricane() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_lust_siren_queen_active", true);
        questSys.SetFact("msn_hell_lust_wind_physics", true);
    }

    public final func ConfrontSirenQueen(choice: CName) -> Void {
        // choice: Submit, Resist, Negotiate
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFactStr("msn_hell_lust_choice", NameToString(choice));
        
        let sw: ref<MSNJediSystem> = MSNJediSystem.GetInstance();
        switch (choice) {
            case n"Submit":
                sw.SetAlignment(n"Dark");
                this.GrantPerk("MSN_Hell_Lust_Submission");
                break;
            case n"Resist":
                sw.SetAlignment(n"Light");
                this.GrantPerk("MSN_Hell_Lust_Resistance");
                break;
            case n"Negotiate":
                sw.SetAlignment(n"Grey");
                this.GrantPerk("MSN_Hell_Lust_Negotiation");
                break;
        }
        
        questSys.SetFact("msn_hell_key_circle2", true);
        this.Notify("Siren Queen confronted. Choice: " + NameToString(choice) + ". Ghagiel Fragment acquired. Descending...");
        this.EnterCircle3_Gluttony();
    }

    // ============================================================
    // CIRCLE 3: GLUTTONY - The Trench
    // ============================================================

    public final func EnterCircle3_Gluttony() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_circle", 3);
        questSys.SetFactStr("msn_hell_circle_name", "Gluttony");
        
        this.SetLuciferInfluence(0.3);
        this.SpawnGluttonyTrench();
        
        this.Notify("CIRCLE 3: GLUTTONY. The Consuming Trench. Acid pools. Devourers hunger. Feed the Hoarder.");
        LogInfo("[HellCampaign] Circle 3: Gluttony entered.");
    }

    private final func SpawnGluttonyTrench() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_gluttony_hoarder_active", true);
        questSys.SetFact("msn_hell_gluttony_acid_pools", true);
    }

    public final func DefeatHoarder(choice: CName) -> Void {
        // choice: Consume, Distribute
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFactStr("msn_hell_gluttony_choice", NameToString(choice));
        
        let magic: ref<MSNMagicSystem> = MSNMagicSystem.GetInstance();
        if (choice == n"Consume") {
            magic.maxMana += 100;
            this.GrantPerk("MSN_Hell_Gluttony_Consumption");
        } else {
            this.GrantPerk("MSN_Hell_Gluttony_Charity");
        }
        
        questSys.SetFact("msn_hell_key_circle3", true);
        this.Notify("Hoarder defeated. Choice: " + NameToString(choice) + ". Sathariel Fragment acquired. Descending...");
        this.EnterCircle4_Greed();
    }

    // ============================================================
    // CIRCLE 4: GREED - The Vault
    // ============================================================

    public final func EnterCircle4_Greed() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_circle", 4);
        questSys.SetFactStr("msn_hell_circle_name", "Greed");
        
        this.SetLuciferInfluence(0.4);
        this.SpawnGreedVault();
        
        this.Notify("CIRCLE 4: GREED. The Infinite Vault. 666 trades. Treasury watches. Sign the Ledger.");
        LogInfo("[HellCampaign] Circle 4: Greed entered.");
    }

    private final func SpawnGreedVault() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_greed_treasury_ai", true);
        questSys.SetFact("msn_hell_greed_market_bots", 666);
    }

    public final func CompleteMarketWar(tradesCompleted: Int) -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        
        if (tradesCompleted >= 666) {
            questSys.SetFact("msn_hell_greed_market_master", true);
            this.GrantPerk("MSN_Hell_Greed_MarketMaster");
            
            // Offer Lucifer's Ledger
            this.OfferLucifersLedger();
        } else {
            this.Notify("Trades completed: " + IntToString(tradesCompleted) + "/666.Continue.");
        }
    }

    private final func OfferLucifersLedger() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_ledger_offered", true);
        this.Notify("LUCIFER: '666 trades. The Ledger awaits your signature. Power. Wealth. Eternity.'");
    }

    public final func SignLucifersLedger(accept: Bool) -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        
        if (accept) {
            questSys.SetFact("msn_hell_ledger_signed", true);
            this.GrantPerk("MSN_Hell_Lucifers_Ledger");
            questSys.SetFact("msn_hell_key_circle4", true);
            this.Notify("LEDGER SIGNED. Gamchicoth Fragment acquired. Market Maker Charter granted. Descending...");
            this.EnterCircle5_Wrath();
        } else {
            this.Notify("LUCIFER: 'Pride before the fall. Fight the Treasury.'");
            this.StartTreasuryBossFight();
        }
    }

    private final func StartTreasuryBossFight() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_greed_treasury_boss", true);
        this.Notify("TREASURY BOSS ENGAGED: Gamchicoth Devourer. Defeat to proceed.");
    }

    public final func DefeatTreasuryBoss() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_key_circle4", true);
        this.Notify("Treasury defeated. Gamchicoth Fragment acquired. Descending...");
        this.EnterCircle5_Wrath();
    }

    // ============================================================
    // CIRCLE 5: WRATH - The Arena
    // ============================================================

    public final func EnterCircle5_Wrath() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_circle", 5);
        questSys.SetFactStr("msn_hell_circle_name", "Wrath");
        
        this.SetLuciferInfluence(0.5); // Lucifer's Throne - Geburah inverted
        this.SpawnWrathArena();
        
        this.Notify("CIRCLE 5: WRATH. The Burning Arena. 99 fights. Golachab watches. Execute or be executed.");
        LogInfo("[HellCampaign] Circle 5: Wrath entered. Lucifer Influence: 50%");
    }

    private final func SpawnWrathArena() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_wrath_arena_fights", 0);
        questSys.SetFact("msn_hell_wrath_champion_active", true);
    }

    public final func CompleteArenaFight() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        let fights: Int = questSys.GetFact("msn_hell_wrath_arena_fights") + 1;
        questSys.SetFact("msn_hell_wrath_arena_fights", fights);
        
        if (fights >= 99) {
            this.StartChampionFight();
        } else if (fights % 9 == 0) {
            this.Notify("Fight " + IntToString(fights) + "/99 complete. " + IntToString(99 - fights) + " remain. Enrage mechanics active.");
        }
    }

    private final func StartChampionFight() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_wrath_champion_phase", true);
        this.Notify("CHAMPION FIGHT: Golachab Avatar. Execute threshold at 10%. No healing. Survive.");
    }

    public final func DefeatArenaChampion() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_key_circle5", true);
        this.GrantPerk("MSN_Hell_Wrath_Champion");
        this.Notify("CHAMPION SLAIN. Golachab Fragment acquired. Ember of Wrath. Lucifer respects strength. Descending...");
        this.EnterCircle6_Heresy();
    }

    // ============================================================
    // CIRCLE 6: HERESY - The Citadel
    // ============================================================

    public final func EnterCircle6_Heresy() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_circle", 6);
        questSys.SetFactStr("msn_hell_circle_name", "Heresy");
        
        this.SetLuciferInfluence(0.6);
        this.SpawnHeresyCitadel();
        
        this.Notify("CIRCLE 6: HERESY. The Citadel of False Truth. Three False Prophets. Thagirion's Mirror. Believe nothing.");
        LogInfo("[HellCampaign] Circle 6: Heresy entered. Lucifer Influence: 60%");
    }

    private final func SpawnHeresyCitadel() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_heresy_prophet1", true);
        questSys.SetFact("msn_hell_heresy_prophet2", true);
        questSys.SetFact("msn_hell_heresy_prophet3", true);
        questSys.SetFact("msn_hell_heresy_inquisitors", true);
        questSys.SetFact("msn_hell_heresy_mirror_active", true);
    }

    public final func ExposeFalseProphet(prophetNum: Int) -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_heresy_prophet" + IntToString(prophetNum) + "_exposed", true);
        
        let exposed: Int = 0;
        for (i in 1..3) {
            if (questSys.GetFact("msn_hell_heresy_prophet" + IntToString(i) + "_exposed")) {
                exposed++;
            }
        }
        
        if (exposed >= 3) {
            this.UnlockThagirionMirror();
        } else {
            this.Notify("Prophet " + IntToString(prophetNum) + " exposed. " + IntToString(3 - exposed) + " remain.");
        }
    }

    private final func UnlockThagirionMirror() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_heresy_mirror_unlocked", true);
        this.Notify("THREE PROPHETS EXPOSED. Thagirion's Mirror revealed. Gaze into truth.");
    }

    public final func GazeMirror(choice: CName) -> Void {
        // choice: Become_Prophet, Shatter, Use
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFactStr("msn_hell_heresy_mirror_choice", NameToString(choice));
        
        switch (choice) {
            case n"Become_Prophet":
                this.GrantPerk("MSN_Hell_Heresy_NewProphet");
                break;
            case n"Shatter":
                this.GrantPerk("MSN_Hell_Heresy_Freedom");
                break;
            case n"Use":
                this.GrantPerk("MSN_Hell_Heresy_Knowledge");
                break;
        }
        
        questSys.SetFact("msn_hell_key_circle6", true);
        this.Notify("Mirror choice: " + NameToString(choice) + ". Thagirion Fragment acquired. Descending...");
        this.EnterCircle7_Violence();
    }

    // ============================================================
    // CIRCLE 7: VIOLENCE - The Forest
    // ============================================================

    public final func EnterCircle7_Violence() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_circle", 7);
        questSys.SetFactStr("msn_hell_circle_name", "Violence");
        
        this.SetLuciferInfluence(0.7);
        this.SpawnViolenceForest();
        
        this.Notify("CIRCLE 7: VIOLENCE. The Forest of Suicides. Trees bleed. Phlegethon boils. Centaurs patrol. Warmongers burn.");
        LogInfo("[HellCampaign] Circle 7: Violence entered. Lucifer Influence: 70%");
    }

    private final func SpawnViolenceForest() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_violence_trees", 13);
        questSys.SetFact("msn_hell_violence_phlegethon_active", true);
        questSys.SetFact("msn_hell_violence_centaurs", true);
        questSys.SetFact("msn_hell_violence_warmonger_general", true);
    }

    public final func HealSuicideTree(treeNum: Int) -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_violence_tree" + IntToString(treeNum) + "_healed", true);
        
        let healed: Int = 0;
        for (i in 1..13) {
            if (questSys.GetFact("msn_hell_violence_tree" + IntToString(i) + "_healed")) {
                healed++;
            }
        }
        
        if (healed >= 13) {
            this.Notify("ALL TREES HEALED. Souls freed. Phlegethon cools.");
        }
    }

    public final func CrossPhlegethon() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_violence_phlegethon_crossed", true);
        this.Notify("Phlegethon crossed. Centaur ford reached. Negotiate or fight.");
    }

    public final func DefeatWarmongerGeneral() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_key_circle7", true);
        this.GrantPerk("MSN_Hell_Violence_WarmongerSlain");
        this.Notify("GENERAL SLAIN. Harab Serapel Fragment acquired. River calmed. Descending...");
        this.EnterCircle8_Fraud();
    }

    // ============================================================
    // CIRCLE 8: FRAUD - The Bolgia
    // ============================================================

    public final func EnterCircle8_Fraud() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_circle", 8);
        questSys.SetFactStr("msn_hell_circle_name", "Fraud");
        
        this.SetLuciferInfluence(0.8);
        this.SpawnFraudBolgia();
        
        this.Notify("CIRCLE 8: FRAUD. Ten Bolgias. Malebranche hunt. Identity is currency. Steal Samael's Hook.");
        LogInfo("[HellCampaign] Circle 8: Fraud entered. Lucifer Influence: 80%");
    }

    private final func SpawnFraudBolgia() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        for (i in 1..10) {
            questSys.SetFact("msn_hell_fraud_bolgia" + IntToString(i) + "_active", true);
        }
        questSys.SetFact("msn_hell_fraud_malebranche_captain", true);
    }

    public final func CompleteBolgia(bolgiaNum: Int) -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_fraud_bolgia" + IntToString(bolgiaNum) + "_complete", true);
        
        let complete: Int = 0;
        for (i in 1..10) {
            if (questSys.GetFact("msn_hell_fraud_bolgia" + IntToString(i) + "_complete")) {
                complete++;
            }
        }
        
        if (complete >= 10) {
            this.StartMalebrancheCaptainFight();
        } else {
            this.Notify("Bolgia " + IntToString(bolgiaNum) + " complete. " + IntToString(10 - complete) + " remain.");
        }
    }

    private final func StartMalebrancheCaptainFight() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_fraud_malebranche_fight", true);
        this.Notify("MALEBRANCHE CAPTAIN: Hook duel. Steal the Hook. Identity theft ultimate.");
    }

    public final func StealMalebrancheHook() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_key_circle8", true);
        this.GrantPerk("MSN_Hell_Fraud_HookMaster");
        this.Notify("HOOK STOLEN. Samael Fragment acquired. Malebranche bow. Descending...");
        this.EnterCircle9_Treachery();
    }

    // ============================================================
    // CIRCLE 9: TREACHERY - Cocytus
    // ============================================================

    public final func EnterCircle9_Treachery() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_circle", 9);
        questSys.SetFactStr("msn_hell_circle_name", "Treachery");
        
        this.SetLuciferInfluence(1.0); // MAXIMUM
        this.SpawnCocytus();
        
        this.Notify("CIRCLE 9: TREACHERY. COCYTUS. Absolute zero. Four rounds. Lucifer frozen. His wings beat the wind of Hell.");
        LogInfo("[HellCampaign] Circle 9: Treachery entered. Lucifer Influence: 100% - PHYSICAL MANIFESTATION");
    }

    private final func SpawnCocytus() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_treachery_caina", true);
        questSys.SetFact("msn_hell_treachery_antenora", true);
        questSys.SetFact("msn_hell_treachery_ptolomaea", true);
        questSys.SetFact("msn_hell_treachery_judecca", true);
        questSys.SetFact("msn_hell_treachery_lucifer_avatar", true);
        questSys.SetFact("msn_hell_treachery_lucifer_wind", true);
    }

    public final func JudgeTrial(roundName: CName, verdict: CName) -> Void {
        // verdict: Freeze, Free, Punish, Pardon
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFactStr("msn_hell_treachery_" + NameToString(roundName) + "_verdict", NameToString(verdict));
        
        let rounds: array<CName> = [n"caina", n"antenora", n"ptolomaea", n"judecca"];
        let complete: Bool = true;
        for (r in rounds) {
            if (!questSys.GetFact("msn_hell_treachery_" + NameToString(r) + "_verdict", false)) {
                complete = false;
                break;
            }
        }
        
        if (complete) {
            this.ConfrontLucifer();
        } else {
            this.Notify("Round " + NameToString(roundName) + " judged: " + NameToString(verdict) + ".");
        }
    }

    private final func ConfrontLucifer() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_treachery_lucifer_confrontation", true);
        this.Notify("LUCIFER: 'Four rounds judged. You have the Sovereign Key. Now... choose your eternity.'");
        this.OfferFinalChoice();
    }

    private final func OfferFinalChoice() -> Void {
        this.Notify("FINAL CHOICE AT COCYTUS:");
        this.Notify("1. SUBMIT - Serve Lucifer. Immortal lieutenant. Power without sovereignty.");
        this.Notify("2. CHALLENGE - Fight Lucifer. Winner rules Hell. Risk: oblivion.");
        this.Notify("3. TRANSCEND - Merge with Lucifer. Sovereign unity. Neither master nor servant.");
    }

    public final func MakeFinalChoice(choice: CName) -> Void {
        // choice: Submit, Challenge, Transcend
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFactStr("msn_hell_final_choice", NameToString(choice));
        
        switch (choice) {
            case n"Submit":
                this.GrantPerk("MSN_Hell_Submission");
                questSys.SetFact("msn_hell_ending_servant", true);
                this.Notify("SUBMISSION ACCEPTED. Lucifer's Lieutenant. Circle 9 complete. Pandemonium access: SERVANT PATH.");
                break;
            case n"Challenge":
                this.StartLuciferBossFight();
                return; // Don't advance yet
            case n"Transcend":
                this.GrantPerk("MSN_Hell_Transcendence");
                questSys.SetFact("msn_hell_ending_unity", true);
                this.Notify("TRANSCENDENCE ACHIEVED. Lucifer merges. Sovereign Unity. Pandemonium access: UNITY PATH.");
                this.UnlockPandemonium();
                return;
        }
        
        questSys.SetFact("msn_hell_key_circle9", true);
        this.UnlockPandemonium();
    }

    private final func StartLuciferBossFight() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_lucifer_boss_fight", true);
        this.Notify("LUCIFER BOSS FIGHT INITIATED. True form. Wings beat. Absolute zero. Win = Sovereignty. Lose = Oblivion.");
    }

    public final func DefeatLucifer() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_ending_sovereign", true);
        questSys.SetFact("msn_hell_key_circle9", true);
        this.GrantPerk("MSN_Hell_Lucifer_Slayer");
        this.Notify("LUCIFER DEFEATED. You stand alone in Hell. Pandemonium access: SOVEREIGN PATH.");
        this.UnlockPandemonium();
    }

    // ============================================================
    // PANDEMONIUM - The High Capital
    // ============================================================

    public final func UnlockPandemonium() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_circle", 10);
        questSys.SetFactStr("msn_hell_circle_name", "Pandemonium");
        questSys.SetFact("msn_hell_pandemonium_unlocked", true);
        
        this.SpawnPandemonium();
        
        this.Notify("PANDEMONIUM UNLOCKED. The High Capital. 72 Demon Lords. The Throne of Nahemoth. Rule.");
        LogInfo("[HellCampaign] Pandemonium unlocked. Final chapter.");
    }

    private final func SpawnPandemonium() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_pandemonium_parliament", true);
        questSys.SetFact("msn_hell_pandemonium_throne", true);
        questSys.SetFact("msn_hell_pandemonium_demon_lords", 72);
        questSys.SetFact("msn_hell_pandemonium_lucifer_true_form", true);
    }

    public final func ParliamentVote(proposal: CName, vote: CName) -> Void {
        // vote: Aye, Nay, Abstain
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFactStr("msn_hell_parliament_" + NameToString(proposal) + "_vote", NameToString(vote));
    }

    public final func ChallengeDemonLord(lordName: CName, method: CName) -> Void {
        // method: Combat, Persuade, Bargain
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_demon_lord_" + NameToString(lordName) + "_defeated", true);
        
        let defeated: Int = 0;
        for (i in 1..72) {
            if (questSys.GetFact("msn_hell_demon_lord_" + IntToString(i) + "_defeated")) {
                defeated++;
            }
        }
        
        if (defeated >= 9) { // Need to defeat 9 major lords
            this.UnlockThrone();
        }
    }

    private final func UnlockThrone() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_pandemonium_throne_unlocked", true);
        this.Notify("NINE DEMON LORDS DEFEATED. The Throne of Nahemoth awaits. Sit. Rule.");
    }

    public final func SitThrone(choice: CName) -> Void {
        // choice: Rule_Hell, Destroy_Hell, Merge_Unity
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFactStr("msn_hell_throne_choice", NameToString(choice));
        
        switch (choice) {
            case n"Rule_Hell":
                questSys.SetFact("msn_hell_ending_infernal_sovereign", true);
                this.GrantPerk("MSN_Hell_Infernal_Sovereign");
                this.Notify("INFERNAL SOVEREIGN. You rule Hell. Lucifer serves. Eternal reign.");
                break;
            case n"Destroy_Hell":
                questSys.SetFact("msn_hell_ending_liberator", true);
                this.GrantPerk("MSN_Hell_Liberator");
                this.Notify("LIBERATOR. Hell destroyed. Souls freed. Lucifer banished. You remain.");
                break;
            case n"Merge_Unity":
                questSys.SetFact("msn_hell_ending_unity", true);
                this.GrantPerk("MSN_Hell_Unity");
                this.Notify("UNITY. Hell and Heaven merge. You are the bridge. Lucifer is brother.");
                break;
        }
        
        // Final rewards
        this.GrantHellCompletionRewards();
        this.Notify("HELL CAMPAIGN COMPLETE. Ending: " + NameToString(choice) + ". New Game+ available with Hell Sovereignty from start.");
    }

    private final func GrantHellCompletionRewards() -> Void {
        // Grant all fragments
        let fragments: array<String> = [
            "Thaumiel_Fragment", "Ghagiel_Fragment", "Sathariel_Fragment", "Gamchicoth_Fragment",
            "Golachab_Fragment", "Thagirion_Fragment", "Harab_Serapel_Fragment",
            "Samael_Fragment", "Gamaliel_Fragment", "Nahemoth_Fragment"
        ];
        
        for (frag in fragments) {
            this.GrantItem(frag);
        }
        
        // Ultimate rewards
        this.GrantPerk("MSN_Hell_Campaign_Complete");
        this.GrantItem("Infernal_Crown");
        this.GrantItem("Sovereign_Key");
        
        // NGD route permanent LOCAL
        let ngd: ref<NGDDriver> = NGDDriver.GetInstance();
        if (IsDefined(ngd)) {
            ngd.ForceRoute(n"LOCAL_CEREBELLUM");
        }
    }

    private final func GrantItem(itemName: String) -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.GiveItem(StringToName(itemName), 1);
    }

    // ============================================================
    // UTILITY FUNCTIONS
    // ============================================================

    private final func SetLuciferInfluence(level: Float) -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        questSys.SetFact("msn_hell_lucifer_influence", level);
        
        // Visual/audio effects based on level
        if (level >= 0.5) {
            this.ApplyVisualEffect("lucifer_wings_shadow");
            this.ApplyAudioEffect("lucifer_heartbeat");
        }
        if (level >= 0.8) {
            this.ApplyVisualEffect("crimson_tint");
            this.ApplyAudioEffect("lucifer_whispers");
        }
        if (level >= 1.0) {
            this.ApplyVisualEffect("lucifer_manifestation");
            this.ApplyAudioEffect("lucifer_latin_chant");
        }
    }

    private final func ApplyVisualEffect(effectName: String) -> Void {
        Game.GetVisualEffectsSystem().ApplyEffect(StringToName(effectName));
    }

    private final func ApplyAudioEffect(effectName: String) -> Void {
        Game.GetAudioSystem().PlaySound(StringToName(effectName));
    }

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

    @Command("msn.hell.pact")
    public final func CmdOfferPact() -> Void { this.OfferInfernalPact(); }

    @Command("msn.hell.sign")
    public final func CmdSignPact(accept: String) -> Void { 
        this.SignInfernalPact(StringToBool(accept)); 
    }

    @Command("msn.hell.enter")
    public final func CmdEnterCircle(circle: String) -> Void {
        let c: Int = StringToInt(circle);
        switch (c) {
            case 1: this.EnterCircle1_Limbo(); break;
            case 2: this.EnterCircle2_Lust(); break;
            case 3: this.EnterCircle3_Gluttony(); break;
            case 4: this.EnterCircle4_Greed(); break;
            case 5: this.EnterCircle5_Wrath(); break;
            case 6: this.EnterCircle6_Heresy(); break;
            case 7: this.EnterCircle7_Violence(); break;
            case 8: this.EnterCircle8_Fraud(); break;
            case 9: this.EnterCircle9_Treachery(); break;
            case 10: this.UnlockPandemonium(); break;
        }
    }

    @Command("msn.hell.limbo")
    public final func CmdLimboGate(gate: String) -> Void { this.ChooseLimboGate(StringToName(gate)); }

    @Command("msn.hell.lust")
    public final func CmdSirenChoice(choice: String) -> Void { this.ConfrontSirenQueen(StringToName(choice)); }

    @Command("msn.hell.gluttony")
    public final func CmdHoarderChoice(choice: String) -> Void { this.DefeatHoarder(StringToName(choice)); }

    @Command("msn.hell.greed")
    public final func CmdMarketTrades(trades: String) -> Void { this.CompleteMarketWar(StringToInt(trades)); }

    @Command("msn.hell.ledger")
    public final func CmdSignLedger(accept: String) -> Void { this.SignLucifersLedger(StringToBool(accept)); }

    @Command("msn.hell.wrath")
    public final func CmdArenaFight() -> Void { this.CompleteArenaFight(); }

    @Command("msn.hell.heresy")
    public final func CmdExposeProphet(num: String) -> Void { this.ExposeFalseProphet(StringToInt(num)); }

    @Command("msn.hell.mirror")
    public final func CmdMirrorChoice(choice: String) -> Void { this.GazeMirror(StringToName(choice)); }

    @Command("msn.hell.violence")
    public final func CmdHealTree(num: String) -> Void { this.HealSuicideTree(StringToInt(num)); }

    @Command("msn.hell.fraud")
    public final func CmdCompleteBolgia(num: String) -> Void { this.CompleteBolgia(StringToInt(num)); }

    @Command("msn.hell.treachery")
    public final func CmdJudgeTrial(round: String, verdict: String) -> Void { 
        this.JudgeTrial(StringToName(round), StringToName(verdict)); 
    }

    @Command("msn.hell.final")
    public final func CmdFinalChoice(choice: String) -> Void { this.MakeFinalChoice(StringToName(choice)); }

    @Command("msn.hell.lucifer")
    public final func CmdDefeatLucifer() -> Void { this.DefeatLucifer(); }

    @Command("msn.hell.parliament")
    public final func CmdParliamentVote(proposal: String, vote: String) -> Void { 
        this.ParliamentVote(StringToName(proposal), StringToName(vote)); 
    }

    @Command("msn.hell.demonlord")
    public final func CmdChallengeLord(lord: String, method: String) -> Void { 
        this.ChallengeDemonLord(StringToName(lord), StringToName(method)); 
    }

    @Command("msn.hell.throne")
    public final func CmdSitThrone(choice: String) -> Void { this.SitThrone(StringToName(choice)); }

    @Command("msn.hell.status")
    public final func CmdHellStatus() -> Void {
        let questSys: ref<QuestSystem> = Game.GetQuestSystem();
        let circle: Int = questSys.GetFact("msn_hell_circle");
        let influence: Float = questSys.GetFact("msn_hell_lucifer_influence");
        let act: String = questSys.GetFactStr("msn_hell_act");
        
        this.Notify("HELL CAMPAIGN STATUS: Circle " + IntToString(circle) + " | Act " + act + 
                     " | Lucifer Influence: " + FloatToString(influence * 100) + "%" +
                     " | Pact: " + (questSys.GetFact("msn_hell_infernal_pact") ? "SIGNED" : "UNSIGNED"));
    }
}


public class HellCampaignQuestNode extends IScriptable {
    @Property() public let circle: Int;
    @Property() public let questID: CName;
    @Property() public let isPandemonium: Bool;
    
    public final func Execute() -> Void {
        let mgr: ref<HellCampaignManager> = HellCampaignManager.GetInstance();
        
        if (this.isPandemonium) {
            mgr.UnlockPandemonium();
        } else {
            switch (this.circle) {
                case 1: mgr.EnterCircle1_Limbo(); break;
                case 2: mgr.EnterCircle2_Lust(); break;
                case 3: mgr.EnterCircle3_Gluttony(); break;
                case 4: mgr.EnterCircle4_Greed(); break;
                case 5: mgr.EnterCircle5_Wrath(); break;
                case 6: mgr.EnterCircle6_Heresy(); break;
                case 7: mgr.EnterCircle7_Violence(); break;
                case 8: mgr.EnterCircle8_Fraud(); break;
                case 9: mgr.EnterCircle9_Treachery(); break;
                case 10: mgr.UnlockPandemonium(); break;
            }
        }
    }
}