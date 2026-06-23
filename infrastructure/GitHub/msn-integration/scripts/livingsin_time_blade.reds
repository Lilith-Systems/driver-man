// Living Sin Time Blade — Legendary Temporal Weapon
// File: r6/scripts/weapons/livingsin_time_blade.reds

// ============================================================================
// LIVING SIN TIME BLADE — CHRONOS EDGE
// ============================================================================

public class LivingSinTimeBlade extends BaseMeleeWeapon {
    @Property public let MaxCharges: Int32 = 3;
    @Property public let CurrentCharges: Int32 = 3;
    @Property public let PartySize: Int32 = 3;
    @Property public let TimeJumpRange: Float = 300.0; // seconds
    @Property public let ParadoxRisk: Float = 0.15;
    @Property public let ParadoxAccumulation: Float = 0.0;
    @Property public let CrownOfSinBound: Bool = false;
    @Property public let TemporalPhaseActive: Bool = false;

    // Recharge ritual state
    @Property public let LastRechargeAttempt: Float = -1.0;
    @Property public let ValidConfessions: Int32 = 0;
    @Property public let FalseConfessions: Int32 = 0;

    // Warnings
    @Property public let ParadoxWarning50: Bool = false;
    @Property public let ParadoxWarning75: Bool = false;
    @Property public let ParadoxWarning90: Bool = false;

    // Mods
    @Property public let TemporalPhaseMod: Bool = false;
    @Property public let SinRechargeMod: Bool = false;
    @Property public let ParadoxGuardMod: Bool = false;

    protected cb func OnAttach() -> Void {
        this.CheckCrownOfSin();
        this.InitializeMods();
        LogInfo("[Living Sin] Time Blade attached. Charges: " + IntToString(this.CurrentCharges) + "/3. Paradox: " + FloatToString(this.ParadoxAccumulation * 100.0) + "%");
    }

    protected cb func OnDetach() -> Void {
        if (this.TemporalPhaseActive) {
            this.EndTemporalPhase();
        }
    }

    private final func CheckCrownOfSin() -> Void {
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        if (IsDefined(player)) {
            let hasCrown: Bool = player.HasItem("Items.CrownOfLivingSin");
            this.CrownOfSinBound = hasCrown;
            if (!hasCrown) {
                LogWarning("[Living Sin] Crown of Living Sin not equipped. Time Blade power suppressed.");
                Game.GetUIManager().ShowNotification("⚠ Living Sin Time Blade: Crown of Living Sin required for temporal powers.");
            } else {
                LogInfo("[Living Sin] Crown of Living Sin detected. Temporal powers unlocked.");
            }
        }
    }

    private final func InitializeMods() -> Void {
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        if (IsDefined(player)) {
            this.TemporalPhaseMod = player.HasItem("Items.LivingSin_TemporalPhase");
            this.SinRechargeMod = player.HasItem("Items.LivingSin_SinRecharge");
            this.ParadoxGuardMod = player.HasItem("Items.LivingSin_ParadoxGuard");
        }
    }

    // ============================================================================
    // TEMPORAL PHASE — MAIN ABILITY
    // ============================================================================

    public final func ActivateTemporalPhase(targetTimeOffset: Float) -> Bool {
        // Validate
        if (!this.CrownOfSinBound) {
            Game.GetUIManager().ShowNotification("✗ Crown of Living Sin required.");
            return false;
        }
        if (this.CurrentCharges <= 0) {
            Game.GetUIManager().ShowNotification("✗ No charges remaining. Perform Confessional Recharge at 3:33 AM.");
            return false;
        }
        if (AbsF(targetTimeOffset) > this.TimeJumpRange) {
            Game.GetUIManager().ShowNotification("✗ Time offset exceeds range (±" + FloatToString(this.TimeJumpRange) + "s).");
            return false;
        }
        if (this.TemporalPhaseActive) {
            Game.GetUIManager().ShowNotification("✗ Temporal phase already active.");
            return false;
        }

        // Consume charge
        this.CurrentCharges--;
        this.TemporalPhaseActive = true;

        // Accumulate paradox
        let paradoxGain: Float = this.ParadoxRisk;
        if (this.ParadoxGuardMod) {
            paradoxGain *= 0.5;
        }
        this.ParadoxAccumulation += paradoxGain;
        this.CheckParadoxWarnings();

        // Gather party members (up to PartySize)
        let targets: array<ref<GameObject>> = this.GatherPartyMembers();
        let actualTargets: Int32 = ArraySize(targets);
        if (actualTargets > this.PartySize) {
            actualTargets = this.PartySize;
            ArrayResize(targets, this.PartySize);
        }

        // Apply temporal phase to all targets
        for (i: Int32 = 0; i < actualTargets; i++) {
            let target: ref<GameObject> = targets[i];
            if (IsDefined(target)) {
                this.ApplyTemporalPhase(target, targetTimeOffset);
            }
        }

        // Visual/audio
        this.SpawnTemporalVFX(targets, targetTimeOffset);
        Game.GetAudioSystem().PlaySound("livingsin_temporal_shear", Game.GetPlayer().GetWorldPosition());
        Game.GetCameraSystem().Shake(1.0, 2.0);

        // Notification
        let direction: String = targetTimeOffset >= 0.0 ? "FORWARD" : "BACKWARD";
        Game.GetUIManager().ShowNotification("⧗ TEMPORAL PHASE: " + IntToString(actualTargets) + " targets " + direction + " " + FloatToString(AbsF(targetTimeOffset)) + "s | Charges: " + IntToString(this.CurrentCharges) + "/3 | Paradox: " + FloatToString(this.ParadoxAccumulation * 100.0) + "%");

        // End phase after duration
        let duration: Float = 10.0;
        if (this.TemporalPhaseMod) {
            duration = 20.0;  // Phase mod doubles temporal window
        }
        this.SchedulePhaseEnd(duration, targets);

        return true;
    }

    private final func GatherPartyMembers() -> array<ref<GameObject>> {
        let members: array<ref<GameObject>> = {};
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        if (IsDefined(player)) {
            members.PushBack(player);

            // Get companions/followers
            let companions: array<ref<GameObject>> = Game.GetCompanionSystem().GetActiveCompanions();
            for (comp in companions) {
                if (IsDefined(comp)) {
                    members.PushBack(comp);
                }
            }

            // Nearby allies (co-op)
            let allies: array<ref<Entity>> = Game.GetSpatialQueries().GetEntitiesInRadius(player.GetWorldPosition(), 10.0);
            for (ally in allies) {
                let puppet: ref<ScriptedPuppet> = ally as ScriptedPuppet;
                if (IsDefined(puppet) && puppet.GetAttitudeTowards(player) == EAIAttitude.Friendly && !ArrayContains(members, puppet)) {
                    members.PushBack(puppet);
                }
            }
        }
        return members;
    }

    private final func ApplyTemporalPhase(target: ref<GameObject>, timeOffset: Float) -> Void {
        let puppet: ref<ScriptedPuppet> = target as ScriptedPuppet;
        if (!IsDefined(puppet)) { return; }

        // Create temporal bubble
        let bubble: ref<TemporalBubble> = new TemporalBubble();
        bubble.target = puppet;
        bubble.timeOffset = timeOffset;
        bubble.startTime = EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime());
        bubble.duration = 10.0;

        // Visual marker
        let vfx: ref<ParticleEffect> = ParticleEffect.Spawn("livingsin_temporal_bubble", puppet.GetWorldPosition());
        if (IsDefined(vfx)) {
            vfx.SetParameter("TimeOffset", timeOffset);
            vfx.SetParameter("Color", timeOffset >= 0.0 ? Color(1.0, 0.2, 0.8, 1.0) : Color(0.2, 0.8, 1.0, 1.0));
        }

        // Apply time displacement
        if (timeOffset > 0.0) {
            // Forward: hasted, see immediate future (precog)
            puppet.ApplyStatusEffect("TemporalHaste", 10.0);
            puppet.SetPrecognition(true, timeOffset);
        } else {
            // Backward: rewind position/health, knowledge of immediate past
            this.RewindTarget(puppet, AbsF(timeOffset));
        }

        // Invulnerability during phase
        puppet.SetInvulnerable(true);
        this.TemporalBubbles.PushBack(bubble);
    }

    private final func RewindTarget(puppet: ref<ScriptedPuppet>, seconds: Float) -> Void {
        // Restore position, health, status from seconds ago
        // This would use Ouroboros memory engrams
        let ouroboros: ref<OuroborosSystem> = OuroborosSystem.GetInstance();
        if (IsDefined(ouroboros)) {
            let pastState: TemporalState = ouroboros.GetStateAt(puppet, EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime()) - seconds);
            if (IsDefined(pastState)) {
                puppet.SetWorldPosition(pastState.position);
                puppet.GetHealthSystem().SetHealth(pastState.health);
                puppet.GetStatusEffectSystem().RestoreState(pastState.statusEffects);
            }
        }
    }

    private final func SchedulePhaseEnd(duration: Float, targets: array<ref<GameObject>>) -> Void {
        // Simple delay - in practice would use game's delay system
        Game.GetDelaySystem().DelayEvent(this, n"OnTemporalPhaseEnd", duration, targets);
    }

    protected cb func OnTemporalPhaseEnd(targets: array<ref<GameObject>>) -> Void {
        this.TemporalPhaseActive = false;

        for (target in targets) {
            let puppet: ref<ScriptedPuppet> = target as ScriptedPuppet;
            if (IsDefined(puppet)) {
                puppet.SetInvulnerable(false);
                puppet.SetPrecognition(false, 0.0);

                // Paradox backlash on end
                if (this.ParadoxAccumulation > 0.5 && RandomF() < this.ParadoxAccumulation * 0.3) {
                    this.ApplyParadoxBacklash(puppet);
                }
            }
        }

        Game.GetUIManager().ShowNotification("⧗ Temporal phase ended. Paradox level: " + FloatToString(this.ParadoxAccumulation * 100.0) + "%");
    }

    // ============================================================================
    // CONFESSIONAL RECHARGE — ANNOYING BALANCING MECHANIC
    // ============================================================================

    public final func AttemptConfessionalRecharge(confession: String) -> Bool {
        // Validate ritual conditions
        if (!this.ValidateRitualConditions()) {
            return false;
        }

        // Validate confession magnitude
        let sinMagnitude: ESinMagnitude = this.AnalyzeConfession(confession);
        if (sinMagnitude < ESinMagnitude.Mortal) {
            Game.GetUIManager().ShowNotification("✗ Confession insufficient. Sin magnitude: " + EnumValueToString("ESinMagnitude", Cast(sinMagnitude)) + ". Required: Mortal or higher.");
            this.FalseConfessions++;
            this.ParadoxAccumulation += 0.25; // Penalty
            this.CheckParadoxWarnings();
            Game.GetAudioSystem().PlaySound("livingsin_false_confession", Game.GetPlayer().GetWorldPosition());
            return false;
        }

        // Valid confession
        this.ValidConfessions++;
        this.CurrentCharges = Min(this.MaxCharges, this.CurrentCharges + 1);
        this.LastRechargeAttempt = EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime());

        // Reduce paradox slightly
        this.ParadoxAccumulation = Max(0.0, this.ParadoxAccumulation - 0.1);
        this.CheckParadoxWarnings();

        // Visceral feedback
        this.SpawnConfessionVFX(confession, sinMagnitude);
        Game.GetAudioSystem().PlaySound("livingsin_true_confession", Game.GetPlayer().GetWorldPosition());
        Game.GetCameraSystem().Shake(2.0, 1.5);

        Game.GetUIManager().ShowNotification("✝ CONFESSION ACCEPTED. Sin: " + EnumValueToString("ESinMagnitude", Cast(sinMagnitude)) + " | Charge restored: " + IntToString(this.CurrentCharges) + "/3 | Valid confessions: " + IntToString(this.ValidConfessions) + " | False: " + IntToString(this.FalseConfessions) + " | Paradox: " + FloatToString(this.ParadoxAccumulation * 100.0) + "%");

        return true;
    }

    private final func ValidateRitualConditions() -> Bool {
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        if (!IsDefined(player)) { return false; }

        // 1. Time check: 3:33 AM (±1 minute)
        let currentTime: GameTime = Game.GetTimeSystem().GetGameTime();
        let hour: Int32 = currentTime.hours;
        let minute: Int32 = currentTime.minutes;

        if (hour != 3 || minute < 32 || minute > 34) {
            Game.GetUIManager().ShowNotification("✗ The hour is not 3:33 AM. Current: " + IntToString(hour) + ":" + IntToString(minute) + ". Wait for the witching hour.");
            return false;
        }

        // 2. Blood requirement: standing in own blood, self-inflicted
        if (!this.CheckBloodRitual(player)) {
            Game.GetUIManager().ShowNotification("✗ No fresh self-inflicted blood detected. Cut yourself and stand in it.");
            return false;
        }

        // 3. Vocal confession (mic input or text with "I confess" prefix)
        // Would check for voice activity or specific chat prefix
        // For now, assume text confession with prefix

        return true;
    }

    private final func CheckBloodRitual(player: ref<PlayerPuppet>) -> Bool {
        // Check for recent self-damage and blood decal under feet
        let pos: Vector4 = player.GetWorldPosition();
        let bloodDecals: array<ref<DecalComponent>> = Game.GetSpatialQueries().GetDecalsInRadius(pos, 1.0, "blood");
        for (decal in bloodDecals) {
            if (decal.age < 30.0 && decal.source == player.GetEntityID()) {
                return true;
            }
        }

        // Alternative: recent self-damage event
        if (player.GetLastSelfDamageTime() < 60.0) {
            return true;
        }

        return false;
    }

    private final func AnalyzeConfession(confession: String) -> ESinMagnitude {
        let lower: String = ToLower(confession);

        // Mortal sins (7 deadly + betrayal)
        let mortalKeywords: array<String> = {
            "murder", "kill", "murdered", "killed", "betray", "betrayed", "treason",
            "adultery", "affair", "cheated", "abandon", "abandoned", "sacrificed",
            "torture", "tortured", "rape", "molest", "abused", "abuse",
            "genocide", "massacre", "slaughter", "butcher", "cannibal",
            "sold my soul", "damned", "eternal", "unforgivable"
        };

        // Venial sins
        let venialKeywords: array<String> = {
            "lie", "lied", "steal", "stole", "cheat", "cheated", "lust", "lusted",
            "greed", "greedy", "gluttony", "glutton", "sloth", "lazy", "wrath", "angry",
            "envy", "envious", "pride", "proud", "vain", "vanity"
        };

        for (kw in mortalKeywords) {
            if (StrContains(lower, kw)) {
                return ESinMagnitude.Mortal;
            }
        }
        for (kw in venialKeywords) {
            if (StrContains(lower, kw)) {
                return ESinMagnitude.Venial;
            }
        }
        return ESinMagnitude.Minor;
    }

    private final func SpawnConfessionVFX(confession: String, magnitude: ESinMagnitude) -> Void {
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        let pos: Vector4 = player.GetWorldPosition();

        let vfx: ref<ParticleEffect>;
        if (magnitude == ESinMagnitude.Mortal) {
            vfx = ParticleEffect.Spawn("livingsin_mortal_confession", pos);
            if (IsDefined(vfx)) {
                vfx.SetParameter("Intensity", 3.0);
                vfx.SetParameter("Color", Color(1.0, 0.0, 0.2, 1.0));
            }
        } else {
            vfx = ParticleEffect.Spawn("livingsin_venial_confession", pos);
            if (IsDefined(vfx)) {
                vfx.SetParameter("Intensity", 1.5);
                vfx.SetParameter("Color", Color(1.0, 0.4, 0.1, 1.0));
            }
        }

        // Text projection
        Game.GetUIManager().ShowHolographicText(pos, "✝ " + confession, 5.0, Color(1.0, 0.1, 0.3, 1.0));
    }

    // ============================================================================
    // PARADOX SYSTEM
    // ============================================================================

    private final func CheckParadoxWarnings() -> Void {
        if (this.ParadoxAccumulation >= 0.9 && !this.ParadoxWarning90) {
            this.ParadoxWarning90 = true;
            Game.GetUIManager().ShowNotification("⚠⚠⚠ PARADOX CRITICAL: 90% — TIMELINE ERASE IMMINENT. One more temporal phase = ERASURE.");
            Game.GetAudioSystem().PlaySound("livingsin_paradox_critical", Game.GetPlayer().GetWorldPosition());
        } else if (this.ParadoxAccumulation >= 0.75 && !this.ParadoxWarning75) {
            this.ParadoxWarning75 = true;
            Game.GetUIManager().ShowNotification("⚠⚠ PARADOX HIGH: 75% — Reality thinning. Avoid temporal powers.");
            Game.GetAudioSystem().PlaySound("livingsin_paradox_high", Game.GetPlayer().GetWorldPosition());
        } else if (this.ParadoxAccumulation >= 0.5 && !this.ParadoxWarning50) {
            this.ParadoxWarning50 = true;
            Game.GetUIManager().ShowNotification("⚠ PARADOX ELEVATED: 50% — Temporal echoes detected.");
        }
    }

    private final func ApplyParadoxBacklash(puppet: ref<ScriptedPuppet>) -> Void {
        let backlashType: Int32 = RandInt(0, 4);

        switch (backlashType) {
            case 0: // Temporal sickness
                puppet.ApplyStatusEffect("TemporalSickness", 60.0);
                Game.GetUIManager().ShowNotification("⛌ PARADOX BACKLASH: Temporal sickness. -50% all stats for 60s.");
                break;
            case 1: // Memory loss
                this.EraseRandomMemory(puppet);
                Game.GetUIManager().ShowNotification("⛌ PARADOX BACKLASH: Memory fragment erased. Skill XP lost.");
                break;
            case 2: // Timeline displacement
                this.DisplaceInTimeline(puppet);
                Game.GetUIManager().ShowNotification("⛌ PARADOX BACKLASH: Displaced 10s in timeline.");
                break;
            case 3: // Erasure (at 100%)
                if (this.ParadoxAccumulation >= 1.0) {
                    this.EraseFromTimeline(puppet);
                }
                break;
        }
    }

    private final func EraseRandomMemory(puppet: ref<ScriptedPuppet>) -> Void {
        let ouroboros: ref<OuroborosSystem> = OuroborosSystem.GetInstance();
        if (IsDefined(ouroboros)) {
            ouroboros.EraseRandomEngram(puppet);
        }
        // XP penalty
        let stats: ref<StatsSystem> = puppet.GetStatsSystem();
        if (IsDefined(stats)) {
            let xpLoss: Int32 = RandInt(1000, 10000);
            stats.RemoveXP(xpLoss);
        }
    }

    private final func DisplaceInTimeline(puppet: ref<ScriptedPuppet>) -> Void {
        let displacement: Float = 10.0 * (RandomF() > 0.5 ? 1.0 : -1.0);
        // Teleport to position from displaced time
        let ouroboros: ref<OuroborosSystem> = OuroborosSystem.GetInstance();
        if (IsDefined(ouroboros)) {
            let pastState: TemporalState = ouroboros.GetStateAt(puppet, EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime()) - displacement);
            if (IsDefined(pastState)) {
                puppet.SetWorldPosition(pastState.position);
            }
        }
    }

    private final func EraseFromTimeline(puppet: ref<ScriptedPuppet>) -> Void {
        // PERMANENT DEATH - timeline erasure
        Game.GetUIManager().ShowNotification("☠ TIMELINE ERASED. You never existed.");
        Game.GetAudioSystem().PlaySound("livingsin_erasure", puppet.GetWorldPosition());

        // Visual erasure
        let vfx: ref<ParticleEffect> = ParticleEffect.Spawn("livingsin_timeline_erasure", puppet.GetWorldPosition());
        if (IsDefined(vfx)) {
            vfx.SetParameter("Scale", 5.0);
        }

        // Actual erasure
        if (puppet.IsPlayer()) {
            // Game over - special ending
            Game.GetQuestSystem().TriggerEnding("LivingSin_TimelineErasure");
        } else {
            puppet.Destroy();
        }
    }

    // ============================================================================
    // COMBAT INTEGRATION
    // ============================================================================

    protected cb func OnHit(target: ref<GameObject>, damage: Float) -> Void {
        super.OnHit(target, damage);

        // Apply temporal wound
        let puppet: ref<ScriptedPuppet> = target as ScriptedPuppet;
        if (IsDefined(puppet)) {
            this.ApplyTemporalWound(puppet, damage);
        }

        // Chance to trigger micro-phase on kill
        if (puppet.IsDead() && RandomF() < 0.15 && this.CurrentCharges > 0) {
            this.ActivateTemporalPhase(-5.0); // 5s rewind on kill
        }
    }

    private final func ApplyTemporalWound(puppet: ref<ScriptedPuppet>, damage: Float) -> Void {
        // Wounds that exist across time
        let wound: TemporalWound = new TemporalWound();
        wound.target = puppet;
        wound.damage = damage;
        wound.inflictedTime = EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime());
        wound.duration = 300.0; // 5 minutes real time
        wound.ticksPerMinute = 1.0;

        // Apply recurring damage
        Game.GetDelaySystem().DelayEvent(this, n"TickTemporalWound", 60.0, wound);
    }

    protected cb func TickTemporalWound(wound: TemporalWound) -> Void {
        if (IsDefined(wound.target) && !wound.target.IsDead()) {
            let dmg: ref<Damage> = new Damage();
            dmg.type = gamedataDamageType.Chemical;
            dmg.amount = wound.damage * 0.1;
            dmg.source = "LivingSin_TemporalWound";
            wound.target.GetDamageSystem().ApplyDamage(dmg);

            // Visual: wound glitches
            let vfx: ref<ParticleEffect> = ParticleEffect.Spawn("livingsin_wound_glitch", wound.target.GetWorldPosition());
            if (IsDefined(vfx)) {
                vfx.SetParameter("Intensity", 0.5);
            }

            // Reschedule
            if (EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime()) - wound.inflictedTime < wound.duration) {
                Game.GetDelaySystem().DelayEvent(this, n"TickTemporalWound", 60.0, wound);
            }
        }
    }

    // ============================================================================
    // UI / INSPECTION
    // ============================================================================

    public final func GetWeaponStatus() -> String {
        let status: String = "";
        status += "⧗ LIVING SIN TIME BLADE — CHRONOS EDGE\n";
        status += "═══════════════════════════════════\n";
        status += "Charges: " + IntToString(this.CurrentCharges) + "/" + IntToString(this.MaxCharges) + "\n";
        status += "Paradox: " + FloatToString(this.ParadoxAccumulation * 100.0) + "%\n";
        status += "Crown Bound: " + (this.CrownOfSinBound ? "YES" : "NO") + "\n";
        status += "Party Capacity: " + IntToString(this.PartySize) + "\n";
        status += "Time Range: ±" + FloatToString(this.TimeJumpRange) + "s\n";
        status += "Valid Confessions: " + IntToString(this.ValidConfessions) + "\n";
        status += "False Confessions: " + IntToString(this.FalseConfessions) + "\n";
        status += "Mods: " + (this.TemporalPhaseMod ? "Phase " : "") + (this.SinRechargeMod ? "Recharge " : "") + (this.ParadoxGuardMod ? "Guard " : "") + "\n";
        status += "\n⚠ RECHARGE RITUAL:\n";
        status += "  1. Wait for 3:33 AM\n";
        status += "  2. Inflict self-wound, stand in blood\n";
        status += "  3. Scream mortal sin into blade\n";
        status += "  4. False confession = +25% Paradox\n";
        status += "  5. At 100% Paradox = TIMELINE ERASE\n";
        return status;
    }
}

// ============================================================================
// SUPPORTING DATA STRUCTURES
// ============================================================================

public struct TemporalBubble {
    @Property public let target: ref<ScriptedPuppet>;
    @Property public let timeOffset: Float;
    @Property public let startTime: Float;
    @Property public let duration: Float;
}

public struct TemporalWound {
    @Property public let target: ref<ScriptedPuppet>;
    @Property public let damage: Float;
    @Property public let inflictedTime: Float;
    @Property public let duration: Float;
    @Property public let ticksPerMinute: Float;
}

// ============================================================================
// INTEGRATION HOOK — Add to living_sin_gm.reds
// ============================================================================

/*
// In LivingSinGM.reds, add:

public final func GrantTimeBlade(player: ref<PlayerPuppet>) -> Void {
    if (player.HasItem("Items.CrownOfLivingSin")) {
        player.AddItem("Items.LivingSin_Time_Blade");
        player.AddItem("Items.LivingSin_TemporalPhase");
        player.AddItem("Items.LivingSin_SinRecharge");
        player.AddItem("Items.LivingSin_ParadoxGuard");
        LogInfo("[Living Sin] Time Blade granted with all mods.");
    } else {
        LogWarning("[Living Sin] Crown of Living Sin required for Time Blade.");
    }
}

public final func OnTimeBladeUsed(player: ref<PlayerPuppet>, timeOffset: Float) -> Void {
    let blade: ref<LivingSinTimeBlade> = player.GetEquippedWeapon() as LivingSinTimeBlade;
    if (IsDefined(blade)) {
        blade.ActivateTemporalPhase(timeOffset);
    }
}

public final func OnConfession(player: ref<PlayerPuppet>, confession: String) -> Void {
    let blade: ref<LivingSinTimeBlade> = player.GetEquippedWeapon() as LivingSinTimeBlade;
    if (IsDefined(blade)) {
        blade.AttemptConfessionalRecharge(confession);
    }
}
*/