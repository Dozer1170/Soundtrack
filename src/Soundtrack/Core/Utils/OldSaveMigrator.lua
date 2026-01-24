
function Soundtrack.MigrateFromOldSavedVariables()
    if Soundtrack_Settings then
        SoundtrackAddon.db.profile.settings = Soundtrack_Settings
        Soundtrack_Settings = nil
    end

    if Soundtrack_Events then
        SoundtrackAddon.db.profile.events = Soundtrack_Events
        Soundtrack_Events = nil
    end
end