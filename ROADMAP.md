# WarRoom Draft Roadmap

## Phase 1: Core Realism (1–2 weeks)
- Team profiles: add a `TeamProfile` model (risk, needs weight, trade appetite) and plug into `CpuDraftStrategy`.
- Improved board logic: tiers + BPA vs Need scoring, surfaced in the UI as a simple “value” tag.
- Trade upgrades: positional scarcity + team window; refine `TradeEngine` inputs.
- Draft settings: expose CPU behavior presets and richer trade tuning in setup.

## Phase 2: Depth + Retention (2–4 weeks)
- Persistence upgrades: save full draft history and settings; “resume from pick N”.
- Analytics layer: reach/steal indicator, alternate pick outcomes, and value delta.
- Recap expansion: team summaries, best value picks, and shareable cards.

## Phase 3: Social + Polish (4–8 weeks)
- Multiplayer hot-seat: multiple users control teams in one session.
- Online co-op (optional): real-time draft rooms with invite links.
- Broadcast mode: pick announcements, animations, ticker, and team branding.

## Phase 4: Advanced Realism (8+ weeks)
- Scouting intel system: injuries/buzz/late risers with CPU reaction.
- Conditional/protected picks and future-year pick modeling.
- Cap/contract context feeding into trade logic.


Real scouting board + intel: prospect tiers, rumors, injury flags, and “buzz” that moves by week; CPU responds to news.
Team‑specific draft profiles: each team gets a behavior model (risk tolerance, positional priorities, trade‑up tendency).
Smarter trade engine: pick value + positional scarcity + cap/contract context + competitive window; trade down chains.
Live analytics: BPA vs Need meter, reach/steal indicator, and “alternate pick outcomes” (who else was likely).
Multi‑user/GM mode: hot‑seat or online co‑op; allow friends to control teams live.
Realistic draft board: comp picks, traded future picks, draft‑day trades, and conditional pick protections.
Full recap package: grades, best value picks, team summaries, and shareable cards.
Customizable speed & auto‑draft: user‑defined timers, “pause on offers”, and auto‑pick AI tuned per team.
Persistence + export: save/load drafts, export CSV/JSON, and “resume from any pick” mode.
Visual polish: dynamic theming by team, draft‑day broadcast mode, and animated pick announcements.
