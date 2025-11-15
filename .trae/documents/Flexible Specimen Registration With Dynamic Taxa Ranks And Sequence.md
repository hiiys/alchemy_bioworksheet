## Goals
- Allow CSV imports with additional rank columns beyond Phylum, Class, Order, Family, Genus, Species, and use them in registration and analysis.
- Support manual addition of a new rank via a “New Taxa” button with a Sequence Number, Rank Name (Taxa), and an optional Specimen value.
- Maintain rank order using a Sequence that can insert at any position; push existing ranks back and re-sort columns by Sequence.
- Keep data partitioned by specimen type (Phytoplankton, Zooplankton, Macrobenthos).

## Database Changes
- Create table `rank_definition` to drive dynamic ranks per specimen type:
  - Columns: `id INTEGER PK`, `specimenType TEXT`, `name TEXT`, `sequence INTEGER`.
  - Unique index `(specimenType, name)`, index `(specimenType, sequence)`.
- Seed defaults for each specimen type: Phylum(1), Class(2), Order(3), Family(4), Genus(5), Species(6).
- Keep `taxon.rank` as the rank name string; validation will reference `rank_definition`.

## DAO Additions/Updates
- Add `RankDefinitionDao`:
  - `getRanksByType(specimenType): List<RankDefinition>` ordered by `sequence`.
  - `insertRank(specimenType, name, sequence)` with logic to increment existing ranks where `sequence >= N`.
  - `ensureRank(specimenType, name)` appends at end if missing.
  - `reorderRank(specimenType, name, newSequence)` updates sequences accordingly.
- Update `TaxonDao`:
  - Validate `rank` exists in `rank_definition` for the given `specimenType` before insert/update (soft validation).
  - Keep `upsertTaxon` behavior unchanged for hierarchy creation.

## Registration UI
- Replace fixed column list with dynamic ranks:
  - Load rank list via `RankDefinitionDao.getRanksByType(_viewSpecimenType)`.
  - Build table columns in `sequence` order; rows show values per rank.
- Add "New Taxa" action (visible in modify mode):
  - Dialog fields: `Sequence Number` (int), `Taxa (Rank Name)` (string), `Specimen` (optional string).
  - On confirm:
    - Insert the rank into `rank_definition` at the chosen sequence, pushing subsequent ranks by +1.
    - If `Specimen` is provided, create a new leaf taxon under this rank as a top-level entry (other ranks can be blank), scoped to `_viewSpecimenType`.
    - Refresh columns and data; columns sorted by `sequence`.
- Manual registration dialog and cell editing:
  - Use dynamic rank list; only insert ranks with non-empty values; blank ranks allowed.

## CSV Import
- Accept any headers; case-insensitive mapping to ranks.
- For headers unknown to current `rank_definition`, append new ranks at the end (or prompt if we need ordering; default is append).
- Construct hierarchy per row by iterating headers in `rank_definition.sequence` order and creating/upserting nodes for non-empty cells.
- Remove the hard requirement for `Phylum`; require at least one non-empty rank.
- Scope imported taxa by active sample’s `specimenType`.

## Analysis
- Use taxonomy ancestry generically; no fixed rank assumptions.
- Where column display is needed (e.g., box or details), read `rank_definition` for the current type to label/organize.

## Export (Optional Phase)
- Update CSV export to output dynamic headers from `rank_definition` for the selected type.
- Populate cells using `getTaxonAncestry` mapped to dynamic ranks.
- Filenames remain type-reflective as implemented.

## Backward Compatibility
- Existing data remains valid; default rank definitions match the current six ranks.
- New ranks apply per specimen type only; no cross-type mixing.
- UI gracefully shows blanks for ranks not set.

## Validation
- Unit/manual checks:
  - Add a new rank at sequence 3 and verify columns shift/reorder.
  - Import a CSV with an extra column (e.g., “Suborder”) and confirm creation and registration.
  - Register a specimen with only a new rank populated; ensure analysis and table display it.
  - Export (if enabled in this phase) includes the dynamic column.

## Rollout
- Implement DB migration and DAOs first.
- Update Registration UI dynamic ranks and “New Taxa” dialog.
- Adjust CSV import to use dynamic ranks.
- Validate on device, then proceed to optional export changes.

Please confirm this plan. Once approved, I will implement the migration, DAOs, UI updates, and CSV logic, and verify on your Android device.