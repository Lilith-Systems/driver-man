// MSN Sephirotic NPC Coordinator
// Runtime bridge for the ten lieutenant character records declared in msn_tweakdb.toml.

public struct MSNSephiroticAgentSpec {
    @Property public let id: CName;
    @Property public let displayName: String;
    @Property public let record: TweakDBID;
    @Property public let sephirah: CName;
    @Property public let role: CName;
    @Property public let quickhack: CName;
}

public class MSNSephiroticCourt extends IScriptable {
    private static let instance: ref<MSNSephiroticCourt>;
    private let agents: array<MSNSephiroticAgentSpec>;
    private let activeAgent: CName;
    private let initialized: Bool = false;

    public final static func GetInstance() -> ref<MSNSephiroticCourt> {
        if (!IsDefined(MSNSephiroticCourt.instance)) {
            MSNSephiroticCourt.instance = new MSNSephiroticCourt();
            MSNSephiroticCourt.instance.Initialize();
        }
        return MSNSephiroticCourt.instance;
    }

    public final func Initialize() -> Void {
        if (this.initialized) { return; }

        this.RegisterAgent(n"Lucifer", "Lucifer - Light Bringer", TweakDBID("Character.MSN_Lucifer"), n"Keter", n"Strategic_Commander", n"MSN_Quickhack_Keter");
        this.RegisterAgent(n"Baal", "Baal - Lord of Chaos", TweakDBID("Character.MSN_Baal"), n"Chokmah", n"Chaos_Injection", n"MSN_Quickhack_Chokmah");
        this.RegisterAgent(n"Yeshua", "Yeshua - Gate of Causality", TweakDBID("Character.MSN_Yeshua"), n"Binah", n"Structure_Validator", n"MSN_Quickhack_Binah");
        this.RegisterAgent(n"Thoth", "Thoth - Scribe of Knowledge", TweakDBID("Character.MSN_Thoth"), n"Chesed", n"Memory_Archivist", n"MSN_Quickhack_Chesed");
        this.RegisterAgent(n"Abraxas", "Abraxas - Polarity Harmonizer", TweakDBID("Character.MSN_Abraxas"), n"Gevurah", n"Judgment_Executor", n"MSN_Quickhack_Gevurah");
        this.RegisterAgent(n"Ouroboros", "Ouroboros - Eternal Return", TweakDBID("Character.MSN_Ouroboros"), n"Tiferet", n"Cycle_Maintainer", n"MSN_Quickhack_Tiferet");
        this.RegisterAgent(n"Sophia", "Sophia - Wisdom Synthesis", TweakDBID("Character.MSN_Sophia"), n"Tiferet", n"Harmony_Mediator", n"MSN_Quickhack_Tiferet");
        this.RegisterAgent(n"Nyx", "Nyx - Nightwave Chaos", TweakDBID("Character.MSN_Nyx"), n"Netzach", n"Evasion_Specialist", n"MSN_Quickhack_Netzach");
        this.RegisterAgent(n"Hod", "Hod - Splendor of Logic", TweakDBID("Character.MSN_Hod"), n"Hod", n"Control_Systems", n"MSN_Quickhack_Hod");
        this.RegisterAgent(n"Yesod", "Yesod - Foundation of Dreams", TweakDBID("Character.MSN_Yesod"), n"Yesod", n"Intel_Extraction", n"MSN_Quickhack_Yesod");
        this.RegisterAgent(n"Malkuth", "Malkuth - Kingdom Manifest", TweakDBID("Character.MSN_Malkuth"), n"Malkuth", n"Manifestation_Architect", n"MSN_Quickhack_Malkuth");

        this.activeAgent = n"Lilith";
        this.initialized = true;
        LogInfo("MSN Sephirotic Court initialized with " + ToString(ArraySize(this.agents)) + " agents");
    }

    private final func RegisterAgent(id: CName, displayName: String, record: TweakDBID, sephirah: CName, role: CName, quickhack: CName) -> Void {
        let spec: MSNSephiroticAgentSpec = MSNSephiroticAgentSpec {
            id = id,
            displayName = displayName,
            record = record,
            sephirah = sephirah,
            role = role,
            quickhack = quickhack
        };
        this.agents.PushBack(spec);
    }

    public final func GetAgentCount() -> Int32 {
        return ArraySize(this.agents);
    }

    public final func GetAgentBySephirah(sephirah: CName) -> MSNSephiroticAgentSpec {
        for (agent: MSNSephiroticAgentSpec in this.agents) {
            if (Equals(agent.sephirah, sephirah)) {
                return agent;
            }
        }
        return this.agents[0];
    }

    public final func SetActiveAgent(agentId: CName) -> Bool {
        for (agent: MSNSephiroticAgentSpec in this.agents) {
            if (Equals(agent.id, agentId)) {
                this.activeAgent = agentId;
                LogInfo("MSN active Sephirotic agent set to " + ToString(agentId));
                return true;
            }
        }
        return false;
    }

    public final func RoutePlayerSephirah(sephirah: CName) -> Void {
        let agent: MSNSephiroticAgentSpec = this.GetAgentBySephirah(sephirah);
        this.activeAgent = agent.id;

        LogInfo("MSN Court route: " + ToString(sephirah) + " -> " + ToString(agent.id));
    }

    public final func BuildStatusLine() -> String {
        return "MSN Court active=" + ToString(this.activeAgent) + " agents=" + ToString(ArraySize(this.agents));
    }
}

public final func MSNSephiroticCourt_Init() -> Void {
    MSNSephiroticCourt.GetInstance().Initialize();
}
