// MSN Drone Swarms - Prevention System Override
// Overrides 4-star wanted level spawns with a swarm of 10 heavily armed Netwatch Drones.

module MSNIntegration.DroneSwarms

@wrapMethod(PreventionSystem)
protected final func SpawnUnit(recordID: TweakDBID, position: Vector4, orientation: Quaternion) -> Void {
    let heatLevel: Int32 = this.GetHeatLevel();
    
    // When the player hits a 4-star wanted level, override standard NCPD spawns
    if heatLevel >= 4 {
        // TweakDB ID for a heavy Netwatch Drone (e.g. Wyvern/Octant variants)
        let droneRecord: TweakDBID = t"Character.veh_drone_wyvern_netwatch"; 
        let swarmSize: Int32 = 10;
        let i: Int32 = 0;
        
        while i < swarmSize {
            // Apply a simple grid offset so the drones don't spawn exactly inside each other
            let offsetX: Float = Cast<Float>(i % 3) * 5.0 - 5.0;
            let offsetY: Float = Cast<Float>(i / 3) * 5.0 - 5.0;
            
            let spawnPos: Vector4 = new Vector4(
                position.X + offsetX,
                position.Y + offsetY,
                position.Z + 25.0, // Spawn from above
                position.W
            );
            
            // Spawn the drone instead of the original unit
            wrappedMethod(droneRecord, spawnPos, orientation);
            i += 1;
        }
    } else {
        // Normal behavior for < 4 stars
        wrappedMethod(recordID, position, orientation);
    }
}

@wrapMethod(PreventionSystem)
protected final func OnHeatLevelChanged(heatLevel: Int32) -> Void {
    wrappedMethod(heatLevel);
    
    if heatLevel == 4 {
        // Optional hook: Additional audio/visual effects when Netwatch swarm is triggered
        // LogChannel(n"DEBUG", "MSN: 4-Star Wanted Level reached. Spawning Netwatch Drone Swarm.");
    }
}
