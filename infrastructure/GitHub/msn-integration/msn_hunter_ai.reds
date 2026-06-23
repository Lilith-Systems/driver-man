module MSN.HunterAI

@wrapMethod(PreventionSystem)
protected final func OnHeatLevelChanged(heatStage: EPreventionHeatStage) -> Void {
    wrappedMethod(heatStage);
    
    // Spawn the elite Netwatch Boss when the player hits 4 stars
    if Equals(heatStage, EPreventionHeatStage.Heat_4) {
        this.SpawnNetwatchBoss();
    }
}

@addMethod(PreventionSystem)
private final func SpawnNetwatchBoss() -> Void {
    let player: ref<PlayerPuppet> = this.GetPlayer();
    if !IsDefined(player) {
        return;
    }
    
    let game: GameInstance = player.GetGame();
    let position: Vector4 = player.GetWorldPosition();
    let forward: Vector4 = player.GetWorldForward();
    
    // Spawn directly next to the player (3 meters in front)
    position.x += forward.x * 3.0;
    position.y += forward.y * 3.0;
    
    let spec: DynamicEntitySpec;
    // TweakDB ID for the custom elite Netwatch Boss
    spec.recordID = t"Character.MSN_Netwatch_Elite_Boss"; 
    spec.position = position;
    spec.orientation = player.GetWorldOrientation();
    spec.persistState = false;
    spec.persistSpawn = false;
    spec.alwaysSpawned = true;
    
    GameInstance.GetDynamicEntitySystem(game).CreateEntity(spec);
}
