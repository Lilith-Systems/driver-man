
module GTC.UI

public class CorruptionHUDController {
    public func UpdatePurityMeter(corruptionLevel: Float) -> Void {
        LogChannel(n"DEBUG", s"Updating HUD Corruption Meter: \(corruptionLevel)");
    }
}
