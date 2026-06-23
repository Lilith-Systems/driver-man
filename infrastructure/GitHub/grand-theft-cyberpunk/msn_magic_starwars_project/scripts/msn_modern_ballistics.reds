// MSN Modern Ballistic Weapons — Advanced Ballistics & Gore Systems
// File: r6/scripts/weapons/msn_modern_ballistics.reds

// ============================================================================
// GORE & HORROR CORE SYSTEM
// ============================================================================

public class MSNGoreSystem extends IScriptable {
    private static let instance: ref<MSNGoreSystem>;
    private let initialized: Bool = false;

    // Gore Configuration
    @Property public let EnableDismemberment: Bool = true;
    @Property public let EnableProceduralGore: Bool = true;
    @Property public let BloodVolumeMultiplier: Float = 2.5;
    @Property public let PersistentDecals: Bool = true;
    @Property public let GibPhysics: Bool = true;
    @Property public let OrganSimulation: Bool = true;
    @Property public let FearSystem: Bool = true;
    @Property public let InfectionSystem: Bool = true;
    @Property public let MaxGibs: Int32 = 50;
    @Property public let DecalLifetime: Float = 120.0;

    // MSN Color Scheme
    @Property public let GoreColorScheme: CName = n"CrimsonViolet";

    public final static func GetInstance() -> ref<MSNGoreSystem> {
        if (!IsDefined(MSNGoreSystem.instance)) {
            MSNGoreSystem.instance = new MSNGoreSystem();
            MSNGoreSystem.instance.Initialize();
        }
        return MSNGoreSystem.instance;
    }

    private final func Initialize() -> Void {
        if (this.initialized) { return; }
        this.initialized = true;
        LogInfo("[MSN Gore] Initialized — Crimson/Violet palette active");
        LogInfo("[MSN Gore] Dismemberment: ON | Procedural: ON | Organs: ON | Fear: ON | Infection: ON");
    }

    // Main gore application entry point
    public final func ApplyGore(victim: ref<GameObject>, attacker: ref<GameObject>, hitData: HitData, weaponData: WeaponGoreData) -> Void {
        if (!this.EnableDismemberment) { return; }

        // Select gore type based on damage type
        let goreType: EGoreType = this.GetGoreType(weaponData.damageType);

        switch (goreType) {
            case EGoreType.Thermal: this.ApplyThermalGore(victim, hitData, weaponData); break;
            case EGoreType.Chemical: this.ApplyChemicalGore(victim, hitData, weaponData); break;
            case EGoreType.Electrical: this.ApplyElectricalGore(victim, hitData, weaponData); break;
            case EGoreType.Physical: this.ApplyPhysicalGore(victim, hitData, weaponData); break;
            case EGoreType.Reality: this.ApplyRealityGore(victim, hitData, weaponData); break;
            default: this.ApplyPhysicalGore(victim, hitData, weaponData); break;
        }

        // Universal effects
        if (this.FearSystem && weaponData.fearRadius > 0.0) {
            this.ApplyFearAura(victim.GetWorldPosition(), weaponData.fearRadius, weaponData.fearIntensity);
        }

        if (this.InfectionSystem && weaponData.infectionChance > 0.0) {
            this.ApplyInfection(attacker, victim, weaponData.infectionChance, weaponData.infectionType);
        }

        // Spawn gibs
        if (this.GibPhysics && weaponData.gibChance > 0.0) {
            this.SpawnGibs(victim, hitData, weaponData.gibChance * weaponData.goreMultiplier);
        }

        // Blood decals
        if (this.PersistentDecals) {
            this.SpawnBloodDecals(victim, hitData, weaponData.goreMultiplier * this.BloodVolumeMultiplier);
        }
    }

    private final func GetGoreType(damageType: gamedataDamageType) -> EGoreType {
        let name: String = EnumValueToString("gamedataDamageType", Cast(damageType));
        if (StrContains(name, "Thermal") || StrContains(name, "Fire") || StrContains(name, "Burn")) { return EGoreType.Thermal; }
        if (StrContains(name, "Chemical") || StrContains(name, "Poison") || StrContains(name, "Acid") || StrContains(name, "Cryo")) { return EGoreType.Chemical; }
        if (StrContains(name, "Electrical") || StrContains(name, "EMP") || StrContains(name, "Shock")) { return EGoreType.Electrical; }
        if (StrContains(name, "Reality") || StrContains(name, "Conceptual") || StrContains(name, "MSN")) { return EGoreType.Reality; }
        return EGoreType.Physical;
    }

    // THERMAL GORE — Cauterized, carbonized, phosphorus glow
    private final func ApplyThermalGore(victim: ref<GameObject>, hitData: HitData, weaponData: WeaponGoreData) -> Void {
        let puppet: ref<ScriptedPuppet> = victim as ScriptedPuppet;
        if (!IsDefined(puppet)) { return; }

        // Cauterized wound edges
        this.ApplyCauterization(puppet, hitData.hitPosition, hitData.hitNormal);

        // Phosphorus glow effect
        if (weaponData.hasPhosphorus) {
            this.SpawnPhosphorusVFX(puppet, hitData.hitPosition);
        }

        // Carbonization
        if (weaponData.carbonizeChance > 0.0 && RandomF() < weaponData.carbonizeChance) {
            this.ApplyCarbonization(puppet);
        }

        // Persistent burn
        if (weaponData.burnDuration > 0.0) {
            this.ApplyPersistentBurn(puppet, weaponData.burnDuration, weaponData.burnDamagePerSec);
        }

        // Fear aura from thermal horror
        this.ApplyFearAura(hitData.hitPosition, weaponData.fearRadius, 0.8);
    }

    // CHEMICAL GORE — Dissolution, melting, organ liquefaction
    private final func ApplyChemicalGore(victim: ref<GameObject>, hitData: HitData, weaponData: WeaponGoreData) -> Void {
        let puppet: ref<ScriptedPuppet> = victim as ScriptedPuppet;
        if (!IsDefined(puppet)) { return; }

        // Flesh dissolution
        if (weaponData.dissolveChance > 0.0) {
            this.ApplyFleshDissolution(puppet, hitData.hitPosition, weaponData.dissolveChance);
        }

        // Cyberware melting
        if (weaponData.meltCyberware && RandomF() < 0.4) {
            this.MeltImplants(puppet, hitData.hitPosition);
        }

        // Organ liquefaction
        if (weaponData.liquefyOrgans) {
            this.LiquefyOrgans(puppet);
        }

        // Toxic cloud
        if (weaponData.toxicCloud) {
            this.SpawnToxicCloud(hitData.hitPosition, weaponData.toxicRadius);
        }

        // Infection vector
        if (weaponData.infectionChance > 0.0) {
            this.ApplyInfection(null, puppet, weaponData.infectionChance, EInfectionType.Chemical);
        }
    }

    // ELECTRICAL GORE — Neural overload, implant cooking, spasms
    private final func ApplyElectricalGore(victim: ref<GameObject>, hitData: HitData, weaponData: WeaponGoreData) -> Void {
        let puppet: ref<ScriptedPuppet> = victim as ScriptedPuppet;
        if (!IsDefined(puppet)) { return; }

        // Neural overload visual
        this.SpawnNeuralOverloadVFX(puppet, hitData.hitPosition);

        // Implant cooking
        if (weaponData.cookImplants) {
            this.CookImplants(puppet, hitData.hitPosition, weaponData.cookRadius);
        }

        // Spasm induction
        if (weaponData.spasmChance > 0.0 && RandomF() < weaponData.spasmChance) {
            this.InduceSpasms(puppet, weaponData.spasmDuration);
        }

        // Chain lightning
        if (weaponData.chainTargets > 0) {
            this.ChainLightning(puppet, hitData.hitPosition, weaponData.chainTargets, weaponData.chainRange);
        }

        // EMP burst
        if (weaponData.empBurst) {
            this.EMPBurst(hitData.hitPosition, weaponData.empRadius);
        }
    }

    // PHYSICAL GORE — Bone shatter, dismemberment, gibs, seismic
    private final func ApplyPhysicalGore(victim: ref<GameObject>, hitData: HitData, weaponData: WeaponGoreData) -> Void {
        let puppet: ref<ScriptedPuppet> = victim as ScriptedPuppet;
        if (!IsDefined(puppet)) { return; }

        // Bone shatter
        if (weaponData.shatterBones) {
            this.ShatterBones(puppet, hitData.hitPosition, hitData.hitNormal);
        }

        // Dismemberment
        if (weaponData.dismemberChance > 0.0 && RandomF() < weaponData.dismemberChance * weaponData.goreMultiplier) {
            this.DismemberLimb(puppet, hitData.hitBone, hitData.hitPosition);
        }

        // Seismic shockwave
        if (weaponData.seismicShockwave) {
            this.SeismicShockwave(hitData.hitPosition, weaponData.seismicRadius, weaponData.seismicForce);
        }

        // Crush liquefaction
        if (weaponData.crushDamage > 1.0) {
            this.CrushLiquefy(puppet, hitData.hitPosition, weaponData.crushDamage);
        }
    }

    // REALITY GORE — Conceptual damage, engram extraction, reality tears
    private final func ApplyRealityGore(victim: ref<GameObject>, hitData: HitData, weaponData: WeaponGoreData) -> Void {
        let puppet: ref<ScriptedPuppet> = victim as ScriptedPuppet;
        if (!IsDefined(puppet)) { return; }

        // Reality tear visual
        this.SpawnRealityTearVFX(hitData.hitPosition, hitData.hitNormal);

        // Engram extraction
        if (weaponData.extractEngrams) {
            this.ExtractEngrams(puppet, hitData.hitPosition);
        }

        // Fear feeding
        if (weaponData.fearFeeding) {
            this.FeedOnFear(puppet, weaponData.fearRadius);
        }

        // No cauterization — pure conceptual wound
        this.ApplyConceptualWound(puppet, hitData.hitPosition);
    }

    // ============================================================================
    // GORE IMPLEMENTATION HELPERS
    // ============================================================================

    private final func ApplyCauterization(puppet: ref<ScriptedPuppet>, pos: Vector4, normal: Vector4) -> Void {
        // Apply cauterized wound decal
        let decal: ref<DecalComponent> = new DecalComponent();
        decal.material = "msn_cauterized_wound";
        decal.size = Vector2(0.15, 0.15);
        decal.lifetime = this.DecalLifetime;
        puppet.AddComponent(decal);
    }

    private final func ApplyCarbonization(puppet: ref<ScriptedPuppet>) -> Void {
        // Char the mesh
        let mesh: ref<MeshComponent> = puppet.GetMesh();
        if (IsDefined(mesh)) {
            mesh.SetMaterialParameter("Carbonization", 1.0);
            mesh.SetMaterialParameter("CarbonColor", Color(0.1, 0.05, 0.02, 1.0));
        }
    }

    private final func ApplyPersistentBurn(puppet: ref<ScriptedPuppet>, duration: Float, dps: Float) -> Void {
        let eff: ref<StatusEffect> = new StatusEffect();
        eff.type = gamedataStatusEffectType.Burning;
        eff.duration = duration;
        eff.magnitude = dps;
        eff.source = "MSN_Thermal_Gore";
        puppet.GetStatusEffectSystem().ApplyStatusEffect(eff);
    }

    private final func SpawnPhosphorusVFX(puppet: ref<ScriptedPuppet>, pos: Vector4) -> Void {
        let vfx: ref<ParticleEffect> = ParticleEffect.Spawn("msn_phosphorus_glow", pos);
        if (IsDefined(vfx)) {
            vfx.SetParameter("GlowColor", Color(1.0, 0.4, 0.1, 1.0));
            vfx.SetParameter("Intensity", 2.0);
        }
    }

    private final func ApplyFleshDissolution(puppet: ref<ScriptedPuppet>, pos: Vector4, chance: Float) -> Void {
        let mesh: ref<MeshComponent> = puppet.GetMesh();
        if (IsDefined(mesh)) {
            mesh.SetMaterialParameter("Dissolution", chance);
            mesh.SetMaterialParameter("DissolvePos", pos);
        }
    }

    private final func MeltImplants(puppet: ref<ScriptedPuppet>, pos: Vector4) -> Void {
        let cyber: ref<CyberwareSystem> = puppet.GetCyberwareSystem();
        if (IsDefined(cyber)) {
            cyber.MeltNearbyImplants(pos, 0.5);
        }
    }

    private final func LiquefyOrgans(puppet: ref<ScriptedPuppet>) -> Void {
        // Internal organ damage - massive damage over time
        let dmg: ref<Damage> = new Damage();
        dmg.type = gamedataDamageType.Chemical;
        dmg.amount = 500.0;
        dmg.source = "MSN_Chemical_Liquefaction";
        puppet.GetDamageSystem().ApplyDamage(dmg);
    }

    private final func SpawnToxicCloud(pos: Vector4, radius: Float) -> Void {
        let vfx: ref<ParticleEffect> = ParticleEffect.Spawn("msn_toxic_cloud", pos);
        if (IsDefined(vfx)) {
            vfx.SetParameter("Radius", radius);
            vfx.SetParameter("Color", Color(0.3, 0.6, 0.2, 0.5));
        }
    }

    private final func SpawnNeuralOverloadVFX(puppet: ref<ScriptedPuppet>, pos: Vector4) -> Void {
        let vfx: ref<ParticleEffect> = ParticleEffect.Spawn("msn_neural_overload", pos);
        if (IsDefined(vfx)) {
            vfx.SetParameter("ArcColor", Color(0.2, 0.8, 1.0, 1.0));
            vfx.SetParameter("Intensity", 3.0);
        }
        // Screen shake
        Game.GetCameraSystem().Shake(1.5, 0.5);
    }

    private final func CookImplants(puppet: ref<ScriptedPuppet>, pos: Vector4, radius: Float) -> Void {
        let cyber: ref<CyberwareSystem> = puppet.GetCyberwareSystem();
        if (IsDefined(cyber)) {
            cyber.CookImplantsInRadius(pos, radius, 0.8);
        }
    }

    private final func InduceSpasms(puppet: ref<ScriptedPuppet>, duration: Float) -> Void {
        let anim: ref<AnimationControllerComponent> = puppet.GetAnimationController();
        if (IsDefined(anim)) {
            anim.PlaySpasmAnimation(duration);
        }
    }

    private final func ChainLightning(source: ref<ScriptedPuppet>, pos: Vector4, targets: Int32, range: Float) -> Void {
        let entities: array<ref<Entity>> = Game.GetSpatialQueries().GetEntitiesInRadius(pos, range);
        let count: Int32 = 0;
        for (ent in entities) {
            if (count >= targets) { break; }
            let puppet: ref<ScriptedPuppet> = ent as ScriptedPuppet;
            if (IsDefined(puppet) && !puppet.IsDead() && puppet != source) {
                let dmg: ref<Damage> = new Damage();
                dmg.type = gamedataDamageType.Electrical;
                dmg.amount = 150.0;
                dmg.source = "MSN_ChainLightning";
                puppet.GetDamageSystem().ApplyDamage(dmg);
                // Arc VFX
                this.SpawnArcVFX(source.GetWorldPosition(), puppet.GetWorldPosition());
                count++;
            }
        }
    }

    private final func EMPBurst(pos: Vector4, radius: Float) -> Void {
        let entities: array<ref<Entity>> = Game.GetSpatialQueries().GetEntitiesInRadius(pos, radius);
        for (ent in entities) {
            let puppet: ref<ScriptedPuppet> = ent as ScriptedPuppet;
            if (IsDefined(puppet)) {
                puppet.DisableCyberwareFor(5.0);
            }
            let device: ref<Device> = ent as Device;
            if (IsDefined(device)) {
                device.TurnOff();
            }
        }
    }

    private final func ShatterBones(puppet: ref<ScriptedPuppet>, pos: Vector4, normal: Vector4) -> Void {
        // Bone break visual
        let vfx: ref<ParticleEffect> = ParticleEffect.Spawn("msn_bone_shatter", pos);
        if (IsDefined(vfx)) {
            vfx.SetParameter("Direction", normal);
            vfx.SetParameter("FragmentCount", 12);
        }
        // Sound
        Game.GetAudioSystem().PlaySound("msn_bone_snap", pos);
    }

    private final func DismemberLimb(puppet: ref<ScriptedPuppet>, boneName: CName, pos: Vector4) -> Void {
        if (boneName == n"") { return; }
        // Detach limb
        puppet.DetachLimb(boneName);
        // Gib spawn
        this.SpawnGib(puppet, boneName, pos);
        // Blood spray
        this.SpawnBloodSpray(pos, 3.0);
    }

    private final func SpawnGib(puppet: ref<ScriptedPuppet>, boneName: CName, pos: Vector4) -> Void {
        let gib: ref<GameObject> = Game.SpawnObject("msn_gib_" + EnumValueToString("CName", Cast(boneName)), pos);
        if (IsDefined(gib)) {
            gib.ApplyImpulse(Vector4(RandomF(-5,5), RandomF(-5,5), RandomF(2,8), 0));
        }
    }

    private final func SpawnBloodSpray(pos: Vector4, intensity: Float) -> Void {
        let vfx: ref<ParticleEffect> = ParticleEffect.Spawn("msn_blood_spray", pos);
        if (IsDefined(vfx)) {
            vfx.SetParameter("Intensity", intensity * this.BloodVolumeMultiplier);
            vfx.SetParameter("Color", this.GetGoreColor());
        }
    }

    private final func SeismicShockwave(pos: Vector4, radius: Float, force: Float) -> Void {
        let entities: array<ref<Entity>> = Game.GetSpatialQueries().GetEntitiesInRadius(pos, radius);
        for (ent in entities) {
            let puppet: ref<ScriptedPuppet> = ent as ScriptedPuppet;
            if (IsDefined(puppet) && !puppet.IsPlayer()) {
                puppet.Knockdown(force);
            }
        }
        // Ground crack VFX
        let vfx: ref<ParticleEffect> = ParticleEffect.Spawn("msn_seismic_crack", pos);
        if (IsDefined(vfx)) {
            vfx.SetParameter("Radius", radius);
        }
        // Screen shake
        Game.GetCameraSystem().Shake(2.0, 1.0);
    }

    private final func CrushLiquefy(puppet: ref<ScriptedPuppet>, pos: Vector4, multiplier: Float) -> Void {
        // Massive internal damage
        let dmg: ref<Damage> = new Damage();
        dmg.type = gamedataDamageType.Physical;
        dmg.amount = 1000.0 * multiplier;
        dmg.source = "MSN_Crush_Liquefaction";
        puppet.GetDamageSystem().ApplyDamage(dmg);
        // Liquefy VFX
        let vfx: ref<ParticleEffect> = ParticleEffect.Spawn("msn_liquefy", pos);
    }

    private final func SpawnRealityTearVFX(pos: Vector4, normal: Vector4) -> Void {
        let vfx: ref<ParticleEffect> = ParticleEffect.Spawn("msn_reality_tear", pos);
        if (IsDefined(vfx)) {
            vfx.SetParameter("Direction", normal);
            vfx.SetParameter("CrimsonIntensity", 1.0);
            vfx.SetParameter("VioletIntensity", 0.5);
        }
    }

    private final func ExtractEngrams(puppet: ref<ScriptedPuppet>, pos: Vector4) -> Void {
        let ouroboros: ref<OuroborosSystem> = OuroborosSystem.GetInstance();
        if (IsDefined(ouroboros)) {
            ouroboros.ExtractEngram(puppet, pos);
        }
        // VFX
        let vfx: ref<ParticleEffect> = ParticleEffect.Spawn("msn_engram_extraction", pos);
        if (IsDefined(vfx)) {
            vfx.SetParameter("Color", Color(0.8, 0.2, 0.8, 1.0));
        }
    }

    private final func FeedOnFear(puppet: ref<ScriptedPuppet>, radius: Float) -> Void {
        let entities: array<ref<Entity>> = Game.GetSpatialQueries().GetEntitiesInRadius(pos, radius);
        for (ent in entities) {
            let target: ref<ScriptedPuppet> = ent as ScriptedPuppet;
            if (IsDefined(target) && target != puppet) {
                target.ApplyFear(10.0);
            }
        }
    }

    private final func ApplyConceptualWound(puppet: ref<ScriptedPuppet>, pos: Vector4) -> Void {
        // Conceptual wound - damages "concept" of health
        let dmg: ref<Damage> = new Damage();
        dmg.type = gamedataDamageType.Chemical;
        dmg.amount = 9999.0; // Bypass normal DR
        dmg.source = "MSN_Reality_Judgment";
        puppet.GetDamageSystem().ApplyDamage(dmg);
    }

    private final func ApplyFearAura(pos: Vector4, radius: Float, intensity: Float) -> Void {
        let entities: array<ref<Entity>> = Game.GetSpatialQueries().GetEntitiesInRadius(pos, radius);
        for (ent in entities) {
            let puppet: ref<ScriptedPuppet> = ent as ScriptedPuppet;
            if (IsDefined(puppet) && !puppet.IsPlayer()) {
                puppet.ApplyFear(intensity * 5.0);
            }
        }
    }

    private final func ApplyInfection(attacker: ref<GameObject>, victim: ref<GameObject>, chance: Float, type: EInfectionType) -> Void {
        let puppet: ref<ScriptedPuppet> = victim as ScriptedPuppet;
        if (!IsDefined(puppet)) { return; }
        if (RandomF() > chance) { return; }

        let eff: ref<StatusEffect> = new StatusEffect();
        switch (type) {
            case EInfectionType.Tetanus: eff.type = gamedataStatusEffectType.Poisoned; eff.duration = 300.0; break;
            case EInfectionType.Sepsis: eff.type = gamedataStatusEffectType.Bleeding; eff.duration = 600.0; break;
            case EInfectionType.Chemical: eff.type = gamedataStatusEffectType.Poisoned; eff.duration = 180.0; break;
            default: eff.type = gamedataStatusEffectType.Poisoned; eff.duration = 120.0; break;
        }
        eff.magnitude = 10.0;
        eff.source = "MSN_Infection";
        puppet.GetStatusEffectSystem().ApplyStatusEffect(eff);
    }

    private final func SpawnGibs(victim: ref<GameObject>, hitData: HitData, chance: Float) -> Void {
        if (RandomF() > chance) { return; }
        let gibCount: Int32 = RandInt(3, 8);
        for (i: Int32 = 0; i < gibCount; i++) {
            let pos: Vector4 = hitData.hitPosition + Vector4(RandomF(-0.5,0.5), RandomF(-0.5,0.5), RandomF(0,1), 0);
            let gib: ref<GameObject> = Game.SpawnObject("msn_gib_generic", pos);
            if (IsDefined(gib)) {
                gib.ApplyImpulse(Vector4(RandomF(-10,10), RandomF(-10,10), RandomF(5,15), 0));
            }
        }
    }

    private final func SpawnBloodDecals(victim: ref<GameObject>, hitData: HitData, volume: Float) -> Void {
        let decal: ref<DecalComponent> = new DecalComponent();
        decal.material = "msn_blood_pool";
        decal.size = Vector2(volume * 0.5, volume * 0.5);
        decal.lifetime = this.DecalLifetime;
        decal.position = hitData.hitPosition;
        decal.rotation = EulerAngles(0, 0, RandomF(0, 360));
        victim.AddComponent(decal);
    }

    private final func GetGoreColor() -> Color {
        if (this.GoreColorScheme == n"CrimsonViolet") {
            return Color(0.8, 0.1, 0.2, 1.0); // Deep crimson with violet undertone
        }
        return Color(0.7, 0.0, 0.0, 1.0);
    }

    private final func SpawnArcVFX(from: Vector4, to: Vector4) -> Void {
        let vfx: ref<ParticleEffect> = ParticleEffect.Spawn("msn_electrical_arc", from);
        if (IsDefined(vfx)) {
            vfx.SetParameter("Target", to);
            vfx.SetParameter("ArcColor", Color(0.2, 0.8, 1.0, 1.0));
        }
    }
}

// ============================================================================
// DATA STRUCTURES
// ============================================================================

public enum EGoreType {
    Physical,
    Thermal,
    Chemical,
    Electrical,
    Reality
}

public enum EInfectionType {
    Tetanus,
    Sepsis,
    Chemical,
    Viral,
    Nanite
}

public struct WeaponGoreData {
    @Property public let damageType: gamedataDamageType;
    @Property public let goreMultiplier: Float = 1.0;
    @Property public let gibChance: Float = 0.0;
    @Property public let dismemberChance: Float = 0.0;
    @Property public let fearRadius: Float = 0.0;
    @Property public let fearIntensity: Float = 0.0;
    @Property public let infectionChance: Float = 0.0;
    @Property public let infectionType: EInfectionType = EInfectionType.Tetanus;

    // Thermal
    @Property public let hasPhosphorus: Bool = false;
    @Property public let carbonizeChance: Float = 0.0;
    @Property public let burnDuration: Float = 0.0;
    @Property public let burnDamagePerSec: Float = 0.0;

    // Chemical
    @Property public let dissolveChance: Float = 0.0;
    @Property public let meltCyberware: Bool = false;
    @Property public let liquefyOrgans: Bool = false;
    @Property public let toxicCloud: Bool = false;
    @Property public let toxicRadius: Float = 0.0;

    // Electrical
    @Property public let cookImplants: Bool = false;
    @Property public let cookRadius: Float = 0.0;
    @Property public let spasmChance: Float = 0.0;
    @Property public let spasmDuration: Float = 0.0;
    @Property public let chainTargets: Int32 = 0;
    @Property public let chainRange: Float = 0.0;
    @Property public let empBurst: Bool = false;
    @Property public let empRadius: Float = 0.0;

    // Physical
    @Property public let shatterBones: Bool = false;
    @Property public let seismicShockwave: Bool = false;
    @Property public let seismicRadius: Float = 0.0;
    @Property public let seismicForce: Float = 0.0;
    @Property public let crushDamage: Float = 1.0;

    // Reality
    @Property public let extractEngrams: Bool = false;
    @Property public let fearFeeding: Bool = false;
}

public struct HitData {
    @Property public let hitPosition: Vector4;
    @Property public let hitNormal: Vector4;
    @Property public let hitBone: CName;
    @Property public let damageAmount: Float;
}

// ============================================================================
// MANUFACTURER WEAPON BEHAVIORS
// ============================================================================

// ARASAKA — Precision Horror
public class ArasakaWeaponBehavior extends WeaponBehavior {
    protected cb func OnHit(target: ref<GameObject>, damage: Float, hitData: HitData) -> Void {
        let gore: ref<MSNGoreSystem> = MSNGoreSystem.GetInstance();
        let goreData: WeaponGoreData = this.BuildGoreData();
        gore.ApplyGore(target, this.GetOwner(), hitData, goreData);
    }

    private final func BuildGoreData() -> WeaponGoreData {
        return WeaponGoreData {
            damageType = gamedataDamageType.Thermal,
            goreMultiplier = 2.5,
            gibChance = 0.2,
            dismemberChance = 0.25,
            fearRadius = 5.0,
            fearIntensity = 0.8,
            hasPhosphorus = true,
            carbonizeChance = 0.3,
            burnDuration = 8.0,
            burnDamagePerSec = 25.0
        };
    }
}

// MILITECH — Industrial Carnage
public class MilitechWeaponBehavior extends WeaponBehavior {
    protected cb func OnHit(target: ref<GameObject>, damage: Float, hitData: HitData) -> Void {
        let gore: ref<MSNGoreSystem> = MSNGoreSystem.GetInstance();
        let goreData: WeaponGoreData = this.BuildGoreData();
        gore.ApplyGore(target, this.GetOwner(), hitData, goreData);
    }

    private final func BuildGoreData() -> WeaponGoreData {
        return WeaponGoreData {
            damageType = gamedataDamageType.Physical,
            goreMultiplier = 2.0,
            gibChance = 0.4,
            dismemberChance = 0.35,
            shatterBones = true,
            seismicShockwave = true,
            seismicRadius = 4.0,
            seismicForce = 1500.0,
            crushDamage = 3.0
        };
    }
}

// KANG TAO — Elemental Visceral
public class KangTaoWeaponBehavior extends WeaponBehavior {
    @Property public let ElementalMode: CName = n"Fire"; // Fire, Ice, Shock

    protected cb func OnHit(target: ref<GameObject>, damage: Float, hitData: HitData) -> Void {
        let gore: ref<MSNGoreSystem> = MSNGoreSystem.GetInstance();
        let goreData: WeaponGoreData = this.BuildGoreData();
        gore.ApplyGore(target, this.GetOwner(), hitData, goreData);
    }

    private final func BuildGoreData() -> WeaponGoreData {
        if (this.ElementalMode == n"Fire") {
            return WeaponGoreData {
                damageType = gamedataDamageType.Thermal,
                goreMultiplier = 2.5,
                hasPhosphorus = true,
                carbonizeChance = 0.5,
                burnDuration = 15.0,
                burnDamagePerSec = 85.0,
                fearRadius = 8.0,
                fearIntensity = 1.0
            };
        } else if (this.ElementalMode == n"Ice") {
            return WeaponGoreData {
                damageType = gamedataDamageType.Chemical,
                goreMultiplier = 2.5,
                dissolveChance = 0.6,
                meltCyberware = true,
                liquefyOrgans = false, // Flash freeze instead
                infectionChance = 0.1,
                fearRadius = 4.0,
                fearIntensity = 0.5
            };
        } else if (this.ElementalMode == n"Shock") {
            return WeaponGoreData {
                damageType = gamedataDamageType.Electrical,
                goreMultiplier = 1.8,
                cookImplants = true,
                cookRadius = 1.5,
                spasmChance = 0.4,
                spasmDuration = 3.0,
                chainTargets = 3,
                chainRange = 6.0,
                empBurst = true,
                empRadius = 4.0
            };
        }
        return WeaponGoreData { damageType = gamedataDamageType.Physical };
    }
}

// BUDGET ARMS — Street Infection
public class BudgetArmsWeaponBehavior extends WeaponBehavior {
    protected cb func OnHit(target: ref<GameObject>, damage: Float, hitData: HitData) -> Void {
        let gore: ref<MSNGoreSystem> = MSNGoreSystem.GetInstance();
        let goreData: WeaponGoreData = this.BuildGoreData();
        gore.ApplyGore(target, this.GetOwner(), hitData, goreData);
    }

    private final func BuildGoreData() -> WeaponGoreData {
        return WeaponGoreData {
            damageType = gamedataDamageType.Physical,
            goreMultiplier = 1.5,
            dismemberChance = 0.15,
            infectionChance = 0.4,
            infectionType = EInfectionType.Tetanus,
            fearRadius = 2.0,
            fearIntensity = 0.3
        };
    }
}

// MSN SYSTEMS — Metaconscious Artistry
public class MSNWeaponBehavior extends WeaponBehavior {
    @Property public let WeaponArchetype: CName = n"Reality"; // Reality, Ouroboros, NGD, Lyra, Sephirot

    protected cb func OnHit(target: ref<GameObject>, damage: Float, hitData: HitData) -> Void {
        let gore: ref<MSNGoreSystem> = MSNGoreSystem.GetInstance();
        let goreData: WeaponGoreData = this.BuildGoreData();
        gore.ApplyGore(target, this.GetOwner(), hitData, goreData);

        // Special effects
        if (this.WeaponArchetype == n"Lilith") {
            this.LilithEffects(target, hitData);
        } else if (this.WeaponArchetype == n"Ouroboros") {
            this.OuroborosEffects(target, hitData);
        } else if (this.WeaponArchetype == n"Lyra") {
            this.LyraEffects(target, hitData);
        }
    }

    private final func BuildGoreData() -> WeaponGoreData {
        if (this.WeaponArchetype == n"Reality" || this.WeaponArchetype == n"Lilith") {
            return WeaponGoreData {
                damageType = gamedataDamageType.Chemical,
                goreMultiplier = 4.0,
                extractEngrams = true,
                fearFeeding = true,
                fearRadius = 10.0,
                fearIntensity = 1.0
            };
        } else if (this.WeaponArchetype == n"Ouroboros") {
            return WeaponGoreData {
                damageType = gamedataDamageType.Physical,
                goreMultiplier = 2.0,
                extractEngrams = true,
                infectionChance = 0.0
            };
        } else if (this.WeaponArchetype == n"NGD") {
            return WeaponGoreData {
                damageType = gamedataDamageType.Physical,
                goreMultiplier = 1.0,
                dismemberChance = 0.1
            };
        } else if (this.WeaponArchetype == n"Lyra") {
            return WeaponGoreData {
                damageType = gamedataDamageType.Chemical,
                goreMultiplier = 2.5,
                extractEngrams = true,
                fearRadius = 6.0,
                fearIntensity = 0.7
            };
        } else if (this.WeaponArchetype == n"Sephirot") {
            return WeaponGoreData {
                damageType = gamedataDamageType.Physical,
                goreMultiplier = 2.0,
                dismemberChance = 0.3
            };
        }
        return WeaponGoreData { damageType = gamedataDamageType.Physical };
    }

    private final func LilithEffects(target: ref<GameObject>, hitData: HitData) -> Void {
        // Crimson resonance wave
        let vfx: ref<ParticleEffect> = ParticleEffect.Spawn("msn_crimson_wave", hitData.hitPosition);
        if (IsDefined(vfx)) {
            vfx.SetParameter("Intensity", 3.0);
        }
        // Fear feed on witnesses
        let entities: array<ref<Entity>> = Game.GetSpatialQueries().GetEntitiesInRadius(hitData.hitPosition, 15.0);
        for (ent in entities) {
            let puppet: ref<ScriptedPuppet> = ent as ScriptedPuppet;
            if (IsDefined(puppet) && !puppet.IsDead()) {
                puppet.ApplyFear(0.5);
            }
        }
    }

    private final func OuroborosEffects(target: ref<GameObject>, hitData: HitData) -> Void {
        // Engram extraction VFX
        let vfx: ref<ParticleEffect> = ParticleEffect.Spawn("msn_engram_extraction", hitData.hitPosition);
        if (IsDefined(vfx)) {
            vfx.SetParameter("Color", Color(0.8, 0.2, 0.8, 1.0));
        }
        // Skill theft notification
        Game.GetUIManager().ShowNotification("Engram extracted. Skill acquired.");
    }

    private final func LyraEffects(target: ref<GameObject>, hitData: HitData) -> Void {
        // Violet resonance
        let vfx: ref<ParticleEffect> = ParticleEffect.Spawn("msn_violet_resonance", hitData.hitPosition);
        if (IsDefined(vfx)) {
            vfx.SetParameter("Mode", this.GetLyraMode());
        }
    }

    private final func GetLyraMode() -> String {
        // Would sync with Lyra server state
        return "Empirical";
    }
}

// ============================================================================
// ADVANCED BALLISTICS — Realistic Trajectory & Penetration
// ============================================================================

public class MSNBallisticsSystem extends IScriptable {
    private static let instance: ref<MSNBallisticsSystem>;

    // Ballistics config
    @Property public let EnableAdvancedBallistics: Bool = true;
    @Property public let Gravity: Float = 9.81;
    @Property public let AirDensity: Float = 1.225;
    @Property public let EnableWind: Bool = true;
    @Property public let WindStrength: Float = 2.0;
    @Property public let EnableCoriolis: Bool = false;
    @Property public let EnableSpinDrift: Bool = true;
    @Property public let EnableMagnusEffect: Bool = true;

    // Penetration
    @Property public let EnableMaterialPenetration: Bool = true;
    @Property public let EnableRicochet: Bool = true;
    @Property public let EnableFragmentation: Bool = true;

    public final static func GetInstance() -> ref<MSNBallisticsSystem> {
        if (!IsDefined(MSNBallisticsSystem.instance)) {
            MSNBallisticsSystem.instance = new MSNBallisticsSystem();
        }
        return MSNBallisticsSystem.instance;
    }

    // Calculate trajectory with all physics
    public final func CalculateTrajectory(origin: Vector4, direction: Vector4, projectile: ProjectileData) -> array<Vector4> {
        let trajectory: array<Vector4> = {};
        let pos: Vector4 = origin;
        let vel: Vector4 = direction * projectile.muzzleVelocity;
        let timeStep: Float = 0.01; // 100Hz simulation
        let maxTime: Float = projectile.maxRange / projectile.muzzleVelocity;
        let currentTime: Float = 0.0;

        while (currentTime < maxTime && Vector4.Length(pos - origin) < projectile.maxRange) {
            trajectory.PushBack(pos);

            // Gravity
            vel.Z -= this.Gravity * timeStep;

            // Air resistance (drag)
            let speed: Float = Vector4.Length(vel);
            let dragForce: Float = 0.5 * this.AirDensity * speed * speed * projectile.dragCoefficient * projectile.crossSection;
            let dragAccel: Vector4 = -vel * (dragForce / projectile.mass);
            vel += dragAccel * timeStep;

            // Wind
            if (this.EnableWind) {
                let wind: Vector4 = this.GetWindAt(pos);
                vel += wind * timeStep * 0.1;
            }

            // Spin drift (Magnus effect)
            if (this.EnableSpinDrift && this.EnableMagnusEffect) {
                let spinAxis: Vector4 = Vector4.Normalize(vel);
                let magnusForce: Vector4 = Vector4.Cross(spinAxis, vel) * projectile.spinRate * 0.01;
                vel += magnusForce * timeStep;
            }

            // Coriolis (negligible at game ranges but included)
            if (this.EnableCoriolis) {
                let coriolis: Vector4 = Vector4.Cross(Vector4(0, 0, 1, 0), vel) * 0.0001;
                vel += coriolis * timeStep;
            }

            pos += vel * timeStep;
            currentTime += timeStep;

            // Check for impact
            let hit: TraceResult = Game.GetSpatialQueries().TraceLine(pos - vel * timeStep, pos, TraceFlag.All);
            if (hit.hit) {
                // Handle penetration/ricochet
                let result: PenetrationResult = this.HandleImpact(hit, vel, projectile);
                if (result.penetrated) {
                    vel = result.exitVelocity;
                    pos = result.exitPoint;
                    continue;
                } else if (result.ricocheted) {
                    vel = result.ricochetVelocity;
                    pos = hit.hitPosition + result.ricochetVelocity * timeStep;
                    continue;
                } else {
                    // Impact - stop
                    trajectory.PushBack(hit.hitPosition);
                    break;
                }
            }
        }

        return trajectory;
    }

    private final func GetWindAt(pos: Vector4) -> Vector4 {
        // Simplified wind field
        return Vector4(
            Sin(pos.X * 0.01) * this.WindStrength,
            Cos(pos.Y * 0.01) * this.WindStrength,
            0.0, 0.0
        );
    }

    private final func HandleImpact(hit: TraceResult, velocity: Vector4, projectile: ProjectileData) -> PenetrationResult {
        let material: ESurfaceMaterial = hit.component.GetMaterial();

        // Penetration check
        let penetrationPower: Float = projectile.penetration * (Vector4.Length(velocity) / projectile.muzzleVelocity);
        let materialResistance: Float = this.GetMaterialResistance(material);

        if (penetrationPower > materialResistance && this.EnableMaterialPenetration) {
            // Calculate exit point
            let thickness: Float = this.EstimateThickness(hit.hitPosition, velocity, material);
            let remainingEnergy: Float = penetrationPower - materialResistance;
            let exitVelocity: Float = Sqrt(remainingEnergy / projectile.mass * 2.0);
            let exitPoint: Vector4 = hit.hitPosition + Vector4.Normalize(velocity) * thickness;

            return PenetrationResult {
                penetrated = true,
                exitPoint = exitPoint,
                exitVelocity = Vector4.Normalize(velocity) * exitVelocity,
                energyLost = materialResistance
            };
        }

        // Ricochet check
        let angle: Float = ACos(Vector4.Dot(Vector4.Normalize(velocity), hit.hitNormal));
        if (angle < 30.0 && this.EnableRicochet) {
            let ricochetVel: Vector4 = Vector4.Reflect(velocity, hit.hitNormal) * 0.6;
            return PenetrationResult {
                ricocheted = true,
                ricochetVelocity = ricochetVel
            };
        }

        // Fragmentation
        if (projectile.fragmentChance > 0.0 && RandomF() < projectile.fragmentChance && this.EnableFragmentation) {
            this.SpawnFragments(hit.hitPosition, velocity, projectile.fragmentCount);
        }

        return PenetrationResult { };
    }

    private final func GetMaterialResistance(material: ESurfaceMaterial) -> Float {
        switch (material) {
            case ESurfaceMaterial.Flesh: return 50.0;
            case ESurfaceMaterial.LightArmor: return 200.0;
            case ESurfaceMaterial.HeavyArmor: return 800.0;
            case ESurfaceMaterial.Concrete: return 1500.0;
            case ESurfaceMaterial.Metal: return 2000.0;
            case ESurfaceMaterial.Glass: return 50.0;
            case ESurfaceMaterial.Wood: return 300.0;
            default: return 100.0;
        }
    }

    private final func EstimateThickness(pos: Vector4, dir: Vector4, material: ESurfaceMaterial) -> Float {
        // Raycast backward from exit side
        let backTrace: TraceResult = Game.GetSpatialQueries().TraceLine(pos + dir * 2.0, pos - dir * 2.0, TraceFlag.All);
        if (backTrace.hit) {
            return Vector4.Distance(pos, backTrace.hitPosition);
        }
        switch (material) {
            case ESurfaceMaterial.Flesh: return 0.3;
            case ESurfaceMaterial.LightArmor: return 0.05;
            case ESurfaceMaterial.HeavyArmor: return 0.2;
            case ESurfaceMaterial.Concrete: return 0.5;
            case ESurfaceMaterial.Metal: return 0.1;
            default: return 0.1;
        }
    }

    private final func SpawnFragments(pos: Vector4, velocity: Vector4, count: Int32) -> Void {
        for (i: Int32 = 0; i < count; i++) {
            let fragVel: Vector4 = Vector4.Normalize(velocity) * 50.0;
            fragVel += Vector4(RandomF(-1,1), RandomF(-1,1), RandomF(0,1), 0) * 20.0;
            let frag: ref<GameObject> = Game.SpawnObject("msn_fragment", pos);
            if (IsDefined(frag)) {
                frag.ApplyImpulse(fragVel);
            }
        }
    }
}

// ============================================================================
// DATA STRUCTURES FOR BALLISTICS
// ============================================================================

public struct ProjectileData {
    @Property public let mass: Float = 0.01; // kg
    @Property public let muzzleVelocity: Float = 800.0; // m/s
    @Property public let dragCoefficient: Float = 0.295;
    @Property public let crossSection: Float = 0.0001; // m^2
    @Property public let penetration: Float = 500.0;
    @Property public let fragmentChance: Float = 0.0;
    @Property public let fragmentCount: Int32 = 0;
    @Property public let spinRate: Float = 1000.0; // RPM
    @Property public let maxRange: Float = 1000.0;
}

public struct TraceResult {
    @Property public let hit: Bool = false;
    @Property public let hitPosition: Vector4;
    @Property public let hitNormal: Vector4;
    @Property public let component: ref<IComponent>;
    @Property public let distance: Float;
}

public struct PenetrationResult {
    @Property public let penetrated: Bool = false;
    @Property public let exitPoint: Vector4;
    @Property public let exitVelocity: Vector4;
    @Property public let ricocheted: Bool = false;
    @Property public let ricochetVelocity: Vector4;
    @Property public let energyLost: Float = 0.0;
}

public enum ESurfaceMaterial {
    Flesh,
    LightArmor,
    HeavyArmor,
    Concrete,
    Metal,
    Glass,
    Wood,
    Energy
}

// ============================================================================
// INTEGRATION HOOKS
// ============================================================================

// Hook into weapon fire event
public class MSNWeaponIntegration extends IScriptable {
    private static let instance: ref<MSNWeaponIntegration>;
    private let ballistics: ref<MSNBallisticsSystem>;
    private let gore: ref<MSNGoreSystem>;

    public final static func GetInstance() -> ref<MSNWeaponIntegration> {
        if (!IsDefined(MSNWeaponIntegration.instance)) {
            MSNWeaponIntegration.instance = new MSNWeaponIntegration();
            MSNWeaponIntegration.instance.Initialize();
        }
        return MSNWeaponIntegration.instance;
    }

    private final func Initialize() -> Void {
        this.ballistics = MSNBallisticsSystem.GetInstance();
        this.gore = MSNGoreSystem.GetInstance();
        LogInfo("[MSN Weapons] Integration initialized — Advanced ballistics + Gore systems active");
    }

    // Called from weapon's OnShoot
    public final func OnWeaponFire(weapon: ref<WeaponItem>, owner: ref<GameObject>, target: Vector4) -> Void {
        if (!this.ballistics.EnableAdvancedBallistics) { return; }

        let projData: ProjectileData = this.GetProjectileData(weapon);
        let trajectory: array<Vector4> = this.ballistics.CalculateTrajectory(
            owner.GetWorldPosition(),
            Vector4.Normalize(target - owner.GetWorldPosition()),
            projData
        );

        // Visualize trajectory for smart weapons
        if (weapon.HasTag("SmartGun") || weapon.HasTag("TechWeapon")) {
            this.VisualizeTrajectory(trajectory);
        }
    }

    // Called from weapon's OnHit
    public final func OnWeaponHit(weapon: ref<WeaponItem>, target: ref<GameObject>, hitData: HitData) -> Void {
        // Determine weapon manufacturer behavior
        let behavior: ref<WeaponBehavior> = this.GetWeaponBehavior(weapon);
        if (IsDefined(behavior)) {
            behavior.OnHit(target, hitData.damageAmount, hitData);
        } else {
            // Fallback to gore system
            let goreData: WeaponGoreData = this.GetGoreDataFromWeapon(weapon);
            this.gore.ApplyGore(target, weapon.GetOwner(), hitData, goreData);
        }
    }

    private final func GetWeaponBehavior(weapon: ref<WeaponItem>) -> ref<WeaponBehavior> {
        if (weapon.HasTag("Arasaka")) { return new ArasakaWeaponBehavior(); }
        if (weapon.HasTag("Militech")) { return new MilitechWeaponBehavior(); }
        if (weapon.HasTag("KangTao")) {
            let b: ref<KangTaoWeaponBehavior> = new KangTaoWeaponBehavior();
            if (weapon.HasTag("Fire")) { b.ElementalMode = n"Fire"; }
            else if (weapon.HasTag("Ice")) { b.ElementalMode = n"Ice"; }
            else if (weapon.HasTag("Shock") || weapon.HasTag("Electrical")) { b.ElementalMode = n"Shock"; }
            return b;
        }
        if (weapon.HasTag("BudgetArms")) { return new BudgetArmsWeaponBehavior(); }
        if (weapon.HasTag("MSN")) {
            let b: ref<MSNWeaponBehavior> = new MSNWeaponBehavior();
            if (weapon.HasTag("Lilith")) { b.WeaponArchetype = n"Lilith"; }
            else if (weapon.HasTag("Ouroboros")) { b.WeaponArchetype = n"Ouroboros"; }
            else if (weapon.HasTag("NGD")) { b.WeaponArchetype = n"NGD"; }
            else if (weapon.HasTag("Lyra")) { b.WeaponArchetype = n"Lyra"; }
            else if (weapon.HasTag("Sephirot")) { b.WeaponArchetype = n"Sephirot"; }
            else { b.WeaponArchetype = n"Reality"; }
            return b;
        }
        return null;
    }

    private final func GetProjectileData(weapon: ref<WeaponItem>) -> ProjectileData {
        // Extract from weapon stats
        return ProjectileData {
            mass = weapon.GetProjectileMass(),
            muzzleVelocity = weapon.GetMuzzleVelocity(),
            dragCoefficient = weapon.GetDragCoefficient(),
            crossSection = weapon.GetCrossSection(),
            penetration = weapon.GetPenetration(),
            fragmentChance = weapon.GetFragmentChance(),
            fragmentCount = weapon.GetFragmentCount(),
            spinRate = weapon.GetSpinRate(),
            maxRange = weapon.GetEffectiveRange()
        };
    }

    private final func GetGoreDataFromWeapon(weapon: ref<WeaponItem>) -> WeaponGoreData {
        // Build from weapon tags/stats
        return WeaponGoreData {
            damageType = weapon.GetDamageType(),
            goreMultiplier = weapon.GetGoreMultiplier(),
            gibChance = weapon.GetGibChance(),
            dismemberChance = weapon.GetDismemberChance(),
            fearRadius = weapon.GetFearRadius(),
            infectionChance = weapon.GetInfectionChance()
        };
    }

    private final func VisualizeTrajectory(trajectory: array<Vector4>) -> Void {
        for (i: Int32 = 0; i < ArraySize(trajectory) - 1; i++) {
            Game.GetDebugVisualizers().DrawLine(trajectory[i], trajectory[i+1], Color(1.0, 0.2, 0.8, 0.5), 0.1);
        }
    }
}