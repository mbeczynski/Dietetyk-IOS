import Foundation

/// Dane NIE-sekretne związane z synchronizacją HealthKit - tak jak `APIConfig`,
/// żyją w `UserDefaults` (nie w Keychain - tu nie ma żadnego sekretu).
enum HealthSyncPreferences {
    private static let enabledKey = "health.sync.enabled"
    private static let lastSyncKey = "health.sync.lastSyncDate"

    /// Czy użytkownik włączył synchronizację HealthKit w Ustawieniach -
    /// kontroluje, czy `DietetykApp`/`HealthSyncService` próbują
    /// automatycznie synchronizować przy starcie/powrocie apki oraz w tle
    /// (HealthKit background delivery).
    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    static var lastSyncDate: Date? {
        get { UserDefaults.standard.object(forKey: lastSyncKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: lastSyncKey) }
    }
}
