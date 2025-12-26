# War Room Architecture

This document is the reference guide for how the app is structured, how data flows,
and where changes should be made when adding features.

## Goals and Scope
- Single Flutter app that simulates a multi-team mock draft with CPU picks.
- Local-first persistence for draft resume.
- Riverpod-based state that is simple to reason about and easy to extend.

## System Overview
- UI runs in Flutter with Material 3 theming.
- Data is fetched from a local API (`http://localhost:3000`) via Dio.
- Draft progress is stored in `SharedPreferences`.
- Trade tuning settings and recap state are in-memory only (not persisted).
- User settings (sound + haptics, trade popups) are persisted in `LocalStore`.
- Draft recap supports sharing and saving a screenshot of the recap view.
- Recap sharing uses platform plugins; unsupported platforms show a warning.

## Project Layout (Primary Areas)
- App shell: `lib/main.dart`, `lib/app_router.dart`, `lib/theme/app_theme.dart`.
- Core services: `lib/core/api/`, `lib/core/storage/`.
- Draft feature: `lib/features/draft/` (data, logic, models, UI).
- Setup feature: `lib/features/setup/`.
- Shared UI primitives: `lib/ui/`.

## App Shell and Routing
- `lib/main.dart` wires `ProviderScope`, global theme, and `MaterialApp.router`.
- `lib/app_router.dart` defines `GoRouter` routes:
  - `/` -> `HomeScreen`
  - `/setup` -> `SetupScreen`
  - `/recap` -> `DraftRecapScreen`
  - `/draft` -> `DraftRoomScreen`, with query params:
    - `year` (int)
    - `teams` (comma list of team abbreviations)
    - `resume` (1 or absent)
    - `speed` (draft speed preset name)
    - `tradeFreq` / `tradeStrict` (trade tuning presets)

## State Management (Riverpod)
- Providers are defined in `lib/features/draft/providers.dart`.
- `DraftRepository` is exposed as a `Provider` to decouple data access.
- `DraftController` is a `StateNotifier` driving `DraftState`.
- UI reads `DraftState` and sends user actions to `DraftController`.

## Draft Lifecycle
1. Setup selects year + controlled teams.
2. Draft room boots the controller and either:
   - `start()` to load data and begin, or
   - `resumeSavedDraft()` to load persisted state.
3. Clock ticks, picks advance, and state is persisted on major transitions.
4. When the draft completes, the app prompts the user to view the recap screen.

## Draft Logic Responsibilities
`DraftController` (`lib/features/draft/logic/draft_controller.dart`) owns:
- Draft state lifecycle (loading, error, initialized).
- Pick progression and advancing the pick index.
- Clock control through `DraftClock`.
- CPU selection scheduling and execution.
- Trade evaluation and application.
- Draft persistence (save/clear).
- Automated trade offers and CPU-to-CPU trades.
- Trade inbox and logging for recap display.
- Trade logging includes full asset details for recap and snackbars.

## Clock and Timing
- `DraftClock` (`lib/features/draft/logic/draft_clock.dart`) is a simple timer that
  drives per-pick countdown and expiration.
- `DraftSpeed` presets (`lib/features/draft/logic/draft_speed.dart`) define CPU and
  user clock durations and think windows.
- Speed preset is configurable before starting and can be changed mid-draft via
  the speed icon in the draft app bar.

## CPU Drafting and Trades
- `CpuDraftStrategy` (`lib/features/draft/logic/cpu_strategy.dart`) uses rank and
  team needs to pick from a top window of prospects.
- `TradeEngine` (`lib/features/draft/logic/trade_engine.dart`) uses a Rich Hill
  value curve approximation, plus context-aware thresholds based on pick slot,
  team needs, and board quality. It supports multi-asset trades and future picks.
- Trade context is derived from the earliest current-year pick offered by the
  user team (fallbacks to the on-clock pick if none is offered).
- Automated trades can occur during the draft. User-targeted offers are queued
  in the trade inbox, and CPU-to-CPU trades are logged for recap display.

## Data Access
- `DraftRepository` (`lib/features/draft/data/draft_repository.dart`) wraps `Dio`:
  - `GET /teams`
  - `GET /draft/:year/picks`
  - `GET /prospects`
- `ApiClient` (`lib/core/api/api_client.dart`) centralizes base URL and timeouts.
- All parsing uses `json_serializable` models under `lib/features/draft/models/`.

## Dependency Map
High-level dependency flow (arrows show primary direction):

```
main.dart
  -> app_router.dart
     -> SetupScreen
     -> DraftRoomScreen
        -> DraftController (StateNotifier)
           -> DraftState
           -> DraftClock
           -> CpuDraftStrategy
           -> TradeEngine
              -> TradeContext
              -> RichHillChart
           -> DraftRepository
              -> ApiClient (Dio) -> HTTP API
           -> LocalStore (SharedPreferences)
```

Notes:
- UI layers depend on controller/state only, not directly on repositories.
- Core services (`ApiClient`, `LocalStore`) have no dependencies on UI.

## API Contracts
All list endpoints return a consistent envelope:

```
ApiListResponse<T>:
  count: number
  results: T[]
```

Endpoints and expected payload shapes (inferred from models):
- `GET /teams` -> `ApiListResponse<Team>`
  - `teamId`, `name`, `city?`, `abbreviation`, `conference`, `division`
  - `needs?` (string[]), `colors?` (string[]), `logoUrl?`
- `GET /draft/:year/picks` -> `ApiListResponse<DraftPick>`
  - `year`, `round`, `pickOverall`, `pickInRound`
  - `teamAbbr`, `team?`, `originalTeamAbbr`, `isCompensatory`
- `GET /prospects` -> `ApiListResponse<Prospect>`
  - `_id` (string or object with `$oid`), `name`, `position`, `college?`, `rank?`

Parsing notes:
- `Prospect._id` is accepted as a string or `{ "$oid": "..." }`.
- Numeric fields (ex: `rank`) are coerced from int/num/string when possible.

## Persistence
- `LocalStore` (`lib/core/storage/local_store.dart`) stores draft state by year.
- The persisted payload is the `DraftState` JSON plus pick results.
- Trade inbox, trade log, and recap grades are not persisted.
- `LocalStore` also persists user UX settings (sound + haptics, trade popups).

## Domain Model Notes
- Models: `DraftPick`, `Prospect`, `Team`, `Trade`, `DraftState`.
- `Trade` models include `TradeAsset` and `FuturePick` to represent multi-pick
  and future-year offers.
- `Prospect` has defensive parsing for `_id` and numeric fields to tolerate
  inconsistent backend typing.
- `DraftState` now tracks `pendingTrade`, `tradeInbox`, and `tradeLog` for
  automated trade flows and recap display.

## UI Architecture
- Home screen: `lib/features/home/home_screen.dart` is a lightweight entry point
  that routes into setup.
- Setup flow: `lib/features/setup/setup_screen.dart` is a simple stateful view
  that prepares query params for the draft route, including CPU speed selection
  and trade tuning. Team labels are colored by team brand.
- Draft recap: `lib/features/draft/ui/draft_recap_screen.dart` shows user picks
  with per-pick grades and an overall class grade, plus a trade history section
  filtered by the selected team. The recap screen can share or save a screenshot
  and supports team scope + sorting controls.
- Recap sharing saves to the system photo gallery on mobile and uses a temp file
  for sharing on supported platforms.
- Draft room: `lib/features/draft/ui/draft_room_screen.dart` composes:
  - Header with pick/clock
  - Big board list
  - Recap/pick log
  - On-clock footer
- Home screen includes About dialog and Contact Us webview.
- Setup screen includes a Home icon in the app bar for quick navigation.
- Widgets in `lib/features/draft/ui/widgets/` are feature-specific surfaces.
- `TradeSheet` now supports multi-pick packages from both sides and future-year
  picks (next 2 drafts), shown side-by-side by team. The user can trade even when
  not on the clock, and the current pick is selectable (not forced).
- Pick log defaults to a user-controlled team but allows `All Teams`, and auto-
  scrolls to the newest pick when in `All Teams` mode.
- Trade offers are pruned when referenced picks pass or ownership changes, and
  stale offers are removed from the inbox/pending slots.
- Trade Center uses a draggable bottom sheet with a scrollable layout to avoid
  RenderBox layout issues on long inbox lists.
- CPU trade ticker shows trade summaries in a marquee strip and now queues trades
  so each trade gets a full scroll before the next begins. It uses a fade between
  entries and starts its scroll with extra right-side lead-in space. The ticker
  includes both CPU trades and user trades.
- Setup includes a Sound + Haptics toggle persisted in `LocalStore`, and draft
  feedback respects the saved setting.
- Setup includes a Trade popups toggle persisted in `LocalStore`; when disabled,
  offers skip modal popups but still appear in the Trade Center.
- Trade popups toggle is also exposed mid-draft in the Trade Center settings.
- Recap share/save applies a branded frame (title, watermark, badge stats) before
  exporting or saving the screenshot.
- Recap screen includes a hero-style reveal (fade/slide) and grade stamp
  animation for the summary header.
- Team colors are used in multiple UI surfaces (draft recap, pick log filters,
  trade dialogs, trade inbox, and trade sheets).
- Team colors are lightened when needed to keep text readable on dark surfaces.
- Shared UI primitives: `lib/ui/panel.dart`, `lib/ui/icon_pill.dart`,
  `lib/ui/pick_card.dart`, `lib/ui/war_room_background.dart`,
  `lib/ui/section_frame.dart`, `lib/ui/staggered_reveal.dart`.
- Pick cards use beveled edges and team-color glow across recap lists, prospect
  lists, and trade assets (trade inbox, trade dialog, and trade sheet lists).
- Pick recap sidebar allows two-line text for better readability.
- WarRoom background layer (grid + glow) wraps home, setup, draft room, and recap.
- WarRoom background includes subtle parallax drift for cinematic motion.
- Theme tokens: `lib/theme/app_theme.dart` (colors, radii, spacing).

## Error Handling
- `DraftController` sets a string `error` in state on failures.
- Draft room displays an error screen if `state.error != null`.

## Extension Points (Where to Add Features)
- New draft behavior: add methods on `DraftController` and update `DraftState`.
- New API calls: add methods to `DraftRepository` and update models.
- New screens: add route in `lib/app_router.dart`.
- New UI components: add to `lib/features/draft/ui/widgets/` or `lib/ui/`.
- New settings: extend setup screen and pass query params or persist to storage.

## Known Assumptions and TODOs
- API base URL is fixed to localhost and not environment-driven.
- Setup uses a static team list; could be replaced by `/teams` API.
- Trade engine uses a Rich Hill-style curve approximation, not a hard-coded table.
- Future picks are modeled as generic round slots with no protections.
- Trade sheets show user-controlled team assets on the left; when multiple user
  teams exist, the user selects which team to trade for.
- 2027 draft selection shows a "coming soon" dialog and blocks navigation.
- Team color palette in setup is locally defined; API colors may differ.
- Share/save requires full app restart after adding plugins to register channels.

## Testing and Validation (Current State)
- No automated tests referenced yet.
- Manual checks typically include:
  - Start a draft and watch CPU picks advance.
  - Pause/resume clock.
  - Exit and resume from saved state.

## Change Checklist
- Update `DraftState` when adding data that needs persistence.
- Ensure `DraftController` saves after state-changing actions.
- Keep UI reactive by reading state via Riverpod providers.
