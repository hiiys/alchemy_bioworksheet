const { program } = require('commander');
const admin = require('firebase-admin');
const ExcelJS = require('exceljs');
const PDFDocument = require('pdfkit');
const fs = require('fs');
const path = require('path');

// Firebase configuration
const firebaseConfig = {
    projectId: 'alchemy-bioworksheet',
    // For production, use a service account key file
};

// Initialize Firebase
let db;
function initializeFirebase() {
    if (!admin.apps.length) {
        // Check for service account file
        const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');
        if (fs.existsSync(serviceAccountPath)) {
            const serviceAccount = require(serviceAccountPath);
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount)
            });
        } else {
            // Use default credentials (for local development)
            admin.initializeApp({
                projectId: firebaseConfig.projectId
            });
        }
    }
    db = admin.firestore();
}

// Fetch analysis results from Firebase
async function fetchAnalysisResults(options = {}) {
    console.log('Fetching analysis results from Firebase...');

    let query = db.collection('analysis_results');

    if (options.specimenType && options.specimenType !== 'all') {
        query = query.where('specimenType', '==', options.specimenType);
    }

    if (options.clientName) {
        query = query.where('clientName', '==', options.clientName);
    }

    const snapshot = await query.orderBy('uploadedAt', 'desc').get();

    const results = [];
    snapshot.forEach(doc => {
        results.push({
            id: doc.id,
            ...doc.data()
        });
    });

    console.log(`Found ${results.length} analysis results`);
    return results;
}

// Generate Excel Report
async function generateExcelReport(results, outputPath, options = {}) {
    console.log('Generating Excel report...');

    const workbook = new ExcelJS.Workbook();
    workbook.creator = 'Alchemy Bioworksheet';
    workbook.created = new Date();

    // Group results by specimen type if mixed
    const specimenTypes = [...new Set(results.map(r => r.specimenType))];

    for (const specimenType of specimenTypes) {
        const typeResults = results.filter(r => r.specimenType === specimenType);

        // Sheet 1: Sample Info
        const infoSheet = workbook.addWorksheet(`${specimenType} - Sample Info`);
        createSampleInfoSheet(infoSheet, typeResults, specimenType);

        // Sheet 2: Sample List
        const listSheet = workbook.addWorksheet(`${specimenType} - Sample List`);
        createSampleListSheet(listSheet, typeResults);

        // Sheet 3: Analysis Data
        const analysisSheet = workbook.addWorksheet(`${specimenType} - Analysis`);
        createAnalysisSheet(analysisSheet, typeResults, specimenType);
    }

    await workbook.xlsx.writeFile(outputPath);
    console.log(`Excel report saved to: ${outputPath}`);
}

// Create Sample Info Sheet
function createSampleInfoSheet(sheet, results, specimenType) {
    // Get first result for header info
    const sample = results[0] || {};

    // Header styling
    const headerStyle = {
        font: { bold: true, size: 12 },
        fill: { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE0E0E0' } }
    };

    // Add header info
    const infoData = [
        ['SAMPLE INFORMATION', ''],
        ['', ''],
        ['Client Name:', sample.clientName || ''],
        ['Client Address:', sample.clientAddress || ''],
        ['Institution:', sample.institution || ''],
        ['', ''],
        ['Type of Sample:', specimenType],
        ['Sample Description:', sample.sampleDescription || ''],
        ['Number of Samples:', results.length],
        ['', ''],
        ['Date Received:', sample.dateReceived ? new Date(sample.dateReceived).toLocaleDateString() : ''],
        ['Date Analysis:', sample.analyzedDate ? new Date(sample.analyzedDate).toLocaleDateString() : ''],
        ['', ''],
        ['SAMM No:', sample.sammNo || ''],
        ['Report No:', sample.reportNo || ''],
        ['Authorized By:', sample.authorizedBy || ''],
        ['', ''],
        ['SAMPLING SPECIFICATIONS', '']
    ];

    // Add specimen-specific info
    if (specimenType === 'Macrobenthos') {
        infoData.push(
            ['Gear Used:', sample.gearUsed || ''],
            ['Area of Grab:', sample.areaOfGrab ? `${sample.areaOfGrab} m²` : ''],
            ['Sieve Size:', sample.sieveSize || '']
        );
    } else {
        infoData.push(
            ['Gear Used:', sample.gearUsed || ''],
            ['Net Diameter:', sample.netDiameter || ''],
            ['Net Mesh:', sample.netMesh || ''],
            ['Tow Type:', sample.towType || ''],
            ['Filtered Volume:', sample.filteredVolume ? `${sample.filteredVolume} L` : ''],
            ['Tow Distance:', sample.towDistance ? `${sample.towDistance} m` : ''],
            ['Sample Volume:', sample.sampleVolume ? `${sample.sampleVolume} ml` : ''],
            ['SR Cell Volume:', sample.srCellVolume ? `${sample.srCellVolume} ml` : ''],
            ['SR Cells Counted:', sample.srCellsCounted || '']
        );
    }

    infoData.push(
        ['', ''],
        ['Method of Analysis:', sample.methodAnalysis || '']
    );

    // Add rows to sheet
    infoData.forEach((row, index) => {
        const excelRow = sheet.addRow(row);
        if (row[0] && row[0].includes(':') === false && row[0] !== '') {
            excelRow.font = { bold: true, size: 12 };
        }
        if (row[0] && row[0].endsWith(':')) {
            excelRow.getCell(1).font = { bold: true };
        }
    });

    // Set column widths
    sheet.getColumn(1).width = 25;
    sheet.getColumn(2).width = 40;
}

// Create Sample List Sheet
function createSampleListSheet(sheet, results) {
    // Header row
    const headers = ['No.', 'Date Received', 'Sample Marking', 'Date Analysis', 'Reference ID', 'Biologist'];
    const headerRow = sheet.addRow(headers);
    headerRow.font = { bold: true };
    headerRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE0E0E0' } };

    // Add data rows
    results.forEach((result, index) => {
        sheet.addRow([
            index + 1,
            result.dateReceived ? new Date(result.dateReceived).toLocaleDateString() : '',
            result.stationId || '',
            result.analyzedDate ? new Date(result.analyzedDate).toLocaleDateString() : '',
            result.referenceId || '',
            result.biologistId || ''
        ]);
    });

    // Set column widths
    sheet.getColumn(1).width = 8;
    sheet.getColumn(2).width = 15;
    sheet.getColumn(3).width = 20;
    sheet.getColumn(4).width = 15;
    sheet.getColumn(5).width = 15;
    sheet.getColumn(6).width = 15;

    // Auto-filter
    sheet.autoFilter = {
        from: 'A1',
        to: `F${results.length + 1}`
    };
}

// Create Analysis Sheet
function createAnalysisSheet(sheet, results, specimenType) {
    // Build taxonomy hierarchy from all results
    const allTaxa = new Map();
    const sampleColumns = [];

    results.forEach((result, index) => {
        sampleColumns.push(result.stationId || `Sample ${index + 1}`);

        if (result.counts) {
            result.counts.forEach(count => {
                const key = count.taxonId || count.taxonName;
                if (!allTaxa.has(key)) {
                    allTaxa.set(key, {
                        name: count.taxonName,
                        rank: count.taxonRank,
                        hierarchy: count.hierarchy || [],
                        counts: new Array(results.length).fill(0),
                        densities: new Array(results.length).fill(0)
                    });
                }
                const taxon = allTaxa.get(key);
                taxon.counts[index] = count.count;
                taxon.densities[index] = count.density || 0;
            });
        }
    });

    // Header rows
    const headers = ['Taxonomy', 'Rank'];
    sampleColumns.forEach(col => {
        headers.push(col);
        headers.push('Density');
    });

    const headerRow = sheet.addRow(headers);
    headerRow.font = { bold: true };
    headerRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE0E0E0' } };

    // Add taxa rows
    const sortedTaxa = Array.from(allTaxa.values()).sort((a, b) => {
        // Sort by hierarchy depth, then name
        const aHierarchy = a.hierarchy.join(' > ');
        const bHierarchy = b.hierarchy.join(' > ');
        return aHierarchy.localeCompare(bHierarchy);
    });

    sortedTaxa.forEach(taxon => {
        const row = [taxon.name, taxon.rank || ''];
        for (let i = 0; i < results.length; i++) {
            row.push(taxon.counts[i] || 0);
            row.push(taxon.densities[i] ? taxon.densities[i].toFixed(2) : '');
        }
        sheet.addRow(row);
    });

    // Add totals row
    const totalsRow = ['TOTAL', ''];
    for (let i = 0; i < results.length; i++) {
        const totalCount = Array.from(allTaxa.values()).reduce((sum, t) => sum + (t.counts[i] || 0), 0);
        const totalDensity = Array.from(allTaxa.values()).reduce((sum, t) => sum + (t.densities[i] || 0), 0);
        totalsRow.push(totalCount);
        totalsRow.push(totalDensity.toFixed(2));
    }
    const totalExcelRow = sheet.addRow(totalsRow);
    totalExcelRow.font = { bold: true };

    // Set column widths
    sheet.getColumn(1).width = 30;
    sheet.getColumn(2).width = 12;
    for (let i = 3; i <= headers.length; i++) {
        sheet.getColumn(i).width = 12;
    }

    // Freeze panes
    sheet.views = [{ state: 'frozen', xSplit: 2, ySplit: 1 }];
}

// Generate PDF Report
async function generatePDFReport(results, outputPath, options = {}) {
    console.log('Generating PDF report...');

    const doc = new PDFDocument({ margin: 50 });
    const stream = fs.createWriteStream(outputPath);
    doc.pipe(stream);

    // Title page
    doc.fontSize(24).text('Analysis Report', { align: 'center' });
    doc.moveDown();
    doc.fontSize(12).text(`Generated: ${new Date().toLocaleDateString()}`, { align: 'center' });
    doc.moveDown(2);

    // Group by specimen type
    const specimenTypes = [...new Set(results.map(r => r.specimenType))];

    for (const specimenType of specimenTypes) {
        const typeResults = results.filter(r => r.specimenType === specimenType);

        doc.addPage();

        // Section header
        doc.fontSize(18).text(`${specimenType} Analysis`, { underline: true });
        doc.moveDown();

        // Sample info
        const sample = typeResults[0] || {};
        doc.fontSize(12);
        doc.text(`Client: ${sample.clientName || 'N/A'}`);
        doc.text(`Institution: ${sample.institution || 'N/A'}`);
        doc.text(`Number of Samples: ${typeResults.length}`);
        doc.text(`SAMM No: ${sample.sammNo || 'N/A'}`);
        doc.text(`Report No: ${sample.reportNo || 'N/A'}`);
        doc.moveDown();

        // Sample list
        doc.fontSize(14).text('Sample List:', { underline: true });
        doc.fontSize(10);
        typeResults.forEach((result, index) => {
            const date = result.analyzedDate ? new Date(result.analyzedDate).toLocaleDateString() : 'N/A';
            doc.text(`${index + 1}. ${result.stationId || 'N/A'} - ${date} - ${result.biologistId || 'N/A'}`);
        });
        doc.moveDown();

        // Taxa summary
        doc.fontSize(14).text('Taxa Summary:', { underline: true });
        doc.fontSize(10);

        // Aggregate taxa counts
        const taxaCounts = new Map();
        typeResults.forEach(result => {
            if (result.counts) {
                result.counts.forEach(count => {
                    const current = taxaCounts.get(count.taxonName) || { count: 0, density: 0 };
                    taxaCounts.set(count.taxonName, {
                        count: current.count + count.count,
                        density: current.density + (count.density || 0)
                    });
                });
            }
        });

        // Sort and display top taxa
        const sortedTaxa = Array.from(taxaCounts.entries())
            .sort((a, b) => b[1].count - a[1].count)
            .slice(0, 20);

        sortedTaxa.forEach(([name, data]) => {
            doc.text(`${name}: ${data.count} (Density: ${data.density.toFixed(2)})`);
        });

        if (taxaCounts.size > 20) {
            doc.text(`... and ${taxaCounts.size - 20} more taxa`);
        }
    }

    // Finalize PDF
    doc.end();

    return new Promise((resolve, reject) => {
        stream.on('finish', () => {
            console.log(`PDF report saved to: ${outputPath}`);
            resolve();
        });
        stream.on('error', reject);
    });
}

// CLI Program
program
    .name('alchemy-report')
    .description('Generate reports from Alchemy Bioworksheet analysis results')
    .version('1.0.0');

program
    .command('generate')
    .description('Generate a report from Firebase data')
    .option('-t, --type <type>', 'Specimen type (Macrobenthos, Zooplankton, Phytoplankton, all)', 'all')
    .option('-c, --client <name>', 'Filter by client name')
    .option('-f, --format <format>', 'Output format (excel, pdf, both)', 'excel')
    .option('-o, --output <path>', 'Output file path', './report')
    .action(async (options) => {
        try {
            initializeFirebase();

            const results = await fetchAnalysisResults({
                specimenType: options.type,
                clientName: options.client
            });

            if (results.length === 0) {
                console.log('No analysis results found matching criteria.');
                process.exit(0);
            }

            const timestamp = new Date().toISOString().split('T')[0];
            const baseName = `${options.output}_${timestamp}`;

            if (options.format === 'excel' || options.format === 'both') {
                await generateExcelReport(results, `${baseName}.xlsx`, options);
            }

            if (options.format === 'pdf' || options.format === 'both') {
                await generatePDFReport(results, `${baseName}.pdf`, options);
            }

            console.log('Report generation complete!');
            process.exit(0);
        } catch (error) {
            console.error('Error generating report:', error);
            process.exit(1);
        }
    });

program
    .command('list')
    .description('List available analysis results')
    .option('-t, --type <type>', 'Specimen type filter', 'all')
    .action(async (options) => {
        try {
            initializeFirebase();

            const results = await fetchAnalysisResults({
                specimenType: options.type
            });

            console.log('\nAvailable Analysis Results:');
            console.log('─'.repeat(80));

            results.forEach((result, index) => {
                const date = result.analyzedDate ? new Date(result.analyzedDate).toLocaleDateString() : 'N/A';
                const taxaCount = result.counts ? result.counts.length : 0;
                console.log(`${index + 1}. ${result.stationId} | ${result.specimenType} | ${result.clientName} | ${date} | ${taxaCount} taxa`);
            });

            console.log('─'.repeat(80));
            console.log(`Total: ${results.length} results\n`);

            process.exit(0);
        } catch (error) {
            console.error('Error listing results:', error);
            process.exit(1);
        }
    });

program.parse();
