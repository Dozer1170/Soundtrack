# Soundtrack – Future Features

## Immersion / Reactivity

- **Time-of-day music** — WoW has a queryable in-game clock. Play different tracks during day vs. night (or dawn/dusk windows).
- **Weather-based music** — WoW exposes weather effects via `GetWeatherType()`. Add rain, snow, sandstorm, and fog variants per zone.
- **Low-health tension music** — When player HP drops below a threshold (e.g., 20%), escalate to a tension/urgency track.
- **Combat duration escalation** — After X seconds in combat, automatically bump to a higher-tier battle track (normal → elite → boss tier), extending the existing escalation system.
- **Seasonal/holiday music** — Detect in-game holidays via `C_DateAndTime` / `C_Calendar` and layer holiday-specific tracks on top of zone music.

## New Event Types

- **Quest events** — Trigger SFX or music on quest accept, quest completion, and quest failure.
- **Battleground objective events** — Map-specific triggers: flag captured, node captured, boss killed in AV, etc. (via `UPDATE_BATTLEFIELD_SCORE` and related events).
- **Vehicle / possession** — Distinct track when entering a vehicle (`UNIT_ENTERED_VEHICLE`).
- **Fishing** — Detect fishing state (`BOBBER_CAST`, `FISHING_LURE_APPLIED`) and play ambient music while waiting for a bite.
- **Dungeon Finder queue pop** — Play a track when the LFG queue fires (`LFG_PROPOSAL_SHOW`).

## Playback Quality

- **Per-event volume control** — A slider on each event to scale its relative volume (0–100%), since custom MP3s vary wildly in recorded loudness.
- **Crossfade / fade transitions** — Smooth fade-out/fade-in between events instead of abrupt stops, approximated via `SetVolume` on the master channel.
- **Track scheduling modes** — Per event: random, sequential, or *weighted random* (assign play-probability weights per track).
- **Minimum play duration** — Don't interrupt a track that started less than N seconds ago, even if the triggering event changes (prevents rapid skipping during micro zone transitions).

## Profiles & Sharing

- **Profile export / import** — Serialize a profile to a share string (similar to WeakAuras) so users can share setups on forums or Discord.
- **Per-character vs. account-wide profiles** — Let the user choose whether a profile applies only to the current character or to all characters on the account.

## UI / Quality of Life

- **"Now Playing" toast** — Brief on-screen notification showing the track name and the event that triggered it (extending the existing `ShowTrackInformation` setting).
- **Recently played history** — A small log of the last N tracks played, each annotated with the event that caused it.
- **Bulk track assignment** — Select multiple events and assign an entire folder or album to all of them at once.
- **Track preview without assigning** — Play any track from the library browser without committing it to an event.

## Battle System Extensions

- **Solo vs. group battle distinction** — Play a different event when soloing vs. in a party (group size is already available in `GetGroupEnemyClassification`).
- **PvP-specific zone music** — Separate music for *being in a PvP zone* at peace (Wintergrasp, Tol Barad) vs. *actively fighting* there.
- **Boss phase music** — Detect meaningful HP thresholds on boss units (e.g., 50%, 30%) to trigger escalating music phases mid-fight.
