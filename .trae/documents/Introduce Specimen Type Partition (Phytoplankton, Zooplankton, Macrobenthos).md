## Goal
Partition the app by specimen type (Phytoplankton, Zooplankton, Macrobenthos) so samples, registration, analysis, lists and exports are type-specific and never mixed.

## Data Model & DB
- Add `Sample.sampleType` (enum as string: `Phytoplankton|Zooplankton|Macrobenthos`).
- Add `Taxon.specimenType` (same enum string) to segregate each taxonomy tree by type.
- Migration (SQLite):
  - `ALTER TABLE sample ADD COLUMN sampleType TEXT` (default to `Macrobenthos` for existing rows).
  - `ALTER TABLE taxon ADD COLUMN specimenType TEXT` (default to `Macrobenthos` for existing rows).
  - Add indexes: `idx_sample_type` on `sample(sampleType)` and `idx_taxon_type` on `taxon(specimenType)`.
- Models:
  - `lib/data/models.dart`: add `sampleType` to `Sample` and `specimenType` to `Taxon`, plus mapping in `toMap/fromMap`.

## State Management
- `lib/core/app_state.dart`:
  - Track `activeSample.sampleType`.
  - Load `taxa` filtered by `specimenType == activeSample.sampleType`.
  - When active sample changes, reload taxa accordingly.
  - Ensure count operations reference the filtered taxa; existing `count_record` remains valid as it links `sampleId` and `taxonId`.

## DAOs
- `lib/data/dao/sample_dao.dart`:
  - Read/write `sampleType` in `insertSample`, `updateSample`, `getAllSamples`, `getSamplesWithCounts`, filters.
- `lib/data/dao/taxon_dao.dart`:
  - Add methods to get taxa by `specimenType`.
  - `upsertTaxon` accepts optional `specimenType` and sets it.
- `lib/data/dao/count_dao.dart`:
  - No schema change; validate joins when showing counts to filter by taxa list for type.

## Sample Info (UI)
- `lib/ui/sample_info/sample_info_page.dart`:
  - After Sample ID input, add a `DropdownButtonFormField<String>` for Sample Type with options: Phytoplankton, Zooplankton, Macrobenthos (default Macrobenthos).
  - Persist the chosen type in the created/updated `Sample`.

## Registration (UI)
- `lib/ui/registration/registration_page.dart`:
  - In view mode, show only taxa whose `specimenType == activeSample.sampleType`.
  - In edit mode, same filter; creation/edit/import operations set/retain `specimenType` of active sample type.
  - CSV import/export:
    - Extend import header to optionally include `SpecimenType`. If absent, use the active sample type.
    - Export includes `SpecimenType` column.
  - Delete (selected/all) affects only the active type subset.

## Analysis (UI)
- `lib/ui/analysis/analysis_page.dart`:
  - Show only taxa for `activeSample.sampleType` (we already switched to leaf-only view; now filter by type as well).
  - Counting uses the filtered taxa; totals unaffected.

## Home Page & Sample List
- `lib/ui/home/home_page.dart`:
  - In Sample Status table, add `Type` column after Date or before Client.
- `lib/ui/sample_list/sample_list_page.dart`:
  - Show a small chip/badge with the sample type in each card’s subtitle.
  - Optional filter by type (dropdown).

## Export Page
- `lib/ui/export/export_page.dart`:
  - Add a `Type` selector (All/Each type).
  - When exporting by client/date range, include type in the CSV and filter by selected type if set.

## Validation & UX
- Enforce sample type selection (required) in Sample Info.
- Registration page disabled when no active sample or sample type is not selected.
- Import warns if `SpecimenType` in CSV does not match active sample type; allow forced replace with a confirmation.

## Implementation Steps
1. DB migration: add columns, indexes; set defaults for existing rows.
2. Models: update `Sample`, `Taxon` mappings.
3. DAOs: add type-aware queries/updates.
4. AppState: filter `taxa` on active type; reload logic.
5. Sample Info: add type selector and persist.
6. Registration: filter by type; import/export set/use type; delete uses current type.
7. Analysis: filter taxa by type.
8. Home/Sample List: show type in tables/cards; optional filter.
9. Export: add type filter; include type in CSV.
10. Basic tests: create samples per type, verify registration isolation, counting isolation, export output.

## Deliverables
- Code changes across data layer, state, and UI pages per the files listed above.
- Migration script that safely adds new columns without data loss.
- Updated CSV import/export formats.

## Confirmation
Shall I proceed to implement the above changes and deliver a tested build with the new specimen type flow?