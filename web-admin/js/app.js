// App State
let currentSpecimenType = 'Macrobenthos';
let currentReportingType = 'Macrobenthos';
let allTaxa = [];
let selectedTaxonId = null;

// DOM Elements
const loginScreen = document.getElementById('login-screen');
const appScreen = document.getElementById('app-screen');
const loginForm = document.getElementById('login-form');
const loginError = document.getElementById('login-error');
const userEmail = document.getElementById('user-email');
const logoutBtn = document.getElementById('logout-btn');
const tabs = document.querySelectorAll('#specimen-tabs .tab');
const navTabs = document.querySelectorAll('.nav-tab');
const reportingTabs = document.querySelectorAll('#reporting-page .tab');
const taxonomyTree = document.getElementById('taxonomy-tree');
const detailsPanel = document.getElementById('details-panel');
const taxonForm = document.getElementById('taxon-form');
const addRootBtn = document.getElementById('add-root-btn');
const refreshBtn = document.getElementById('refresh-btn');
const taxaCount = document.getElementById('taxa-count');
const statusMessage = document.getElementById('status-message');
const lastModified = document.getElementById('last-modified');
const taxonomyPage = document.getElementById('taxonomy-page');
const reportingPage = document.getElementById('reporting-page');
const reportLogPage = document.getElementById('report-log-page');
const ordersPage = document.getElementById('orders-page');
const samplesPage = document.getElementById('samples-page');
const specimenTabs = document.getElementById('specimen-tabs');
const resultsSectionTitle = document.getElementById('results-section-title');

// Add modal elements
const addModal = document.getElementById('add-modal');
const addChildForm = document.getElementById('add-child-form');
const modalParentName = document.getElementById('modal-parent-name');
const modalCancelBtn = document.getElementById('modal-cancel-btn');

// Authentication
auth.onAuthStateChanged(user => {
    if (user) {
        loginScreen.classList.add('hidden');
        appScreen.classList.remove('hidden');
        userEmail.textContent = user.email;
        loadTaxonomy();
    } else {
        loginScreen.classList.remove('hidden');
        appScreen.classList.add('hidden');
    }
});

loginForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;

    try {
        await auth.signInWithEmailAndPassword(email, password);
        loginError.textContent = '';
    } catch (error) {
        loginError.textContent = error.message;
    }
});

logoutBtn.addEventListener('click', () => {
    auth.signOut();
});

// Main navigation (Taxonomy/Reporting/Report Log/Orders/Samples) tab switching
navTabs.forEach(navTab => {
    navTab.addEventListener('click', () => {
        navTabs.forEach(t => t.classList.remove('active'));
        navTab.classList.add('active');
        const page = navTab.dataset.page;

        if (page === 'taxonomy') {
            taxonomyPage.classList.remove('hidden');
            reportingPage.classList.add('hidden');
            reportLogPage.classList.add('hidden');
            ordersPage.classList.add('hidden');
            samplesPage.classList.add('hidden');
            specimenTabs.style.display = 'flex';
        } else if (page === 'reporting') {
            taxonomyPage.classList.add('hidden');
            reportingPage.classList.remove('hidden');
            reportLogPage.classList.add('hidden');
            ordersPage.classList.add('hidden');
            samplesPage.classList.add('hidden');
            specimenTabs.style.display = 'none';
            loadReportInfo();
            loadAnalysisResults();
        } else if (page === 'report-log') {
            taxonomyPage.classList.add('hidden');
            reportingPage.classList.add('hidden');
            reportLogPage.classList.remove('hidden');
            ordersPage.classList.add('hidden');
            samplesPage.classList.add('hidden');
            specimenTabs.style.display = 'none';
            loadReportLogs();
        } else if (page === 'orders') {
            taxonomyPage.classList.add('hidden');
            reportingPage.classList.add('hidden');
            reportLogPage.classList.add('hidden');
            ordersPage.classList.remove('hidden');
            samplesPage.classList.add('hidden');
            specimenTabs.style.display = 'none';
            // Load orders data - handled by registration.js
            if (typeof loadOrdersData === 'function') {
                loadOrdersData();
            }
        } else if (page === 'samples') {
            taxonomyPage.classList.add('hidden');
            reportingPage.classList.add('hidden');
            reportLogPage.classList.add('hidden');
            ordersPage.classList.add('hidden');
            samplesPage.classList.remove('hidden');
            specimenTabs.style.display = 'none';
            // Load samples data - handled by registration.js
            if (typeof loadSamplesData === 'function') {
                loadSamplesData();
            }
        }
    });
});

// Specimen type tab switching
tabs.forEach(tab => {
    tab.addEventListener('click', () => {
        tabs.forEach(t => t.classList.remove('active'));
        tab.classList.add('active');
        currentSpecimenType = tab.dataset.type;
        hideDetailsPanel();
        loadTaxonomy();
        updateRankOptions();
    });
});

// Reporting specimen type tab switching
reportingTabs.forEach(tab => {
    tab.addEventListener('click', () => {
        reportingTabs.forEach(t => t.classList.remove('active'));
        tab.classList.add('active');
        currentReportingType = tab.dataset.type;
        resultsSectionTitle.textContent = `${currentReportingType} Analysis Results`;
        loadAnalysisResults();
    });
});

// Load taxonomy from Firestore
async function loadTaxonomy() {
    taxonomyTree.innerHTML = '<p class="loading">Loading taxonomy...</p>';
    setStatus('Loading...');

    try {
        const taxaRef = db.collection('taxonomies').doc(currentSpecimenType).collection('taxa');
        const snapshot = await taxaRef.get();

        allTaxa = snapshot.docs.map(doc => ({
            id: parseInt(doc.id),
            ...doc.data()
        }));

        renderTree();
        taxaCount.textContent = `${allTaxa.length} taxa`;

        // Get last modified time
        const metaDoc = await db.collection('taxonomies').doc(currentSpecimenType).get();
        if (metaDoc.exists && metaDoc.data().lastModified) {
            const date = metaDoc.data().lastModified.toDate();
            lastModified.textContent = `Last modified: ${date.toLocaleString()}`;
        }

        setStatus('Ready');
    } catch (error) {
        taxonomyTree.innerHTML = `<p class="error">Error: ${error.message}</p>`;
        setStatus('Error loading taxonomy');
    }
}

// Render taxonomy tree
function renderTree() {
    const rootTaxa = allTaxa.filter(t => t.parentId === null);

    if (rootTaxa.length === 0) {
        taxonomyTree.innerHTML = '<p class="loading">No taxa found. Click "Add Root Taxon" to create one.</p>';
        return;
    }

    taxonomyTree.innerHTML = '';
    rootTaxa.forEach(taxon => {
        taxonomyTree.appendChild(createTreeNode(taxon));
    });
}

// Create tree node element
function createTreeNode(taxon) {
    const children = allTaxa.filter(t => t.parentId === taxon.id);
    const hasChildren = children.length > 0;

    const node = document.createElement('div');
    node.className = 'tree-node';
    node.dataset.id = taxon.id;

    const content = document.createElement('div');
    content.className = 'node-content';
    if (taxon.id === selectedTaxonId) {
        content.classList.add('selected');
    }

    // Toggle button
    const toggle = document.createElement('button');
    toggle.className = 'toggle-btn';
    toggle.textContent = hasChildren ? '▼' : '•';
    toggle.onclick = (e) => {
        e.stopPropagation();
        if (hasChildren) {
            const childrenDiv = node.querySelector('.children');
            childrenDiv.classList.toggle('collapsed');
            toggle.textContent = childrenDiv.classList.contains('collapsed') ? '▶' : '▼';
        }
    };

    // Name and rank
    const name = document.createElement('span');
    name.className = 'node-name';
    name.textContent = taxon.name;

    const rank = document.createElement('span');
    rank.className = 'node-rank';
    rank.textContent = `(${taxon.rank || 'Unknown'})`;

    // Add child button
    const actions = document.createElement('div');
    actions.className = 'node-actions';

    const addBtn = document.createElement('button');
    addBtn.className = 'add-child-btn';
    addBtn.textContent = '+ Child';
    addBtn.onclick = (e) => {
        e.stopPropagation();
        showAddModal(taxon);
    };
    actions.appendChild(addBtn);

    content.appendChild(toggle);
    content.appendChild(name);
    content.appendChild(rank);
    content.appendChild(actions);

    content.onclick = () => selectTaxon(taxon);

    node.appendChild(content);

    // Children container
    if (hasChildren) {
        const childrenDiv = document.createElement('div');
        childrenDiv.className = 'children';
        children.forEach(child => {
            childrenDiv.appendChild(createTreeNode(child));
        });
        node.appendChild(childrenDiv);
    }

    return node;
}

// Select taxon and show details
function selectTaxon(taxon) {
    selectedTaxonId = taxon.id;

    // Update selection highlighting
    document.querySelectorAll('.node-content').forEach(el => {
        el.classList.remove('selected');
    });
    const selectedNode = document.querySelector(`[data-id="${taxon.id}"] > .node-content`);
    if (selectedNode) {
        selectedNode.classList.add('selected');
    }

    // Show details panel
    showDetailsPanel(taxon);
}

// Show details panel
function showDetailsPanel(taxon) {
    detailsPanel.classList.remove('hidden');
    document.getElementById('details-title').textContent = 'Edit Taxon';

    document.getElementById('taxon-id').value = taxon.id;
    document.getElementById('taxon-parent-id').value = taxon.parentId || '';
    document.getElementById('taxon-name').value = taxon.name;
    document.getElementById('taxon-rank').value = taxon.rank || '';
    document.getElementById('taxon-notes').value = taxon.notes || '';

    updateRankOptions();
}

// Hide details panel
function hideDetailsPanel() {
    detailsPanel.classList.add('hidden');
    selectedTaxonId = null;
    document.querySelectorAll('.node-content').forEach(el => {
        el.classList.remove('selected');
    });
}

// Update rank dropdown options
function updateRankOptions() {
    const ranks = rankDefinitions[currentSpecimenType];
    const selects = [document.getElementById('taxon-rank'), document.getElementById('add-rank')];

    selects.forEach(select => {
        const currentValue = select.value;
        select.innerHTML = '<option value="">Select rank...</option>';
        ranks.forEach(rank => {
            const option = document.createElement('option');
            option.value = rank;
            option.textContent = rank;
            select.appendChild(option);
        });
        select.value = currentValue;
    });
}

// Save taxon
taxonForm.addEventListener('submit', async (e) => {
    e.preventDefault();

    const id = document.getElementById('taxon-id').value;
    const parentId = document.getElementById('taxon-parent-id').value;
    const name = document.getElementById('taxon-name').value.trim();
    const rank = document.getElementById('taxon-rank').value;
    const notes = document.getElementById('taxon-notes').value.trim();

    if (!name || !rank) {
        alert('Name and rank are required');
        return;
    }

    setStatus('Saving...');

    try {
        const taxaRef = db.collection('taxonomies').doc(currentSpecimenType).collection('taxa');

        await taxaRef.doc(id).set({
            parentId: parentId ? parseInt(parentId) : null,
            name: name,
            rank: rank,
            notes: notes || null,
            specimenType: currentSpecimenType
        });

        // Update metadata
        await db.collection('taxonomies').doc(currentSpecimenType).set({
            lastModified: firebase.firestore.FieldValue.serverTimestamp(),
            modifiedBy: auth.currentUser.email
        }, { merge: true });

        setStatus('Saved successfully');
        loadTaxonomy();
    } catch (error) {
        alert('Error saving: ' + error.message);
        setStatus('Error saving');
    }
});

// Cancel button
document.getElementById('cancel-btn').addEventListener('click', hideDetailsPanel);

// Delete taxon
document.getElementById('delete-btn').addEventListener('click', async () => {
    const id = document.getElementById('taxon-id').value;
    const name = document.getElementById('taxon-name').value;

    // Check for children
    const children = allTaxa.filter(t => t.parentId === parseInt(id));
    if (children.length > 0) {
        alert(`Cannot delete "${name}" - it has ${children.length} child taxa. Delete children first.`);
        return;
    }

    if (!confirm(`Delete "${name}"? This cannot be undone.`)) {
        return;
    }

    setStatus('Deleting...');

    try {
        await db.collection('taxonomies').doc(currentSpecimenType)
            .collection('taxa').doc(id).delete();

        // Update metadata
        await db.collection('taxonomies').doc(currentSpecimenType).set({
            lastModified: firebase.firestore.FieldValue.serverTimestamp(),
            modifiedBy: auth.currentUser.email
        }, { merge: true });

        setStatus('Deleted successfully');
        hideDetailsPanel();
        loadTaxonomy();
    } catch (error) {
        alert('Error deleting: ' + error.message);
        setStatus('Error deleting');
    }
});

// Add root taxon
addRootBtn.addEventListener('click', () => {
    showAddModal(null);
});

// Show add modal
function showAddModal(parentTaxon) {
    addModal.classList.remove('hidden');

    if (parentTaxon) {
        modalParentName.textContent = parentTaxon.name;
        document.getElementById('add-parent-id').value = parentTaxon.id;
    } else {
        modalParentName.textContent = '(Root level)';
        document.getElementById('add-parent-id').value = '';
    }

    document.getElementById('add-name').value = '';
    document.getElementById('add-notes').value = '';
    updateRankOptions();
    document.getElementById('add-name').focus();
}

// Close modal
modalCancelBtn.addEventListener('click', () => {
    addModal.classList.add('hidden');
});

// Add child form submit
addChildForm.addEventListener('submit', async (e) => {
    e.preventDefault();

    const parentId = document.getElementById('add-parent-id').value;
    const name = document.getElementById('add-name').value.trim();
    const rank = document.getElementById('add-rank').value;
    const notes = document.getElementById('add-notes').value.trim();

    if (!name || !rank) {
        alert('Name and rank are required');
        return;
    }

    // Generate new ID (find max ID and add 1)
    let newId;
    if (currentSpecimenType === 'Zooplankton') {
        const maxId = allTaxa.reduce((max, t) => Math.max(max, t.id), 1000000);
        newId = maxId + 1;
    } else if (currentSpecimenType === 'Phytoplankton') {
        const maxId = allTaxa.reduce((max, t) => Math.max(max, t.id), 2000000);
        newId = maxId + 1;
    } else {
        const maxId = allTaxa.reduce((max, t) => Math.max(max, t.id), 0);
        newId = maxId + 1;
    }

    setStatus('Adding...');

    try {
        const taxaRef = db.collection('taxonomies').doc(currentSpecimenType).collection('taxa');

        await taxaRef.doc(newId.toString()).set({
            parentId: parentId ? parseInt(parentId) : null,
            name: name,
            rank: rank,
            notes: notes || null,
            specimenType: currentSpecimenType
        });

        // Update metadata
        await db.collection('taxonomies').doc(currentSpecimenType).set({
            lastModified: firebase.firestore.FieldValue.serverTimestamp(),
            modifiedBy: auth.currentUser.email,
            taxaCount: allTaxa.length + 1
        }, { merge: true });

        addModal.classList.add('hidden');
        setStatus('Added successfully');
        loadTaxonomy();
    } catch (error) {
        alert('Error adding: ' + error.message);
        setStatus('Error adding');
    }
});

// Refresh button
refreshBtn.addEventListener('click', loadTaxonomy);

// Set status message
function setStatus(message) {
    statusMessage.textContent = message;
}

// Initialize rank options
updateRankOptions();

// CSV Import/Export functionality
const importCsvBtn = document.getElementById('import-csv-btn');
const exportCsvBtn = document.getElementById('export-csv-btn');
const importModal = document.getElementById('import-modal');
const importCancelBtn = document.getElementById('import-cancel-btn');
const importUploadBtn = document.getElementById('import-upload-btn');
const csvFileInput = document.getElementById('csv-file-input');
const csvPreview = document.getElementById('csv-preview');
const csvPreviewTable = document.getElementById('csv-preview-table');
const csvRowCount = document.getElementById('csv-row-count');
const importErrors = document.getElementById('import-errors');
const importSpecimenType = document.getElementById('import-specimen-type');

let parsedCsvData = [];

// Open import modal
importCsvBtn.addEventListener('click', () => {
    importModal.classList.remove('hidden');
    importSpecimenType.textContent = currentSpecimenType;
    resetImportModal();
});

// Close import modal
importCancelBtn.addEventListener('click', () => {
    importModal.classList.add('hidden');
    resetImportModal();
});

// Reset import modal state
function resetImportModal() {
    csvFileInput.value = '';
    csvPreview.classList.add('hidden');
    importErrors.classList.add('hidden');
    importUploadBtn.disabled = true;
    parsedCsvData = [];
}

// Handle file selection
csvFileInput.addEventListener('change', (e) => {
    const file = e.target.files[0];
    if (file) {
        readCsvFile(file);
    }
});

// Read and parse CSV file
function readCsvFile(file) {
    const reader = new FileReader();
    reader.onload = (e) => {
        const text = e.target.result;
        parseCsv(text);
    };
    reader.readAsText(file);
}

// Parse CSV text
function parseCsv(text) {
    const lines = text.split(/\r?\n/).filter(line => line.trim());
    if (lines.length < 2) {
        showImportError('CSV file must have a header row and at least one data row.');
        return;
    }

    const headers = lines[0].split(',').map(h => h.trim().toLowerCase());

    // Detect CSV format
    const isHierarchicalFormat = headers.includes('taxa_id') ||
                                 (headers.includes('phylum') && headers.includes('genus'));

    if (isHierarchicalFormat) {
        parseHierarchicalCsv(lines, headers);
    } else {
        parseStandardCsv(lines, headers);
    }
}

// Parse standard CSV format (id, parentId, name, rank, notes)
function parseStandardCsv(lines, headers) {
    const requiredHeaders = ['id', 'name', 'rank'];
    const missingHeaders = requiredHeaders.filter(h => !headers.includes(h));

    if (missingHeaders.length > 0) {
        showImportError(`Missing required columns: ${missingHeaders.join(', ')}`);
        return;
    }

    const errors = [];
    parsedCsvData = [];

    for (let i = 1; i < lines.length; i++) {
        const values = parseCSVLine(lines[i]);
        if (values.length !== headers.length) {
            errors.push(`Row ${i + 1}: Column count mismatch (expected ${headers.length}, got ${values.length})`);
            continue;
        }

        const row = {};
        headers.forEach((header, index) => {
            row[header] = values[index].trim();
        });

        // Validate row
        if (!row.id || isNaN(parseInt(row.id))) {
            errors.push(`Row ${i + 1}: Invalid or missing ID`);
            continue;
        }
        if (!row.name) {
            errors.push(`Row ${i + 1}: Missing name`);
            continue;
        }
        if (!row.rank) {
            errors.push(`Row ${i + 1}: Missing rank`);
            continue;
        }

        // Validate rank against definitions
        const validRanks = rankDefinitions[currentSpecimenType];
        if (!validRanks.includes(row.rank)) {
            errors.push(`Row ${i + 1}: Invalid rank "${row.rank}". Valid ranks: ${validRanks.join(', ')}`);
            continue;
        }

        parsedCsvData.push({
            id: parseInt(row.id),
            parentId: row.parentid ? parseInt(row.parentid) : null,
            name: row.name,
            rank: row.rank,
            notes: row.notes || null
        });
    }

    if (errors.length > 0 && parsedCsvData.length === 0) {
        showImportError('All rows have errors:<ul>' + errors.map(e => `<li>${e}</li>`).join('') + '</ul>');
        return;
    }

    if (errors.length > 0) {
        importErrors.innerHTML = `<strong>Warning:</strong> ${errors.length} row(s) skipped due to errors:<ul>` +
            errors.slice(0, 5).map(e => `<li>${e}</li>`).join('') +
            (errors.length > 5 ? `<li>...and ${errors.length - 5} more</li>` : '') + '</ul>';
        importErrors.classList.remove('hidden');
    } else {
        importErrors.classList.add('hidden');
    }

    // Show preview
    showCsvPreview();
    importUploadBtn.disabled = false;
}

// Parse hierarchical CSV format (Taxa_ID, Phylum, Class, Order, Family, Genus)
function parseHierarchicalCsv(lines, headers) {
    const errors = [];
    parsedCsvData = [];

    // Map to track unique taxa by name+rank combination
    const taxaMap = new Map();

    // Generate unique IDs based on specimen type to avoid conflicts
    // Macrobenthos: 1-999999, Zooplankton: 1000000-1999999, Phytoplankton: 2000000-2999999
    let nextId;
    if (currentSpecimenType === 'Macrobenthos') {
        nextId = 1;
    } else if (currentSpecimenType === 'Zooplankton') {
        nextId = 1000000;
    } else if (currentSpecimenType === 'Phytoplankton') {
        nextId = 2000000;
    } else {
        nextId = 3000000; // Default for other types
    }

    // Define rank hierarchy
    const rankHierarchy = ['Phylum', 'Class', 'Order', 'Family', 'Genus', 'Species'];

    for (let i = 1; i < lines.length; i++) {
        const values = parseCSVLine(lines[i]);
        if (values.length !== headers.length) {
            errors.push(`Row ${i + 1}: Column count mismatch`);
            continue;
        }

        const row = {};
        headers.forEach((header, index) => {
            row[header] = values[index].trim();
        });

        // Build hierarchical structure
        let parentId = null;

        for (const rank of rankHierarchy) {
            const rankLower = rank.toLowerCase();
            const taxonName = row[rankLower];

            if (!taxonName || taxonName === '') continue;

            const key = `${taxonName}|${rank}`;

            if (!taxaMap.has(key)) {
                const taxon = {
                    id: nextId++,
                    parentId: parentId,
                    name: taxonName,
                    rank: rank,
                    notes: null
                };
                taxaMap.set(key, taxon);
                parsedCsvData.push(taxon);
            }

            // Update parent for next level
            parentId = taxaMap.get(key).id;
        }
    }

    if (parsedCsvData.length === 0) {
        showImportError('No valid taxa found in CSV file.');
        return;
    }

    if (errors.length > 0) {
        importErrors.innerHTML = `<strong>Warning:</strong> ${errors.length} row(s) skipped due to errors:<ul>` +
            errors.slice(0, 5).map(e => `<li>${e}</li>`).join('') +
            (errors.length > 5 ? `<li>...and ${errors.length - 5} more</li>` : '') + '</ul>';
        importErrors.classList.remove('hidden');
    } else {
        importErrors.classList.add('hidden');
    }

    // Show preview
    showCsvPreview();
    importUploadBtn.disabled = false;
}

// Parse a single CSV line (handling quoted values)
function parseCSVLine(line) {
    const result = [];
    let current = '';
    let inQuotes = false;

    for (let i = 0; i < line.length; i++) {
        const char = line[i];
        if (char === '"') {
            inQuotes = !inQuotes;
        } else if (char === ',' && !inQuotes) {
            result.push(current);
            current = '';
        } else {
            current += char;
        }
    }
    result.push(current);
    return result;
}

// Show import error
function showImportError(message) {
    importErrors.innerHTML = message;
    importErrors.classList.remove('hidden');
    csvPreview.classList.add('hidden');
    importUploadBtn.disabled = true;
}

// Show CSV preview table
function showCsvPreview() {
    csvRowCount.textContent = parsedCsvData.length;

    let html = '<table><thead><tr><th>ID</th><th>Parent ID</th><th>Name</th><th>Rank</th><th>Notes</th></tr></thead><tbody>';

    const previewRows = parsedCsvData.slice(0, 10);
    previewRows.forEach(row => {
        html += `<tr>
            <td>${row.id}</td>
            <td>${row.parentId || '-'}</td>
            <td>${row.name}</td>
            <td>${row.rank}</td>
            <td>${row.notes || '-'}</td>
        </tr>`;
    });

    if (parsedCsvData.length > 10) {
        html += `<tr><td colspan="5" style="text-align: center; color: #666;">... and ${parsedCsvData.length - 10} more rows</td></tr>`;
    }

    html += '</tbody></table>';
    csvPreviewTable.innerHTML = html;
    csvPreview.classList.remove('hidden');
}

// Handle import upload
importUploadBtn.addEventListener('click', async () => {
    if (parsedCsvData.length === 0) return;

    const confirmed = confirm(`Import ${parsedCsvData.length} taxa to ${currentSpecimenType}? Existing taxa with matching IDs will be updated.`);
    if (!confirmed) return;

    setStatus('Importing...');
    importUploadBtn.disabled = true;

    try {
        const taxaRef = db.collection('taxonomies').doc(currentSpecimenType).collection('taxa');
        const batch = db.batch();
        let count = 0;

        for (const taxon of parsedCsvData) {
            const docRef = taxaRef.doc(taxon.id.toString());
            batch.set(docRef, {
                parentId: taxon.parentId,
                name: taxon.name,
                rank: taxon.rank,
                notes: taxon.notes,
                specimenType: currentSpecimenType
            });
            count++;

            // Firestore batch limit is 500
            if (count >= 500) {
                await batch.commit();
                count = 0;
            }
        }

        if (count > 0) {
            await batch.commit();
        }

        // Update metadata
        await db.collection('taxonomies').doc(currentSpecimenType).set({
            lastModified: firebase.firestore.FieldValue.serverTimestamp(),
            modifiedBy: auth.currentUser.email
        }, { merge: true });

        importModal.classList.add('hidden');
        setStatus(`Imported ${parsedCsvData.length} taxa successfully`);
        loadTaxonomy();
    } catch (error) {
        alert('Error importing: ' + error.message);
        setStatus('Error importing');
        importUploadBtn.disabled = false;
    }
});

// Export to CSV
exportCsvBtn.addEventListener('click', () => {
    if (allTaxa.length === 0) {
        alert('No taxa to export');
        return;
    }

    // Create CSV content
    let csv = 'id,parentId,name,rank,notes\n';

    allTaxa.forEach(taxon => {
        const notes = taxon.notes ? `"${taxon.notes.replace(/"/g, '""')}"` : '';
        csv += `${taxon.id},${taxon.parentId || ''},${taxon.name},${taxon.rank},${notes}\n`;
    });

    // Download file
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${currentSpecimenType}_taxonomy.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);

    setStatus(`Exported ${allTaxa.length} taxa to CSV`);
});

// Help modal functionality
const helpBtn = document.getElementById('help-btn');
const helpModal = document.getElementById('help-modal');
const helpCloseBtn = document.getElementById('help-close-btn');
const downloadSampleBtn = document.getElementById('download-sample-btn');

// Open help modal
helpBtn.addEventListener('click', () => {
    helpModal.classList.remove('hidden');
});

// Close help modal
helpCloseBtn.addEventListener('click', () => {
    helpModal.classList.add('hidden');
});

// Download sample CSV
downloadSampleBtn.addEventListener('click', () => {
    let sampleCsv = '';

    if (currentSpecimenType === 'Macrobenthos') {
        sampleCsv = `id,parentId,name,rank,notes
1,,Annelida,Phylum,Segmented worms
2,1,Polychaeta,Class,Marine bristle worms
3,2,Phyllodocida,Order,
4,3,Nereididae,Family,Ragworms
5,4,Nereis,Genus,
6,5,Nereis diversicolor,Species,Common ragworm
7,,Arthropoda,Phylum,Jointed-legged invertebrates
8,7,Malacostraca,Class,Crustaceans
9,8,Decapoda,Order,
10,9,Portunidae,Family,Swimming crabs
11,10,Portunus,Genus,
12,11,Portunus pelagicus,Species,Blue swimming crab
13,,Mollusca,Phylum,Soft-bodied invertebrates
14,13,Bivalvia,Class,Two-shelled molluscs
15,14,Veneroida,Order,
16,15,Veneridae,Family,Venus clams
17,16,Meretrix,Genus,
18,17,Meretrix meretrix,Species,Asiatic hard clam`;
    } else if (currentSpecimenType === 'Zooplankton') {
        sampleCsv = `id,parentId,name,rank,notes
1000001,,Arthropoda,Phylum,Jointed-legged invertebrates
1000002,1000001,Maxillopoda,Class,Copepods and relatives
1000003,1000002,Calanoida,Order,Calanoid copepods
1000004,1000003,Calanidae,Family,
1000005,1000004,Calanus,Genus,
1000006,1000005,Calanus finmarchicus,Species,Common calanoid copepod
1000007,1000002,Cyclopoida,Order,Cyclopoid copepods
1000008,1000007,Oithonidae,Family,
1000009,1000008,Oithona,Genus,
1000010,1000009,Oithona similis,Species,Small cyclopoid copepod
1000011,,Cnidaria,Phylum,Jellyfish and hydrozoans
1000012,1000011,Hydrozoa,Class,Hydroids
1000013,1000012,Siphonophora,Order,Colonial hydrozoans
1000014,1000013,Diphyidae,Family,`;
    } else if (currentSpecimenType === 'Phytoplankton') {
        // Use hierarchical format for Phytoplankton
        sampleCsv = `Taxa_ID,Phylum,Class,Order,Family,Genus
Phyt001,Heterokontophyta,Bacillariophyceae,Achnanthales,Achnanthaceae,Achnanthes
Phyt002,Heterokontophyta,Coscinodiscophyceae,Coscinodiscales,Hemidiscaceae,Actinocyclus
Phyt003,Heterokontophyta,Coscinodiscophyceae,Coscinodiscales,Heliopeltaceae,Actinoptychus
Phyt004,Dinoflagellata,Dinophyceae,Akashiwales,Akashiwaceae,Akashiwo
Phyt005,Dinoflagellata,Dinophyceae,Gonyaulacales,Pyrophacaceae,Alexandrium
Phyt006,Dinoflagellata,Dinophyceae,Dinophysales,Amphisoleniaceae,Amphisolenia
Phyt007,Heterokontophyta,Bacillariophyceae,Thalassiophysales,Catenulaceae,Amphora
Phyt008,Cyanobacteria,Cyanophyceae,Nostocales,Aphanizomenonaceae,Anabaena
Phyt009,Cyanobacteria,Cyanophyceae,Nostocales,Aphanizomenonaceae,Aphanizomenon
Phyt010,Cyanobacteria,Cyanophyceae,Oscillatoriales,Microcoleaceae,Arthrospira`;
    }

    // Download file
    const blob = new Blob([sampleCsv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `sample_${currentSpecimenType.toLowerCase()}_taxonomy.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);

    setStatus(`Downloaded sample CSV for ${currentSpecimenType}`);
});

// Close modals when clicking outside
window.addEventListener('click', (e) => {
    if (e.target === helpModal) {
        helpModal.classList.add('hidden');
    }
    if (e.target === importModal) {
        importModal.classList.add('hidden');
        resetImportModal();
    }
    if (e.target === addModal) {
        addModal.classList.add('hidden');
    }
    if (e.target === reviewChangesModal) {
        reviewChangesModal.classList.add('hidden');
    }
});

// Pending Changes Review functionality
const reviewChangesBtn = document.getElementById('review-changes-btn');
const reviewChangesModal = document.getElementById('review-changes-modal');
const reviewCloseBtn = document.getElementById('review-close-btn');
const pendingChangesList = document.getElementById('pending-changes-list');
const changeTypeFilter = document.getElementById('change-type-filter');
const changeStatusFilter = document.getElementById('change-status-filter');
const approveAllBtn = document.getElementById('approve-all-btn');
const rejectAllBtn = document.getElementById('reject-all-btn');
const pendingCountBadge = document.getElementById('pending-count-badge');

let allPendingChanges = [];

// Load pending changes count on auth state change
const originalAuthCallback = auth.onAuthStateChanged;
auth.onAuthStateChanged(async (user) => {
    if (user) {
        loadPendingChangesCount();
    }
});

// Load pending changes count (only counts pending status)
async function loadPendingChangesCount() {
    try {
        const snapshot = await db.collection('pending_changes')
            .where('status', '==', 'pending')
            .get();
        const count = snapshot.size;

        if (count > 0) {
            pendingCountBadge.textContent = count;
            pendingCountBadge.classList.remove('hidden');
        } else {
            pendingCountBadge.classList.add('hidden');
        }
    } catch (error) {
        console.error('Error loading pending changes count:', error);
    }
}

// Open review changes modal
reviewChangesBtn.addEventListener('click', () => {
    reviewChangesModal.classList.remove('hidden');
    loadPendingChanges();
});

// Close review changes modal
reviewCloseBtn.addEventListener('click', () => {
    reviewChangesModal.classList.add('hidden');
});

// Filter changes by type
changeTypeFilter.addEventListener('change', () => {
    renderPendingChanges();
});

// Filter changes by status
changeStatusFilter.addEventListener('change', () => {
    renderPendingChanges();
});

// Load pending changes from Firestore
async function loadPendingChanges() {
    pendingChangesList.innerHTML = '<p class="loading">Loading pending changes...</p>';

    try {
        const snapshot = await db.collection('pending_changes')
            .orderBy('timestamp', 'desc')
            .get();

        allPendingChanges = snapshot.docs.map(doc => ({
            docId: doc.id,
            ...doc.data()
        }));

        renderPendingChanges();

        // Update buttons state
        const hasChanges = allPendingChanges.length > 0;
        approveAllBtn.disabled = !hasChanges;
        rejectAllBtn.disabled = !hasChanges;

    } catch (error) {
        pendingChangesList.innerHTML = `<p class="error">Error loading changes: ${error.message}</p>`;
    }
}

// Render pending changes list
function renderPendingChanges() {
    const filterType = changeTypeFilter.value;
    const filterStatus = changeStatusFilter.value;

    let filteredChanges = allPendingChanges;

    // Filter by specimen type
    if (filterType !== 'all') {
        filteredChanges = filteredChanges.filter(c => c.specimenType === filterType);
    }

    // Filter by status
    if (filterStatus !== 'all') {
        filteredChanges = filteredChanges.filter(c => (c.status || 'pending') === filterStatus);
    }

    if (filteredChanges.length === 0) {
        pendingChangesList.innerHTML = '<p class="loading">No changes found matching filters.</p>';
        approveAllBtn.disabled = true;
        rejectAllBtn.disabled = true;
        return;
    }

    // Enable bulk buttons only if there are pending changes in the filtered list
    const hasPendingChanges = filteredChanges.some(c => (c.status || 'pending') === 'pending');
    approveAllBtn.disabled = !hasPendingChanges;
    rejectAllBtn.disabled = !hasPendingChanges;

    let html = '<table class="pending-changes-table"><thead><tr>';
    html += '<th>Type</th><th>Action</th><th>Specimen Type</th><th>Taxon</th><th>Device</th><th>Timestamp</th><th>Status</th><th>Actions</th>';
    html += '</tr></thead><tbody>';

    filteredChanges.forEach(change => {
        const changeData = change.newData ? JSON.parse(change.newData) : (change.oldData ? JSON.parse(change.oldData) : {});
        const taxonName = changeData.name || 'Unknown';
        const status = change.status || 'pending';
        let timestamp = 'Unknown';
        if (change.timestamp) {
            // Handle different timestamp formats
            if (change.timestamp.toDate) {
                // Firestore Timestamp object
                timestamp = change.timestamp.toDate().toLocaleString();
            } else if (change.timestamp.seconds) {
                // Firestore Timestamp as plain object
                timestamp = new Date(change.timestamp.seconds * 1000).toLocaleString();
            } else if (typeof change.timestamp === 'string') {
                // ISO 8601 string format
                timestamp = new Date(change.timestamp).toLocaleString();
            } else if (change.timestamp instanceof Date) {
                timestamp = change.timestamp.toLocaleString();
            }
        }

        let actionClass = '';
        if (change.changeType === 'create') actionClass = 'action-create';
        else if (change.changeType === 'update') actionClass = 'action-update';
        else if (change.changeType === 'delete') actionClass = 'action-delete';

        let statusClass = '';
        if (status === 'approved') statusClass = 'status-approved';
        else if (status === 'rejected') statusClass = 'status-rejected';
        else statusClass = 'status-pending';

        html += `<tr data-doc-id="${change.docId}">
            <td><span class="change-type ${actionClass}">${change.changeType}</span></td>
            <td class="change-details">`;

        if (change.changeType === 'update' && change.oldData && change.newData) {
            const oldData = JSON.parse(change.oldData);
            const newData = JSON.parse(change.newData);
            if (oldData.name !== newData.name) {
                html += `Name: ${oldData.name} → ${newData.name}<br>`;
            }
            if (oldData.rank !== newData.rank) {
                html += `Rank: ${oldData.rank} → ${newData.rank}<br>`;
            }
            if (oldData.parentId !== newData.parentId) {
                html += `Parent: ${oldData.parentId || 'root'} → ${newData.parentId || 'root'}`;
            }
        } else if (change.changeType === 'create') {
            html += `New: ${taxonName} (${changeData.rank || 'Unknown'})`;
        } else if (change.changeType === 'delete') {
            html += `Delete: ${taxonName}`;
        }

        html += `</td>
            <td>${change.specimenType}</td>
            <td>${taxonName}</td>
            <td>${change.deviceId || 'Unknown'}</td>
            <td>${timestamp}</td>
            <td><span class="change-status ${statusClass}">${status}</span></td>
            <td class="action-buttons">`;

        if (status === 'pending') {
            html += `<button class="btn-approve" onclick="approveChange('${change.docId}')">Approve</button>
                <button class="btn-reject" onclick="rejectChange('${change.docId}')">Reject</button>`;
        } else {
            html += `<span style="color: #999; font-size: 11px;">${status === 'approved' ? 'Applied' : 'Dismissed'}</span>`;
        }

        html += `</td>
        </tr>`;
    });

    html += '</tbody></table>';
    pendingChangesList.innerHTML = html;
}

// Approve a single change
async function approveChange(docId) {
    const change = allPendingChanges.find(c => c.docId === docId);
    if (!change) return;

    setStatus('Applying change...');

    try {
        const taxaRef = db.collection('taxonomies').doc(change.specimenType).collection('taxa');

        if (change.changeType === 'create' || change.changeType === 'update') {
            const newData = JSON.parse(change.newData);
            await taxaRef.doc(newData.id.toString()).set({
                parentId: newData.parentId || null,
                name: newData.name,
                rank: newData.rank,
                notes: newData.notes || null,
                specimenType: change.specimenType
            });
        } else if (change.changeType === 'delete') {
            const oldData = JSON.parse(change.oldData);
            await taxaRef.doc(oldData.id.toString()).delete();
        }

        // Update metadata
        await db.collection('taxonomies').doc(change.specimenType).set({
            lastModified: firebase.firestore.FieldValue.serverTimestamp(),
            modifiedBy: auth.currentUser.email
        }, { merge: true });

        // Update the change status to approved (keep for logging)
        await db.collection('pending_changes').doc(docId).update({
            status: 'approved',
            reviewedBy: auth.currentUser.email,
            reviewedAt: firebase.firestore.FieldValue.serverTimestamp()
        });

        // Refresh the list
        await loadPendingChanges();
        await loadPendingChangesCount();

        // Reload taxonomy if current type matches
        if (change.specimenType === currentSpecimenType) {
            loadTaxonomy();
        }

        setStatus('Change approved successfully');
    } catch (error) {
        alert('Error approving change: ' + error.message);
        setStatus('Error approving change');
    }
}

// Reject a single change
async function rejectChange(docId) {
    if (!confirm('Reject this change? It will be marked as rejected but kept in the log.')) return;

    setStatus('Rejecting change...');

    try {
        // Update status to rejected (keep for logging)
        await db.collection('pending_changes').doc(docId).update({
            status: 'rejected',
            reviewedBy: auth.currentUser.email,
            reviewedAt: firebase.firestore.FieldValue.serverTimestamp()
        });

        await loadPendingChanges();
        await loadPendingChangesCount();

        setStatus('Change rejected');
    } catch (error) {
        alert('Error rejecting change: ' + error.message);
        setStatus('Error rejecting change');
    }
}

// Approve all filtered changes
approveAllBtn.addEventListener('click', async () => {
    const filterType = changeTypeFilter.value;
    let filteredChanges = allPendingChanges;

    // Filter by specimen type
    if (filterType !== 'all') {
        filteredChanges = filteredChanges.filter(c => c.specimenType === filterType);
    }

    // Only process pending changes
    const pendingChanges = filteredChanges.filter(c => (c.status || 'pending') === 'pending');

    if (pendingChanges.length === 0) return;

    if (!confirm(`Approve all ${pendingChanges.length} pending changes?`)) return;

    setStatus('Approving all changes...');
    approveAllBtn.disabled = true;

    let approved = 0;
    let errors = 0;

    for (const change of pendingChanges) {
        try {
            const taxaRef = db.collection('taxonomies').doc(change.specimenType).collection('taxa');

            if (change.changeType === 'create' || change.changeType === 'update') {
                const newData = JSON.parse(change.newData);
                await taxaRef.doc(newData.id.toString()).set({
                    parentId: newData.parentId || null,
                    name: newData.name,
                    rank: newData.rank,
                    notes: newData.notes || null,
                    specimenType: change.specimenType
                });
            } else if (change.changeType === 'delete') {
                const oldData = JSON.parse(change.oldData);
                await taxaRef.doc(oldData.id.toString()).delete();
            }

            // Update status to approved
            await db.collection('pending_changes').doc(change.docId).update({
                status: 'approved',
                reviewedBy: auth.currentUser.email,
                reviewedAt: firebase.firestore.FieldValue.serverTimestamp()
            });
            approved++;
        } catch (error) {
            console.error('Error approving change:', error);
            errors++;
        }
    }

    // Update metadata for affected specimen types
    const affectedTypes = [...new Set(pendingChanges.map(c => c.specimenType))];
    for (const type of affectedTypes) {
        await db.collection('taxonomies').doc(type).set({
            lastModified: firebase.firestore.FieldValue.serverTimestamp(),
            modifiedBy: auth.currentUser.email
        }, { merge: true });
    }

    await loadPendingChanges();
    await loadPendingChangesCount();
    loadTaxonomy();

    setStatus(`Approved ${approved} changes${errors > 0 ? `, ${errors} errors` : ''}`);
});

// Reject all filtered changes
rejectAllBtn.addEventListener('click', async () => {
    const filterType = changeTypeFilter.value;
    let filteredChanges = allPendingChanges;

    // Filter by specimen type
    if (filterType !== 'all') {
        filteredChanges = filteredChanges.filter(c => c.specimenType === filterType);
    }

    // Only process pending changes
    const pendingChanges = filteredChanges.filter(c => (c.status || 'pending') === 'pending');

    if (pendingChanges.length === 0) return;

    if (!confirm(`Reject all ${pendingChanges.length} pending changes? They will be marked as rejected but kept in the log.`)) return;

    setStatus('Rejecting all changes...');
    rejectAllBtn.disabled = true;

    let rejected = 0;

    for (const change of pendingChanges) {
        try {
            // Update status to rejected
            await db.collection('pending_changes').doc(change.docId).update({
                status: 'rejected',
                reviewedBy: auth.currentUser.email,
                reviewedAt: firebase.firestore.FieldValue.serverTimestamp()
            });
            rejected++;
        } catch (error) {
            console.error('Error rejecting change:', error);
        }
    }

    await loadPendingChanges();
    await loadPendingChangesCount();

    setStatus(`Rejected ${rejected} changes`);
});

// ==================== Report Information Section ====================

const saveReportInfoBtn = document.getElementById('save-report-info-btn');
const clearReportInfoBtn = document.getElementById('clear-report-info-btn');
const sammNoInput = document.getElementById('samm-no');
const reportNoInput = document.getElementById('report-no');
const institutionInput = document.getElementById('institution');
const clientAddressInput = document.getElementById('client-address');
const authorisedByInput = document.getElementById('authorised-by');

// Save Report Info to localStorage
saveReportInfoBtn.addEventListener('click', () => {
    const reportInfo = {
        sammNo: sammNoInput.value.trim(),
        // reportNo is auto-generated from selected results, not saved
        institution: institutionInput.value.trim(),
        clientAddress: clientAddressInput.value.trim(),
        authorisedBy: authorisedByInput.value.trim()
    };

    localStorage.setItem('reportInfo', JSON.stringify(reportInfo));
    setStatus('Report information saved');
});

// Clear Report Info
clearReportInfoBtn.addEventListener('click', () => {
    sammNoInput.value = '';
    // reportNo is auto-generated, don't clear it here
    institutionInput.value = '';
    clientAddressInput.value = '';
    authorisedByInput.value = '';
    localStorage.removeItem('reportInfo');
    setStatus('Report information cleared');
});

// Load Report Info from localStorage
function loadReportInfo() {
    const savedInfo = localStorage.getItem('reportInfo');
    if (savedInfo) {
        try {
            const reportInfo = JSON.parse(savedInfo);
            sammNoInput.value = reportInfo.sammNo || '';
            // reportNo is auto-generated from selected results, not loaded
            institutionInput.value = reportInfo.institution || '';
            clientAddressInput.value = reportInfo.clientAddress || '';
            authorisedByInput.value = reportInfo.authorisedBy || '';
        } catch (error) {
            console.error('Error loading report info:', error);
        }
    }
}

// ==================== Analysis Results Section ====================

const resultsClientFilter = document.getElementById('results-client-filter');
const resultsSearchBtn = document.getElementById('results-search-btn');
const exportSelectedBtn = document.getElementById('export-selected-btn');
const generateExcelBtn = document.getElementById('generate-excel-btn');
const generatePdfBtn = document.getElementById('generate-pdf-btn');
const selectAllResultsBtn = document.getElementById('select-all-results-btn');
const deselectAllResultsBtn = document.getElementById('deselect-all-results-btn');
const resultsCountSpan = document.getElementById('results-count');
const selectedCountSpan = document.getElementById('selected-count');
const analysisResultsList = document.getElementById('analysis-results-list');

let analysisResults = [];
let selectedResults = new Set();

// Search button
resultsSearchBtn.addEventListener('click', loadAnalysisResults);

// Load Analysis Results from Firebase
async function loadAnalysisResults() {
    analysisResultsList.innerHTML = '<p class="loading">Loading analysis results...</p>';
    selectedResults.clear();
    updateSelectedCount();

    try {
        console.log('Loading analysis results for:', currentReportingType);
        let query = db.collection('analysis_results');

        // Filter by current reporting type
        query = query.where('specimenType', '==', currentReportingType);

        let snapshot;
        try {
            // Try with orderBy first
            snapshot = await query.orderBy('uploadedAt', 'desc').get();
        } catch (indexError) {
            // If index error, fall back to query without orderBy
            console.warn('Index not available, fetching without orderBy:', indexError);
            console.log('To create the required index, check your browser console for the index creation link');
            snapshot = await query.get();
        }

        console.log('Found documents:', snapshot.size);

        analysisResults = [];
        const clientFilter = resultsClientFilter.value.toLowerCase().trim();

        snapshot.forEach(doc => {
            const data = doc.data();
            console.log('Document data:', data);
            console.log('Date Received value:', data.dateReceived, 'Type:', typeof data.dateReceived);
            // Apply client filter
            if (clientFilter && !data.clientName.toLowerCase().includes(clientFilter)) {
                return;
            }
            analysisResults.push({
                id: doc.id,
                ...data
            });
        });

        // Sort by uploadedAt if available (client-side sorting)
        analysisResults.sort((a, b) => {
            const dateA = a.uploadedAt ? new Date(a.uploadedAt) : new Date(0);
            const dateB = b.uploadedAt ? new Date(b.uploadedAt) : new Date(0);
            return dateB - dateA;
        });

        console.log('Filtered results:', analysisResults.length);
        resultsCountSpan.textContent = `${analysisResults.length} results`;
        renderAnalysisResults();
    } catch (error) {
        console.error('Error loading analysis results:', error);
        console.error('Error details:', error.message, error.code);
        analysisResultsList.innerHTML = `<p class="error">Error loading results: ${error.message}<br>Please check the browser console for details.</p>`;
    }
}

// Render Analysis Results
function renderAnalysisResults() {
    if (analysisResults.length === 0) {
        analysisResultsList.innerHTML = '<p style="padding: 20px; text-align: center; color: #666;">No analysis results found.</p>';
        exportSelectedBtn.disabled = true;
        return;
    }

    let html = '<table class="analysis-results-table">';
    html += `<thead>
        <tr>
            <th><input type="checkbox" id="select-all-checkbox"></th>
            <th>Station</th>
            <th>Type</th>
            <th>Client</th>
            <th>Biologist</th>
            <th>Date</th>
            <th>Taxa</th>
            <th>Actions</th>
        </tr>
    </thead><tbody>`;

    for (const result of analysisResults) {
        const typeClass = `result-type-${result.specimenType.toLowerCase()}`;
        const analyzedDate = result.analyzedDate ? new Date(result.analyzedDate).toLocaleDateString() : 'N/A';
        const taxaCount = result.counts ? result.counts.length : 0;

        html += `
            <tr class="analysis-result-item" data-id="${result.id}">
                <td>
                    <input type="checkbox" class="result-select" data-id="${result.id}" ${selectedResults.has(result.id) ? 'checked' : ''}>
                </td>
                <td>${result.stationId || 'N/A'}</td>
                <td><span class="result-type ${typeClass}">${result.specimenType}</span></td>
                <td>${result.clientName || 'N/A'}</td>
                <td>${result.biologistId || 'N/A'}</td>
                <td>${analyzedDate}</td>
                <td>${taxaCount}</td>
                <td>
                    <button class="btn-secondary view-result-btn" data-id="${result.id}">View</button>
                    <button class="btn-danger delete-result-btn" data-id="${result.id}" style="padding: 4px 8px; font-size: 11px;">Delete</button>
                </td>
            </tr>
        `;
    }

    html += '</tbody></table>';
    analysisResultsList.innerHTML = html;

    // Add event listeners
    document.querySelectorAll('.result-select').forEach(cb => {
        cb.addEventListener('change', (e) => {
            if (e.target.checked) {
                selectedResults.add(e.target.dataset.id);
            } else {
                selectedResults.delete(e.target.dataset.id);
            }
            updateSelectedCount();
        });
    });

    document.getElementById('select-all-checkbox').addEventListener('change', (e) => {
        document.querySelectorAll('.result-select').forEach(cb => {
            cb.checked = e.target.checked;
            if (e.target.checked) {
                selectedResults.add(cb.dataset.id);
            } else {
                selectedResults.delete(cb.dataset.id);
            }
        });
        updateSelectedCount();
    });

    document.querySelectorAll('.view-result-btn').forEach(btn => {
        btn.addEventListener('click', () => viewAnalysisResult(btn.dataset.id));
    });

    document.querySelectorAll('.delete-result-btn').forEach(btn => {
        btn.addEventListener('click', () => deleteAnalysisResult(btn.dataset.id));
    });
}

// Update selected count and report cover
function updateSelectedCount() {
    selectedCountSpan.textContent = `${selectedResults.size} selected`;
    const hasSelection = selectedResults.size > 0;
    exportSelectedBtn.disabled = !hasSelection;
    generateExcelBtn.disabled = !hasSelection;
    generatePdfBtn.disabled = !hasSelection;

    // Update report cover field
    const reportNoInput = document.getElementById('report-no');
    if (hasSelection) {
        // Get selected results data
        const selectedData = analysisResults.filter(r => selectedResults.has(r.id));

        // Extract and sort report numbers
        const reportNumbers = selectedData
            .map(r => r.reportNo)
            .filter(rn => rn && rn.trim() !== '')
            .sort();

        if (reportNumbers.length > 0) {
            // Generate report cover range
            const firstReport = reportNumbers[0];
            const lastReport = reportNumbers[reportNumbers.length - 1];

            if (firstReport === lastReport) {
                reportNoInput.value = firstReport;
            } else {
                reportNoInput.value = `${firstReport} - ${lastReport}`;
            }
        } else {
            reportNoInput.value = '';
        }
    } else {
        reportNoInput.value = '';
    }
}

// Select All / Deselect All
selectAllResultsBtn.addEventListener('click', () => {
    document.querySelectorAll('.result-select').forEach(cb => {
        cb.checked = true;
        selectedResults.add(cb.dataset.id);
    });
    const selectAllCb = document.getElementById('select-all-checkbox');
    if (selectAllCb) selectAllCb.checked = true;
    updateSelectedCount();
});

deselectAllResultsBtn.addEventListener('click', () => {
    document.querySelectorAll('.result-select').forEach(cb => {
        cb.checked = false;
    });
    selectedResults.clear();
    const selectAllCb = document.getElementById('select-all-checkbox');
    if (selectAllCb) selectAllCb.checked = false;
    updateSelectedCount();
});

// View Analysis Result Details
async function viewAnalysisResult(id) {
    const result = analysisResults.find(r => r.id === id);
    if (!result) return;

    let detailsHtml = `
        <h4>Analysis Details</h4>
        <p><strong>Station:</strong> ${result.stationId}</p>
        <p><strong>Client:</strong> ${result.clientName}</p>
        <p><strong>Type:</strong> ${result.specimenType}</p>
        <p><strong>Biologist:</strong> ${result.biologistId}</p>
        <p><strong>SAMM No:</strong> ${result.sammNo || 'N/A'}</p>
        <p><strong>Report No:</strong> ${result.reportNo || 'N/A'}</p>
        <p><strong>Reference ID:</strong> ${result.referenceId || 'N/A'}</p>
        <hr>
        <h4>Taxa Counts (${result.counts ? result.counts.length : 0} taxa)</h4>
        <div style="max-height: 200px; overflow-y: auto;">
            <table style="width: 100%; font-size: 12px; border-collapse: collapse;">
                <tr><th style="text-align: left; padding: 5px;">Taxon</th><th style="text-align: right; padding: 5px;">Count</th><th style="text-align: right; padding: 5px;">Density</th></tr>
    `;

    if (result.counts) {
        for (const count of result.counts) {
            const density = count.density ? count.density.toFixed(2) : 'N/A';
            detailsHtml += `<tr><td style="padding: 5px;">${count.taxonName}</td><td style="text-align: right; padding: 5px;">${count.count}</td><td style="text-align: right; padding: 5px;">${density}</td></tr>`;
        }
    }

    detailsHtml += '</table></div>';

    alert(detailsHtml.replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' '));
}

// Delete Analysis Result
async function deleteAnalysisResult(id) {
    if (!confirm('Are you sure you want to delete this analysis result?')) return;

    try {
        await db.collection('analysis_results').doc(id).delete();
        setStatus('Analysis result deleted');
        await loadAnalysisResults();
    } catch (error) {
        console.error('Error deleting result:', error);
        setStatus('Error deleting result');
    }
}

// Export Selected Results to CSV
exportSelectedBtn.addEventListener('click', () => {
    if (selectedResults.size === 0) return;

    const selectedData = analysisResults.filter(r => selectedResults.has(r.id));

    // Build CSV with flattened taxa data
    let csv = 'Station,Type,Client,Biologist,SAMM No,Report No,Reference ID,Analyzed Date,Area of Grab,Filtered Volume,Taxon,Hierarchy,Count,Density,Note\n';

    for (const result of selectedData) {
        const analyzedDate = result.analyzedDate ? new Date(result.analyzedDate).toISOString().split('T')[0] : '';
        const baseData = [
            result.stationId || '',
            result.specimenType || '',
            (result.clientName || '').replace(/,/g, ';'),
            result.biologistId || '',
            result.sammNo || '',
            result.reportNo || '',
            result.referenceId || '',
            analyzedDate,
            result.areaOfGrab || '',
            result.filteredVolume || ''
        ];

        if (result.counts && result.counts.length > 0) {
            for (const count of result.counts) {
                const hierarchy = count.hierarchy ? count.hierarchy.join(' > ') : '';
                const density = count.density ? count.density.toFixed(4) : '';
                const row = [
                    ...baseData,
                    (count.taxonName || '').replace(/,/g, ';'),
                    hierarchy.replace(/,/g, ';'),
                    count.count || 0,
                    density,
                    (count.note || '').replace(/,/g, ';')
                ];
                csv += row.join(',') + '\n';
            }
        } else {
            csv += baseData.join(',') + ',,,,\n';
        }
    }

    // Download CSV
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `analysis_results_${new Date().toISOString().split('T')[0]}.csv`;
    a.click();
    URL.revokeObjectURL(url);

    setStatus(`Exported ${selectedResults.size} results to CSV`);
});

// Generate Excel Report
generateExcelBtn.addEventListener('click', () => {
    if (selectedResults.size === 0) return;

    const selectedData = analysisResults.filter(r => selectedResults.has(r.id));

    // Group by specimen type
    const specimenTypes = [...new Set(selectedData.map(r => r.specimenType))];

    const workbook = XLSX.utils.book_new();

    for (const specimenType of specimenTypes) {
        const typeResults = selectedData.filter(r => r.specimenType === specimenType);

        // Sheet 1: Sample Info
        const infoData = createSampleInfoData(typeResults, specimenType);
        const infoSheet = XLSX.utils.aoa_to_sheet(infoData);
        XLSX.utils.book_append_sheet(workbook, infoSheet, `${specimenType} - Info`);

        // Sheet 2: Sample List
        const listData = createSampleListData(typeResults);
        const listSheet = XLSX.utils.aoa_to_sheet(listData);

        // Apply center alignment to table headers and data (rows 7 onwards)
        const range = XLSX.utils.decode_range(listSheet['!ref']);
        for (let R = 6; R <= range.e.r; R++) { // Row 7 (index 6) onwards
            for (let C = range.s.c; C <= range.e.c; C++) {
                const cellAddress = XLSX.utils.encode_cell({ r: R, c: C });
                if (!listSheet[cellAddress]) continue;

                // Initialize cell style if not exists
                if (!listSheet[cellAddress].s) {
                    listSheet[cellAddress].s = {};
                }

                // Set center alignment
                listSheet[cellAddress].s.alignment = {
                    horizontal: 'center',
                    vertical: 'center'
                };
            }
        }

        XLSX.utils.book_append_sheet(workbook, listSheet, 'Sample List');

        // Sheet 3+: Macro Analysis (paginated - max 6 samples per sheet)
        const maxSamplesPerPage = 6;
        const numPages = Math.ceil(typeResults.length / maxSamplesPerPage);

        for (let pageIndex = 0; pageIndex < numPages; pageIndex++) {
            const startIdx = pageIndex * maxSamplesPerPage;
            const endIdx = Math.min(startIdx + maxSamplesPerPage, typeResults.length);
            const pageResults = typeResults.slice(startIdx, endIdx);

            const analysisData = createAnalysisData(pageResults);
            const analysisSheet = XLSX.utils.aoa_to_sheet(analysisData);

            // Apply formatting to the analysis sheet
            const range = XLSX.utils.decode_range(analysisSheet['!ref']);

            // Find row indices for special formatting
            const areaOfGrabRow = 4; // Row 5 in Excel (0-indexed: row 5 = index 4)
            const dataStartRow = 2; // Row 3 where table data starts (Reference ID row)

            // Find the row with "Total Number of Taxa:" to add bold top border
            let totalTaxaRow = -1;
            for (let R = dataStartRow; R <= range.e.r; R++) {
                const cellAddress = XLSX.utils.encode_cell({ r: R, c: 5 });
                if (analysisSheet[cellAddress] &&
                    analysisSheet[cellAddress].v === 'Total Number of Taxa:') {
                    totalTaxaRow = R;
                    break;
                }
            }

            // Apply borders and alignment to all cells in the table
            for (let R = dataStartRow; R <= range.e.r; R++) {
                for (let C = range.s.c; C <= range.e.c; C++) {
                    const cellAddress = XLSX.utils.encode_cell({ r: R, c: C });
                    if (!analysisSheet[cellAddress]) {
                        analysisSheet[cellAddress] = { t: 's', v: '' };
                    }

                    if (!analysisSheet[cellAddress].s) {
                        analysisSheet[cellAddress].s = {};
                    }

                    // Default borders - thin horizontal, bold vertical
                    const border = {
                        top: { style: 'thin', color: { rgb: 'D3D3D3' } },
                        bottom: { style: 'thin', color: { rgb: 'D3D3D3' } },
                        left: { style: 'medium', color: { rgb: 'D3D3D3' } },   // Bold vertical
                        right: { style: 'medium', color: { rgb: 'D3D3D3' } }   // Bold vertical
                    };

                    // Bold line after Area of grab row
                    if (R === areaOfGrabRow) {
                        border.bottom = { style: 'medium', color: { rgb: '000000' } };
                    }

                    // Bold line before Total Number of Taxa
                    if (R === totalTaxaRow) {
                        border.top = { style: 'medium', color: { rgb: '000000' } };
                    }

                    analysisSheet[cellAddress].s.border = border;

                    // Center-align sample columns (all columns except first column which is column 5, index 5)
                    // Column 6 onwards (index 6+) are sample data columns
                    if (C >= 6) {
                        analysisSheet[cellAddress].s.alignment = {
                            horizontal: 'center',
                            vertical: 'center'
                        };
                    }

                    // Ensure black font color
                    analysisSheet[cellAddress].s.font = {
                        color: { rgb: '000000' }
                    };
                }
            }

            // Determine sheet name based on specimen type
            let analysisSheetName;
            if (specimenType === 'Macrobenthos') {
                analysisSheetName = numPages > 1 ? `Macro Analysis ${pageIndex + 1}` : 'Macro Analysis';
            } else if (specimenType === 'Phytoplankton') {
                analysisSheetName = numPages > 1 ? `Phyto Analysis ${pageIndex + 1}` : 'Phyto Analysis';
            } else if (specimenType === 'Zooplankton') {
                analysisSheetName = numPages > 1 ? `Zoo Analysis ${pageIndex + 1}` : 'Zoo Analysis';
            } else {
                analysisSheetName = numPages > 1 ? `${specimenType} Analysis ${pageIndex + 1}` : `${specimenType} Analysis`;
            }

            XLSX.utils.book_append_sheet(workbook, analysisSheet, analysisSheetName);
        }
    }

    // Download
    const timestamp = new Date().toISOString().split('T')[0];
    XLSX.writeFile(workbook, `analysis_report_${timestamp}.xlsx`);

    setStatus(`Generated Excel report with ${selectedResults.size} samples`);

    // Save report log
    const firstResult = selectedData[0];
    const reportNumbers = selectedData
        .map(r => r.reportNo)
        .filter(rn => rn && rn.trim() !== '')
        .sort();
    const reportCover = reportNumbers.length > 0
        ? (reportNumbers[0] === reportNumbers[reportNumbers.length - 1]
            ? reportNumbers[0]
            : `${reportNumbers[0]} - ${reportNumbers[reportNumbers.length - 1]}`)
        : '';

    saveReportLog({
        clientName: firstResult.clientName,
        institution: firstResult.institution,
        referenceId: firstResult.referenceId,
        reportCover: reportCover,
        dateReceived: firstResult.dateReceived,
        numberOfSamples: selectedData.length,
        reportType: 'Excel',
        specimenType: specimenTypes.join(', ')
    });
});

// Helper: Create Sample Info sheet data
function createSampleInfoData(results, specimenType) {
    const sample = results[0] || {};

    // Get report info from localStorage
    const reportInfo = localStorage.getItem('reportInfo');
    let sammNo = '';
    let clientAddress = '';
    let authorisedBy = '';

    if (reportInfo) {
        try {
            const info = JSON.parse(reportInfo);
            sammNo = info.sammNo || '';
            // reportNo is no longer in localStorage - calculate from results
            clientAddress = info.clientAddress || '';
            authorisedBy = info.authorisedBy || '';
        } catch (e) {
            console.error('Error parsing report info:', e);
        }
    }

    // Calculate report cover range from results
    const reportNumbers = results
        .map(r => r.reportNo)
        .filter(rn => rn && rn.trim() !== '')
        .sort();

    let reportNo = '';
    if (reportNumbers.length > 0) {
        const firstReport = reportNumbers[0];
        const lastReport = reportNumbers[reportNumbers.length - 1];
        reportNo = (firstReport === lastReport) ? firstReport : `${firstReport} - ${lastReport}`;
    }

    // Collect all unique station IDs (sample markings)
    const allStationIds = [...new Set(results.map(r => r.stationId))].sort().join(', ');

    const data = [
        ['ALCHEMY Laboratory & Services Sdn. Bhd. (Company No: 903112 K)', '', '', '', '', `SAMM NO. ${sammNo}`],
        ['326B, 1st Floor, Lot 2520, Jalan Hijiran, Mukim Losong,', '', '', '', '', ''],
        ['20300, Kuala Terengganu, Terengganu, Malaysia.', '', '', '', '', ''],
        ['Tel: +609-622 4166, Fax: +609-622 4177.', '', '', '', '', ''],
        ['', '', '', '', '', ''],
        ['', '', '', '', `Report ID : ${reportNo}`, ''],
        ['', '', '', '', `Date : ${new Date().toLocaleDateString('en-GB')}`, ''],
        ['', '', '', '', 'Pages : 3', ''],
        ['', '', '', '', '', ''],
        ['CERTIFICATE OF ANALYSIS', '', '', '', '', ''],
        [`${specimenType}: Sample Information`, '', '', '', '', ''],
        ['', '', '', '', '', ''],
        ['Client Name:', sample.clientName || '', '', '', '', ''],
        ['Client Address:', clientAddress || sample.clientAddress || '', '', '', '', ''],
        ['', '', '', '', '', ''],
        ['Sample Type:', 'Sediment', '', '', '', ''],
        ['Sample Marking:', allStationIds || '', '', '', '', ''],
        ['Number of samples:', results.length, '', '', '', ''],
        ['Number of replicates:', 'N/A', '', '', '', ''],
        ['Date Received:', sample.dateReceived ? new Date(sample.dateReceived).toLocaleDateString('en-GB') : '', '', '', '', ''],
        ['Gear used:', sample.gearUsed || '', '', '', '', '']
    ];

    if (specimenType === 'Macrobenthos') {
        data.push(
            ['Area of Grab:', sample.areaOfGrab ? `${sample.areaOfGrab} m²` : '', '', '', '', ''],
            ['Sieve size:', sample.sieveSize ? `${sample.sieveSize} mm` : '', '', '', '', '']
        );
    } else {
        data.push(
            ['Net Diameter:', sample.netDiameter || '', '', '', '', ''],
            ['Net Mesh:', sample.netMesh || '', '', '', '', ''],
            ['Tow Type:', sample.towType || '', '', '', '', ''],
            ['Filtered Volume:', sample.filteredVolume ? `${sample.filteredVolume} L` : '', '', '', '', '']
        );
    }

    data.push(
        ['Method of Analysis:', sample.methodAnalysis || 'SOP No.: ALC_B_004', '', '', '', ''],
        ['Comments:', 'based on APHA 10500 C', '', '', '', ''],
        ['', '', '', '', '', ''],
        ['', '', '', '', '', ''],
        ['The details above are provided by the client. The reported results refer to sample(s) submitted by client only.', '', '', '', '', ''],
        ['', '', '', '', '', ''],
        ['Authorized by:', '', '', '', '', ''],
        ['', '', '', '', '', ''],
        ['', '', '', '', '', ''],
        ['.............................................', '', '', '', '', ''],
        [authorisedBy || 'Muhammad Firdaus Bin Daud', '', '', '', '', ''],
        ['Marine Biologist', '', '', '', '', ''],
        ['BSc.(Marine Science)', '', '', '', '', '']
    );

    return data;
}

// Helper: Create Sample List sheet data
function createSampleListData(results) {
    const sample = results[0] || {};

    // Get report info from localStorage
    const reportInfo = localStorage.getItem('reportInfo');
    let institution = '';

    if (reportInfo) {
        try {
            const info = JSON.parse(reportInfo);
            // reportNo is no longer in localStorage - each result has its own auto-generated reportNo
            institution = info.institution || '';
        } catch (e) {
            console.error('Error parsing report info:', e);
        }
    }

    const data = [
        ['ALCHEMY Laboratory & Services Sdn Bhd', '', '', '', ''],
        ['', '', '', '', ''],
        ['Client:', sample.clientName || '', '', '', ''],
        ['Institution:', institution || sample.institution || sample.clientName || '', '', '', ''],
        ['Description:', 'SEDIMENT', '', '', ''],
        ['', '', '', '', ''],
        ['', 'Date Received', 'Sample Marking', 'Date of Analysis', 'Reference ID', 'Report No.']
    ];

    results.forEach((result, index) => {
        data.push([
            index + 1,
            result.dateReceived ? new Date(result.dateReceived).toLocaleDateString('en-GB') : '',
            result.stationId || '',
            result.analyzedDate ? new Date(result.analyzedDate).toLocaleDateString('en-GB') : '',
            result.referenceId || '',
            result.reportNo || ''  // Use individual result's auto-generated Report No.
        ]);
    });

    return data;
}

// Helper: Create Analysis sheet data
function createAnalysisData(results) {
    const specimenType = results[0]?.specimenType || 'Macrobenthos';

    // Build hierarchical taxonomy tree structure
    const taxonomyTree = buildTaxonomyTree(results);

    // Initialize data array with headers
    const data = [];

    // Row 1: Company name
    data.push(['ALCHEMY Laboratory & Services Sdn Bhd', '', '', '', '', ...new Array(results.length).fill('')]);

    // Row 2: Sheet title
    const densityUnit = specimenType === 'Macrobenthos' ? 'unit m2' : 'units/L';
    data.push([`${specimenType} Data Sheet: Analysed density per sample/${densityUnit}`, '', '', '', '', ...new Array(results.length).fill('')]);

    // Row 3: Reference IDs (part of table)
    const refIdRow = ['', '', '', '', '', 'Reference ID:', ...results.map(r => r.referenceId || '')];
    data.push(refIdRow);

    // Row 4: Sample Markings (part of table)
    const sampleRow = ['', '', '', '', '', 'Sample Marking:', ...results.map(r => r.stationId || '')];
    data.push(sampleRow);

    // Row 5: Area/Volume (part of table)
    const areaLabel = specimenType === 'Macrobenthos' ? 'Area of grab (m2)' : 'Filtered Volume (L)';
    const areaValues = results.map(r => {
        if (specimenType === 'Macrobenthos') {
            return r.areaOfGrab || 0.3;
        } else {
            return r.filteredVolume || 1;
        }
    });
    data.push(['', '', '', '', '', areaLabel, ...areaValues]);

    // Add taxonomy rows
    const taxonomyRows = renderTaxonomyTree(taxonomyTree, results);
    data.push(...taxonomyRows);

    // Add empty separator row
    data.push(['', '', '', '', '', '', ...new Array(results.length).fill('')]);

    // Summary statistics (all part of table)
    // Total Number of Taxa
    const taxaCounts = calculateTaxaCounts(results);
    data.push(['', '', '', '', '', 'Total Number of Taxa:', ...taxaCounts]);

    // Overall density
    const overallDensities = calculateOverallDensities(results);
    const densityLabel2 = specimenType === 'Macrobenthos' ? 'Overall density(units/m2):' : 'Overall density(units/L):';
    data.push(['', '', '', '', '', densityLabel2, ...overallDensities]);

    // Taxa diversity Index (H')
    const shannonIndices = calculateShannonIndices(results);
    data.push(['', '', '', '', '', "Taxa diversity Index (H'):", ...shannonIndices]);

    // Evenness Index (J')
    const evennessIndices = calculateEvennessIndices(results);
    data.push(['', '', '', '', '', "Eveness Index (J'):", ...evennessIndices]);

    return data;
}

// Helper: Build complete taxonomy tree from all results
function buildTaxonomyTree(results) {
    const tree = {};

    // Collect all taxa with their hierarchies
    results.forEach((result, resultIndex) => {
        if (!result.counts) return;

        result.counts.forEach(count => {
            const hierarchy = count.hierarchy || [];
            if (hierarchy.length === 0) return;

            // Build path through tree
            let currentLevel = tree;
            hierarchy.forEach((taxonName, level) => {
                if (!currentLevel[taxonName]) {
                    currentLevel[taxonName] = {
                        name: taxonName,
                        rank: getRankFromLevel(level, results[0]?.specimenType),
                        children: {},
                        densities: new Array(results.length).fill(null),
                        counts: new Array(results.length).fill(0)
                    };
                }

                // If this is the final level (the taxon that was counted)
                if (level === hierarchy.length - 1) {
                    currentLevel[taxonName].densities[resultIndex] = count.density;
                    currentLevel[taxonName].counts[resultIndex] = count.count;
                }

                currentLevel = currentLevel[taxonName].children;
            });
        });
    });

    return tree;
}

// Helper: Get rank name from hierarchy level
function getRankFromLevel(level, specimenType) {
    if (specimenType === 'Phytoplankton') {
        const ranks = ['Division', 'Class', 'Order', 'Family', 'Genus', 'Species'];
        return ranks[level] || '';
    } else {
        const ranks = ['Phylum', 'Class', 'Order', 'Family', 'Genus', 'Species'];
        return ranks[level] || '';
    }
}

// Helper: Render taxonomy tree to rows with proper indentation
function renderTaxonomyTree(tree, results, level = 0, rows = []) {
    // Sort taxa alphabetically at each level
    const sortedKeys = Object.keys(tree).sort();

    sortedKeys.forEach(taxonName => {
        const taxon = tree[taxonName];
        const row = new Array(6 + results.length).fill('');

        // Add indentation and taxon name
        if (level === 0) {
            row[0] = `${taxon.rank}:`;
            row[1] = taxon.name;
        } else {
            // Indentation by level
            row[level] = `${taxon.rank}:`;
            row[level + 1] = taxon.name;
        }

        // Add density values (only where counted)
        for (let i = 0; i < results.length; i++) {
            if (taxon.densities[i] !== null) {
                row[6 + i] = taxon.densities[i];
            }
        }

        rows.push(row);

        // Add empty row if this taxon has no children (leaf node)
        if (Object.keys(taxon.children).length === 0) {
            rows.push(new Array(6 + results.length).fill(''));
        }

        // Recursively render children
        if (Object.keys(taxon.children).length > 0) {
            renderTaxonomyTree(taxon.children, results, level + 1, rows);
        }
    });

    return rows;
}

// Helper: Calculate total number of unique taxa per sample
function calculateTaxaCounts(results) {
    return results.map(result => {
        if (!result.counts || result.counts.length === 0) return 0;
        // Count unique taxa (taxa with non-zero counts)
        return result.counts.filter(c => c.count > 0).length;
    });
}

// Helper: Calculate overall density per sample
function calculateOverallDensities(results) {
    return results.map(result => {
        if (!result.counts || result.counts.length === 0) return 0;
        // Sum all densities
        const totalDensity = result.counts.reduce((sum, c) => sum + (c.density || 0), 0);
        return totalDensity;
    });
}

// Helper: Calculate Shannon Diversity Index (H') for each sample
function calculateShannonIndices(results) {
    return results.map(result => {
        if (!result.counts || result.counts.length === 0) return 0;

        // Get counts for taxa with non-zero counts
        const counts = result.counts.filter(c => c.count > 0).map(c => c.count);
        if (counts.length === 0) return 0;

        // Calculate total individuals
        const totalIndividuals = counts.reduce((sum, count) => sum + count, 0);
        if (totalIndividuals === 0) return 0;

        // Calculate Shannon Index: H' = -Σ(pi × ln(pi))
        let shannonIndex = 0;
        counts.forEach(count => {
            const proportion = count / totalIndividuals;
            if (proportion > 0) {
                shannonIndex -= proportion * Math.log(proportion);
            }
        });

        return shannonIndex;
    });
}

// Helper: Calculate Pielou's Evenness Index (J') for each sample
function calculateEvennessIndices(results) {
    return results.map((result, index) => {
        if (!result.counts || result.counts.length === 0) return 0;

        // Get counts for taxa with non-zero counts
        const counts = result.counts.filter(c => c.count > 0).map(c => c.count);
        const numSpecies = counts.length;
        if (numSpecies === 0 || numSpecies === 1) return 0;

        // Calculate Shannon Index (H')
        const shannonIndices = calculateShannonIndices(results);
        const H = shannonIndices[index];

        // Calculate Maximum Diversity: H'max = ln(S)
        const Hmax = Math.log(numSpecies);

        // Calculate Evenness: J' = H' / H'max
        if (Hmax === 0) return 0;
        return H / Hmax;
    });
}

// Helper: Build taxonomy table data for PDF (flatten tree with indentation)
function buildTaxonomyTableForPDF(tree, results, level = 0, rows = []) {
    const sortedKeys = Object.keys(tree).sort();

    sortedKeys.forEach(taxonName => {
        const taxon = tree[taxonName];

        // Create indentation string
        const indent = '  '.repeat(level);
        const taxonLabel = `${indent}${taxon.rank}: ${taxon.name}`;

        // Build row with densities
        const row = [taxonLabel];
        for (let i = 0; i < results.length; i++) {
            if (taxon.densities[i] !== null) {
                row.push(taxon.densities[i].toFixed(2));
            } else {
                row.push('');
            }
        }

        rows.push(row);

        // Recursively add children
        if (Object.keys(taxon.children).length > 0) {
            buildTaxonomyTableForPDF(taxon.children, results, level + 1, rows);
        }
    });

    return rows;
}

// Generate PDF Report
generatePdfBtn.addEventListener('click', async () => {
    if (selectedResults.size === 0) return;

    const selectedData = analysisResults.filter(r => selectedResults.has(r.id));

    // Get report info from localStorage
    const reportInfo = localStorage.getItem('reportInfo');
    let sammNo = '';
    let institution = '';
    let clientAddress = '';
    let authorisedBy = '';

    if (reportInfo) {
        try {
            const info = JSON.parse(reportInfo);
            sammNo = info.sammNo || '';
            // reportNo is no longer in localStorage - calculate from results
            institution = info.institution || '';
            clientAddress = info.clientAddress || '';
            authorisedBy = info.authorisedBy || 'Muhammad Firdaus Bin Daud';
        } catch (e) {
            console.error('Error parsing report info:', e);
            authorisedBy = 'Muhammad Firdaus Bin Daud';
        }
    } else {
        authorisedBy = 'Muhammad Firdaus Bin Daud';
    }

    // Calculate report cover range from selected results
    const reportNumbers = selectedData
        .map(r => r.reportNo)
        .filter(rn => rn && rn.trim() !== '')
        .sort();

    let reportNo = '';
    if (reportNumbers.length > 0) {
        const firstReport = reportNumbers[0];
        const lastReport = reportNumbers[reportNumbers.length - 1];
        reportNo = (firstReport === lastReport) ? firstReport : `${firstReport} - ${lastReport}`;
    }

    const { jsPDF } = window.jspdf;
    const doc = new jsPDF();

    // Group by specimen type
    const specimenTypes = [...new Set(selectedData.map(r => r.specimenType))];

    for (const specimenType of specimenTypes) {
        const typeResults = selectedData.filter(r => r.specimenType === specimenType);
        const sample = typeResults[0] || {};

        // ============ PAGE 1: Sample Information ============

        // Add logos (convert to base64 or use image URLs)
        try {
            // Alchemy logo - centered at top
            doc.addImage('images/logo.png', 'PNG', 80, 10, 50, 20);

            // SAMM logo - right side of first row
            doc.addImage('images/samm-logo.png', 'PNG', 170, 8, 25, 25);
        } catch (e) {
            console.warn('Could not load logos:', e);
        }

        // SAMM NO. - top right
        doc.setFontSize(10);
        doc.setFont('helvetica', 'bold');
        doc.text(`SAMM NO. ${sammNo}`, 195, 38, { align: 'right' });

        // Horizontal line above Alchemy address
        doc.setLineWidth(0.5);
        doc.line(15, 41.5, 195, 41.5);

        // Company header (moved down one more row)
        doc.setFontSize(11);
        doc.setFont('helvetica', 'bold');
        doc.text('ALCHEMY Laboratory & Services Sdn. Bhd. (Company No: 903112 K)', 105, 48, { align: 'center' });

        doc.setFont('helvetica', 'normal');
        doc.setFontSize(9);
        doc.text('326B, 1st Floor, Lot 2520, Jalan Hijiran, Mukim Losong,', 105, 53, { align: 'center' });
        doc.text('20300, Kuala Terengganu, Terengganu, Malaysia.', 105, 57, { align: 'center' });
        doc.text('Tel: +609-622 4166, Fax: +609-622 4177.', 105, 61, { align: 'center' });

        // Horizontal line after Alchemy address
        doc.setLineWidth(0.5);
        doc.line(15, 65, 195, 65);

        // Report details - right side (moved down one more line)
        doc.setFont('helvetica', 'normal');
        doc.setFontSize(9);
        const today = new Date();
        const dateStr = `${today.getDate()}-${today.toLocaleString('en-US', { month: 'short' })}-${today.getFullYear().toString().slice(-2)}`;
        doc.text(`Report ID : ${reportNo}`, 195, 73, { align: 'right' });
        doc.text(`Date : ${dateStr}`, 195, 78, { align: 'right' });
        doc.text('Pages : 3', 195, 83, { align: 'right' });

        // Title
        doc.setFontSize(14);
        doc.setFont('helvetica', 'bold');
        doc.text('CERTIFICATE OF ANALYSIS', 105, 93, { align: 'center' });

        doc.setFontSize(12);
        doc.text(`${specimenType}: Sample Information`, 15, 103);

        // Sample information table
        doc.setFont('helvetica', 'normal');
        doc.setFontSize(10);
        let y = 110;

        const addRow = (label, value) => {
            doc.setFont('helvetica', 'bold');
            doc.text(label, 15, y);
            doc.setFont('helvetica', 'normal');
            doc.text(String(value || ''), 70, y);
            y += 6;
        };

        addRow('Client Name:', sample.clientName || '');

        // Handle multi-line client address
        const addressLines = (clientAddress || sample.clientAddress || '').split('\n');
        doc.setFont('helvetica', 'bold');
        doc.text('Client Address:', 15, y);
        doc.setFont('helvetica', 'normal');
        addressLines.forEach((line, i) => {
            doc.text(line, 70, y + (i * 5));
        });
        y += Math.max(addressLines.length * 5, 6);

        // Collect all unique station IDs (sample markings)
        const allStationIds = [...new Set(typeResults.map(r => r.stationId))].sort().join(', ');

        y += 2;
        addRow('Sample Type:', 'Sediment');
        addRow('Sample Marking:', allStationIds || '');
        addRow('Number of samples:', String(typeResults.length));
        addRow('Number of replicates:', 'N/A');
        addRow('Date Received:', sample.dateReceived ? new Date(sample.dateReceived).toLocaleDateString('en-GB') : '');
        addRow('Gear used:', sample.gearUsed || '');

        if (specimenType === 'Macrobenthos') {
            addRow('Area of Grab:', sample.areaOfGrab ? `${sample.areaOfGrab} m²` : '');
            addRow('Sieve size:', sample.sieveSize ? `${sample.sieveSize} mm` : '');
        } else {
            addRow('Net Diameter:', sample.netDiameter || '');
            addRow('Net Mesh:', sample.netMesh || '');
            addRow('Tow Type:', sample.towType || '');
            addRow('Filtered Volume:', sample.filteredVolume ? `${sample.filteredVolume} L` : '');
        }

        addRow('Method of Analysis:', sample.methodAnalysis || 'SOP No.: ALC_B_004');
        addRow('Comments:', 'based on APHA 10500 C');

        // Disclaimer
        y += 5;
        doc.setFontSize(9);
        doc.setFont('helvetica', 'italic');
        doc.text('The details above are provided by the client. The reported results refer to sample(s) submitted by client only.', 15, y, {
            maxWidth: 180
        });

        // Signature section
        y += 15;
        doc.setFont('helvetica', 'bold');
        doc.text('Authorized by:', 15, y);

        y += 15;
        doc.setFont('helvetica', 'normal');
        doc.text('.............................................', 15, y);
        y += 5;
        doc.text(authorisedBy, 15, y);
        y += 5;
        doc.text('Marine Biologist', 15, y);
        y += 5;
        doc.text('BSc.(Marine Science)', 15, y);

        // ============ PAGE 2: Sample List ============
        doc.addPage();

        // Define margins (2cm = 20mm, converted from points to mm)
        const marginLeft = 20;  // 2cm in mm
        const marginRight = 20; // 2cm in mm
        const marginTop = 20;
        const pageWidth = 210; // A4 width in mm

        // Header
        doc.setFontSize(16);
        doc.setFont('helvetica', 'bold');
        doc.text('ALCHEMY Laboratory & Services Sdn Bhd', 105, marginTop + 10, { align: 'center' });

        // Client information
        doc.setFontSize(11);
        doc.setFont('helvetica', 'bold');
        doc.text('Client:', marginLeft, marginTop + 25);
        doc.setFont('helvetica', 'normal');
        doc.text(sample.clientName || '', marginLeft + 45, marginTop + 25);

        doc.setFont('helvetica', 'bold');
        doc.text('Institution:', marginLeft, marginTop + 32);
        doc.setFont('helvetica', 'normal');
        doc.text(institution || sample.institution || sample.clientName || '', marginLeft + 45, marginTop + 32);

        doc.setFont('helvetica', 'bold');
        doc.text('Description:', marginLeft, marginTop + 39);
        doc.setFont('helvetica', 'normal');
        doc.text('SEDIMENT', marginLeft + 45, marginTop + 39);

        // Sample List Table
        const tableStartY = marginTop + 50;
        const usableWidth = pageWidth - marginLeft - marginRight; // 210 - 20 - 20 = 170mm
        // Adjusted column widths to fit within 170mm and accommodate Report No. (TR/BM/00001/25)
        const colWidths = [10, 28, 30, 28, 28, 46]; // Total: 170mm
        const colX = [
            marginLeft,                    // No.: 20mm
            marginLeft + 10,               // Date Received: 30mm
            marginLeft + 38,               // Sample Marking: 68mm
            marginLeft + 68,               // Date of Analysis: 96mm
            marginLeft + 96,               // Reference ID: 124mm
            marginLeft + 124               // Report No.: 170mm
        ];

        // Table header background
        doc.setFillColor(245, 245, 245);
        doc.rect(marginLeft, tableStartY, usableWidth, 10, 'F');

        // Table headers
        doc.setFontSize(9);
        doc.setFont('helvetica', 'bold');
        const headers = ['', 'Date Received', 'Sample Marking', 'Date of Analysis', 'Reference ID', 'Report No.'];
        headers.forEach((header, i) => {
            const centerX = colX[i] + (colWidths[i] / 2);
            doc.text(header, centerX, tableStartY + 7, { align: 'center' });
        });

        // Table borders
        doc.setLineWidth(0.3);
        doc.rect(marginLeft, tableStartY, usableWidth, 10); // Header row border

        // Table rows
        doc.setFont('helvetica', 'normal');
        doc.setFontSize(8);
        let rowY = tableStartY + 10;

        typeResults.forEach((result, index) => {
            // Row background (alternating)
            if (index % 2 === 1) {
                doc.setFillColor(250, 250, 250);
                doc.rect(marginLeft, rowY, usableWidth, 8, 'F');
            }

            // Row data - Date Received from uploaded data (center-aligned)
            doc.text(String(index + 1), colX[0] + (colWidths[0] / 2), rowY + 5.5, { align: 'center' });
            doc.text(result.dateReceived ? new Date(result.dateReceived).toLocaleDateString('en-GB') : '', colX[1] + (colWidths[1] / 2), rowY + 5.5, { align: 'center' });
            doc.text(result.stationId || '', colX[2] + (colWidths[2] / 2), rowY + 5.5, { align: 'center' });
            doc.text(result.analyzedDate ? new Date(result.analyzedDate).toLocaleDateString('en-GB') : '', colX[3] + (colWidths[3] / 2), rowY + 5.5, { align: 'center' });
            doc.text(result.referenceId || '', colX[4] + (colWidths[4] / 2), rowY + 5.5, { align: 'center' });
            doc.text(result.reportNo || '', colX[5] + (colWidths[5] / 2), rowY + 5.5, { align: 'center' });  // Use individual result's auto-generated Report No.

            // Row border
            doc.rect(marginLeft, rowY, usableWidth, 8);

            rowY += 8;
        });

        // ============ PAGE 3+: Macro Analysis (Paginated - max 6 samples per page) ============
        const maxSamplesPerPage = 6;
        const numAnalysisPages = Math.ceil(typeResults.length / maxSamplesPerPage);

        for (let pageIdx = 0; pageIdx < numAnalysisPages; pageIdx++) {
            const startIdx = pageIdx * maxSamplesPerPage;
            const endIdx = Math.min(startIdx + maxSamplesPerPage, typeResults.length);
            const pageResults = typeResults.slice(startIdx, endIdx);

            doc.addPage();

            // Header
            doc.setFontSize(14);
            doc.setFont('helvetica', 'bold');
            doc.text('ALCHEMY Laboratory & Services Sdn Bhd', 105, 20, { align: 'center' });

            // Sheet title
            doc.setFontSize(11);
            const densityUnit = specimenType === 'Macrobenthos' ? 'unit m2' : 'units/L';
            doc.text(`${specimenType} Data Sheet: Analysed density per sample/${densityUnit}`, 105, 28, { align: 'center' });

            // Page number if multiple pages
            if (numAnalysisPages > 1) {
                doc.setFontSize(9);
                doc.text(`(Page ${pageIdx + 1} of ${numAnalysisPages})`, 105, 34, { align: 'center' });
            }

            // Build complete table data including info rows, taxonomy, and statistics
            const tableData = [];

            // Reference ID row
            const refIdRow = ['Reference ID:', ...pageResults.map(r => r.referenceId || '')];
            tableData.push(refIdRow);

            // Sample Marking row
            const sampleMarkingRow = ['Sample Marking:', ...pageResults.map(r => r.stationId || '')];
            tableData.push(sampleMarkingRow);

            // Area/Volume row
            const areaLabel = specimenType === 'Macrobenthos' ? 'Area of grab (m2)' : 'Filtered Volume (L)';
            const areaRow = [areaLabel, ...pageResults.map(r => {
                const value = specimenType === 'Macrobenthos'
                    ? (r.areaOfGrab || 0.3)
                    : (r.filteredVolume || 1);
                return String(value);
            })];
            tableData.push(areaRow);

            // Build taxonomy data
            const taxonomyTree = buildTaxonomyTree(pageResults);
            const taxonomyRows = buildTaxonomyTableForPDF(taxonomyTree, pageResults);
            tableData.push(...taxonomyRows);

            // Empty separator row
            tableData.push(['', ...new Array(pageResults.length).fill('')]);

            // Summary statistics
            // Total Number of Taxa
            const taxaCounts = calculateTaxaCounts(pageResults);
            tableData.push(['Total Number of Taxa:', ...taxaCounts.map(c => String(c))]);

            // Overall density
            const densityLabel2 = specimenType === 'Macrobenthos' ? 'Overall density(units/m2):' : 'Overall density(units/L):';
            const overallDensities = calculateOverallDensities(pageResults);
            tableData.push([densityLabel2, ...overallDensities.map(d => d.toFixed(2))]);

            // Taxa diversity Index (H')
            const shannonIndices = calculateShannonIndices(pageResults);
            tableData.push(["Taxa diversity Index (H'):", ...shannonIndices.map(i => i.toFixed(4))]);

            // Evenness Index (J')
            const evennessIndices = calculateEvennessIndices(pageResults);
            tableData.push(["Eveness Index (J'):", ...evennessIndices.map(i => i.toFixed(4))]);

            // Render complete table with custom formatting
            const infoY = 38;
            const areaOfGrabRowIndex = 2; // Row 3 (0-indexed: 0=RefID, 1=SampleMarking, 2=Area)
            const totalTaxaRowIndex = tableData.length - 4; // Total Number of Taxa row

            doc.autoTable({
                startY: infoY,
                body: tableData,
                theme: 'grid',
                styles: {
                    fontSize: 8,
                    cellPadding: 2,
                    lineWidth: 0.1, // Thin grey lines
                    lineColor: [128, 128, 128], // Grey color
                    textColor: [0, 0, 0], // Black text
                },
                columnStyles: {
                    0: { cellWidth: 60, halign: 'left', fontStyle: 'bold' },
                    // Center-align all sample columns (columns 1+)
                    ...Object.fromEntries(
                        Array.from({ length: pageResults.length }, (_, i) => [i + 1, { halign: 'center' }])
                    ),
                },
                margin: { left: marginLeft, right: marginRight },
                didParseCell: function(data) {
                    // Default line widths - thin horizontal, bold vertical
                    const defaultLineWidth = {
                        top: 0.1,      // Thin grey horizontal
                        right: 0.3,    // Bold vertical
                        bottom: 0.1,   // Thin grey horizontal
                        left: 0.3      // Bold vertical
                    };
                    data.cell.styles.lineWidth = defaultLineWidth;
                    data.cell.styles.lineColor = [128, 128, 128];

                    // Bold line after Area of grab row (before first taxonomy)
                    if (data.row.index === areaOfGrabRowIndex) {
                        data.cell.styles.lineWidth = {
                            top: 0.1,
                            right: 0.3,    // Bold vertical
                            bottom: 0.5,   // Bold bottom border
                            left: 0.3      // Bold vertical
                        };
                        data.cell.styles.lineColor = {
                            top: [128, 128, 128],
                            right: [128, 128, 128],
                            bottom: [0, 0, 0],  // Black bottom border
                            left: [128, 128, 128]
                        };
                    }

                    // Bold line before Total Number of Taxa
                    if (data.row.index === totalTaxaRowIndex) {
                        data.cell.styles.lineWidth = {
                            top: 0.5,      // Bold top border
                            right: 0.3,    // Bold vertical
                            bottom: 0.1,
                            left: 0.3      // Bold vertical
                        };
                        data.cell.styles.lineColor = {
                            top: [0, 0, 0],  // Black top border
                            right: [128, 128, 128],
                            bottom: [128, 128, 128],
                            left: [128, 128, 128]
                        };
                    }
                },
            });
        }
    }

    // Download
    const timestamp = new Date().toISOString().split('T')[0];
    doc.save(`analysis_report_${timestamp}.pdf`);

    setStatus(`Generated PDF report with ${selectedResults.size} samples`);

    // Save report log
    const firstResult = selectedData[0];
    saveReportLog({
        clientName: firstResult.clientName,
        institution: institution || firstResult.institution,
        referenceId: firstResult.referenceId,
        reportCover: reportNo,
        dateReceived: firstResult.dateReceived,
        numberOfSamples: selectedData.length,
        reportType: 'PDF',
        specimenType: specimenTypes.join(', ')
    });
});
