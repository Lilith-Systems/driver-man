// MSN Horsemen Audio Hooks
// Plays custom Lyra and Lilith audio events when a Four Horsemen Cyberpsycho engages the player.
// Written by Swarm Architect

module MSN.Horsemen.Audio

@addMethod(GameObject)
public final func IsMSNHorseman() -> Bool {
    let recordID = this.GetRecordID();
    let isWar = Equals(recordID, t"Character.MSN_Bosses.War") || Equals(recordID, t"MSN_Bosses.War");
    let isFamine = Equals(recordID, t"Character.MSN_Bosses.Famine") || Equals(recordID, t"MSN_Bosses.Famine");
    let isPestilence = Equals(recordID, t"Character.MSN_Bosses.Pestilence") || Equals(recordID, t"MSN_Bosses.Pestilence");
    let isDeath = Equals(recordID, t"Character.MSN_Bosses.Death") || Equals(recordID, t"MSN_Bosses.Death");
    
    return isWar || isFamine || isPestilence || isDeath;
}

// Hook when the boss takes damage (player attacked first)
@wrapMethod(ScriptedPuppet)
protected cb func OnTakeDamage(evt: ref<gameDamageReceivedEvent>) -> Bool {
    let isHorseman = this.IsMSNHorseman();
    let isFirstHit = false;
    
    if isHorseman {
        let currentHealth = GameInstance.GetStatPoolsSystem(this.GetGame()).GetStatPoolValue(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatPoolType.Health, false);
        let maxHealth = GameInstance.GetStatPoolsSystem(this.GetGame()).GetStatPoolValue(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatPoolType.Health, true);
        
        if currentHealth > 0.0 && maxHealth > 0.0 {
            // Check if health is practically full (start of encounter)
            if (currentHealth / maxHealth) > 0.98 {
                isFirstHit = true;
            }
        }
    }
    
    let result = wrappedMethod(evt);
    
    if isHorseman && isFirstHit {
        GameObject.PlaySoundEvent(this, n"lilith_horseman_spawn");
        GameObject.PlaySoundEvent(this, n"lyra_horseman_warning");
        GameObjectEffectHelper.StartEffectEvent(this, n"boss_spawn_effect");
        
        Game.GetAudioSystem().PlaySound("lilith_horseman_spawn", this.GetWorldPosition());
        Game.GetAudioSystem().PlaySound("lyra_horseman_warning", this.GetWorldPosition());
    }
    
    return result;
}

// Hook when the player takes damage (boss attacked first)
@wrapMethod(PlayerPuppet)
protected cb func OnTakeDamage(evt: ref<gameDamageReceivedEvent>) -> Bool {
    let instigator = evt.instigator as ScriptedPuppet;
    let isFirstHit = false;
    
    if IsDefined(instigator) && instigator.IsMSNHorseman() {
        let currentHealth = GameInstance.GetStatPoolsSystem(instigator.GetGame()).GetStatPoolValue(Cast<StatsObjectID>(instigator.GetEntityID()), gamedataStatPoolType.Health, false);
        let maxHealth = GameInstance.GetStatPoolsSystem(instigator.GetGame()).GetStatPoolValue(Cast<StatsObjectID>(instigator.GetEntityID()), gamedataStatPoolType.Health, true);
        
        if currentHealth > 0.0 && maxHealth > 0.0 {
            if (currentHealth / maxHealth) > 0.98 {
                isFirstHit = true;
            }
        }
    }
    
    let result = wrappedMethod(evt);
    
    if isFirstHit && IsDefined(instigator) {
        GameObject.PlaySoundEvent(instigator, n"lilith_horseman_spawn");
        GameObject.PlaySoundEvent(instigator, n"lyra_horseman_warning");
        GameObjectEffectHelper.StartEffectEvent(instigator, n"boss_spawn_effect");
        
        Game.GetAudioSystem().PlaySound("lilith_horseman_spawn", instigator.GetWorldPosition());
        Game.GetAudioSystem().PlaySound("lyra_horseman_warning", instigator.GetWorldPosition());
    }
    
    return result;
}

// Hook when quickhacked (if player opens with a quickhack instead of shooting)
@wrapMethod(ScriptedPuppet)
protected cb func OnQuickHackTriggered(evt: ref<QuickHackEvent>) -> Bool {
    let isHorseman = this.IsMSNHorseman();
    let isFirstHit = false;
    
    if isHorseman {
        let currentHealth = GameInstance.GetStatPoolsSystem(this.GetGame()).GetStatPoolValue(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatPoolType.Health, false);
        let maxHealth = GameInstance.GetStatPoolsSystem(this.GetGame()).GetStatPoolValue(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatPoolType.Health, true);
        
        if currentHealth > 0.0 && maxHealth > 0.0 {
            if (currentHealth / maxHealth) > 0.98 {
                isFirstHit = true;
            }
        }
    }
    
    let result = wrappedMethod(evt);
    
    if isHorseman && isFirstHit {
        GameObject.PlaySoundEvent(this, n"lilith_horseman_spawn");
        GameObject.PlaySoundEvent(this, n"lyra_horseman_warning");
        GameObjectEffectHelper.StartEffectEvent(this, n"boss_spawn_effect");
        
        Game.GetAudioSystem().PlaySound("lilith_horseman_spawn", this.GetWorldPosition());
        Game.GetAudioSystem().PlaySound("lyra_horseman_warning", this.GetWorldPosition());
    }
    
    return result;
}
