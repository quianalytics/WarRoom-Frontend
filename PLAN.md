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

## Project Layout (Primary Areas)
- App shell: `lib/main.dart`, `lib/app_router.dart`, `lib/theme/app_theme.dart`.
- Core services: `lib/core/api/`, `lib/core/storage/`.
- Draft feature: `lib/features/draft/` (data, logic, models, UI).
- Setup feature: `lib/features/setup/`.
- Shared UI primitives: `lib/ui/`.

## App Shell and Routing
- `lib/main.dart` wires `ProviderScope`, global theme, and `MaterialApp.router`.
- `lib/app_router.dart` defines `GoRouter` routes:
  - `/` -> `SetupScreen`
  - `/draft` -> `DraftRoomScreen`, with query params:
    - `year` (int)
    - `teams` (comma list of team abbreviations)
    - `resume` (1 or absent)

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

## Draft Logic Responsibilities
`DraftController` (`lib/features/draft/logic/draft_controller.dart`) owns:
- Draft state lifecycle (loading, error, initialized).
- Pick progression and advancing the pick index.
- Clock control through `DraftClock`.
- CPU selection scheduling and execution.
- Trade evaluation and application.
- Draft persistence (save/clear).

## Clock and Timing
- `DraftClock` (`lib/features/draft/logic/draft_clock.dart`) is a simple timer that
  drives per-pick countdown and expiration.
- `DraftSpeed` presets (`lib/features/draft/logic/draft_speed.dart`) define CPU and
  user clock durations and think windows.

## CPU Drafting and Trades
- `CpuDraftStrategy` (`lib/features/draft/logic/cpu_strategy.dart`) uses rank and
  team needs to pick from a top window of prospects.
- `TradeEngine` (`lib/features/draft/logic/trade_engine.dart`) uses a Rich Hill
  value curve approximation, plus context-aware thresholds based on pick slot,
  team needs, and board quality. It supports multi-asset trades and future picks.
- Trade context is derived from the earliest current-year pick offered by the
  user team (fallbacks to the on-clock pick if none is offered).

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

## Domain Model Notes
- Models: `DraftPick`, `Prospect`, `Team`, `Trade`, `DraftState`.
- `Trade` models include `TradeAsset` and `FuturePick` to represent multi-pick
  and future-year offers.
- `Prospect` has defensive parsing for `_id` and numeric fields to tolerate
  inconsistent backend typing.

## UI Architecture
- Setup flow: `lib/features/setup/setup_screen.dart` is a simple stateful view
  that prepares query params for the draft route.
- Draft room: `lib/features/draft/ui/draft_room_screen.dart` composes:
  - Header with pick/clock
  - Big board list
  - Recap/pick log
  - On-clock footer
- Widgets in `lib/features/draft/ui/widgets/` are feature-specific surfaces.
- `TradeSheet` now supports multi-pick packages from both sides and future-year
  picks (next 2 drafts), shown side-by-side by team. The user can trade even when
  not on the clock, and the current pick is selectable (not forced).
- Shared UI primitives: `lib/ui/panel.dart`, `lib/ui/icon_pill.dart`.
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
