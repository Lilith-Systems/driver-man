// GRAND THEFT CYBERPUNK — HELL CAMPAIGN CIRCLE QUESTS
// Abyssal Assets Mod: Quest Definitions for The Nine Circles + Pandemonium
// File: r6/scripts/quests/hell_circle_quests.reds
// Generated: 2026-06-19 | Lucifer's Seal | Sephirah: Yesod (Foundation)

public class HellCircleQuests extends IScriptable {
    private static let instance: ref<HellCircleQuests>;
    private let hellCampaign: ref<HellCampaignManager>;
    private let luciferSystem: ref<LuciferDialogueSystem>;
    private let questStates: map<String, QuestState>;
    
    public final static func GetInstance() -> ref<HellCircleQuests> {
        if (!IsDefined(HellCircleQuests.instance)) {
            HellCircleQuests.instance = new HellCircleQuests();
            HellCircleQuests.instance.Initialize();
        }
        return HellCircleQuests.instance;
    }
    
    private final func Initialize() -> Void {
        this.hellCampaign = HellCampaignManager.GetInstance();
        this.luciferSystem = LuciferDialogueSystem.GetInstance();
        this.InitializeQuestDefinitions();
        LogInfo("[HellCircleQuests] INITIALIZED — 12 Main Quests + 10 Side Quests loaded");
    }
    
    private final func InitializeQuestDefinitions() -> Void {
        this.questStates = {
            // MAIN QUESTS — Circle Progression
            ["q_hell_00_entry"]: new QuestState {
                id = "q_hell_00_entry",
                name = "The Abyssal Gate",
                category = "Main",
                circle = 0,
                state = "NotStarted",
                objectives = {
                    "Investigate Night City Sub-Net Anomaly",
                    "Locate the Abyssal Gate in Pacifica Ruins",
                    "Defeat Gatekeeper AI",
                    "Enter the Abyss"
                },
                rewards = {"Abyssal Gate Key", "Memory Shard", "500 Street Cred"},
                luciferDialogue = "lucifer_generic_descent"
            },
            ["q_hell_01_limbo"]: new QuestState {
                id = "q_hell_01_limbo",
                name = "The Vestibule of Indecision",
                category = "Main",
                circle = 1,
                qliphoth = "Thaumiel",
                state = "Locked",
                prerequisites = {"q_hell_00_entry"},
                objectives = {
                    "Navigate the Endless Fog",
                    "Speak with 3 Vestige Souls",
                    "Resist the Apathy Field",
                    "Choose: Memory or Void at the Crossroads",
                    "Defeat Limbo Walker Prime",
                    "Claim the Thaumiel Fragment"
                },
                rewards = {"Thaumiel Fragment", "Limbo Clearance", "Memory Shard x5", "1000 Street Cred"},
                luciferDialogue = "lucifer_generic_descent",
                ngdRoute = "HYBRID_OK"
            },
            ["q_hell_02_lust"]: new QuestState {
                id = "q_hell_02_lust",
                name = "The Hurricane of Desire",
                category = "Main",
                circle = 2,
                qliphoth = "Ghagiel",
                state = "Locked",
                prerequisites = {"q_hell_01_limbo"},
                objectives = {
                    "Enter the Neon Flesh Market",
                    "Resist the Siren's Song (Dialogue challenge)",
                    "Disable 3 Siren Netrunners",
                    "Purge 2 Incubus Scripts",
                    "Defeat Siren Queen Vespertine",
                    "Claim the Ghagiel Fragment"
                },
                rewards = {"Ghagiel Fragment", "Lust Clearance", "Siren Chip", "Desire_Stim x3", "1500 Street Cred"},
                luciferDialogue = "lucifer_generic_descent",
                ngdRoute = "HYBRID_OK"
            },
            ["q_hell_03_gluttony"]: new QuestState {
                id = "q_hell_03_gluttony",
                name = "The Consuming Trench",
                category = "Main",
                circle = 3,
                qliphoth = "Sathariel",
                state = "Locked",
                prerequisites = {"q_hell_02_lust"},
                objectives = {
                    "Navigate the Visceral Data Tract",
                    "Avoid Acid Data Pools",
                    "Steal the Hoard Key from a Hoarder AI",
                    "Feed a False Soul to the Devourer",
                    "Defeat Devourer Prime Omega",
                    "Claim the Sathariel Fragment"
                },
                rewards = {"Sathariel Fragment", "Gluttony Clearance", "Consumer Core", "Digestive Enzyme x3", "2000 Street Cred"},
                luciferDialogue = "lucifer_generic_descent",
                ngdRoute = "LOCAL_REQUIRED"
            },
            ["q_hell_04_greed"]: new QuestState {
                id = "q_hell_04_greed",
                name = "The Infinite Vault",
                category = "Main",
                circle = 4,
                qliphoth = "Gamchicoth",
                state = "Locked",
                prerequisites = {"q_hell_03_gluttony"},
                objectives = {
                    "Enter the Corporate Gold Vault",
                    "Crash 3 Sub-Markets via Arbitrage",
                    "Choose Side: Hoarders or Wasters",
                    "Eliminate the Opposition Leader",
                    "Break the Market Maker's Contract",
                    "Defeat Market Maker Prime Mammon",
                    "Claim the Gamchicoth Fragment"
                },
                rewards = {"Gamchicoth Fragment", "Greed Clearance", "Contract Shard", "Treasury Key", "Market Data x5", "3000 Street Cred"},
                luciferDialogue = "lucifer_pact_offer",
                ngdRoute = "LOCAL_REQUIRED",
                luciferPactOffer = true
            },
            ["q_hell_05_wrath"]: new QuestState {
                id = "q_hell_05_wrath",
                name = "The Burning Abyss",
                category = "Main",
                circle = 5,
                qliphoth = "Golachab",
                state = "Locked",
                prerequisites = {"q_hell_04_greed"},
                objectives = {
                    "Survive the Rage Eruption",
                    "Calm 3 Rage Daemons",
                    "Shatter the Armor Shred",
                    "Defeat Fury Berserker x3",
                    "Defeat Wrath Incarnate Golachab",
                    "Claim the Golachab Fragment"
                },
                rewards = {"Golachab Fragment", "Wrath Clearance", "Rage Core", "Fury Brand", "4000 Street Cred"},
                luciferDialogue = "lucifer_circle5_wrath",
                ngdRoute = "LOCAL_REQUIRED"
            },
            ["q_hell_06_heresy"]: new QuestState {
                id = "q_hell_06_heresy",
                name = "The Iron Maiden",
                category = "Main",
                circle = 6,
                qliphoth = "Tagiriron",
                state = "Locked",
                prerequisites = {"q_hell_05_wrath"},
                objectives = {
                    "Pierce the Unpierceable Shield",
                    "Hack without Quickhacks (Manual breach)",
                    "Defile the Iconoclast Altar",
                    "Silence the Sacrilege Choir",
                    "Defeat Inquisitor Prime Tagiriron",
                    "Claim the Tagiriron Fragment"
                },
                rewards = {"Tagiriron Fragment", "Heresy Clearance", "Blasphemer Bolt", "Iconoclast Iron", "Sacrilege Scythe", "5000 Street Cred"},
                luciferDialogue = "lucifer_generic_descent",
                ngdRoute = "LOCAL_CEREBELLUM"
            },
            ["q_hell_07_violence"]: new QuestState {
                id = "q_hell_07_violence",
                name = "Eternal Slaughterhouse",
                category = "Main",
                circle = 7,
                qliphoth = "Harab_Serapel",
                state = "Locked",
                prerequisites = {"q_hell_06_heresy"},
                objectives = {
                    "Execute 10 Enemies below 20% HP",
                    "Chain 5 Cleaves in a single combat",
                    "Destroy the Carnage Cannons",
                    "Break the Fear Aura",
                    "Defeat Butcher Prime Harab",
                    "Claim the Harab Serapel Fragment"
                },
                rewards = {"Harab_Serapel Fragment", "Violence Clearance", "Violence Core", "Slaughter Key", "Brutality Edge", "7000 Street Cred"},
                luciferDialogue = "lucifer_generic_descent",
                ngdRoute = "LOCAL_CEREBELLUM"
            },
            ["q_hell_08_fraud"]: new QuestState {
                id = "q_hell_08_fraud",
                name = "Hall of Mirrors",
                category = "Main",
                circle = 8,
                qliphoth = "Samael",
                state = "Locked",
                prerequisites = {"q_hell_07_violence"},
                objectives = {
                    "Identify 5 Real Targets among Decoys",
                    "Shatter the Mirror Labyrinth",
                    "Fire Blind — Detect Invisible Projectiles",
                    "Expose the Grand Deceiver",
                    "Defeat Deceiver Prime Samael",
                    "Claim the Samael Fragment"
                },
                rewards = {"Samael Fragment", "Fraud Clearance", "Deception Key", "Mirror Shard", "Lie Protocol", "10000 Street Cred"},
                luciferDialogue = "lucifer_generic_descent",
                ngdRoute = "LOCAL_CEREBELLUM"
            },
            ["q_hell_09_treachery"]: new QuestState {
                id = "q_hell_09_treachery",
                name = "Cocytus — The Frozen Lake",
                category = "Main",
                circle = 9,
                qliphoth = "Gamaliel",
                state = "Locked",
                prerequisites = {"q_hell_08_fraud"},
                objectives = {
                    "Convert 2 Enemies to Allies",
                    "Avoid Friendly Fire Bonus",
                    "Steal Cyberware from a Betrayer",
                    "Freeze Loyalty of the Oathbreaker",
                    "Defeat Oathbreaker Prime Gamaliel",
                    "Claim the Gamaliel Fragment"
                },
                rewards = {"Gamaliel Fragment", "Treachery Clearance", "Treachery Core", "Betrayal Key", "Oathbreaker Shard", "15000 Street Cred"},
                luciferDialogue = "lucifer_circle9_treachery",
                ngdRoute = "LOCAL_CEREBELLUM"
            },
            ["q_hell_10_throne"]: new QuestState {
                id = "q_hell_10_throne",
                name = "Lucifer's Throne — The Obsidian Apex",
                category = "Main",
                circle = 10,
                qliphoth = "Lilith",
                state = "Locked",
                prerequisites = {"q_hell_09_treachery", "All_Nine_Keys"},
                objectives = {
                    "Survive Morningstar's Mercy (Phase 1)",
                    "Endure Pride's Peak — History Erasure (Phase 2)",
                    "Defeat Your Own Reflection (Phase 3)",
                    "CONFRONT LUCIFER MORNINGSTAR (Phase 4)",
                    "CHOOSE: Submit / Rebel / Transcend"
                },
                rewards = {"Morningstar (Weapon)", "Pride's Peak (Armor)", "Fallen Finale (Cyberdeck)", "Devil's Due (Vehicle)", "Lilith Fragment", "Abyssal Crown", "50000 Street Cred", "SOVEREIGN TITLE"},
                luciferDialogue = "lucifer_throne_final",
                ngdRoute = "LOCAL_CEREBELLUM",
                isFinalBoss = true
            },
            // SECRET QUEST — Pandemonium
            ["q_hell_11_pandemonium"]: new QuestState {
                id = "q_hell_11_pandemonium",
                name = "Pandemonium — The Void Beyond",
                category = "Secret",
                circle = 11,
                qliphoth = "NONE",
                state = "Hidden",
                prerequisites = {"q_hell_10_throne", "Sovereign_Status"},
                objectives = {
                    "Survive Non-Existence in The Unraveling",
                    "Break the Silence of the Choir",
                    "Sit on the Throne of Nothing",
                    "Defeat Lucifer's Shadow",
                    "BECOME THE MORNINGSTAR — Rewrite the Abyss"
                },
                rewards = {"Abyssal Crown", "Void Key", "New Abyss Decree", "TRUE SOVEREIGN TITLE", "ABYSS REWRITTEN"},
                luciferDialogue = "lucifer_generic_descent",
                ngdRoute = "LOCAL_CEREBELLUM",
                isSecret = true
            },
            
            // SIDE QUESTS
            ["q_hell_side_vestige_memories"]: new QuestState {
                id = "q_hell_side_vestige_memories",
                name = "Echoes of the Uncommitted",
                category = "Side",
                circle = 1,
                state = "Available",
                objectives = {
                    "Find 5 Memory Shards in Limbo",
                    "Reconstruct a Vestige's Past",
                    "Choice: Return Memory or Consume It"
                },
                rewards = {"Memory Reconstruction Tool", "Vestige Ally", "Indecision Essence x3"}
            },
            ["q_hell_side_siren_heart"]: new QuestState {
                id = "q_hell_side_siren_heart",
                name = "A Siren's Broken Heart",
                category = "Side",
                circle = 2,
                state = "Available",
                objectives = {
                    "Find the Siren's Locket",
                    "Decrypt the Love Data",
                    "Choice: Return to Siren Queen or Keep"
                },
                rewards = {"Siren's Favor", "Desire Stim x5", "Pleasure Protocol"}
            },
            ["q_hell_side_hoarder_stash"]: new QuestState {
                id = "q_hell_side_hoarder_stash",
                name = "The Hoarder's Secret Stash",
                category = "Side",
                circle = 3,
                state = "Available",
                objectives = {
                    "Locate 3 Hidden Hoards in the Trench",
                    "Solve the Consumption Riddle",
                    "Claim the Ultimate Hoard"
                },
                rewards = {"Hoarder's Master Key", "Consumer Core x3", "Sathariel Fragment"}
            },
            ["q_hell_side_market_manipulation"]: new QuestState {
                id = "q_hell_side_market_manipulation",
                name = "Arbitrage Opportunity",
                category = "Side",
                circle = 4,
                state = "Available",
                objectives = {
                    "Manipulate 5 Micro-Markets",
                    "Profit 1,000,000 Eddies",
                    "Avoid Treasury Bot Detection"
                },
                rewards = {"Market Maker Algorithm", "Contract Shard x3", "Gamchicoth Fragment"}
            },
            ["q_hell_side_berserker_calm"]: new QuestState {
                id = "q_hell_side_berserker_calm",
                name = "Calming the Storm",
                category = "Side",
                circle = 5,
                state = "Available",
                objectives = {
                    "Calm 5 Rage Daemons without Combat",
                    "Use Only Dialogue and Environment",
                    "Teach Rage to Burn Inward"
                },
                rewards = {"Fury Brand (Unique)", "Rage Core x2", "Golachab Fragment"}
            },
            ["q_hell_side_iconoclast_test"]: new QuestState {
                id = "q_hell_side_iconoclast_test",
                name = "The Iconoclast's Test",
                category = "Side",
                circle = 6,
                state = "Available",
                objectives = {
                    "Hack 3 Systems without Quickhacks",
                    "Survive Cyberware Corruption Wave",
                    "Prove Faith in the Machine"
                },
                rewards = {"Iconoclast Iron (Unique)", "Blasphemer Bolt", "Tagiriron Fragment"}
            },
            ["q_hell_side_executioner_trial"]: new QuestState {
                id = "q_hell_side_executioner_trial",
                name = "The Executioner's Trial",
                category = "Side",
                circle = 7,
                state = "Available",
                objectives = {
                    "Execute 20 Enemies in Under 60 Seconds",
                    "Chain 10 Cleaves",
                    "Zero Damage Taken"
                },
                rewards = {"Butcher's Blade (Legendary)", "Brutality Edge", "Harab Serapel Fragment"}
            },
            ["q_hell_side_mirror_truth"]: new QuestState {
                id = "q_hell_side_mirror_truth",
                name = "Truth in the Reflection",
                category = "Side",
                circle = 8,
                state = "Available",
                objectives = {
                    "Shatter 10 Mirrors without Breaking the True Ones",
                    "Identify the Real Deceiver among 5 Clones",
                    "Complete the Hall without Position Swap"
                },
                rewards = {"Deception Key (Master)", "Mirror Shard x3", "Samael Fragment"}
            },
            ["q_hell_side_oathkeeper_test"]: new QuestState {
                id = "q_hell_side_oathkeeper_test",
                name = "The Oathkeeper's Test",
                category = "Side",
                circle = 9,
                state = "Available",
                objectives = {
                    "Refuse 3 Betrayal Opportunities",
                    "Protect a Traitor from Justice",
                    "Maintain Loyalty at All Costs"
                },
                rewards = {"Betrayal Key (Unbreakable)", "Oathbreaker Shard", "Gamaliel Fragment"}
            },
            ["q_hell_side_lucifer_wager"]: new QuestState {
                id = "q_hell_side_lucifer_wager",
                name = "The Devil's Wager",
                category = "Side",
                circle = 10,
                state = "Hidden",
                objectives = {
                    "Accept Lucifer's Final Wager",
                    "Bet Your Soul on a Coin Flip",
                    "Win: Transcend | Lose: Eternal Damnation"
                },
                rewards = {"ABYSSAL CROWN", "VOID KEY", "TRUE SOVEREIGN", "OR: Save Deleted"},
                isHidden = true,
                ngdRoute = "LOCAL_CEREBELLUM"
            }
        };
    }
    
    public final func GetQuestState(questId: String) -> QuestState {
        return this.questStates[questId];
    }
    
    public final func UpdateQuestState(questId: String, newState: String, objectiveIndex: Int32 = -1) -> Void {
        let quest = this.questStates[questId];
        if (IsDefined(quest)) {
            quest.state = newState;
            if (objectiveIndex >= 0) {
                // Mark objective complete
            }
            LogInfo("[HellQuests] " + questId + " -> " + newState);
        }
    }
    
    public final func CheckPrerequisites(questId: String) -> Bool {
        let quest = this.questStates[questId];
        if (!IsDefined(quest)) return false;
        for (req in quest.prerequisites) {
            let reqQuest = this.questStates[req];
            if (!IsDefined(reqQuest) || reqQuest.state != "Completed") {
                return false;
            }
        }
        return true;
    }
    
    public final func CompleteQuest(questId: String) -> Void {
        let quest = this.questStates[questId];
        if (IsDefined(quest)) {
            quest.state = "Completed";
            // Trigger circle completion if main quest
            if (quest.category == "Main" && quest.circle > 0) {
                this.hellCampaign.CompleteQuest(quest.circle);
            }
            // Trigger Lucifer dialogue
            if (quest.luciferDialogue != "") {
                this.luciferSystem.Speak(quest.luciferDialogue, quest.name);
            }
            // Check for pact offer
            if (quest.luciferPactOffer) {
                this.hellCampaign.CheckLuciferPactAvailability();
            }
            LogInfo("[HellQuests] " + questId + " COMPLETED");
        }
    }
    
    // NSSP Console Routes
    public final func Console_QuestList() -> String {
        let result = "HELL CAMPAIGN QUESTS\n";
        result += "====================\n";
        for (id, quest in this.questStates) {
            let marker = "";
            if (quest.isSecret) marker = " [SECRET]";
            if (quest.isHidden) marker = " [HIDDEN]";
            result += id + ": " + quest.name + " | Circle " + quest.circle + " | " + quest.state + marker + "\n";
        }
        return result;
    }
    
    public final func Console_QuestInfo(questId: String) -> String {
        let quest = this.questStates[questId];
        if (!IsDefined(quest)) return "Quest not found: " + questId;
        
        let result = "QUEST: " + quest.name + "\n";
        result += "ID: " + quest.id + "\n";
        result += "Category: " + quest.category + "\n";
        result += "Circle: " + quest.circle + "\n";
        if (quest.qliphoth != "") result += "Qliphoth: " + quest.qliphoth + "\n";
        result += "State: " + quest.state + "\n";
        result += "Prerequisites: " + String.Join(", ", quest.prerequisites) + "\n";
        result += "Objectives:\n";
        for (i, obj in quest.objectives) {
            result += "  " + IntToString(i+1) + ". " + obj + "\n";
        }
        result += "Rewards: " + String.Join(", ", quest.rewards) + "\n";
        result += "NGD Route: " + quest.ngdRoute + "\n";
        if (quest.luciferDialogue != "") result += "Lucifer Dialogue: " + quest.luciferDialogue + "\n";
        return result;
    }
    
    public final func Console_QuestStart(questId: String) -> String {
        if (!this.CheckPrerequisites(questId)) {
            return "Prerequisites not met for: " + questId;
        }
        this.UpdateQuestState(questId, "Active");
        return "Quest started: " + questId;
    }
    
    public final func Console_QuestComplete(questId: String) -> String {
        this.CompleteQuest(questId);
        return "Quest completed: " + questId;
    }
}

struct QuestState {
    id: String;
    name: String;
    category: String; // Main, Side, Secret
    circle: Int32;
    qliphoth: String = "";
    state: String; // NotStarted, Locked, Available, Active, Completed, Hidden
    prerequisites: array<String> = {};
    objectives: array<String>;
    rewards: array<String>;
    luciferDialogue: String = "";
    ngdRoute: String = "HYBRID_OK";
    luciferPactOffer: Bool = false;
    isSecret: Bool = false;
    isHidden: Bool = false;
}
