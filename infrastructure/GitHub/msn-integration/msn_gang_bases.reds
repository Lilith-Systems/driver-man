module MSN.GangBases

public class AbyssalMiningRigNode {
    public let position: Vector4;
    public let rigSpawned: Bool;
    public let nodeID: String;
    
    public func Initialize(pos: Vector4, id: String) {
        this.position = pos;
        this.nodeID = id;
        this.rigSpawned = false;
    }
}

public class MSNGangBaseSystem extends ScriptableSystem {
    private let m_nodes: array<ref<AbyssalMiningRigNode>>;
    private let m_player: wref<PlayerPuppet>;
    private let m_activationDistance: Float;
    private let m_updateTimer: Float;
    
    private func OnAttach() -> Void {
        this.m_activationDistance = 25.0; // Distance to spawn rig
        this.m_updateTimer = 0.0;
        this.InitializeNodes();
    }
    
    private func InitializeNodes() -> Void {
        // Badlands coordinates
        let node1 = new AbyssalMiningRigNode();
        node1.Initialize(new Vector4(1500.0, -1200.0, 150.0, 1.0), "Rig_Badlands_Alpha");
        ArrayPush(this.m_nodes, node1);
        
        // Pacifica coordinates
        let node2 = new AbyssalMiningRigNode();
        node2.Initialize(new Vector4(-2100.0, -2400.0, 20.0, 1.0), "Rig_Pacifica_Omega");
        ArrayPush(this.m_nodes, node2);
        
        // City Center coordinates
        let node3 = new AbyssalMiningRigNode();
        node3.Initialize(new Vector4(-100.0, 100.0, 35.0, 1.0), "Rig_CityCenter_Nexus");
        ArrayPush(this.m_nodes, node3);
    }
    
    public final func RegisterPlayer(player: ref<PlayerPuppet>) -> Void {
        this.m_player = player;
    }
    
    public final func IsPlayerRegistered() -> Bool {
        return IsDefined(this.m_player);
    }
    
    public final func OnPlayerUpdate(dt: Float, playerPos: Vector4) -> Void {
        this.m_updateTimer += dt;
        if this.m_updateTimer < 1.0 { // Throttle: Check every 1 second
            return;
        }
        this.m_updateTimer = 0.0;
        
        let i: Int32 = 0;
        let dist: Float;
        
        while i < ArraySize(this.m_nodes) {
            let node = this.m_nodes[i];
            
            if !node.rigSpawned {
                dist = Vector4.Distance(playerPos, node.position);
                
                if dist <= this.m_activationDistance {
                    this.SpawnAbyssalMiningRig(node);
                }
            }
            i += 1;
        }
    }
    
    private final func SpawnAbyssalMiningRig(node: ref<AbyssalMiningRigNode>) -> Void {
        let spawnTransform: Transform;
        Transform.SetPosition(spawnTransform, node.position);
        
        // Target TweakDB ID for the Abyssal Mining Rig prop
        // Assumes TweakDB entry: Items.AbyssalMiningRig
        let rigRecordID: TweakDBID = t"Items.AbyssalMiningRig"; 
        
        // Dynamically spawn the rig entity
        let dynamicSystem = GameInstance.GetDynamicEntitySystem(this.GetGameInstance());
        if IsDefined(dynamicSystem) {
            let entityId: EntityID = dynamicSystem.SpawnEntity(rigRecordID, spawnTransform);
            LogChannel(n"DEBUG", s"Abyssal Mining Rig Spawned: " + node.nodeID);
        }
        
        node.rigSpawned = true;
    }
}

// Hook into PlayerPuppet to feed location data to our GangBaseSystem
@wrapMethod(PlayerPuppet)
protected cb func OnUpdate(dt: Float) -> Bool {
    wrappedMethod(dt);
    
    let gangSystem: ref<MSNGangBaseSystem> = GameInstance.GetScriptableSystemsContainer(this.GetGame()).Get(n"MSN.GangBases.MSNGangBaseSystem") as MSNGangBaseSystem;
    
    if IsDefined(gangSystem) {
        if !gangSystem.IsPlayerRegistered() {
            gangSystem.RegisterPlayer(this);
        }
        
        let playerPos: Vector4 = this.GetWorldPosition();
        gangSystem.OnPlayerUpdate(dt, playerPos);
    }
}
