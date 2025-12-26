# WarRoom Draft Roadmap

## Phase 1: Core Realism (1–2 weeks)
- Team profiles: add a `TeamProfile` model (risk, needs weight, trade appetite) and plug into `CpuDraftStrategy`.
- Improved board logic: tiers + BPA vs Need scoring, surfaced in the UI as a simple “value” tag.
- Trade upgrades: positional scarcity + team window; refine `TradeEngine` inputs.
- Draft settings: expose CPU behavior presets and richer trade tuning in setup.

## Phase 2: Depth + Retention (2–4 weeks)
- Persistence upgrades: save full draft history and settings; “resume from pick N”.
- Save & revisit: multi-draft history and “resume from pick X” for iterating scenarios.
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


Signature visual system: define a bold “WarRoom” identity (custom type pairing, gritty texture overlay, subtle film grain, team‑color glow accents). This alone will make the app feel owned instead of generic.
Hero moments: turn key screens into cinematic moments (home hero banner with animated draft ticker; draft room background with subtle motion; recap screen with celebratory reveal and grade “stamp” animation).
Information hierarchy polish: reduce visual noise with bigger section headers, tighter spacing rhythm, and fewer competing accents; introduce consistent “section frames” for pick lists, trade inbox, and recap cards.
Custom micro‑components: replace standard chips, dropdowns, and cards with custom WarRoom UI (badge pills, “pick card” with ticket‑style edge, trade offers styled like contract slips).
Motion design pass: staggered list reveals, gentle shimmer on on‑clock pick, and subtle parallax on background panels; avoid micro‑jitter and use 120–180ms ease‑out transitions.
Refined color language: lean into team colors but add a fixed neutral palette for readability (off‑white, slate, graphite) + controlled accent usage.
Sound + haptics (optional): soft “pick made” click, subtle rumble on trade offer; keeps things engaging without being noisy.
Recap share polish: auto‑layout the recap screenshot into a branded frame with watermark + draft stats badges.


Draft intel layer: team needs heatmap + positional scarcity indicator so users see why a pick makes sense.
Real‑time trade market: trade value meter that reacts to clock pressure and position runs; show win/lose delta.
Live board context: “best available vs. team need” split, plus a contextual “likely pick” band for CPUs.
Storytelling recap: grade by value + fit, and show “steals/reaches” summary with visual callouts.
Scout profiles: add player comps, strengths/weaknesses, and scheme fit tags for decisions beyond rank.
Pick simulator options: “aggressive trades,” “positional runs,” “GM traits,” and custom CPU archetypes.
Shared highlights: auto‑generate a shareable recap image with badges (best pick, biggest steal, favorite team).
Save & revisit: multi‑draft history and “resume from pick X” for iterating scenarios.
