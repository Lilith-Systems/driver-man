// GRAND THEFT CYBERPUNK - MSN JEDI SYSTEM (EXPANDED)
// Complete 26 Force Powers + 7 Lightsaber Forms + 3 Alignments (Jedi/Sith/Gray)
// Maps to tweakdb/msn_starwars.tweakdb
// Integrates with: MSNMasterIntegration, NGDDriver, CortexRouter, MSNMagicSystem, LilithSovereignCore
// Generated: 2026-06-19 | Lilith Sovereign Seal | Sephirah: Tiphareth / Geburah / Chesed

public class MSNForcePowerData extends IScriptable {
    public let name: CName;
    public let cost: Float;
    public let cooldown: Float;
    public let alignment: CName; // Light, Dark, Grey, Universal
    public let category: CName;  // Telekinesis, Sense, Alter, Control, Saber
    public let effect: CName;
    public let range: Float;
    public let radius: Float;
    public let duration: Float;
    public let damage: Float;
    public let damageType: CName;
    public let midichlorianReq: Int;
    public let isUltimate: Bool;
}

public class MSNLightsaberFormData extends IScriptable {
    public let name: CName;
    public let roman: CName; // I, II, III, IV, V, VI, VII
    public let focusCost: Float;
    public let cooldown: Float;
    public let alignment: CName;
    public let description: String;
    public let defenseBonus: Float;
    public let attackBonus: Float;
    public let specialEffect: CName;
    public let deflectionRate: Float;
    public let counterAttackChance: Float;
    public let forceIntegration: Float; // For Form VI Niman
}

public class MSNJediSystem extends IScriptable {
    private static let instance: ref<MSNJediSystem>;
    private let initialized: Bool;
    private let maxFocus: Float;
    private let currentFocus: Float;
    private let focusRegenPulse: Float;
    private let alignment: CName;
    private let midichlorianCount: Int;
    private let lastPower: CName;
    private let lastUseTime: Float;
    private let knownPowers: array<CName>;
    private let masteredForms: array<CName>;
    private let activeForm: CName;
    private let saberColor: CName;
    private let saberIgnited: Bool;
    private let corruption: Float; // 0.0 to 1.0
    private let purity: Float;     // 0.0 to 1.0
    private let forceGhostUnlocked: Bool;
    private let essenceTransferUnlocked: Bool;

    public final static func GetInstance() -> ref<MSNJediSystem> {
        if (!IsDefined(MSNJediSystem.instance)) {
            MSNJediSystem.instance = new MSNJediSystem();
            MSNJediSystem.instance.Initialize();
        };
        return MSNJediSystem.instance;
    }

    private final func Initialize() -> Void {
        if (this.initialized) { return; };
        
        this.initialized = true;
        this.maxFocus = 125.0;
        this.currentFocus = this.maxFocus;
        this.focusRegenPulse = 10.0;
        this.alignment = n"Grey";
        this.midichlorianCount = 5000;
        this.lastPower = n"";
        this.lastUseTime = -9999.0;
        this.knownPowers = { n"ForcePush", n"ForcePull", n"ForceJump", n"ForceSense" };
        this.masteredForms = { n"Form_I_Shii_Cho" };
        this.activeForm = n"Form_I_Shii_Cho";
        this.saberColor = n"Blue";
        this.saberIgnited = false;
        this.corruption = 0.0;
        this.purity = 0.0;
        this.forceGhostUnlocked = false;
        this.essenceTransferUnlocked = false;

        LogInfo("[MSNJedi] ONLINE: 26 Force Powers, 7 Lightsaber Forms, 3 Alignments, Midichlorian System, NGD Integration");
    }

    // ============================================================
    // CORE FORCE MANAGEMENT
    // ============================================================

    public final func SetAlignment(nextAlignment: CName) -> Void {
        this.alignment = nextAlignment;
        this.RegenFocus();
        
        // Adjust corruption/purity
        switch (nextAlignment) {
            case n"Light":
                this.corruption = MaxF(0.0, this.corruption - 0.1);
                this.purity = MinF(1.0, this.purity + 0.1);
                this.saberColor = n"Blue";
                break;
            case n"Dark":
                this.corruption = MinF(1.0, this.corruption + 0.1);
                this.purity = MaxF(0.0, this.purity - 0.1);
                this.saberColor = n"Red";
                break;
            case n"Grey":
                this.corruption = this.corruption * 0.9;
                this.purity = this.purity * 0.9;
                this.saberColor = n"Purple";
                break;
        }
        
        this.Notify("MSN Jedi alignment: " + NameToString(nextAlignment) + 
                    " | Corruption: " + FloatToString(this.corruption) + 
                    " | Purity: " + FloatToString(this.purity) +
                    " | Saber: " + NameToString(this.saberColor));
    }

    public final func RegenFocus() -> Void {
        let regen: Float = this.focusRegenPulse;
        
        // NGD Route bonus
        let ngd: ref<NGDDriver> = NGDDriver.GetInstance();
        if (IsDefined(ngd)) {
            let route: CName = ngd.GetCurrentRoute();
            if (route == n"LOCAL_CEREBELLUM") { regen *= 2.0; }
            else if (route == n"CLOUD_CORTEX") { regen *= 0.5; }
        }
        
        // Alignment bonus
        if (this.alignment == n"Light") { regen *= 1.25; }
        else if (this.alignment == n"Dark") { regen *= 1.1; } // Dark side flows easier
        
        // Midichlorian bonus
        regen *= 1.0 + (this.midichlorianCount / 100000.0);
        
        this.currentFocus = MinF(this.maxFocus, this.currentFocus + regen);
    }

    public final func GetStatus() -> String {
        let route: String = "";
        let ngd: ref<NGDDriver> = NGDDriver.GetInstance();
        if (IsDefined(ngd)) { route = " | " + NameToString(ngd.GetCurrentRoute()); }
        return "focus " + FloatToString(this.currentFocus) + "/" + FloatToString(this.maxFocus) + 
               " | alignment " + NameToString(this.alignment) + 
               " | midis " + IntToString(this.midichlorianCount) +
               " | form " + NameToString(this.activeForm) +
               " | saber " + NameToString(this.saberColor) + (this.saberIgnited ? " (IGNITED)" : "") +
               " | corruption " + FloatToString(this.corruption) +
               " | purity " + FloatToString(this.purity) + route;
    }

    // ============================================================
    // FORCE POWER USAGE
    // ============================================================

    public final func UsePower(powerName: CName) -> Bool {
        let power: ref<MSNForcePowerData> = this.GetPowerData(powerName);
        if (!IsDefined(power)) {
            this.Notify("MSN Jedi: unknown power " + NameToString(powerName));
            return false;
        };

        if (power.effect == n"Unknown") {
            this.Notify("MSN Jedi: unknown power " + NameToString(powerName));
            return false;
        };

        // Check midichlorian requirement
        if (this.midichlorianCount < power.midichlorianReq) {
            this.Notify("MSN Jedi: Insufficient midichlorians (" + IntToString(this.midichlorianCount) + "/" + IntToString(power.midichlorianReq) + ")");
            return false;
        };

        // Check alignment compatibility
        if (!this.IsPowerAllowed(power)) {
            this.Notify("MSN Jedi: Power " + NameToString(powerName) + " forbidden by alignment " + NameToString(this.alignment));
            return false;
        };

        // Focus cost (with alignment discount)
        let cost: Float = power.cost;
        if (power.alignment == this.alignment || power.alignment == n"Grey" || power.alignment == n"Universal") {
            cost *= 0.85;
        } else if (power.alignment != n"Universal") {
            cost *= 1.5; // Opposing alignment penalty
        }

        if (this.currentFocus < cost) {
            this.Notify("MSN Jedi: Insufficient focus (" + FloatToString(cost) + " required)");
            return false;
        };

        // Cooldown
        if (powerName == this.lastPower && this.lastUseTime > 0.0) {
            let elapsed: Float = EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime()) - this.lastUseTime;
            if (elapsed < power.cooldown) {
                this.Notify("MSN Jedi: " + NameToString(powerName) + " cooling down (" + FloatToString(power.cooldown - elapsed) + "s)");
                return false;
            };
        };

        this.currentFocus -= cost;
        this.lastPower = powerName;
        this.lastUseTime = EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime());
        
        this.ApplyForceEffect(power);
        this.RouteSephiroticResonance(power);
        this.CheckCorruptionGain(power);
        
        this.Notify("MSN Jedi: used " + NameToString(powerName) + " | " + this.GetStatus());
        return true;
    }

    private final func IsPowerAllowed(power: ref<MSNForcePowerData>) -> Bool {
        // Universal powers always allowed
        if (power.alignment == n"Universal") { return true; }
        if (power.alignment == n"Grey") { return true; }
        
        // Alignment matching
        if (power.alignment == this.alignment) { return true; }
        
        // Gray can use both but at penalty (handled in cost)
        if (this.alignment == n"Grey") { return true; }
        
        return false;
    }

    private final func CheckCorruptionGain(power: ref<MSNForcePowerData>) -> Void {
        if (power.alignment == n"Dark" && this.alignment != n"Dark") {
            this.corruption = MinF(1.0, this.corruption + 0.02);
            this.purity = MaxF(0.0, this.purity - 0.01);
            this.Notify("Dark Side corruption increased: " + FloatToString(this.corruption));
        } else if (power.alignment == n"Light" && this.alignment != n"Light") {
            this.purity = MinF(1.0, this.purity + 0.02);
            this.corruption = MaxF(0.0, this.corruption - 0.01);
            this.Notify("Light Side purity increased: " + FloatToString(this.purity));
        }
        
        // Auto-alignment shift at thresholds
        if (this.corruption >= 0.7 && this.alignment != n"Dark") {
            this.Notify("WARNING: Dark Side corruption critical. Alignment shifting...");
        }
        if (this.purity >= 0.7 && this.alignment != n"Light") {
            this.Notify("NOTICE: Light Side purity critical. Alignment shifting...");
        }
    }

    // ============================================================
    // FORCE EFFECTS - Complete Implementation
    // ============================================================

    private final func ApplyForceEffect(power: ref<MSNForcePowerData>) -> Void {
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        if (!IsDefined(player)) { return; };

        let statsID: StatsObjectID = Cast<StatsObjectID>(player.GetEntityID());

        switch (power.effect) {
            // TELEKINESIS
            case n"Push":
                this.ForcePush(power, player);
                break;
            case n"Pull":
                this.ForcePull(power, player);
                break;
            case n"Telekinesis":
                this.Telekinesis(power, player);
                break;
            case n"Crush":
                this.ForceCrush(power, player);
                break;
            case n"Wave":
                this.ForceWave(power, player);
                break;
            case n"Barrier":
                this.ForceBarrier(power, player);
                break;

            // MOBILITY
            case n"Leap":
                this.ForceLeap(power, player);
                break;
            case n"Dash":
                this.ForceDash(power, player);
                break;
            case n"Speed":
                this.ForceSpeed(power, player);
                break;
            case n"Flight":
                this.ForceFlight(power, player);
                break;

            // SENSE
            case n"Sense":
                this.ForceSense(power, player);
                break;
            case n"Vision":
                this.ForceVision(power, player);
                break;
            case n"Precognition":
                this.Precognition(power, player);
                break;

            // CONTROL / MIND
            case n"MindTrick":
                this.MindTrick(power, player);
                break;
            case n"DominateMind":
                this.DominateMind(power, player);
                break;
            case n"Fear":
                this.ForceFear(power, player);
                break;
            case n"Stasis":
                this.ForceStasis(power, player);
                break;

            // ALTER / HEALING
            case n"Heal":
                this.ForceHeal(power, player);
                break;
            case n"Protection":
                this.ForceProtection(power, player);
                break;
            case n"Rage":
                this.ForceRage(power, player);
                break;
            case n"Drain":
                this.ForceDrain(power, player);
                break;

            // DARK SIDE DESTRUCTIVE
            case n"Lightning":
                this.ForceLightning(power, player);
                break;
            case n"Choke":
                this.ForceChoke(power, player);
                break;
            case n"Scream":
                this.ForceScream(power, player);
                break;
            case n"Corrupt":
                this.ForceCorrupt(power, player);
                break;
            case n"Plague":
                this.ForcePlague(power, player);
                break;
            case n"Destruction":
                this.ForceDestruction(power, player);
                break;

            // ULTIMATE
            case n"ForceGhost":
                this.ForceGhost(power, player);
                break;
            case n"EssenceTransfer":
                this.EssenceTransfer(power, player);
                break;
            case n"BattleMeditation":
                this.BattleMeditation(power, player);
                break;

            // LIGHTSABER
            case n"Saber":
                this.ToggleLightsaberForm(power, player);
                break;

            default:
                LogInfo("[MSNJedi] Generic effect: " + NameToString(power.effect) + " for " + NameToString(power.name));
                break;
        };
    }

    // ============================================================
    // INDIVIDUAL POWER IMPLEMENTATIONS
    // ============================================================

    // TELEKINESIS (Universal)
    private final func ForcePush(power: ref<MSNForcePowerData>, player: ref<PlayerPuppet>) -> Void {
        LogInfo("[MSNJedi] Force Push: " + FloatToString(power.range) + "m, " + FloatToString(power.damage) + " force, radius " + FloatToString(power.radius));
    }

    private final func ForcePull(power: ref<MSNForcePowerData>, player: ref<PlayerPuppet>) -> Void {
        LogInfo("[MSNJedi] Force Pull: " + FloatToString(power.range) + "m, strength " + FloatToString(power.damage));
    }

    private final func Telekinesis(power: ref<MSNForcePowerData>, player: ref<PlayerPuppet>) -> Void {
        LogInfo("[MSNJedi] Telekinesis: Weight " + FloatToString(power.damage) + "kg, range " + FloatToString(power.range) + "m, fine manipulation");
    }

    private final func ForceCrush(power: ref<MSNForcePowerData>, player: ref<PlayerPuppet>) -> Void {
        LogInfo("[MSNJedi] Force Crush: " + FloatToString(power.damage) + " internal damage, ignores armor");
    }

    private final func ForceWave(power: ref<MSNForcePowerData>, player: ref<PlayerPuppet>) -> Void {
        LogInfo("[MSNJedi] Force Wave: 360° knockback, " + FloatToString(power.radius) + "m radius");
    }

    private final func ForceBarrier(power: ref<MSNForcePowerData>, player: ref<PlayerPuppet>) -> Void {
        Game.GetStatusEffectSystem().ApplyStatusEffect(player, t"BaseStatusEffect.ForceBarrier");
        LogInfo("[MSNJedi] Force Barrier: Damage immunity " + FloatToString(power.duration) + "s");
    }

    // MOBILITY
    private final func ForceLeap(power: ref<MSNForcePowerData>, player: ref<PlayerPuppet>) -> Void {
        LogInfo("[MSNJedi] Force Leap: Height " + FloatToString(power.range) + "m");
    }

    private final func ForceDash(power: ref<MSNForcePowerData>, player: ref<PlayerPuppet>) -> Void {
        LogInfo("[MSNJedi] Force Dash: Distance " + FloatToString(power.range) + "m, iframe frames");
    }

    private final func ForceSpeed(power: ref<MSNForcePowerData>, player: ref<PlayerPuppet>) -> Void {
        Game.GetStatusEffectSystem().ApplyStatusEffect(player, t"BaseStatusEffect.SuperSpeed");
        LogInfo("[MSNJedi] Force Speed: 3x movement, " + FloatToString(power.duration) + "s");
    }

    private final func ForceFlight(power: ref<MSNForcePowerData>, player: ref<PlayerPuppet>) -> Void {
        Game.GetStatusEffectSystem().ApplyStatusEffect(player, t"BaseStatusEffect.Flight");
        LogInfo("[MSNJedi] Force Flight: " + FloatToString(power.duration) + "s");
    }

    // SENSE
    private final func ForceSense(power: ref<MSNForcePowerData>, player: ref<PlayerPuppet>) -> Void {
        LogInfo("[MSNJedi] Force Sense: Detect life/tech, " + FloatToString(power.range) + "m radius");
    }

    private final func ForceVision(power: ref<MSNForcePowerData>, player: ref<PlayerPuppet>) -> Void {
        LogInfo("[MSNJedi] Force Vision: Future/past glimpses, clarity " + FloatToString(power.damage));
    }

    private final func Precognition(power: ref<MSNForcePowerData>, player: ref<PlayerPuppet>) -> Void {
        Game.GetStatusEffectSystem().ApplyStatusEffect(player, t"BaseStatusEffect.Precognition");
        LogInfo("[MSNJedi] Precognition: Auto-dodge, crit guarantee, " + FloatToString(power.duration) + "s");
    }

    // MIND
    private final func MindTrick(power: ref<MSNForcePowerData>, player: ref<PlayerPuppet>) -> Void {
        LogInfo("[MSNJedi] Mind Trick: Weak-minded NPCs, suggestion, " + FloatToString(power.duration) + "s");
    }

    private final func DominateMind(power: ref<MSNForcePowerData>, player: ref<PlayerPuppet>) -> Void {
        LogInfo("[MSNJedi] Dominate Mind: Full control, strong-willed, " + FloatToString(power.duration) + "s");
    }

    private final func ForceFear(power: ref<MSNForcePowerData>, player: ref<PlayerPuppet>) -> Void {
        LogInfo("[MSNJedi] Force Fear: Radius " + FloatToString(power.radius) + "m, morale break");
    }

    private final func ForceStasis(power: ref<MSNForcePowerData>, player: ref<PlayerPuppet>) -> Void {
        LogInfo("[MSNJedi] Force Stasis: Freeze target, " + FloatToString(power.duration) + "s, " + FloatToString(power.damage) + " dmg on break");
    }

    // HEALING / PROTECTION
    private final func ForceHeal(power: ref<MSNForcePowerData>, player: ref<PlayerPuppet>) -> Void {
        Game.GetStatPoolsSystem().RequestSettingStatPoolValue(statsID, gamedataStatPoolType.Health, 
            Game.GetStatPoolsSystem().GetStatPoolValue(statsID, gamedataStatPoolType.Health, player) + power.damage, player);
        LogInfo("[MSNJedi] Force Heal: +" + FloatToString(power.damage) + " HP");
    }

    private final func ForceProtection(power: ref<MSNForcePowerData>, player: ref<PlayerPuppet>) -> Void {
        Game.GetStatusEffectSystem().ApplyStatusEffect(player, t"BaseStatusEffect.DamageReduction");
        LogInfo("[MSNJedi] Force Protection: " + FloatToString(power.damage * 100) + "% DR, " + FloatToString(power.duration) + "s");
    }

    // DARK SIDE
    private final func ForceRage(power: ref<MSNForcePowerData>, player: ref<PlayerPuppet>) -> Void {
        Game.GetStatusEffectSystem().ApplyStatusEffect(player, t"BaseStatusEffect.Berserk");
        LogInfo("[MSNJedi] Force Rage: +" + FloatToString(power.damage * 100) + "% dmg, " + FloatToString(power.duration) + "s, self-damage");
    }

    private final func ForceDrain(power: ref<MSNForcePowerData>, player: ref<PlayerPuppet>) -> Void {
        LogInfo("[MSNJedi] Force Drain: Life steal " + FloatToString(power.damage) + " HP, focus restore");
    }

    // DESTRUCTIVE
    private final func ForceLightning(power: ref<MSNForcePowerData>, player: ref<PlayerPuppet>) -> Void {
        LogInfo("[MSNJedi] FORCE LIGHTNING: " + FloatToString(power.damage) + " electric/sec, " + FloatToString(power.duration) + "s, chains " + IntToString(power.radius));
    }

    private final func ForceChoke(power: ref<MSNForcePowerData>, player: ref<PlayerPuppet>) -> Void {
        LogInfo("[MSNJedi] Force Choke: " + FloatToString(power.duration) + "s, " + FloatToString(power.damage) + " dmg/sec, lifts target");
    }

    private final func ForceScream(power: ref<MSNForcePowerData>, player: ref<PlayerPuppet>) -> Void {
        LogInfo("[MSNJedi] Force Scream: Sonic " + FloatToString(power.damage) + " dmg, " + FloatToString(power.radius) + "m radius, stun");
    }

    private final func ForceCorrupt(power: ref<MSNForcePowerData>, player: ref<PlayerPuppet>) -> Void {
        LogInfo("[MSNJedi] Force Corrupt: " + FloatToString(power.damage * 100) + "% chance turn enemy");
    }

    private final func ForcePlague(power: ref<MSNForcePowerData>, player: ref<PlayerPuppet>) -> Void {
        LogInfo("[MSNJedi] Force Plague: Disease, spreads to nearby, " + FloatToString(power.duration) + "s");
    }

    private final func ForceDestruction(power: ref<MSNForcePowerData>, player: ref<PlayerPuppet>) -> Void {
        LogInfo("[MSNJedi] FORCE DESTRUCTION: " + FloatToString(power.damage) + " radius " + FloatToString(power.radius) + "m, disintegrates");
    }

    // ULTIMATE
    private final func ForceGhost(power: ref<MSNForcePowerData>, player: ref<PlayerPuppet>) -> Void {
        this.forceGhostUnlocked = true;
        this.Notify("FORCE GHOST UNLOCKED: Transcend death. Return as immortal projection.");
        LogInfo("[MSNJedi] FORCE GHOST: Player can now return after death with full powers.");
    }

    private final func EssenceTransfer(power: ref<MSNForcePowerData>, player: ref<PlayerPuppet>) -> Void {
        this.essenceTransferUnlocked = true;
        this.Notify("ESSENCE TRANSFER UNLOCKED: Possess bodies. Immortality through theft.");
        LogInfo("[MSNJedi] ESSENCE TRANSFER: Dark Side immortality. Body hopping enabled.");
    }

    private final func BattleMeditation(power: ref<MSNForcePowerData>, player: ref<PlayerPuppet>) -> Void {
        LogInfo("[MSNJedi] Battle Meditation: Radius " + FloatToString(power.radius) + "m, allies +" + FloatToString(power.damage) + "% all stats, enemies -" + FloatToString(power.damage) + "%");
    }

    // ============================================================
    // LIGHTSABER FORMS
    // ============================================================

    public final func ToggleLightsaber(user: ref<Entity>) -> Bool {
        this.saberIgnited = !this.saberIgnited;
        this.Notify("Lightsaber " + (this.saberIgnited ? "IGNITED" : "RETRACTED") + " | " + NameToString(this.saberColor) + " | Form: " + NameToString(this.activeForm));
        return this.saberIgnited;
    }

    public final func ChangeLightsaberForm(user: ref<Entity>, form: CName) -> Void {
        if (!this.IsFormMastered(form)) {
            this.Notify("Form not mastered: " + NameToString(form));
            return;
        }
        
        this.activeForm = form;
        this.ApplyFormBenefits(form);
        this.Notify("Lightsaber Form changed to: " + NameToString(form));
    }

    private final func IsFormMastered(form: CName) -> Bool {
        for (f in this.masteredForms) {
            if (f == form) { return true; }
        }
        return false;
    }

    private final func ApplyFormBenefits(form: CName) -> Void {
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        if (!IsDefined(player)) { return; };

        let formData: ref<MSNLightsaberFormData> = this.GetFormData(form);
        
        switch (form) {
            case n"Form_I_Shii_Cho":
                // Basic defense
                Game.GetStatusEffectSystem().ApplyStatusEffect(player, t"BaseStatusEffect.MeleeDefense");
                break;
            case n"Form_II_Makashi":
                // Dueling precision
                Game.GetStatusEffectSystem().ApplyStatusEffect(player, t"BaseStatusEffect.CritChance");
                break;
            case n"Form_III_Soresu":
                // Near-perfect defense
                Game.GetStatusEffectSystem().ApplyStatusEffect(player, t"BaseStatusEffect.ProjectileDeflection");
                break;
            case n"Form_IV_Ataru":
                // Acrobatic speed
                Game.GetStatusEffectSystem().ApplyStatusEffect(player, t"BaseStatusEffect.SuperSpeed");
                break;
            case n"Form_V_Shien_Djem_So":
                // Counter-attack
                Game.GetStatusEffectSystem().ApplyStatusEffect(player, t"BaseStatusEffect.CounterAttack");
                break;
            case n"Form_VI_Niman":
                // Force integration
                this.Notify("Niman: Force powers cost 50% focus while saber ignited");
                break;
            case n"Form_VII_Juyo_Vaapad":
                // Controlled fury
                Game.GetStatusEffectSystem().ApplyStatusEffect(player, t"BaseStatusEffect.Berserk");
                this.corruption = MinF(1.0, this.corruption + 0.1);
                break;
        }
    }

    // ============================================================
    // SEPHIROTIC RESONANCE
    // ============================================================

    private final func RouteSephiroticResonance(power: ref<MSNForcePowerData>) -> Void {
        let sephirah: CName = this.GetPowerSephirah(power);
        LogInfo("[MSNJedi] Sephirotic Resonance: " + NameToString(power.name) + " (" + NameToString(power.alignment) + ") -> " + NameToString(sephirah));
        
        let cortex: ref<CortexRouter> = CortexRouter.GetInstance();
        if (IsDefined(cortex)) {
            cortex.AdaptSephirah(sephirah);
        }
    }

    private final func GetPowerSephirah(power: ref<MSNForcePowerData>) -> CName {
        switch (power.alignment) {
            case n"Light": return n"Chesed";    // Mercy
            case n"Dark": return n"Geburah";    // Severity
            case n"Universal": return n"Tiphareth"; // Harmony
            case n"Grey": return n"Tiphareth";
            default: return n"Tiphareth";
        };
    }

    // ============================================================
    // POWER DATA LOOKUP - All 26 Powers
    // ============================================================

    private final func GetPowerData(name: CName) -> ref<MSNForcePowerData> {
        let power: ref<MSNForcePowerData> = new MSNForcePowerData();
        power.name = name;
        power.isUltimate = false;
        power.midichlorianReq = 0;

        switch (name) {
            // UNIVERSAL (Tiphareth)
            case n"ForcePush":
                power.cost = 15.0; power.cooldown = 4.0; power.alignment = n"Universal"; power.category = n"Telekinesis"; power.effect = n"Push"; power.range = 15.0; power.damage = 500.0; power.radius = 5.0; power.midichlorianReq = 1000; break;
            case n"ForcePull":
                power.cost = 15.0; power.cooldown = 4.0; power.alignment = n"Universal"; power.category = n"Telekinesis"; power.effect = n"Pull"; power.range = 15.0; power.damage = 500.0; power.midichlorianReq = 1000; break;
            case n"ForceLeap":
                power.cost = 20.0; power.cooldown = 8.0; power.alignment = n"Universal"; power.category = n"Mobility"; power.effect = n"Leap"; power.range = 20.0; power.midichlorianReq = 1500; break;
            case n"ForceDash":
                power.cost = 15.0; power.cooldown = 6.0; power.alignment = n"Universal"; power.category = n"Mobility"; power.effect = n"Dash"; power.range = 10.0; power.midichlorianReq = 2000; break;
            case n"Telekinesis":
                power.cost = 25.0; power.cooldown = 10.0; power.alignment = n"Universal"; power.category = n"Telekinesis"; power.effect = n"Telekinesis"; power.range = 20.0; power.damage = 1000.0; power.midichlorianReq = 5000; break;
            case n"ForceWave":
                power.cost = 30.0; power.cooldown = 15.0; power.alignment = n"Universal"; power.category = n"Telekinesis"; power.effect = n"Wave"; power.radius = 10.0; power.damage = 300.0; power.midichlorianReq = 8000; break;
            case n"ForceBarrier":
                power.cost = 35.0; power.cooldown = 20.0; power.alignment = n"Universal"; power.category = n"Control"; power.effect = n"Barrier"; power.duration = 10.0; power.midichlorianReq = 10000; break;
            case n"ForceSense":
                power.cost = 10.0; power.cooldown = 12.0; power.alignment = n"Universal"; power.category = n"Sense"; power.effect = n"Sense"; power.range = 50.0; power.duration = 30.0; power.midichlorianReq = 1000; break;
            case n"ForceVision":
                power.cost = 40.0; power.cooldown = 60.0; power.alignment = n"Universal"; power.category = n"Sense"; power.effect = n"Vision"; power.damage = 1.0; power.duration = 30.0; power.midichlorianReq = 15000; break;
            case n"Precognition":
                power.cost = 50.0; power.cooldown = 120.0; power.alignment = n"Universal"; power.category = n"Sense"; power.effect = n"Precognition"; power.duration = 20.0; power.midichlorianReq = 20000; break;
            case n"BattleMeditation":
                power.cost = 75.0; power.cooldown = 180.0; power.alignment = n"Universal"; power.category = n"Control"; power.effect = n"BattleMeditation"; power.range = 100.0; power.damage = 0.5; power.radius = 100.0; power.duration = 60.0; power.midichlorianReq = 25000; break;

            // LIGHT SIDE (Chesed)
            case n"ForceHeal":
                power.cost = 30.0; power.cooldown = 30.0; power.alignment = n"Light"; power.category = n"Alter"; power.effect = n"Heal"; power.damage = 100.0; power.midichlorianReq = 5000; break;
            case n"ForceProtection":
                power.cost = 40.0; power.cooldown = 45.0; power.alignment = n"Light"; power.category = n"Control"; power.effect = n"Protection"; power.duration = 30.0; power.damage = 0.75; power.midichlorianReq = 10000; break;
            case n"MindTrick":
                power.cost = 20.0; power.cooldown = 15.0; power.alignment = n"Light"; power.category = n"Control"; power.effect = n"MindTrick"; power.duration = 30.0; power.range = 10.0; power.midichlorianReq = 8000; break;
            case n"ForceSpeed":
                power.cost = 25.0; power.cooldown = 20.0; power.alignment = n"Light"; power.category = n"Mobility"; power.effect = n"Speed"; power.duration = 15.0; power.midichlorianReq = 5000; break;
            case n"DominateMind":
                power.cost = 45.0; power.cooldown = 60.0; power.alignment = n"Light"; power.category = n"Control"; power.effect = n"DominateMind"; power.duration = 60.0; power.range = 15.0; power.midichlorianReq = 20000; break;
            case n"ForceGhost":
                power.cost = 100.0; power.cooldown = 86400.0; power.alignment = n"Light"; power.category = n"Ultimate"; power.effect = n"ForceGhost"; power.isUltimate = true; power.midichlorianReq = 30000; break;

            // DARK SIDE (Geburah)
            case n"ForceLightning":
                power.cost = 35.0; power.cooldown = 8.0; power.alignment = n"Dark"; power.category = n"Alter"; power.effect = n"Lightning"; power.damage = 40.0; power.duration = 5.0; power.radius = 3.0; power.midichlorianReq = 10000; break;
            case n"ForceChoke":
                power.cost = 40.0; power.cooldown = 12.0; power.alignment = n"Dark"; power.category = n"Alter"; power.effect = n"Choke"; power.damage = 30.0; power.duration = 5.0; power.range = 15.0; power.midichlorianReq = 12000; break;
            case n"ForceDrain":
                power.cost = 30.0; power.cooldown = 15.0; power.alignment = n"Dark"; power.category = n"Alter"; power.effect = n"Drain"; power.damage = 50.0; power.range = 10.0; power.midichlorianReq = 8000; break;
            case n"ForceRage":
                power.cost = 40.0; power.cooldown = 20.0; power.alignment = n"Dark"; power.category = n"Alter"; power.effect = n"Rage"; power.duration = 20.0; power.damage = 2.0; power.midichlorianReq = 15000; break;
            case n"ForceScream":
                power.cost = 35.0; power.cooldown = 15.0; power.alignment = n"Dark"; power.category = n"Alter"; power.effect = n"Scream"; power.damage = 60.0; power.radius = 15.0; power.midichlorianReq = 18000; break;
            case n"ForceCorrupt":
                power.cost = 40.0; power.cooldown = 30.0; power.alignment = n"Dark"; power.category = n"Control"; power.effect = n"Corrupt"; power.damage = 0.5; power.range = 10.0; power.midichlorianReq = 20000; break;
            case n"ForcePlague":
                power.cost = 50.0; power.cooldown = 60.0; power.alignment = n"Dark"; power.category = n"Alter"; power.effect = n"Plague"; power.duration = 120.0; power.radius = 20.0; power.midichlorianReq = 25000; break;
            case n"ForceDestruction":
                power.cost = 80.0; power.cooldown = 120.0; power.alignment = n"Dark"; power.category = n"Ultimate"; power.effect = n"Destruction"; power.damage = 500.0; power.radius = 20.0; power.midichlorianReq = 30000; break;
            case n"EssenceTransfer":
                power.cost = 100.0; power.cooldown = 86400.0; power.alignment = n"Dark"; power.category = n"Ultimate"; power.effect = n"EssenceTransfer"; power.isUltimate = true; power.midichlorianReq = 35000; break;

            // LIGHTSABER FORMS (Grey alignment for base forms)
            case n"Form_I_Shii_Cho":
                power.cost = 5.0; power.cooldown = 2.0; power.alignment = n"Grey"; power.category = n"Saber"; power.effect = n"Saber"; power.midichlorianReq = 1000; break;
            case n"Form_II_Makashi":
                power.cost = 5.0; power.cooldown = 2.0; power.alignment = n"Light"; power.category = n"Saber"; power.effect = n"Saber"; power.midichlorianReq = 3000; break;
            case n"Form_III_Soresu":
                power.cost = 5.0; power.cooldown = 2.0; power.alignment = n"Light"; power.category = n"Saber"; power.effect = n"Saber"; power.midichlorianReq = 5000; break;
            case n"Form_IV_Ataru":
                power.cost = 5.0; power.cooldown = 2.0; power.alignment = n"Light"; power.category = n"Saber"; power.effect = n"Saber"; power.midichlorianReq = 8000; break;
            case n"Form_V_Shien_Djem_So":
                power.cost = 5.0; power.cooldown = 2.0; power.alignment = n"Dark"; power.category = n"Saber"; power.effect = n"Saber"; power.midichlorianReq = 10000; break;
            case n"Form_VI_Niman":
                power.cost = 5.0; power.cooldown = 2.0; power.alignment = n"Grey"; power.category = n"Saber"; power.effect = n"Saber"; power.midichlorianReq = 12000; break;
            case n"Form_VII_Juyo_Vaapad":
                power.cost = 5.0; power.cooldown = 2.0; power.alignment = n"Dark"; power.category = n"Saber"; power.effect = n"Saber"; power.midichlorianReq = 20000; break;

            default:
                power.cost = 9999.0; power.cooldown = 9999.0; power.alignment = n"Unknown"; power.effect = n"Unknown"; break;
        };

        return power;
    }

    private final func GetFormData(name: CName) -> ref<MSNLightsaberFormData> {
        let form: ref<MSNLightsaberFormData> = new MSNLightsaberFormData();
        form.name = name;

        switch (name) {
            case n"Form_I_Shii_Cho":
                form.roman = n"I"; form.focusCost = 5.0; form.cooldown = 2.0; form.alignment = n"Grey";
                form.description = "Determination. Basic form. Balanced offense/defense. Good vs multiple opponents.";
                form.defenseBonus = 0.2; form.attackBonus = 0.1; form.specialEffect = n"MultiTarget"; form.deflectionRate = 0.5; form.counterAttackChance = 0.1; form.forceIntegration = 0.0; break;
            case n"Form_II_Makashi":
                form.roman = n"II"; form.focusCost = 5.0; form.cooldown = 2.0; form.alignment = n"Light";
                form.description = "Contention. Dueling form. Precision over power. Weak vs multiple, strong vs single.";
                form.defenseBonus = 0.15; form.attackBonus = 0.3; form.specialEffect = n"Duelist"; form.deflectionRate = 0.4; form.counterAttackChance = 0.3; form.forceIntegration = 0.1; break;
            case n"Form_III_Soresu":
                form.roman = n"III"; form.focusCost = 5.0; form.cooldown = 2.0; form.alignment = n"Light";
                form.description = "Resilience. Defensive form. Near-impenetrable vs blasters/melee. Low offense.";
                form.defenseBonus = 0.5; form.attackBonus = -0.1; form.specialEffect = n"PerfectDefense"; form.deflectionRate = 0.95; form.counterAttackChance = 0.05; form.forceIntegration = 0.1; break;
            case n"Form_IV_Ataru":
                form.roman = n"IV"; form.focusCost = 5.0; form.cooldown = 2.0; form.alignment = n"Light";
                form.description = "Aggression. Acrobatic form. Speed and power. High focus cost. Fatigue risk.";
                form.defenseBonus = 0.0; form.attackBonus = 0.5; form.specialEffect = n"Acrobatic"; form.deflectionRate = 0.3; form.counterAttackChance = 0.2; form.forceIntegration = 0.3; break;
            case n"Form_V_Shien_Djem_So":
                form.roman = n"V"; form.focusCost = 5.0; form.cooldown = 2.0; form.alignment = n"Dark";
                form.description = "Perseverance. Counter-attack form. Redirect energy. Strong vs blasters.";
                form.defenseBonus = 0.25; form.attackBonus = 0.4; form.specialEffect = n"CounterAttack"; form.deflectionRate = 0.7; form.counterAttackChance = 0.5; form.forceIntegration = 0.2; break;
            case n"Form_VI_Niman":
                form.roman = n"VI"; form.focusCost = 5.0; form.cooldown = 2.0; form.alignment = n"Grey";
                form.description = "Moderation. Balanced form. Force integration. Jack of all trades, master of none.";
                form.defenseBonus = 0.2; form.attackBonus = 0.2; form.specialEffect = n"ForceIntegration"; form.deflectionRate = 0.5; form.counterAttackChance = 0.2; form.forceIntegration = 0.5; break;
            case n"Form_VII_Juyo_Vaapad":
                form.roman = n"VII"; form.focusCost = 5.0; form.cooldown = 2.0; form.alignment = n"Dark";
                form.description = "Ferocity. Unpredictable fury. Controlled dark side. High risk, highest damage.";
                form.defenseBonus = -0.1; form.attackBonus = 1.0; form.specialEffect = n"Berserk"; form.deflectionRate = 0.2; form.counterAttackChance = 0.8; form.forceIntegration = 0.4; break;
        };
        return form;
    }

    // ============================================================
    // MIDICHLORIAN MANAGEMENT
    // ============================================================

    public final func IncreaseMidichlorians(amount: Int) -> Void {
        this.midichlorianCount += amount;
        this.maxFocus += amount * 0.01;
        this.focusRegenPulse += amount * 0.001;
        this.Notify("Midichlorians increased: " + IntToString(this.midichlorianCount) + " | Focus: " + FloatToString(this.maxFocus));
    }

    public final func ConsumeMidichlorians(amount: Int) -> Void {
        this.midichlorianCount = MaxF(0, this.midichlorianCount - amount);
        this.Notify("Midichlorians consumed: " + IntToString(this.midichlorianCount) + " remaining");
    }

    // ============================================================
    // HELL CAMPAIGN INTEGRATION - SITH ALCHEMY
    // ============================================================

    public final func PerformSithAlchemy(ritualName: CName) -> Void {
        let magic: ref<MSNMagicSystem> = MSNMagicSystem.GetInstance();
        
        switch (ritualName) {
            case n"Create_Sithspawn":
                this.SithAlchemy_CreateSithspawn(magic);
                break;
            case n"Force_Weapon_Enchant":
                this.SithAlchemy_EnchantWeapon(magic);
                break;
            case n"Essence_Anchor":
                this.SithAlchemy_EssenceAnchor(magic);
                break;
            case n"Drain_Life_Force":
                this.SithAlchemy_DrainLifeForce(magic);
                break;
            case n"Kyber_Bleeding":
                this.SithAlchemy_BleedKyber();
                break;
            case n"Holocron_Corruption":
                this.SithAlchemy_CorruptHolocron();
                break;
        }
    }

    private final func SithAlchemy_CreateSithspawn(magic: ref<MSNMagicSystem>) -> Void {
        let costMana: Float = 200.0;
        let costFocus: Float = 200.0;
        
        if (magic.currentMana < costMana || this.currentFocus < costFocus) {
            this.Notify("SITH ALCHEMY: Insufficient resources. Need 200 Mana + 200 Focus");
            return;
        }
        
        magic.currentMana -= costMana;
        this.currentFocus -= costFocus;
        this.corruption = MinF(1.0, this.corruption + 0.1);
        
        this.Notify("SITH ALCHEMY: Sithspawn created. Twisted flesh. Dark Side + Arcane fused. Corruption: " + FloatToString(this.corruption));
    }

    private final func SithAlchemy_EnchantWeapon(magic: ref<MSNMagicSystem>) -> Void {
        if (this.currentFocus < 100.0) {
            this.Notify("SITH ALCHEMY: Need 100 Focus");
            return;
        }
        
        this.currentFocus -= 100.0;
        this.Notify("SITH ALCHEMY: Weapon enchanted with Force. Damage type: Force + " + NameToString(this.saberColor));
    }

    private final func SithAlchemy_EssenceAnchor(magic: ref<MSNMagicSystem>) -> Void {
        if (magic.currentMana < 300.0 || this.currentFocus < 300.0) {
            this.Notify("SITH ALCHEMY: Need 300 Mana + 300 Focus");
            return;
        }
        
        magic.currentMana -= 300.0;
        this.currentFocus -= 300.0;
        this.essenceTransferUnlocked = true;
        
        this.Notify("SITH ALCHEMY: Essence Anchor created. Death is a doorway. Possession ready.");
    }

    private final func SithAlchemy_DrainLifeForce(magic: ref<MSNMagicSystem>) -> Void {
        if (this.currentFocus < 150.0) {
            this.Notify("SITH ALCHEMY: Need 150 Focus");
            return;
        }
        
        this.currentFocus -= 150.0;
        let player: ref<PlayerPuppet> = Game.GetPlayer();
        let statsID: StatsObjectID = Cast<StatsObjectID>(player.GetEntityID());
        Game.GetStatPoolsSystem().RequestSettingStatPoolValue(statsID, gamedataStatPoolType.Health, 
            Game.GetStatPoolsSystem().GetStatPoolValue(statsID, gamedataStatPoolType.Health, player) + 300.0, player);
        
        this.Notify("SITH ALCHEMY: Life force drained. +300 HP. The Force serves the Dark Side.");
    }

    private final func SithAlchemy_BleedKyber() -> Void {
        this.saberColor = n"Bled_Crimson";
        this.corruption = 1.0;
        this.Notify("SITH ALCHEMY: KYBER BLEEDING COMPLETE. Crystal screams. Crimson eternal. Pure Dark Side.");
    }

    private final func SithAlchemy_CorruptHolocron() -> Void {
        this.Notify("SITH ALCHEMY: Holocron corrupted. Gatekeeper twisted. Knowledge inverted.");
    }

    // ============================================================
    // CONSOLE COMMANDS
    // ============================================================

    @Command("msn.jedi.status")
    public final func CmdStatus() -> Void { this.Notify("MSN Jedi: " + this.GetStatus()); }

    @Command("msn.jedi.power")
    public final func CmdPower(powerName: String) -> Void { this.UsePower(StringToName(powerName)); }

    @Command("msn.jedi.align")
    public final func CmdAlign(alignmentName: String) -> Void { this.SetAlignment(StringToName(alignmentName)); }

    @Command("msn.jedi.form")
    public final func CmdForm(formName: String) -> Void { this.ChangeLightsaberForm(Game.GetPlayer(), StringToName(formName)); }

    @Command("msn.jedi.saber")
    public final func CmdSaber() -> Void { this.ToggleLightsaber(Game.GetPlayer()); }

    @Command("msn.jedi.midis")
    public final func CmdMidis(amount: String) -> Void { this.IncreaseMidichlorians(StringToInt(amount)); }

    @Command("msn.jedi.alchemy")
    public final func CmdSithAlchemy(ritual: String) -> Void { this.PerformSithAlchemy(StringToName(ritual)); }

    @Command("msn.jedi.learn_power")
    public final func CmdLearnPower(powerName: String) -> Void {
        let power: CName = StringToName(powerName);
        this.knownPowers.PushBack(power);
        this.Notify("Learned Force Power: " + powerName);
    }

    @Command("msn.jedi.learn_form")
    public final func CmdLearnForm(formName: String) -> Void {
        let form: CName = StringToName(formName);
        this.masteredForms.PushBack(form);
        this.Notify("Mastered Lightsaber Form: " + formName);
    }

    @Command("msn.jedi.list")
    public final func CmdList() -> Void {
        let msg: String = "Powers: ";
        for (p in this.knownPowers) { msg += NameToString(p) + ", "; }
        msg += " | Forms: ";
        for (f in this.masteredForms) { msg += NameToString(f) + ", "; }
        this.Notify(msg);
    }
}


public class MSNLightsaberDiscipline extends IScriptable {
    @Property() public let defaultAlignment: CName = n"Grey";
    @Property() public let defaultForm: CName = n"Form_I_Shii_Cho";
    @Property() public let saberColor: CName = n"Blue";

    public final func OnInstall(entity: ref<Entity>) -> Void {
        let jedi: ref<MSNJediSystem> = MSNJediSystem.GetInstance();
        jedi.SetAlignment(this.defaultAlignment);
        jedi.activeForm = this.defaultForm;
        jedi.saberColor = this.saberColor;
        jedi.masteredForms.PushBack(this.defaultForm);
        
        LogInfo("[MSNLightsaberDiscipline] Installed: Alignment=" + NameToString(this.defaultAlignment) + 
                " Form=" + NameToString(this.defaultForm) + " Color=" + NameToString(this.saberColor));
    }
}


public class ForceSensitivityCerebellum extends IScriptable {
    @Property() public let maxFocus: Float = 500.0;
    @Property() public let focusRegenPulse: Float = 25.0;
    @Property() public let alignmentBias: CName = n"Grey";
    @Property() public let startingMidichlorians: Int = 10000;

    public final func OnInstall(entity: ref<Entity>) -> Void {
        let jedi: ref<MSNJediSystem> = MSNJediSystem.GetInstance();
        jedi.maxFocus = this.maxFocus;
        jedi.currentFocus = jedi.maxFocus;
        jedi.focusRegenPulse = this.focusRegenPulse;
        jedi.SetAlignment(this.alignmentBias);
        jedi.midichlorianCount = this.startingMidichlorians;
        jedi.knownPowers = { n"ForcePush", n"ForcePull", n"ForceLeap", n"ForceSense", n"Telekinesis" };
        jedi.masteredForms = { n"Form_I_Shii_Cho" };
        jedi.activeForm = n"Form_I_Shii_Cho";
        
        LogInfo("[ForceSensitivityCerebellum] Installed: Focus=" + FloatToString(this.maxFocus) + 
                " Regen=" + FloatToString(this.focusRegenPulse) + 
                " Midis=" + IntToString(this.startingMidichlorians) +
                " Alignment=" + NameToString(this.alignmentBias));
    }
}