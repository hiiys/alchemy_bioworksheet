## Objectives
- Fix duplicate taxa on Analysis with minimal changes.
- Implement CSV export that saves to `Documents/macrobenthos` and shares via WhatsApp/email.
- Add Export Page features: client and date range selection, expected filename preview, and a progress spinner.
- Support “each client has their own sample list” with minimal schema change.
- Implement taxa CSV import respecting rank order (Phylum required; others optional).
- Add a lightweight password gate for Sample Registration.

## Minimal-Change Approach
- Avoid large restructures; keep Provider/Sqflite architecture intact.
- Prefer UI/state fixes over heavy DB constraints.

## Analysis Dedup (UI + State)
- State: modify `AppState._loadCurrentCounts` to aggregate duplicate `count_record` rows by `(sampleId, taxonId)` so totals are correct.
- UI: update `AppState.currentChildren` and Analysis grid/search to deduplicate children by lowercase `name` at each level, and sort alphabetically.
- Optional DAO helper `getChildrenDistinctByName(parentId)` to reduce in-memory work (no schema change needed).

## CSV Export, Save, and Share
- Build rows from `CountDao.getCountsWithTaxa` and compute full taxon path (Phylum→Species) by walking parents.
- Save CSV under a created `macrobenthos` subfolder within app documents via `path_provider`.
- Share using system share sheet via `share_plus` for WhatsApp/email.

## Export Page Enhancements
- Add an Export page with:
  - Client selector and Start/End date pickers.
  - Filename preview before processing (e.g., `client_<Client>_<YYYYMMDD-YYYYMMDD>.csv`).
  - Rotating wheel (circular progress indicator) while exporting; disable actions; show success path and share button.
  - If multiple files per-sample are generated in range, list filenames.

## Clients Per Sample (Minimal Schema Change)
- Add `client TEXT` column to `sample` via migration.
- When creating a sample, set `sample.client = currentProject.client`.
- Sample List: filter/group by `sample.client`; display client on cards.
- Export filters use `sample.client` and `sample.date` for range.

## Taxa CSV Import
- Implement in Registration page:
  - Expect CSV where each column is a specimen and rows are ranks: `Phylum, Class, Order, Family, Genus, Species`.
  - Validate that `Phylum` is present; others optional.
  - For each column, upsert the hierarchical path using existing `taxon` table; avoid duplicates by checking existing `(parentId, name)`.
  - Show import preview and summary of created vs reused taxa.

## Password Gate (Lightweight)
- Store a PIN hash in `SharedPreferences`.
- Add a small `AccessGate` screen that intercepts navigation to Sample Registration; prompt for PIN.
- Settings dialog to set/change PIN.

## Migrations (Safe, Minimal)
- Implement `onUpgrade` to:
  - Add `client` column to `sample`.
  - Optionally create non-unique indexes for performance.
  - No disruptive uniqueness constraints; rely on UI/state dedup and aggregation.

## Files To Update
- `lib/core/app_state.dart` — counts aggregation; children dedup; export helpers.
- `lib/ui/analysis/analysis_page.dart` — dedup rendering; sorting; export action.
- `lib/ui/export/export_page.dart` — new minimal page following existing patterns.
- `lib/ui/sample_info/sample_info_page.dart` — client field; route gate hook.
- `lib/ui/sample_list/sample_list_page.dart` — client filter/grouping; export action.
- `lib/ui/registration/registration_page.dart` — CSV import implementation.
- `lib/core/routing.dart` — add Export and AccessGate routes.
- `lib/data/db.dart` — add `client` column; `onUpgrade`.
- `lib/data/dao/sample_dao.dart` — include `client` in CRUD; add filters.

## Dependencies
- `share_plus` for sharing CSV.
- `shared_preferences` for PIN.
- Optional `csv` for parsing/writing; can implement simple parsing manually to stay lean.

## Verification
- Unit tests: counts aggregation, CSV export correctness, CSV import parsing, sample filters by client.
- Manual E2E: create client/project → sample → count in Analysis (no duplicates shown) → export with preview and spinner → share; verify file on disk; password gate enforcement.

## Milestones
1) Counts aggregation + UI dedup.
2) Export core (save + share) + Export page features.
3) Add `client` to Sample + UI filters.
4) CSV import.
5) Password gate.
6) UI polish + tests.

On approval, I will implement these minimal refinements and verify end-to-end.