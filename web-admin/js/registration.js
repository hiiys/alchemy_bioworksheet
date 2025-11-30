// Registration Page State
let currentOrdersType = 'Macrobenthos';
let currentSamplesType = 'Macrobenthos';
let allOrders = [];
let allSamples = [];
let ordersClientFilter = '';
let samplesClientFilter = '';
let samplesOrderFilter = '';

// DOM Elements for Orders Page
const ordersTabs = document.querySelectorAll('#orders-page .tab');
// DOM Elements for Samples Page
const samplesTabs = document.querySelectorAll('#samples-page .tab');
const ordersSectionTitle = document.getElementById('orders-section-title');
const samplesSectionTitle = document.getElementById('samples-section-title');
const ordersClientFilterInput = document.getElementById('orders-client-filter');
const ordersSearchBtn = document.getElementById('orders-search-btn');
const ordersRefreshBtn = document.getElementById('orders-refresh-btn');
const exportOrdersCsvBtn = document.getElementById('export-orders-csv-btn');
const ordersCount = document.getElementById('orders-count');
const ordersList = document.getElementById('orders-list');
const samplesClientFilterInput = document.getElementById('samples-client-filter');
const samplesOrderFilterInput = document.getElementById('samples-order-filter');
const samplesSearchBtn = document.getElementById('samples-search-btn');
const samplesRefreshBtn = document.getElementById('samples-refresh-btn');
const exportSamplesCsvBtn = document.getElementById('export-samples-csv-btn');
const samplesCount = document.getElementById('samples-count');
const samplesList = document.getElementById('samples-list');
const addSampleBtn = document.getElementById('add-sample-btn');
const addSampleModal = document.getElementById('add-sample-modal');
const addSampleForm = document.getElementById('add-sample-form');
const sampleModalCancelBtn = document.getElementById('sample-modal-cancel-btn');
const addOrderBtn = document.getElementById('add-order-btn');
const addOrderModal = document.getElementById('add-order-modal');
const addOrderForm = document.getElementById('add-order-form');
const orderModalCancelBtn = document.getElementById('order-modal-cancel-btn');
const orderSpecimenTypeSpan = document.getElementById('order-specimen-type');
const benthosFields = document.getElementById('benthos-fields');
const planktonFields = document.getElementById('plankton-fields');
const orderNumReplicatesGroup = document.getElementById('order-num-replicates-group');
const sampleMarkingsModal = document.getElementById('sample-markings-modal');
const markingOrderClient = document.getElementById('marking-order-client');
const markingOrderType = document.getElementById('marking-order-type');
const markingSampleMarking = document.getElementById('marking-sample-marking');
const markingDateReceived = document.getElementById('marking-date-received');
const addMarkingBtn = document.getElementById('add-marking-btn');
const orderSamplesList = document.getElementById('order-samples-list');
const markingModalCloseBtn = document.getElementById('marking-modal-close-btn');
const editSampleModal = document.getElementById('edit-sample-modal');
const editSampleForm = document.getElementById('edit-sample-form');
const editSampleRefId = document.getElementById('edit-sample-ref-id');
const editSampleOrderId = document.getElementById('edit-sample-order-id');
const editSampleStationId = document.getElementById('edit-sample-station-id');
const editSampleClient = document.getElementById('edit-sample-client');
const editSampleDate = document.getElementById('edit-sample-date');
const editSampleLat = document.getElementById('edit-sample-lat');
const editSampleLon = document.getElementById('edit-sample-lon');
const editSampleHabitat = document.getElementById('edit-sample-habitat');
const editSampleRemarks = document.getElementById('edit-sample-remarks');
const editSampleCompleted = document.getElementById('edit-sample-completed');
const editSampleCancelBtn = document.getElementById('edit-sample-cancel-btn');

// Edit order modal elements
const editOrderModal = document.getElementById('edit-order-modal');
const editOrderForm = document.getElementById('edit-order-form');
const editOrderSpecimenType = document.getElementById('edit-order-specimen-type');
const editOrderClientName = document.getElementById('edit-order-client-name');
const editOrderInstitution = document.getElementById('edit-order-institution');
const editOrderNumSamples = document.getElementById('edit-order-num-samples');
const editOrderNumReplicates = document.getElementById('edit-order-num-replicates');
const editOrderSampleDescription = document.getElementById('edit-order-sample-description');
const editOrderGearUsed = document.getElementById('edit-order-gear-used');
const editOrderAreaGrab = document.getElementById('edit-order-area-grab');
const editOrderSieveSize = document.getElementById('edit-order-sieve-size');
const editOrderNetDiameter = document.getElementById('edit-order-net-diameter');
const editOrderNetMesh = document.getElementById('edit-order-net-mesh');
const editOrderTowType = document.getElementById('edit-order-tow-type');
const editOrderFilteredVolume = document.getElementById('edit-order-filtered-volume');
const editOrderTowDistance = document.getElementById('edit-order-tow-distance');
const editOrderSampleVolume = document.getElementById('edit-order-sample-volume');
const editOrderSrCellVolume = document.getElementById('edit-order-sr-cell-volume');
const editOrderSrCellsCounted = document.getElementById('edit-order-sr-cells-counted');
const editOrderComments = document.getElementById('edit-order-comments');
const editOrderCancelBtn = document.getElementById('edit-order-cancel-btn');
const editBenthosFields = document.getElementById('edit-benthos-fields');
const editPlanktonFields = document.getElementById('edit-plankton-fields');
const editOrderNumReplicatesGroup = document.getElementById('edit-order-num-replicates-group');
const manageSamplesBtn = document.getElementById('manage-samples-btn');

// Current selected order for sample markings
let selectedOrder = null;
// Current selected sample for editing
let selectedSample = null;

// Orders specimen type tab switching
ordersTabs.forEach(tab => {
    tab.addEventListener('click', () => {
        ordersTabs.forEach(t => t.classList.remove('active'));
        tab.classList.add('active');
        currentOrdersType = tab.dataset.type;
        ordersSectionTitle.textContent = `${currentOrdersType} Orders`;
        loadOrders();
    });
});

// Samples specimen type tab switching
samplesTabs.forEach(tab => {
    tab.addEventListener('click', () => {
        samplesTabs.forEach(t => t.classList.remove('active'));
        tab.classList.add('active');
        currentSamplesType = tab.dataset.type;
        samplesSectionTitle.textContent = `${currentSamplesType} Samples`;
        loadSamples();
    });
});

// Orders filter and refresh
ordersSearchBtn.addEventListener('click', () => {
    ordersClientFilter = ordersClientFilterInput.value.trim().toLowerCase();
    renderOrders();
});

ordersRefreshBtn.addEventListener('click', () => {
    ordersClientFilter = '';
    ordersClientFilterInput.value = '';
    loadOrders();
});

// Orders export CSV
exportOrdersCsvBtn.addEventListener('click', () => {
    exportOrdersToCSV();
});

// Samples filter and refresh
samplesSearchBtn.addEventListener('click', () => {
    samplesClientFilter = samplesClientFilterInput.value.trim().toLowerCase();
    samplesOrderFilter = samplesOrderFilterInput.value.trim();
    renderSamples();
});

samplesRefreshBtn.addEventListener('click', () => {
    samplesClientFilter = '';
    samplesOrderFilter = '';
    samplesClientFilterInput.value = '';
    samplesOrderFilterInput.value = '';
    loadSamples();
});

// Samples export CSV
exportSamplesCsvBtn.addEventListener('click', () => {
    exportSamplesToCSV();
});

// Add sample modal
addSampleBtn.addEventListener('click', async () => {
    addSampleModal.classList.remove('hidden');
    // Set default date to today
    document.getElementById('sample-date').value = new Date().toISOString().split('T')[0];

    // Populate order IDs datalist with available orders
    await updateAddSampleOrdersList();
});

// Update the datalist with available order IDs for the Add Sample form
async function updateAddSampleOrdersList() {
    try {
        const datalist = document.getElementById('add-sample-orders-list');
        if (!datalist) return;

        // Get all orders
        const ordersSnapshot = await db.collection('orders').get();

        // Clear and populate datalist
        datalist.innerHTML = '';
        ordersSnapshot.docs.forEach(doc => {
            const order = doc.data();
            const option = document.createElement('option');
            option.value = doc.id;
            option.textContent = `${doc.id} - ${order.clientName} (${order.specimenType})`;
            datalist.appendChild(option);
        });
    } catch (error) {
        console.error('Error updating orders list:', error);
    }
}

sampleModalCancelBtn.addEventListener('click', () => {
    addSampleModal.classList.add('hidden');
    addSampleForm.reset();
});

addSampleForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    await addNewSample();
});

// Add order modal
addOrderBtn.addEventListener('click', () => {
    // Update modal title with current specimen type
    orderSpecimenTypeSpan.textContent = currentOrdersType;

    // Show/hide fields based on specimen type
    updateOrderFormFields();

    addOrderModal.classList.remove('hidden');
});

orderModalCancelBtn.addEventListener('click', () => {
    addOrderModal.classList.add('hidden');
    addOrderForm.reset();
});

addOrderForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    await addNewOrder();
});

// Update order form fields based on specimen type
function updateOrderFormFields() {
    const isBenthos = currentOrdersType === 'Macrobenthos';
    const isPlankton = currentOrdersType === 'Zooplankton' || currentOrdersType === 'Phytoplankton';

    // Show/hide fields
    if (isBenthos) {
        benthosFields.classList.remove('hidden');
        planktonFields.classList.add('hidden');
        orderNumReplicatesGroup.classList.remove('hidden');
    } else if (isPlankton) {
        benthosFields.classList.add('hidden');
        planktonFields.classList.remove('hidden');
        orderNumReplicatesGroup.classList.add('hidden');
    }
}

// Sample markings modal handlers
markingModalCloseBtn.addEventListener('click', () => {
    sampleMarkingsModal.classList.add('hidden');
    selectedOrder = null;
});

addMarkingBtn.addEventListener('click', async () => {
    await addSampleMarking();
});

// Allow Enter key to add marking
markingSampleMarking.addEventListener('keypress', async (e) => {
    if (e.key === 'Enter') {
        await addSampleMarking();
    }
});

// Edit sample modal handlers
editSampleCancelBtn.addEventListener('click', () => {
    editSampleModal.classList.add('hidden');
    selectedSample = null;
});

editSampleForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    await updateSample();
});

// Edit order modal handlers
editOrderCancelBtn.addEventListener('click', () => {
    editOrderModal.classList.add('hidden');
    selectedOrder = null;
});

editOrderForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    await updateOrder();
});

// Manage samples button - opens sample markings modal
manageSamplesBtn.addEventListener('click', () => {
    if (selectedOrder) {
        editOrderModal.classList.add('hidden');
        openSampleMarkingsModal(selectedOrder.id);
    }
});

// Load orders from Firebase
async function loadOrders() {
    ordersList.innerHTML = '<p class="loading">Loading orders...</p>';

    try {
        const ordersRef = db.collection('orders');
        let query = ordersRef.where('specimenType', '==', currentOrdersType);
        const snapshot = await query.orderBy('createdAt', 'desc').get();

        allOrders = snapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));

        // Recalculate actual sample counts for each order
        await recalculateOrderSampleCounts();

        updateOrdersAutocomplete();
        renderOrders();
    } catch (error) {
        console.error('Error loading orders:', error);
        ordersList.innerHTML = `<p class="error">Error loading orders: ${error.message}</p>`;
    }
}

// Recalculate sample counts for all orders based on actual samples in Firestore
async function recalculateOrderSampleCounts() {
    try {
        // Get all samples for the current specimen type
        const samplesRef = db.collection('samples');
        const samplesSnapshot = await samplesRef.where('sampleType', '==', currentOrdersType).get();

        const samplesByOrder = {};

        // Count samples for each order
        samplesSnapshot.docs.forEach(doc => {
            const sample = doc.data();
            const orderId = sample.orderId;
            if (orderId) {
                samplesByOrder[orderId] = (samplesByOrder[orderId] || 0) + 1;
            }
        });

        // Update numberOfSamples for each order with actual count
        allOrders.forEach(order => {
            const actualCount = samplesByOrder[order.id] || 0;
            order.actualSampleCount = actualCount;

            // Log if there's a discrepancy
            if (order.numberOfSamples !== actualCount) {
                console.log(`Order ${order.clientName} (${order.id}): stored=${order.numberOfSamples}, actual=${actualCount}`);
            }
        });
    } catch (error) {
        console.error('Error recalculating sample counts:', error);
    }
}

// Render orders table
function renderOrders() {
    const filteredOrders = allOrders.filter(order => {
        if (ordersClientFilter && !order.clientName.toLowerCase().includes(ordersClientFilter)) {
            return false;
        }
        return true;
    });

    ordersCount.textContent = `${filteredOrders.length} orders`;

    if (filteredOrders.length === 0) {
        ordersList.innerHTML = '<p style="text-align: center; padding: 20px; color: #666;">No orders found</p>';
        return;
    }

    let html = '<table class="orders-table"><thead><tr>';
    html += '<th>Client Name</th>';
    html += '<th>Specimen Type</th>';
    html += '<th>Date Received</th>';
    html += '<th>Samples</th>';
    html += '<th>Replicates</th>';
    html += '<th>Report No</th>';
    html += '<th>Order ID</th>';
    html += '<th style="width: 80px;">Action</th>';
    html += '</tr></thead><tbody>';

    filteredOrders.forEach(order => {
        // Use actualSampleCount if available, otherwise fall back to numberOfSamples
        const sampleCount = order.actualSampleCount !== undefined ? order.actualSampleCount : (order.numberOfSamples || 0);

        html += '<tr>';
        html += `<td style="cursor: pointer;" onclick="openEditOrderModal('${order.id}')">${order.clientName || 'N/A'}</td>`;
        html += `<td style="cursor: pointer;" onclick="openEditOrderModal('${order.id}')">${order.specimenType || 'N/A'}</td>`;
        html += `<td style="cursor: pointer;" onclick="openEditOrderModal('${order.id}')">${formatDate(order.dateReceived)}</td>`;
        html += `<td style="cursor: pointer;" onclick="openEditOrderModal('${order.id}')">${sampleCount}</td>`;
        html += `<td style="cursor: pointer;" onclick="openEditOrderModal('${order.id}')">${order.numberOfReplicates || 0}</td>`;
        html += `<td style="cursor: pointer;" onclick="openEditOrderModal('${order.id}')">${order.reportNo || 'N/A'}</td>`;
        html += `<td style="cursor: pointer;" onclick="openEditOrderModal('${order.id}')"><strong>${order.id || 'N/A'}</strong></td>`;
        html += `<td><button class="delete-btn" onclick="event.stopPropagation(); deleteOrder('${order.id}', '${order.clientName}');" title="Delete order">Delete</button></td>`;
        html += '</tr>';
    });

    html += '</tbody></table>';
    ordersList.innerHTML = html;
}

// Load samples from Firebase
async function loadSamples() {
    samplesList.innerHTML = '<p class="loading">Loading samples...</p>';

    try {
        const samplesRef = db.collection('samples');
        let query = samplesRef.where('sampleType', '==', currentSamplesType);
        const snapshot = await query.orderBy('createdAt', 'desc').get();

        allSamples = snapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));

        updateSamplesAutocomplete();
        renderSamples();
    } catch (error) {
        console.error('Error loading samples:', error);
        samplesList.innerHTML = `<p class="error">Error loading samples: ${error.message}</p>`;
    }
}

// Render samples table
function renderSamples() {
    const filteredSamples = allSamples.filter(sample => {
        if (samplesClientFilter && !sample.client.toLowerCase().includes(samplesClientFilter)) {
            return false;
        }
        if (samplesOrderFilter && !sample.orderId.toString().includes(samplesOrderFilter)) {
            return false;
        }
        return true;
    });

    samplesCount.textContent = `${filteredSamples.length} samples`;

    if (filteredSamples.length === 0) {
        samplesList.innerHTML = '<p style="text-align: center; padding: 20px; color: #666;">No samples found</p>';
        return;
    }

    let html = '<table class="samples-table"><thead><tr>';
    html += '<th>Reference ID</th>';
    html += '<th>Order ID</th>';
    html += '<th>Station ID</th>';
    html += '<th>Client</th>';
    html += '<th>Date</th>';
    html += '<th>Lat/Lon</th>';
    html += '<th>Habitat</th>';
    html += '<th>Status</th>';
    html += '<th style="width: 80px;">Action</th>';
    html += '</tr></thead><tbody>';

    filteredSamples.forEach(sample => {
        html += '<tr>';
        html += `<td style="cursor: pointer;" onclick="openEditSampleModal('${sample.id}')"><strong>${sample.receiveId || 'N/A'}</strong></td>`;
        html += `<td style="cursor: pointer;" onclick="openEditSampleModal('${sample.id}')">${sample.orderId || 'N/A'}</td>`;
        html += `<td style="cursor: pointer;" onclick="openEditSampleModal('${sample.id}')">${sample.stationId || sample.sampleMarking || 'N/A'}</td>`;
        html += `<td style="cursor: pointer;" onclick="openEditSampleModal('${sample.id}')">${sample.client || 'N/A'}</td>`;
        html += `<td style="cursor: pointer;" onclick="openEditSampleModal('${sample.id}')">${formatDate(sample.date)}</td>`;
        html += `<td style="cursor: pointer;" onclick="openEditSampleModal('${sample.id}')">${sample.lat && sample.lon ? `${sample.lat}, ${sample.lon}` : 'N/A'}</td>`;
        html += `<td style="cursor: pointer;" onclick="openEditSampleModal('${sample.id}')">${sample.habitat || 'N/A'}</td>`;
        html += `<td style="cursor: pointer;" onclick="openEditSampleModal('${sample.id}')">${sample.completed ? '<span style="color: green;">Completed</span>' : '<span style="color: orange;">Pending</span>'}</td>`;
        html += `<td><button class="delete-btn" onclick="event.stopPropagation(); deleteSample('${sample.id}', '${sample.sampleMarking || sample.receiveId}');" title="Delete sample">Delete</button></td>`;
        html += '</tr>';
    });

    html += '</tbody></table>';
    samplesList.innerHTML = html;
}

// Add new sample to Firebase with auto-generated Reference ID
async function addNewSample() {
    try {
        const orderIdInput = document.getElementById('sample-order-id').value.trim();
        const stationId = document.getElementById('sample-station-id').value.trim();
        const client = document.getElementById('sample-client').value.trim();
        const date = document.getElementById('sample-date').value;
        const lat = document.getElementById('sample-lat').value.trim();
        const lon = document.getElementById('sample-lon').value.trim();
        const habitat = document.getElementById('sample-habitat').value.trim();
        const remarks = document.getElementById('sample-remarks').value.trim();

        // CRITICAL VALIDATION: Order ID is required
        if (!orderIdInput) {
            alert('Order ID is required. Every sample must belong to an order.');
            document.getElementById('sample-order-id').focus();
            return;
        }

        const orderId = orderIdInput;

        // CRITICAL VALIDATION: Verify the order exists
        try {
            const orderDoc = await db.collection('orders').doc(orderId).get();
            if (!orderDoc.exists) {
                alert(`Order ID "${orderId}" does not exist. Please enter a valid Order ID.`);
                document.getElementById('sample-order-id').focus();
                return;
            }
            console.log('Order verified:', orderDoc.id);
        } catch (error) {
            alert(`Error verifying Order ID: ${error.message}`);
            return;
        }

        // Generate Reference ID
        const referenceId = await generateReferenceId(currentSamplesType);

        // Create sample object
        const sampleData = {
            orderId: orderId,
            stationId: stationId,
            sampleMarking: stationId,
            client: client,
            date: date,
            lat: lat || null,
            lon: lon || null,
            habitat: habitat || null,
            remarks: remarks || null,
            sampleType: currentSamplesType,
            receiveId: referenceId,
            completed: false,
            deviceId: 'web-admin',
            createdAt: firebase.firestore.FieldValue.serverTimestamp(),
            updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
            synced: true
        };

        // Add to Firebase
        const docRef = await db.collection('samples').add(sampleData);

        console.log('Sample added successfully:', docRef.id);
        alert(`Sample added successfully with Reference ID: ${referenceId}`);

        // Close modal and reload samples
        addSampleModal.classList.add('hidden');
        addSampleForm.reset();
        loadSamples();

    } catch (error) {
        console.error('Error adding sample:', error);
        alert(`Error adding sample: ${error.message}`);
    }
}

// Add new order to Firebase and auto-create samples
async function addNewOrder() {
    try {
        const clientName = document.getElementById('order-client-name').value.trim();
        const institution = document.getElementById('order-institution').value.trim();
        const numSamples = parseInt(document.getElementById('order-num-samples').value);
        const numReplicates = parseInt(document.getElementById('order-num-replicates').value) || 1;
        const sampleDescription = document.getElementById('order-sample-description').value.trim();
        const gearUsed = document.getElementById('order-gear-used').value.trim();
        const comments = document.getElementById('order-comments').value.trim();

        // Type-specific fields
        const areaOfGrab = document.getElementById('order-area-grab').value.trim();
        const sieveSize = document.getElementById('order-sieve-size').value.trim();
        const netDiameter = document.getElementById('order-net-diameter').value.trim();
        const netMesh = document.getElementById('order-net-mesh').value.trim();
        const towType = document.getElementById('order-tow-type').value.trim();
        const filteredVolume = document.getElementById('order-filtered-volume').value.trim();
        const towDistance = document.getElementById('order-tow-distance').value.trim();
        const sampleVolume = document.getElementById('order-sample-volume').value.trim();
        const srCellVolume = document.getElementById('order-sr-cell-volume').value.trim();
        const srCellsCounted = document.getElementById('order-sr-cells-counted').value.trim();

        const dateReceived = new Date().toISOString().split('T')[0];

        // Create order object
        const orderData = {
            clientName: clientName,
            clientAddress: '', // Not collected in web form
            specimenType: currentOrdersType,
            numberOfSamples: numSamples,
            numberOfReplicates: numReplicates,
            dateReceived: dateReceived,
            dateAnalysis: null,
            gearUsed: gearUsed || null,
            areaOfGrab: areaOfGrab || null,
            sieveSize: sieveSize || null,
            netDiameter: netDiameter || null,
            netMesh: netMesh || null,
            towType: towType || null,
            filteredVolume: filteredVolume || null,
            methodAnalysis: null,
            reportNo: null,
            referenceId: null,
            comments: comments || null,
            sammNo: null,
            authorizedBy: null,
            institution: institution || null,
            sampleDescription: sampleDescription || null,
            towDistance: towDistance || null,
            sampleVolume: sampleVolume || null,
            srCellVolume: srCellVolume || null,
            srCellsCounted: srCellsCounted || null,
            deviceId: 'web-admin',
            createdAt: firebase.firestore.FieldValue.serverTimestamp(),
            updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
            synced: true
        };

        // Add order to Firebase
        const orderDocRef = await db.collection('orders').add(orderData);
        const orderId = orderDocRef.id;

        console.log('Order added successfully:', orderId);

        alert(`Order added successfully!\n- Order ID: ${orderId}\n- Client: ${clientName}\n\nClick on the order in the table to add sample markings.`);

        // Close modal and reload orders
        addOrderModal.classList.add('hidden');
        addOrderForm.reset();
        loadOrders();

    } catch (error) {
        console.error('Error adding order:', error);
        alert(`Error adding order: ${error.message}`);
    }
}

// Generate Reference ID (same logic as Dart service)
async function generateReferenceId(specimenType) {
    let prefix;
    switch (specimenType) {
        case 'Macrobenthos':
            prefix = 'BM/';
            break;
        case 'Zooplankton':
            prefix = 'BZ/';
            break;
        case 'Phytoplankton':
            prefix = 'BP/';
            break;
        default:
            prefix = 'XX/';
    }

    const year = new Date().getFullYear() % 100;
    const yearStr = year.toString().padStart(2, '0');

    try {
        // Query all existing Reference IDs for this specimen type
        const snapshot = await db.collection('samples')
            .where('sampleType', '==', specimenType)
            .get();

        let maxSequence = 0;

        // Parse existing Reference IDs to find the highest sequence number
        snapshot.docs.forEach(doc => {
            const data = doc.data();
            const referenceId = data.receiveId;

            if (referenceId && referenceId.startsWith(prefix)) {
                // Extract the 5-digit sequence number
                // Format: BM/00001/25 -> extract "00001"
                const parts = referenceId.split('/');
                if (parts.length >= 3) {
                    const sequenceStr = parts[1];
                    const sequence = parseInt(sequenceStr, 10);
                    if (!isNaN(sequence) && sequence > maxSequence) {
                        maxSequence = sequence;
                    }
                }
            }
        });

        // Increment sequence number
        const nextSequence = maxSequence + 1;
        const sequenceStr = nextSequence.toString().padStart(5, '0');

        // Format: BM/00001/25
        return `${prefix}${sequenceStr}/${yearStr}`;
    } catch (error) {
        console.error('Error generating Reference ID:', error);
        // Fallback to 00001 if there's an error
        return `${prefix}${'1'.padStart(5, '0')}/${yearStr}`;
    }
}

// Open sample markings modal for an order
async function openSampleMarkingsModal(orderId) {
    try {
        // Find order in allOrders array
        const order = allOrders.find(o => o.id === orderId);

        if (!order) {
            alert('Order not found');
            return;
        }

        // Set selected order
        selectedOrder = order;

        // Update modal with order details
        markingOrderClient.textContent = order.clientName || 'N/A';
        markingOrderType.textContent = order.specimenType || 'N/A';

        // Set default date to today
        markingDateReceived.value = new Date().toISOString().split('T')[0];

        // Clear sample marking input
        markingSampleMarking.value = '';

        // Load existing samples for this order
        await loadOrderSamples(orderId);

        // Show modal
        sampleMarkingsModal.classList.remove('hidden');

        // Focus on sample marking input
        markingSampleMarking.focus();

    } catch (error) {
        console.error('Error opening sample markings modal:', error);
        alert(`Error: ${error.message}`);
    }
}

// Add sample marking for the selected order
async function addSampleMarking() {
    try {
        if (!selectedOrder) {
            alert('No order selected');
            return;
        }

        const marking = markingSampleMarking.value.trim();
        const dateReceived = markingDateReceived.value;

        // Validate inputs
        if (!marking) {
            alert('Please enter a sample marking');
            markingSampleMarking.focus();
            return;
        }

        if (!dateReceived) {
            alert('Please select a date received');
            markingDateReceived.focus();
            return;
        }

        // Disable button to prevent double submission
        addMarkingBtn.disabled = true;
        addMarkingBtn.textContent = 'Adding...';

        // Generate Reference ID
        const referenceId = await generateReferenceId(selectedOrder.specimenType);

        // Create sample object
        const sampleData = {
            orderId: selectedOrder.id,
            sampleMarking: marking,
            stationId: marking, // Use marking as station ID as well
            client: selectedOrder.clientName,
            date: dateReceived,
            sampleType: selectedOrder.specimenType,
            receiveId: referenceId,
            completed: false,
            lat: null,
            lon: null,
            habitat: null,
            remarks: null,
            deviceId: 'web-admin',
            createdAt: firebase.firestore.FieldValue.serverTimestamp(),
            updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
            synced: true
        };

        // Add to Firebase
        const docRef = await db.collection('samples').add(sampleData);

        console.log('Sample added successfully:', docRef.id);

        // Update order's numberOfSamples field
        const samplesSnapshot = await db.collection('samples').where('orderId', '==', selectedOrder.id).get();
        const sampleCount = samplesSnapshot.size;
        await db.collection('orders').doc(selectedOrder.id).update({
            numberOfSamples: sampleCount,
            updatedAt: firebase.firestore.FieldValue.serverTimestamp()
        });

        // Clear input
        markingSampleMarking.value = '';

        // Reload order samples
        await loadOrderSamples(selectedOrder.id);

        // Reload orders table to reflect updated count
        loadOrders();

        // Re-enable button
        addMarkingBtn.disabled = false;
        addMarkingBtn.textContent = 'Add Sample';

        // Show success message briefly
        const originalText = addMarkingBtn.textContent;
        addMarkingBtn.textContent = '✓ Added';
        setTimeout(() => {
            addMarkingBtn.textContent = originalText;
        }, 1500);

        // Focus back on marking input for next entry
        markingSampleMarking.focus();

    } catch (error) {
        console.error('Error adding sample marking:', error);
        alert(`Error adding sample: ${error.message}`);

        // Re-enable button
        addMarkingBtn.disabled = false;
        addMarkingBtn.textContent = 'Add Sample';
    }
}

// Load and display samples for a specific order
async function loadOrderSamples(orderId) {
    orderSamplesList.innerHTML = '<p class="loading">Loading samples...</p>';

    try {
        const samplesRef = db.collection('samples');
        const snapshot = await samplesRef.where('orderId', '==', orderId).get();

        const samples = snapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));

        // Sort by creation date (newest first)
        samples.sort((a, b) => {
            const dateA = a.createdAt ? a.createdAt.toMillis() : 0;
            const dateB = b.createdAt ? b.createdAt.toMillis() : 0;
            return dateB - dateA;
        });

        if (samples.length === 0) {
            orderSamplesList.innerHTML = '<p style="text-align: center; padding: 20px; color: #666;">No samples registered yet</p>';
            return;
        }

        // Create table
        let html = '<table class="samples-table"><thead><tr>';
        html += '<th>Sample Marking</th>';
        html += '<th>Reference ID</th>';
        html += '<th>Date Received</th>';
        html += '</tr></thead><tbody>';

        samples.forEach(sample => {
            html += '<tr>';
            html += `<td><strong>${sample.sampleMarking || 'N/A'}</strong></td>`;
            html += `<td>${sample.receiveId || 'N/A'}</td>`;
            html += `<td>${formatDate(sample.date)}</td>`;
            html += '</tr>';
        });

        html += '</tbody></table>';
        orderSamplesList.innerHTML = html;

    } catch (error) {
        console.error('Error loading order samples:', error);
        orderSamplesList.innerHTML = `<p class="error">Error loading samples: ${error.message}</p>`;
    }
}

// Delete order from Firebase
async function deleteOrder(orderId, clientName) {
    try {
        // First, get count of samples that will be deleted
        const samplesSnapshot = await db.collection('samples').where('orderId', '==', orderId).get();
        const sampleCount = samplesSnapshot.size;

        // Confirm deletion
        const confirmMessage = sampleCount > 0
            ? `Are you sure you want to delete this order?\n\nClient: ${clientName}\nOrder ID: ${orderId}\n\nThis will also delete ${sampleCount} associated sample(s).\n\nThis action cannot be undone.`
            : `Are you sure you want to delete this order?\n\nClient: ${clientName}\nOrder ID: ${orderId}\n\nThis action cannot be undone.`;

        const confirmDelete = confirm(confirmMessage);

        if (!confirmDelete) {
            return;
        }

        // Delete all samples associated with this order
        if (sampleCount > 0) {
            const batch = db.batch();
            samplesSnapshot.docs.forEach(doc => {
                batch.delete(doc.ref);
            });
            await batch.commit();
            console.log(`Deleted ${sampleCount} samples associated with order ${orderId}`);
        }

        // Delete the order
        await db.collection('orders').doc(orderId).delete();

        console.log('Order deleted successfully:', orderId);
        alert(`Order deleted successfully${sampleCount > 0 ? ` along with ${sampleCount} sample(s)` : ''}`);

        // Reload orders and samples
        loadOrders();
        loadSamples();

    } catch (error) {
        console.error('Error deleting order:', error);
        alert(`Error deleting order: ${error.message}`);
    }
}

// Delete sample from Firebase
async function deleteSample(sampleId, sampleMarking) {
    try {
        // Confirm deletion
        const confirmDelete = confirm(`Are you sure you want to delete this sample?\n\nSample Marking: ${sampleMarking}\nSample ID: ${sampleId}\n\nThis action cannot be undone.`);

        if (!confirmDelete) {
            return;
        }

        // Get the sample to find its orderId before deletion
        const sampleDoc = await db.collection('samples').doc(sampleId).get();
        const sampleData = sampleDoc.data();
        const orderId = sampleData ? sampleData.orderId : null;

        // Delete the sample
        await db.collection('samples').doc(sampleId).delete();

        console.log('Sample deleted successfully:', sampleId);

        // Update order's numberOfSamples if orderId exists
        if (orderId) {
            const samplesSnapshot = await db.collection('samples').where('orderId', '==', orderId).get();
            const sampleCount = samplesSnapshot.size;
            await db.collection('orders').doc(orderId).update({
                numberOfSamples: sampleCount,
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });

            // Reload orders table to reflect updated count
            loadOrders();
        }

        alert('Sample deleted successfully');

        // Reload samples
        loadSamples();

    } catch (error) {
        console.error('Error deleting sample:', error);
        alert(`Error deleting sample: ${error.message}`);
    }
}

// Open edit sample modal and populate with sample data
async function openEditSampleModal(sampleId) {
    try {
        // Find sample in allSamples array
        const sample = allSamples.find(s => s.id === sampleId);

        if (!sample) {
            alert('Sample not found');
            return;
        }

        // Set selected sample
        selectedSample = sample;

        // Populate form fields
        editSampleRefId.textContent = sample.receiveId || 'N/A';
        editSampleOrderId.value = sample.orderId || '';
        editSampleStationId.value = sample.stationId || sample.sampleMarking || '';
        editSampleClient.value = sample.client || '';
        editSampleDate.value = sample.date || '';
        editSampleLat.value = sample.lat || '';
        editSampleLon.value = sample.lon || '';
        editSampleHabitat.value = sample.habitat || '';
        editSampleRemarks.value = sample.remarks || '';
        editSampleCompleted.value = sample.completed ? 'true' : 'false';

        // Show modal
        editSampleModal.classList.remove('hidden');

    } catch (error) {
        console.error('Error opening edit sample modal:', error);
        alert(`Error: ${error.message}`);
    }
}

// Update sample in Firebase
async function updateSample() {
    try {
        if (!selectedSample) {
            alert('No sample selected');
            return;
        }

        const stationId = editSampleStationId.value.trim();
        const client = editSampleClient.value.trim();
        const date = editSampleDate.value;
        const lat = editSampleLat.value.trim();
        const lon = editSampleLon.value.trim();
        const habitat = editSampleHabitat.value.trim();
        const remarks = editSampleRemarks.value.trim();
        const completed = editSampleCompleted.value === 'true';

        // Validate required fields
        if (!stationId || !client || !date) {
            alert('Please fill in all required fields');
            return;
        }

        // Update sample object
        const updateData = {
            stationId: stationId,
            sampleMarking: stationId,
            client: client,
            date: date,
            lat: lat || null,
            lon: lon || null,
            habitat: habitat || null,
            remarks: remarks || null,
            completed: completed,
            updatedAt: firebase.firestore.FieldValue.serverTimestamp()
        };

        // Update in Firebase
        await db.collection('samples').doc(selectedSample.id).update(updateData);

        console.log('Sample updated successfully:', selectedSample.id);
        alert('Sample updated successfully');

        // Close modal and reload samples
        editSampleModal.classList.add('hidden');
        selectedSample = null;
        loadSamples();

    } catch (error) {
        console.error('Error updating sample:', error);
        alert(`Error updating sample: ${error.message}`);
    }
}

// Open edit order modal and populate with order data
async function openEditOrderModal(orderId) {
    try {
        // Find order in allOrders array
        const order = allOrders.find(o => o.id === orderId);

        if (!order) {
            alert('Order not found');
            return;
        }

        // Set selected order
        selectedOrder = order;

        // Count samples for this order
        const samplesSnapshot = await db.collection('samples').where('orderId', '==', orderId).get();
        const sampleCount = samplesSnapshot.size;

        // Populate form fields
        editOrderSpecimenType.textContent = order.specimenType || 'N/A';
        editOrderClientName.value = order.clientName || '';
        editOrderInstitution.value = order.institution || '';
        editOrderNumSamples.value = sampleCount;
        editOrderNumReplicates.value = order.numberOfReplicates || 1;
        editOrderSampleDescription.value = order.sampleDescription || '';
        editOrderGearUsed.value = order.gearUsed || '';
        editOrderAreaGrab.value = order.areaOfGrab || '';
        editOrderSieveSize.value = order.sieveSize || '';
        editOrderNetDiameter.value = order.netDiameter || '';
        editOrderNetMesh.value = order.netMesh || '';
        editOrderTowType.value = order.towType || '';
        editOrderFilteredVolume.value = order.filteredVolume || '';
        editOrderTowDistance.value = order.towDistance || '';
        editOrderSampleVolume.value = order.sampleVolume || '';
        editOrderSrCellVolume.value = order.srCellVolume || '';
        editOrderSrCellsCounted.value = order.srCellsCounted || '';
        editOrderComments.value = order.comments || '';

        // Show/hide fields based on specimen type
        const isBenthos = order.specimenType === 'Macrobenthos';
        const isPlankton = order.specimenType === 'Zooplankton' || order.specimenType === 'Phytoplankton';

        if (isBenthos) {
            editBenthosFields.classList.remove('hidden');
            editPlanktonFields.classList.add('hidden');
            editOrderNumReplicatesGroup.classList.remove('hidden');
        } else if (isPlankton) {
            editBenthosFields.classList.add('hidden');
            editPlanktonFields.classList.remove('hidden');
            editOrderNumReplicatesGroup.classList.add('hidden');
        }

        // Show modal
        editOrderModal.classList.remove('hidden');

    } catch (error) {
        console.error('Error opening edit order modal:', error);
        alert(`Error: ${error.message}`);
    }
}

// Update order in Firebase
async function updateOrder() {
    try {
        if (!selectedOrder) {
            alert('No order selected');
            return;
        }

        const clientName = editOrderClientName.value.trim();
        const institution = editOrderInstitution.value.trim();
        const numReplicates = parseInt(editOrderNumReplicates.value) || 1;
        const sampleDescription = editOrderSampleDescription.value.trim();
        const gearUsed = editOrderGearUsed.value.trim();
        const comments = editOrderComments.value.trim();

        // Type-specific fields
        const areaOfGrab = editOrderAreaGrab.value.trim();
        const sieveSize = editOrderSieveSize.value.trim();
        const netDiameter = editOrderNetDiameter.value.trim();
        const netMesh = editOrderNetMesh.value.trim();
        const towType = editOrderTowType.value.trim();
        const filteredVolume = editOrderFilteredVolume.value.trim();
        const towDistance = editOrderTowDistance.value.trim();
        const sampleVolume = editOrderSampleVolume.value.trim();
        const srCellVolume = editOrderSrCellVolume.value.trim();
        const srCellsCounted = editOrderSrCellsCounted.value.trim();

        // Validate required fields
        if (!clientName) {
            alert('Please enter a client name');
            return;
        }

        // Count samples for this order to update numberOfSamples
        const samplesSnapshot = await db.collection('samples').where('orderId', '==', selectedOrder.id).get();
        const sampleCount = samplesSnapshot.size;

        // Update order object
        const updateData = {
            clientName: clientName,
            institution: institution || null,
            numberOfSamples: sampleCount,
            numberOfReplicates: numReplicates,
            sampleDescription: sampleDescription || null,
            gearUsed: gearUsed || null,
            areaOfGrab: areaOfGrab || null,
            sieveSize: sieveSize || null,
            netDiameter: netDiameter || null,
            netMesh: netMesh || null,
            towType: towType || null,
            filteredVolume: filteredVolume || null,
            towDistance: towDistance || null,
            sampleVolume: sampleVolume || null,
            srCellVolume: srCellVolume || null,
            srCellsCounted: srCellsCounted || null,
            comments: comments || null,
            updatedAt: firebase.firestore.FieldValue.serverTimestamp()
        };

        // Update in Firebase
        await db.collection('orders').doc(selectedOrder.id).update(updateData);

        console.log('Order updated successfully:', selectedOrder.id);
        alert('Order updated successfully');

        // Close modal and reload orders
        editOrderModal.classList.add('hidden');
        selectedOrder = null;
        loadOrders();

    } catch (error) {
        console.error('Error updating order:', error);
        alert(`Error updating order: ${error.message}`);
    }
}

// Update orders autocomplete datalist
function updateOrdersAutocomplete() {
    const datalist = document.getElementById('orders-clients-list');
    if (!datalist) return;

    // Get unique client names from allOrders
    const uniqueClients = [...new Set(allOrders.map(order => order.clientName).filter(name => name))];

    // Sort alphabetically
    uniqueClients.sort((a, b) => a.localeCompare(b));

    // Clear and populate datalist
    datalist.innerHTML = '';
    uniqueClients.forEach(client => {
        const option = document.createElement('option');
        option.value = client;
        datalist.appendChild(option);
    });
}

// Update samples autocomplete datalists
function updateSamplesAutocomplete() {
    // Update clients datalist
    const clientsDatalist = document.getElementById('samples-clients-list');
    if (clientsDatalist) {
        const uniqueClients = [...new Set(allSamples.map(sample => sample.client).filter(name => name))];
        uniqueClients.sort((a, b) => a.localeCompare(b));

        clientsDatalist.innerHTML = '';
        uniqueClients.forEach(client => {
            const option = document.createElement('option');
            option.value = client;
            clientsDatalist.appendChild(option);
        });
    }

    // Update order IDs datalist
    const ordersDatalist = document.getElementById('samples-orders-list');
    if (ordersDatalist) {
        const uniqueOrderIds = [...new Set(allSamples.map(sample => sample.orderId).filter(id => id))];
        uniqueOrderIds.sort();

        ordersDatalist.innerHTML = '';
        uniqueOrderIds.forEach(orderId => {
            const option = document.createElement('option');
            option.value = orderId;
            ordersDatalist.appendChild(option);
        });
    }
}

// Export orders to CSV
function exportOrdersToCSV() {
    try {
        // Get filtered orders (same as what's displayed in the table)
        const filteredOrders = allOrders.filter(order => {
            if (ordersClientFilter && !order.clientName.toLowerCase().includes(ordersClientFilter)) {
                return false;
            }
            return true;
        });

        if (filteredOrders.length === 0) {
            alert('No orders to export');
            return;
        }

        // CSV headers
        const headers = ['Client Name', 'Specimen Type', 'Date Received', 'Samples', 'Replicates', 'Report No', 'Order ID', 'Institution', 'Gear Used', 'Comments'];

        // CSV rows
        const rows = filteredOrders.map(order => {
            return [
                escapeCSV(order.clientName || ''),
                escapeCSV(order.specimenType || ''),
                formatDateForCSV(order.dateReceived),
                order.numberOfSamples || 0,
                order.numberOfReplicates || 0,
                escapeCSV(order.reportNo || ''),
                escapeCSV(order.id || ''),
                escapeCSV(order.institution || ''),
                escapeCSV(order.gearUsed || ''),
                escapeCSV(order.comments || '')
            ].join(',');
        });

        // Combine headers and rows
        const csv = [headers.join(','), ...rows].join('\n');

        // Create download
        const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        const url = URL.createObjectURL(blob);
        const timestamp = new Date().toISOString().split('T')[0];
        link.setAttribute('href', url);
        link.setAttribute('download', `orders_${currentOrdersType}_${timestamp}.csv`);
        link.style.visibility = 'hidden';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);

        console.log(`Exported ${filteredOrders.length} orders to CSV`);
    } catch (error) {
        console.error('Error exporting orders to CSV:', error);
        alert(`Error exporting orders: ${error.message}`);
    }
}

// Export samples to CSV
function exportSamplesToCSV() {
    try {
        // Get filtered samples (same as what's displayed in the table)
        const filteredSamples = allSamples.filter(sample => {
            if (samplesClientFilter && !sample.client.toLowerCase().includes(samplesClientFilter)) {
                return false;
            }
            if (samplesOrderFilter && !sample.orderId.toString().includes(samplesOrderFilter)) {
                return false;
            }
            return true;
        });

        if (filteredSamples.length === 0) {
            alert('No samples to export');
            return;
        }

        // CSV headers
        const headers = ['Reference ID', 'Order ID', 'Station ID', 'Client', 'Date', 'Latitude', 'Longitude', 'Habitat', 'Remarks', 'Status'];

        // CSV rows
        const rows = filteredSamples.map(sample => {
            return [
                escapeCSV(sample.receiveId || ''),
                escapeCSV(sample.orderId || ''),
                escapeCSV(sample.stationId || sample.sampleMarking || ''),
                escapeCSV(sample.client || ''),
                formatDateForCSV(sample.date),
                escapeCSV(sample.lat || ''),
                escapeCSV(sample.lon || ''),
                escapeCSV(sample.habitat || ''),
                escapeCSV(sample.remarks || ''),
                sample.completed ? 'Completed' : 'Pending'
            ].join(',');
        });

        // Combine headers and rows
        const csv = [headers.join(','), ...rows].join('\n');

        // Create download
        const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        const url = URL.createObjectURL(blob);
        const timestamp = new Date().toISOString().split('T')[0];
        link.setAttribute('href', url);
        link.setAttribute('download', `samples_${currentSamplesType}_${timestamp}.csv`);
        link.style.visibility = 'hidden';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);

        console.log(`Exported ${filteredSamples.length} samples to CSV`);
    } catch (error) {
        console.error('Error exporting samples to CSV:', error);
        alert(`Error exporting samples: ${error.message}`);
    }
}

// Helper function to escape CSV values
function escapeCSV(value) {
    if (value === null || value === undefined) return '';
    const stringValue = String(value);
    // If value contains comma, quote, or newline, wrap in quotes and escape quotes
    if (stringValue.includes(',') || stringValue.includes('"') || stringValue.includes('\n')) {
        return '"' + stringValue.replace(/"/g, '""') + '"';
    }
    return stringValue;
}

// Format date for CSV export
function formatDateForCSV(dateValue) {
    if (!dateValue) return '';

    try {
        let date;
        if (dateValue.toDate) {
            // Firestore Timestamp
            date = dateValue.toDate();
        } else if (typeof dateValue === 'string') {
            date = new Date(dateValue);
        } else {
            date = dateValue;
        }

        // Return YYYY-MM-DD format
        return date.toISOString().split('T')[0];
    } catch (error) {
        console.error('Error formatting date for CSV:', error);
        return '';
    }
}

// Format date helper
function formatDate(dateValue) {
    if (!dateValue) return 'N/A';

    try {
        let date;
        if (dateValue.toDate) {
            // Firestore Timestamp
            date = dateValue.toDate();
        } else if (typeof dateValue === 'string') {
            date = new Date(dateValue);
        } else {
            date = dateValue;
        }

        return date.toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
        });
    } catch (error) {
        console.error('Error formatting date:', error);
        return 'Invalid Date';
    }
}

// Clean up orphaned samples (samples that reference non-existent orders)
async function cleanupOrphanedSamples() {
    try {
        // Get all orders
        const ordersSnapshot = await db.collection('orders').get();
        const orderIds = new Set(ordersSnapshot.docs.map(doc => doc.id));

        console.log(`Found ${orderIds.size} orders in database`);

        // Get all samples
        const samplesSnapshot = await db.collection('samples').get();
        const orphanedSamples = [];

        samplesSnapshot.docs.forEach(doc => {
            const sample = doc.data();
            const sampleOrderId = sample.orderId;

            // Check if orderId exists and is not in the orders set
            if (sampleOrderId && !orderIds.has(sampleOrderId)) {
                orphanedSamples.push({
                    id: doc.id,
                    ...sample
                });
            }
        });

        console.log(`Found ${orphanedSamples.length} orphaned samples`);

        if (orphanedSamples.length === 0) {
            alert('No orphaned samples found. Database is clean!');
            return;
        }

        // Confirm deletion
        const confirmDelete = confirm(`Found ${orphanedSamples.length} orphaned sample(s) that reference deleted orders.\n\nDo you want to delete them?\n\nThis action cannot be undone.`);

        if (!confirmDelete) {
            return;
        }

        // Delete orphaned samples using batch
        const batch = db.batch();
        orphanedSamples.forEach(sample => {
            batch.delete(db.collection('samples').doc(sample.id));
        });

        await batch.commit();

        console.log(`Deleted ${orphanedSamples.length} orphaned samples`);
        alert(`Successfully deleted ${orphanedSamples.length} orphaned sample(s)`);

        // Reload samples
        loadSamples();

    } catch (error) {
        console.error('Error cleaning up orphaned samples:', error);
        alert(`Error cleaning up orphaned samples: ${error.message}`);
    }
}

// Global functions to load data (called from app.js)
function loadOrdersData() {
    loadOrders();
}

function loadSamplesData() {
    loadSamples();
}

// Expose cleanup function globally
window.cleanupOrphanedSamples = cleanupOrphanedSamples;
