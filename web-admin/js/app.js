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
