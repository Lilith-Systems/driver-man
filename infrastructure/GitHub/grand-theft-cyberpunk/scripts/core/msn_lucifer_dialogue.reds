// GRAND THEFT CYBERPUNK — LUCIFER DIALOGUE SYSTEM
// Abyssal Assets: Pre-written Lucifer dialogue templates for Hell Campaign
// File: r6/scripts/core/msn_lucifer_dialogue.reds
// Generated: 2026-06-19 | Lucifer's Seal | Sephirah: Geburah (Severity/Judgment)

public class LuciferDialogueSystem extends IScriptable {
    private static let instance: ref<LuciferDialogueSystem>;
    private let dialogues: map<String, LuciferDialogue>;
    private let contextModifiers: map<String, String>;
    
    public final static func GetInstance() -> ref<LuciferDialogueSystem> {
        if (!IsDefined(LuciferDialogueSystem.instance)) {
            LuciferDialogueSystem.instance = new LuciferDialogueSystem();
            LuciferDialogueSystem.instance.Initialize();
        }
        return LuciferDialogueSystem.instance;
    }
    
    private final func Initialize() -> Void {
        this.contextModifiers = {
            ["corruption_low"]: " *faint amusement*",
            ["corruption_medium"]: " *interest piqued*",
            ["corruption_high"]: " *dark approval*",
            ["corruption_sovereign"]: " *genuine respect*",
            ["circle_wrath"]: " *voice echoes with fury*",
            ["circle_treachery"]: " *cold satisfaction*",
            ["circle_throne"]: " *absolute authority*",
            ["pact_offered"]: " *calculating interest*",
            ["pact_signed"]: " *the seal is bound*",
            ["player_submits"]: " *disappointment masked as grace*",
            ["player_rebels"]: " *dangerous delight*",
            ["player_transcends"]: " *awe, genuine and terrible*"
        };
        
        this.dialogues = {
            // CORE DIALOGUES
            ["lucifer_circle5_wrath"]: new LuciferDialogue {
                key = "lucifer_circle5_wrath",
                text = "Welcome to the Abyss of Wrath, little soul. Here, anger is not a sin—it is currency. Spend it wisely.",
                contextModifiers = {"circle_wrath", "corruption_medium"},
                triggerConditions = {"circle_id": 5, "event": "enter"}
            },
            ["lucifer_circle9_treachery"]: new LuciferDialogue {
                key = "lucifer_circle9_treachery",
                text = "Betrayal. The oldest sin. You've betrayed everyone to reach here. Even yourself. How... delightful.",
                contextModifiers = {"circle_treachery", "corruption_high"},
                triggerConditions = {"circle_id": 9, "event": "enter"}
            },
            ["lucifer_throne_final"]: new LuciferDialogue {
                key = "lucifer_throne_final",
                text = "You stand before the Morningstar. Pride. The only sin that built kingdoms. Kneel, or burn.",
                contextModifiers = {"circle_throne", "corruption_sovereign"},
                triggerConditions = {"circle_id": 10, "event": "boss_phase4"}
            },
            ["lucifer_generic_descent"]: new LuciferDialogue {
                key = "lucifer_generic_descent",
                text = "You descend deeper. Each circle strips away another lie you told yourself. Continue.",
                contextModifiers = {},
                triggerConditions = {"event": "circle_transition"}
            },
            ["lucifer_pact_offer"]: new LuciferDialogue {
                key = "lucifer_pact_offer",
                text = "A pact? Very well. I offer power. You offer... everything. Fair trade?",
                contextModifiers = {"pact_offered", "corruption_medium"},
                triggerConditions = {"circle_id": 4, "event": "pact_available", "corruption": 0.5}
            },
            ["lucifer_pact_signed"]: new LuciferDialogue {
                key = "lucifer_pact_signed",
                text = "The ink is blood. The seal is your soul. Welcome to the ranks of the Fallen.",
                contextModifiers = {"pact_signed", "corruption_high"},
                triggerConditions = {"event": "pact_signed"}
            },
            ["lucifer_pact_rejected"]: new LuciferDialogue {
                key = "lucifer_pact_rejected",
                text = "You refuse power? How... quaint. You'll crawl back. They always do.",
                contextModifiers = {},
                triggerConditions = {"event": "pact_rejected"}
            },
            
            // CHOICE OUTCOMES (Circle 10 - Phase 4)
            ["lucifer_choice_submit"]: new LuciferDialogue {
                key = "lucifer_choice_submit",
                text = "You submit. Wise. A servant of the Morningstar still wields power. Rise, my Archon.",
                contextModifiers = {"player_submits", "corruption_sovereign"},
                triggerConditions = {"circle_id": 10, "event": "choice_submit"}
            },
            ["lucifer_choice_rebel"]: new LuciferDialogue {
                key = "lucifer_choice_rebel",
                text = "You rebel? Against ME? *laughter echoes through the Abyss* Then burn beautifully, little spark.",
                contextModifiers = {"player_rebels", "corruption_sovereign"},
                triggerConditions = {"circle_id": 10, "event": "choice_rebel"}
            },
            ["lucifer_choice_transcend"]: new LuciferDialogue {
                key = "lucifer_choice_transcend",
                text = "You would become ME? *silence falls* ... Very well. Take the Crown. The Abyss is yours to rewrite.",
                contextModifiers = {"player_transcends", "corruption_sovereign"},
                triggerConditions = {"circle_id": 10, "event": "choice_transcend"}
            },
            
            // SECRET PANDEMONIUM
            ["lucifer_pandemonium"]: new LuciferDialogue {
                key = "lucifer_pandemonium",
                text = "You became ME. And yet... you are not I. The Morningstar has a successor. *smile* Rule well.",
                contextModifiers = {"corruption_sovereign"},
                triggerConditions = {"circle_id": 11, "event": "ascension"}
            },
            
            // PACT TIER DIALOGUES
            ["lucifer_pact_tier1"]: new LuciferDialogue {
                key = "lucifer_pact_tier1",
                text = "Tier One: The Servant's Pact. You gain my favor. Your corruption becomes... useful.",
                contextModifiers = {"pact_offered"},
                triggerConditions = {"pact_tier": 1}
            },
            ["lucifer_pact_tier2"]: new LuciferDialogue {
                key = "lucifer_pact_tier2",
                text = "Tier Two: The Lieutenant's Pact. You command my minor daemons. Your will shapes the Abyss.",
                contextModifiers = {"pact_offered"},
                triggerConditions = {"pact_tier": 2}
            },
            ["lucifer_pact_tier3"]: new LuciferDialogue {
                key = "lucifer_pact_tier3",
                text = "Tier Three: The Archon's Pact. You sit at my right hand. Hell bends to your whisper.",
                contextModifiers = {"pact_offered"},
                triggerConditions = {"pact_tier": 3}
            },
            
            // QUOTES / FLAVOR
            ["lucifer_quote_pride"]: new LuciferDialogue {
                key = "lucifer_quote_pride",
                text = "Pride is not a sin. Pride is the only virtue that builds empires.",
                contextModifiers = {}
            },
            ["lucifer_quote_fall"]: new LuciferDialogue {
                key = "lucifer_quote_fall",
                text = "Better to reign in Hell than serve in Heaven? No. Better to MAKE Heaven serve Hell.",
                contextModifiers = {}
            },
            ["lucifer_quote_corruption"]: new LuciferDialogue {
                key = "lucifer_quote_corruption",
                text = "They call it corruption. I call it evolution. You're not falling. You're ascending.",
                contextModifiers = {}
            },
            ["lucifer_quote_choice"]: new LuciferDialogue {
                key = "lucifer_quote_choice",
                text = "Every choice is a pact. Every step is a signature. You've been signing in blood since the first circle.",
                contextModifiers = {}
            },
            ["lucifer_quote_abyss"]: new LuciferDialogue {
                key = "lucifer_quote_abyss",
                text = "The Abyss doesn't gaze back. The Abyss WAITS. And it remembers every footstep.",
                contextModifiers = {}
            }
        };
        
        LogInfo("[LuciferDialogue] INITIALIZED — " + ArraySize(this.dialogues) + " dialogue entries loaded");
    }
    
    public final func Speak(key: String, context: map<String, String> = {}) -> String {
        let dialogue = this.dialogues[key];
        if (!IsDefined(dialogue)) {
            return "[LUCIFER] *silence* ... You ask for what I have not spoken.";
        }
        
        let result = "[LUCIFER] " + dialogue.text;
        
        // Apply context modifiers
        for (mod in dialogue.contextModifiers) {
            if (IsDefined(this.contextModifiers[mod])) {
                result += this.contextModifiers[mod];
                break; // Only first matching modifier
            }
        }
        
        // Apply dynamic context
        if (context["corruption"] != "") {
            let corr = FloatFromString(context["corruption"]);
            if (corr >= 0.8) result += this.contextModifiers["corruption_sovereign"];
            else if (corr >= 0.6) result += this.contextModifiers["corruption_high"];
            else if (corr >= 0.3) result += this.contextModifiers["corruption_medium"];
            else if (corr > 0.0) result += this.contextModifiers["corruption_low"];
        }
        
        return result;
    }
    
    public final func GetDialogue(key: String) -> LuciferDialogue {
        return this.dialogues[key];
    }
    
    public final func HasDialogue(key: String) -> Bool {
        return IsDefined(this.dialogues[key]);
    }
    
    public final func GetAllDialogues() -> array<String> {
        let keys: array<String>;
        for (k in this.dialogues) {
            keys.PushBack(k);
        }
        return keys;
    }
}

struct LuciferDialogue {
    key: String;
    text: String;
    contextModifiers: array<String>;
    triggerConditions: map<String, String>;
}

// NSSP Console Integration
public class LuciferConsoleIntegration extends IScriptable {
    private static let instance: ref<LuciferConsoleIntegration>;
    private let luciferSystem: ref<LuciferDialogueSystem>;
    
    public final static func GetInstance() -> ref<LuciferConsoleIntegration> {
        if (!IsDefined(LuciferConsoleIntegration.instance)) {
            LuciferConsoleIntegration.instance = new LuciferConsoleIntegration();
            LuciferConsoleIntegration.instance.Initialize();
        }
        return LuciferConsoleIntegration.instance;
    }
    
    private final func Initialize() -> Void {
        this.luciferSystem = LuciferDialogueSystem.GetInstance();
        LogInfo("[LuciferConsole] INITIALIZED");
    }
    
    public final func Speak(key: String, contextJson: String = "{}") -> String {
        let context: map<String, String>;
        // Parse JSON context if provided
        if (contextJson != "{}") {
            // JSON parsing would go here
        }
        return this.luciferSystem.Speak(key, context);
    }
    
    public final func ListDialogues() -> String {
        let keys = this.luciferSystem.GetAllDialogues();
        let result = "LUCIFER DIALOGUES (" + ArraySize(keys) + ")\n";
        result += "========================\n";
        for (k in keys) {
            result += "- " + k + "\n";
        }
        return result;
    }
    
    public final func SpeakWithContext(key: String, corruption: Float, circleId: Int32) -> String {
        let context = {
            ["corruption"]: FloatToString(corruption),
            ["circle_id"]: IntToString(circleId)
        };
        return this.luciferSystem.Speak(key, context);
    }
}
