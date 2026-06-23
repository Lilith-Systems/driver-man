// GRAND THEFT CYBERPUNK - STAR WARS/JEDI COMPATIBILITY WRAPPER
// The older StarWarsSystem entry point now delegates to MSNJediSystem.
// Item, holocron, and saber records are data-only in tweakdb/msn_magic_jedi.tweakdb.

public class StarWarsSystem extends IScriptable {
    private static let instance: ref<StarWarsSystem>;
    private let initialized: Bool;

    public final static func GetInstance() -> ref<StarWarsSystem> {
        if (!IsDefined(StarWarsSystem.instance)) {
            StarWarsSystem.instance = new StarWarsSystem();
            StarWarsSystem.instance.Initialize();
        };
        return StarWarsSystem.instance;
    }

    private final func Initialize() -> Void {
        if (this.initialized) {
            return;
        };
        this.initialized = true;
        MSNJediSystem.GetInstance();
        LogInfo("[StarWarsSystem] compatibility wrapper online; delegated to MSNJediSystem");
    }

    public final func InitializeForceUser(entity: ref<Entity>, alignment: CName) -> Void {
        let jedi: ref<MSNJediSystem> = MSNJediSystem.GetInstance();
        jedi.SetAlignment(alignment);
    }

    public final func UseForcePower(powerName: CName) -> Bool {
        let jedi: ref<MSNJediSystem> = MSNJediSystem.GetInstance();
        return jedi.UsePower(powerName);
    }

    public final func ToggleLightsaber(user: ref<Entity>) -> Bool {
        let jedi: ref<MSNJediSystem> = MSNJediSystem.GetInstance();
        return jedi.UsePower(n"SaberFormShiiCho");
    }

    public final func ChangeLightsaberForm(user: ref<Entity>, form: CName) -> Void {
        let jedi: ref<MSNJediSystem> = MSNJediSystem.GetInstance();
        jedi.UsePower(form);
    }

    @Command("msn.starwars.status")
    public final func CmdStarWarsStatus() -> Void {
        let jedi: ref<MSNJediSystem> = MSNJediSystem.GetInstance();
        Game.GetUIManager().ShowNotification("MSN Star Wars compatibility: " + jedi.GetStatus());
    }
}

public class ForceSensitivityCerebellum extends IScriptable {
    @Property() public let alignmentBias: CName = n"Grey";

    public final func OnInstall(entity: ref<Entity>) -> Void {
        let sw: ref<StarWarsSystem> = StarWarsSystem.GetInstance();
        sw.InitializeForceUser(entity, this.alignmentBias);
    }
}
