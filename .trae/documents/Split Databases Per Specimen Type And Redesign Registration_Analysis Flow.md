## Objectives
- Split storage by specimen type: separate SQLite databases for Macrobenthos, Zooplankton, Phytoplankton.
- Redesign registration to capture rich order-level metadata and auto-generate Sample Marking entries.
- Keep combined Sample List on Home and Sample List pages while analysis/reporting remain type-specific.
- Add modal flow to pick a Sample Marking to start analysis.
- Ensure exports include new fields and remain type-specific.

## Architecture
### Database Router
- Implement `DatabaseRouter` to select DB file by `specimenType` (e.g., `macrobenthos.db`, `zooplankton.db`, `phytoplankton.db`).
- Each DB has identical core schema but per-type tables and data; App uses DAOs that call the router.
- Files under app documents directory:
  - `Macrobenthos/macrobenthos.db`
  - `Zooplankton/zooplankton.db`
  - `Phytoplankton/phytoplankton.db`

### Schema Per DB
- `orders` (one row per registration order)
  - Common fields: `id PK`, `clientName`, `clientAddress`, `specimenType`, `numberOfSamples`, `numberOfReplicates`, `dateReceived`, `dateAnalysis`, `gearUsed`, `methodAnalysis`, `reportNo`, `batchId`, `comments`.
  - Macrobenthos-only: `areaOfGrab`, `sieveSize`.
  - Zooplankton/Phytoplankton-only: `netDiameter`, `netMesh`, `towType`, `filteredVolume`.
- `samples` (one row per Sample Marking)
  - `id PK`, `orderId FK`, `sampleMarking` (string), `replicateIndex` (int), `receiveId` (optional), `biologistId` (optional), `completed` (bool), `dateAnalysis` (optional).
- `taxon` / `count_record` / `rank_definition` (as now, per DB).

## Data Models & DAOs
- Add `Order` model and `OrderDao` with CRUD and query by `orderId`.
- Update `Sample` model: include `orderId`, `sampleMarking`, and type-specific analysis fields; remove cross-type fields not needed.
- Refactor `SampleDao`, `TaxonDao`, `CountDao` to use `DatabaseRouter`.
- Aggregator service reads `orders` + `samples` across all three DBs to build combined lists for Home/Sample List.

## Registration Flow (Per Type)
### Order Registration Page (replaces Sample Info for type-specific order)
- Macrobenthos fields:
  - Client Name, Client Address, Sample Type (auto: Macrobenthos), Sample Marking (prefix/pattern), Number of samples, Number of replicates, Date Received, Date of Analysis, Gear used, Area of Grab, Sieve size, Method of Analysis, Report No., Batch ID, Comments.
- Zooplankton/Phytoplankton fields (similar with specific fields): Net diameter, Net mesh, Tow type, Filtered volume.
- After submitting:
  - Create `orders` row in type DB.
  - Auto-generate `samples` rows: count = `numberOfSamples * (numberOfReplicates or 1)`.
  - Sample Marking generation:
    - Base pattern from input (e.g., `OrderID-1`, `OrderID-1R1`, … or `Station/Seq` as defined).
    - Save `sampleMarking` strings to `samples` table.

### Start Analysis From Order
- After order creation, show modal listing Sample Markings for that `orderId`.
- User picks a marking → sets active DB (type) and active sample; navigates to Analysis.

## Specimen Registration & Analysis (Per Type)
- Registration (taxonomy) uses router-selected DB; dynamic ranks remain supported.
- Analysis page counts against the active `samples.id` in the selected DB.
- Biologist prompt remains; stored per sample in type DB.

## Home & Sample List (Combined View)
- Combined lists built by aggregating `orders`/`samples` from the three DBs.
- Display columns: Client Name, Sample Type, `Order ID`, `Receive ID`.
- Tap row → modal shows all Sample Markings under that `Order ID` (current design for sample ID table is preserved).
- Tap a Sample Marking → activate and go to Analysis.

## Export & Reporting
- Export functions select router DB based on chosen `specimenType`.
- CSV includes order-level fields and `BiologistID`, plus taxonomy dynamic ranks.
- Filenames include type as now.

## Migration Strategy
- On app upgrade:
  - If legacy data exists in monolithic DB (Macrobenthos only), copy relevant rows into `Macrobenthos/macrobenthos.db` (orders constructed from existing samples, samples created from existing sample entries).
  - Initialize empty DBs for Zooplankton/Phytoplankton.
  - Maintain user guidance to re-register orders for zooplankton/phytoplankton.

## UI Design Details
- Three entry points to Order Registration: buttons for Macrobenthos, Zooplankton, Phytoplankton.
- Clean form sections per type; validation for required fields.
- Modal list follows current card/list tile style; clear action to Start Analysis.

## Validation
- Create orders for each type; auto-generate correct number of Sample Markings (including replicates multiplication).
- Modal shows expected Sample Markings; selecting one starts analysis with type-specific DB.
- Combined lists show Client, Type, Order ID, Receive ID.
- Exports include new fields and correct taxonomy per type.

## Implementation Phases
1. Create DatabaseRouter and new per-type schemas (orders, refactored samples).
2. Models/DAOs for orders and router-backed DAOs.
3. Order Registration UI per type and Sample Marking generation.
4. Modal selection to start analysis; router activation.
5. Combined Home/Sample List aggregator.
6. Export updates and validations.

If you approve, I’ll implement the router, schemas, forms, modal flow, list aggregations, and export updates, and validate on device.