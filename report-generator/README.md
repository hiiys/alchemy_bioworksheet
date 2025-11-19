# Alchemy Bioworksheet Report Generator

Command-line tool to generate Excel and PDF reports from analysis results stored in Firebase.

## Setup

1. Install dependencies:
   ```bash
   cd report-generator
   npm install
   ```

2. Firebase Authentication:
   - Download your Firebase service account key from the Firebase Console
   - Save it as `serviceAccountKey.json` in the `report-generator` directory
   - Alternatively, use `gcloud auth application-default login` for local development

## Usage

### List Available Results

```bash
node index.js list
node index.js list --type Macrobenthos
```

### Generate Reports

Generate Excel report (default):
```bash
node index.js generate
```

Generate PDF report:
```bash
node index.js generate --format pdf
```

Generate both Excel and PDF:
```bash
node index.js generate --format both
```

### Options

- `-t, --type <type>`: Filter by specimen type (Macrobenthos, Zooplankton, Phytoplankton, all)
- `-c, --client <name>`: Filter by client name
- `-f, --format <format>`: Output format (excel, pdf, both)
- `-o, --output <path>`: Output file path prefix (default: ./report)

### Examples

```bash
# Generate Excel report for Macrobenthos samples
node index.js generate --type Macrobenthos --format excel

# Generate PDF report for specific client
node index.js generate --client "ACME Corp" --format pdf

# Generate both formats with custom output path
node index.js generate --format both --output ./reports/monthly_report
```

## Output Format

### Excel Report
The Excel report contains three sheets per specimen type:

1. **Sample Info**: Client information, sampling specifications, and method details
2. **Sample List**: List of all samples with dates and reference IDs
3. **Analysis**: Taxa counts and densities for each sample

### PDF Report
The PDF report includes:
- Title page with generation date
- Sample information and specifications
- Sample list
- Taxa summary with counts and densities

## Report Structure

The generated reports follow the same structure as the example reports:

- **Macrobenthos**: Density calculated as Count / Area of Grab (ind/m²)
- **Plankton**: Density calculated as Count × Dilution Factor / Volume Filtered (units/L)

## Troubleshooting

### Firebase Authentication Error
Ensure your `serviceAccountKey.json` is properly configured and has access to Firestore.

### No Results Found
Check that:
- Analysis results have been uploaded from the mobile app
- The specimen type filter matches existing data
- The client name filter (if used) matches exactly

## License

MIT License - Alchemy Bioworksheet
