// App State
let currentSpecimenType = 'Macrobenthos';
let allTaxa = [];
let selectedTaxonId = null;

// DOM Elements
const loginScreen = document.getElementById('login-screen');
const appScreen = document.getElementById('app-screen');
const loginForm = document.getElementById('login-form');
const loginError = document.getElementById('login-error');
const userEmail = document.getElementById('user-email');
const logoutBtn = document.getElementById('logout-btn');
const tabs = document.querySelectorAll('.tab');
const taxonomyTree = document.getElementById('taxonomy-tree');
const detailsPanel = document.getElementById('details-panel');
const taxonForm = document.getElementById('taxon-form');
const addRootBtn = document.getElementById('add-root-btn');
const refreshBtn = document.getElementById('refresh-btn');
const taxaCount = document.getElementById('taxa-count');
const statusMessage = document.getElementById('status-message');
const lastModified = document.getElementById('last-modified');

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

// Tab switching
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
        sampleCsv = `id,parentId,name,rank,notes
2000001,,Bacillariophyta,Division,Diatoms
2000002,2000001,Bacillariophyceae,Class,Pennate diatoms
2000003,2000002,Naviculales,Order,
2000004,2000003,Naviculaceae,Family,
2000005,2000004,Navicula,Genus,
2000006,2000005,Navicula radiosa,Species,Common pennate diatom
2000007,2000001,Coscinodiscophyceae,Class,Centric diatoms
2000008,2000007,Thalassiosirales,Order,
2000009,2000008,Thalassiosiraceae,Family,
2000010,2000009,Thalassiosira,Genus,
2000011,2000010,Thalassiosira pseudonana,Species,Model centric diatom
2000012,,Dinophyta,Division,Dinoflagellates
2000013,2000012,Dinophyceae,Class,
2000014,2000013,Peridiniales,Order,
2000015,2000014,Peridiniaceae,Family,`;
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
