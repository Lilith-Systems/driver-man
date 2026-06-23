# Cyberpunk 2077 Mod Build Report

## `msn_integration`
- **Location:** `~/.local/share/Steam/steamapps/common/Cyberpunk 2077/r6/mods/msn_integration`
- **Action:** Executed `WolvenKit.CLI build` using the existing `msn_integration.cpmodproj`.
- **Result:** Successfully built and packed.
- **Output Archive:** `packed/archive/pc/mod/msn_integration.archive`

## `MSNWeaponOverhaul`
- **Location:** `~/.local/share/Steam/steamapps/common/Cyberpunk 2077/r6/mods/MSNWeaponOverhaul`
- **Action:** Created `MSNWeaponOverhaul.cpmodproj` and an empty `source/resources` folder to prevent build errors. Executed `WolvenKit.CLI build`.
- **Result:** Successfully built and packed.
- **Output Archive:** `packed/archive/pc/mod/MSNWeaponOverhaul.archive`

Both mods are now fully compiled and packed into `.archive` files using the WolvenKit CLI!
