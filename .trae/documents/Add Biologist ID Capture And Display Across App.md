## Goals
- Prompt for Biologist ID the first time a sample is analyzed; prefill with last used ID.
- Store Biologist ID per sample in the database.
- Show Biologist ID on Home, Sample List, and include in Export CSV.
- Keep last Biologist ID in preferences for convenience.

## Database & Models
- Add column `biologistId TEXT` to `sample` table via migration in `lib/data/db.dart` (`_ensureSchema`): add column if missing.
- Extend `Sample` model in `lib/data/models.dart` with `final String? biologistId`, update `toMap/fromMap`.
- Update `SampleDao` (insert/update queries) to handle `biologistId` (file: `lib/data/dao/sample_dao.dart`).

## App State & Preferences
- In `lib/core/app_state.dart`:
  - Track and expose `activeSample.biologistId`.
  - Add helpers to update just `biologistId` for a sample.
- Use `SharedPreferences` to remember `lastBiologistId`:
  - Read on app start; provide as default when prompting.
  - Update when user enters a new Biologist ID.

## Analysis Page Prompt
- In `lib/ui/analysis/analysis_page.dart`:
  - On load, if `activeSample.biologistId` is null/empty, show an `AlertDialog` to input Biologist ID.
  - Prefill with `lastBiologistId` from preferences.
  - On confirm:
    - Save to DB via AppState (updateSample with new `biologistId`).
    - Persist `lastBiologistId` to preferences.
    - Proceed with analysis UI.

## UI Display
- Home `Sample Status` table (`lib/ui/home/home_page.dart`):
  - Add a `Biologist` column showing `sample.biologistId`.
- Sample List (`lib/ui/sample_list/sample_list_page.dart`):
  - Add a column or badge for `Biologist`.
- Sample Info page (`lib/ui/sample_info/sample_info_page.dart`):
  - Optional input field to view/edit `Biologist ID` (non-mandatory; analysis prompt covers first entry).

## Export CSV
- In `lib/core/app_state.dart` export functions:
  - Add header `BiologistID` after `ClientID`.
  - Populate with `sample.biologistId` for each exported row.

## Validation
- Create a new sample; open Analysis → prompt appears → enter ID.
- Confirm Home and Sample List show Biologist.
- Export CSV contains `BiologistID` column with values.
- Start another sample → prompt shows last used Biologist ID as default.

## Notes
- Migration ensures backward compatibility; existing samples get `biologistId = null` until set.
- Prefill logic improves speed for repeated analyses by the same biologist.

Please confirm the plan. Upon approval, I will implement DB migration, model/DAO changes, the Analysis prompt, UI displays, and export updates, then validate on your device.