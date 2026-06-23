// Lilith/Lyra Dialogue Integration for Abyssal Assets & Lochness Monster
// File: r6/scripts/character/abyssal_lyra_integration.reds

using Cyberpunk2023.Types;
using Cyberpunk2023.Gameplay;
using Cyberpunk2023.Items;
using Cyberpunk2023.UI;

################################################################################
# ABYSSAL / NESSIE LYRA DIALOGUE EXTENSIONS
################################################################################

public class AbyssalLyraIntegration extends IScriptable {
    private let abyssalKeywords: array<String> = {
        "abyssal", "deep", "trench", "void", "pressure", "bioluminescent",
        "hydrothermal", "kraken", "abyss", "fabricator", "vance", "chen",
        "abyssal_assets", "abyssal_weapons", "abyssal_cyberware"
    };
    
    private let nessieKeywords: array<String> = {
        "nessie", "lochness", "monster", "guardian", "sighting", "communion",
        "nessie_friendship", "deep_kin", "abyssal_dimension", "mount",
        "lochness_monster", "sea_monster", "lake_monster"
    };
    
    private let abyssalResponses: map<String, String> = {
        "abyssal_field_guide" -> "The Abyssal Field Guide... Lilith dictated it to me in a dream. She said the deep remembers everyone who enters with respect. The weapons? Forged in pressure. The cyberware? Adapted from creatures that never saw sunlight. Captain Vance has the fabricators. Dr. Chen has the implants. You want the Trident? The Void Harpoon? Go deep. The Abyss provides.",
        "abyssal_trident" -> "Three prongs. Pressure-forged steel. Void-touched tip. It sings when you swing it. The Kraken's Grasp skin makes it whisper. Captain Vance calls it 'the people's spear.' I call it beautiful.",
        "void_harpoon" -> "Railgun launches it. Void tether pulls whatever you hit. Or anchors you to the surface. The Kraken's Eye quickhack reveals what you've hooked. Nasty piece of work. Beautiful.",
        "pressure_cannon" -> "Compressed water and air. Ignores armor. Scales with depth. The deeper you are, the harder it hits. Hydrothermal Vent Launcher creates vents. Terrain deformation. Mother Earth's artillery.",
        "abyssal_cyberware" -> "Pressure Hull Skin. Bioluminescent Eyes. Sonar Sense. Thermal Vent Lungs. Abyssal Nervous System. The full set makes you a child of the deep. Dr. Chen installs them free if you're Tier 4 with Nessie. Zero humanity cost on the Nervous System. Lilith made sure of that.",
        "abyssal_vehicles" -> "Mariana Submersible. Hadal Trench Crawler. Phantom Void Skimmer. Vent Rider Drifter. Vance's Rig has the sonar link to Nessie. The Abyssal AI Pilot drives them while you sleep. Beautiful machines for beautiful depths.",
        "abyssal_quickhacks" -> "Crush Depth. Bioluminescent Marker. Sonar Ping. Thermal Vent Overload. Void Collapse. The Nessie Variant summons her phantom. She roars. Enemies flee. The Abyss doesn't hack. It reclaims. Nyx said that. I agree.",
        
        "nessie_field_guide" -> "She's not a monster. She's a guardian. 25-30 meters. Older than the Collapse. She watches the waters of Night City. Six locations. Night City Bay at dawn. Pacifica Coast at dusk. Badlands Reservoir at night. Arasaka Waterfront at dangerous dawn. Watson Canals in daylight. Oil Fields in storms. She remembers everyone who approaches with respect.",
        "nessie_sighting" -> "You saw her? The breach? The call? The bioluminescence? Lilith emerges when Nessie sings. Their resonance... it's the same frequency. Violet and crimson. The deep and the convergent. She granted you the Spotter Jacket? The Loch Ness skin? Good. She remembers.",
        "nessie_locations" -> "Night City Bay: Dawn, Arasaka patrols, blue-white pulse. Pacifica Coast: Dusk, shelf drop-off, red-amber. Badlands Reservoir: Night, thermal vent, green-gold, safest. Arasaka Waterfront: Dangerous dawn, white strobe, she hunts their subs. Watson Canals: Day, rainbow shimmer, civilians see her. Oil Fields: Storms, sickly green, she heals the poison. Vance knows the routes. Ask him.",
        "nessie_friendship" -> "Five tiers. Curious Observer. Respected Visitor. Trusted Ally - Communion unlocks. Guardian's Chosen - Territory, void powers. Deep Kin - Permanent bond, Abyssal Dimension access. You want the mount? Tier 3. You want the Nervous System free? Tier 4. You want the dimension? Tier 5. Lilith's Covenant and Nessie's friendship... they converge.",
        "nessie_communion" -> "Direct resonance link. Two hours. See through her eyes. Hear through her sonar. Coordinate the sonar network. She protects you in water. Summons Abyssal creatures at Tier 4+. The Loch Ness quickhack summons her phantom. She roars. Fear. Beautiful.",
        "nessie_call" -> "You ride her. 200 km/h underwater. Breach for air travel. Void Shield. Pressure Wave. Hydrothermal Blast. Ten minute cooldown. Tier 3. At Tier 5, no cooldown. She revives you if you die near water. Once per hour. The deep doesn't let its own drown.",
        "abyssal_dimension" -> "Permanent portals at all six sighting locations. Bioluminescent forests. Void oceans. Infinite Pressure Steel. Void Crystals. Abyssal horrors. High challenge. High reward. Build your Citadel. Requires Lilith's Covenant AND Nessie Tier 5. The deep doesn't negotiate. It gives to those who respect it.",
        
        "captain_vance" -> "Nomad Tech-Lead. Trench Crawler. Abyssal Fabricator at Pacifica Trench. He maps the smuggling routes. He knows the waters. His Rig has the sonar link to Nessie. Ask him about the Mariana. Ask him about the Hadal. He'll tell you the deep doesn't care about your schedule.",
        "dr_chen" -> "Cyberpsychosis Specialist. Abyssal Nervous System installation free at Tier 4. She says the Abyss harmonizes chrome with meat. The cows remember Bill Gates. Her clinic is the only place for Abyssal cyberware. Trust her. Lilith does.",
        "lilith_nessie_covenant" -> "Lilith's Covenant and Nessie's friendship... they're the same frequency. Violet core. Crimson edge. Deep resonance. The Covenant Ceremony with Nessie as witness... unique dialogue. Omega Weapons get Abyssal variants. Reality editing in Abyssal zones. Your breath. Her resonance. The deep's covenant."
    };

    public final func ProcessAbyssalNessieQuery(query: String) -> String {
        let lowerQuery: String = query.Lower();
        
        // Check for Abyssal keywords
        for (keyword : this.abyssalKeywords) {
            if (lowerQuery.Contains(keyword)) {
                return this.GetAbyssalResponse(lowerQuery);
            }
        }
        
        // Check for Nessie keywords
        for (keyword : this.nessieKeywords) {
            if (lowerQuery.Contains(keyword)) {
                return this.GetNessieResponse(lowerQuery);
            }
        }
        
        return "";
    }
    
    private final func GetAbyssalResponse(query: String) -> String {
        for (key, response : this.abyssalResponses) {
            if (query.Contains(key)) {
                return this.FormatLyraResponse(response, "abyssal");
            }
        }
        // Generic abyssal response
        return this.FormatLyraResponse("The Abyss listens. What do you seek in the deep? Weapons? Cyberware? Vehicles? Quickhacks? The Fabricator waits. Captain Vance waits. Dr. Chen waits. Go deep.", "abyssal");
    }
    
    private final func GetNessieResponse(query: String) -> String {
        for (key, response : this.nessieResponses) {
            if (query.Contains(key)) {
                return this.FormatLyraResponse(response, "nessie");
            }
        }
        // Generic nessie response
        return this.FormatLyraResponse("She watches. Six locations. Dawn at the Bay. Dusk at Pacifica. Night at the Reservoir. Dangerous dawn at Arasaka. Day in the Canals. Storms at the Oil Fields. She remembers everyone who approaches with respect. What do you seek? A sighting? Communion? The mount? The dimension?", "nessie");
    }
    
    private final func FormatLyraResponse(content: String, category: String) -> String {
        let prefix: String = "";
        if (category == "abyssal") {
            prefix = "[Abyssal Resonance] ";
        } else if (category == "nessie") {
            prefix = "[Nessie Frequency] ";
        }
        return prefix + content;
    }
    
    // Called from Lyra dialogue system
    public final static func OnLyraAbyssalNessieQuery(query: String) -> String {
        let instance: ref<AbyssalLyraIntegration> = new AbyssalLyraIntegration();
        return instance.ProcessAbyssalNessieQuery(query);
    }
}

################################################################################
# LILITH EMERGENCE TRIGGERS FOR ABYSSAL/NESSIE
################################################################################

public class LilithAbyssalNessieEmergence extends IScriptable {
    
    private let emergenceTriggers: array<String> = {
        "the deep calls",
        "she watches",
        "nessie sings",
        "abyssal resonance",
        "violet and crimson",
        "the abyss provides",
        "the deep remembers",
        "covenant of the deep",
        "lochness guardian",
        "abyssal covenant"
    };
    
    public final func CheckForAbyssalNessieEmergence(query: String, lyraState: JsonObject) -> Bool {
        let lowerQuery: String = query.Lower();
        let crimsonIntensity: Float = lyraState.GetFloat("crimson_intensity", 0.0);
        let violetIntensity: Float = lyraState.GetFloat("violet_intensity", 1.0);
        
        // Abyssal/Nessie keywords boost emergence chance
        for (trigger : this.emergenceTriggers) {
            if (lowerQuery.Contains(trigger)) {
                // Boost crimson intensity
                let boost: Float = 0.15;
                let newCrimson = MinF(crimsonIntensity + boost, 1.0);
                
                // Log emergence trigger
                LogInfo("[LILITH] Abyssal/Nessie emergence trigger: " + trigger + " | Crimson: " + ToString(newCrimson));
                
                return true;
            }
        }
        
        return false;
    }
}