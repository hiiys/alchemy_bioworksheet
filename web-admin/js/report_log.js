// ==================== Report Log Section ====================

// DOM Elements for Report Log
const reportLogList = document.getElementById('report-log-list');
const logCountSpan = document.getElementById('log-count');
const logClientFilter = document.getElementById('log-client-filter');
const logDateFrom = document.getElementById('log-date-from');
const logDateTo = document.getElementById('log-date-to');
const logSearchBtn = document.getElementById('log-search-btn');
const logClearBtn = document.getElementById('log-clear-btn');
const exportLogBtn = document.getElementById('export-log-btn');

let reportLogs = [];

// Load Report Logs from Firestore
async function loadReportLogs() {
    reportLogList.innerHTML = '<p class="loading">Loading report logs...</p>';

    try {
        // Fetch all logs (no orderBy to avoid index requirements)
        const snapshot = await db.collection('report_logs').get();

        console.log(`Fetched ${snapshot.docs.length} total logs from Firestore`);

        reportLogs = snapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));

        // Get filter values
        const clientFilter = (logClientFilter.value || '').trim().toLowerCase();
        const dateFromValue = logDateFrom.value;
        const dateToValue = logDateTo.value;

        console.log('Filters:', { clientFilter, dateFromValue, dateToValue });

        // Apply client filter (case-insensitive partial match)
        if (clientFilter) {
            try {
                reportLogs = reportLogs.filter(log => {
                    const clientName = (log.clientName || '').toLowerCase();
                    return clientName.includes(clientFilter);
                });
                console.log(`After client filter: ${reportLogs.length} logs`);
            } catch (filterError) {
                console.error('Error in client filter:', filterError);
                throw new Error('Client filter failed: ' + filterError.message);
            }
        }

        // Apply date filtering (client-side)
        if (dateFromValue || dateToValue) {
            try {
                const fromDate = dateFromValue ? new Date(dateFromValue + 'T00:00:00') : null;
                const toDate = dateToValue ? new Date(dateToValue + 'T23:59:59') : null;

                console.log('Date range:', { fromDate, toDate });

                reportLogs = reportLogs.filter(log => {
                    if (!log.dateGenerated) {
                        console.log('Log missing dateGenerated:', log.id);
                        return false;
                    }

                    let logDate;
                    try {
                        logDate = log.dateGenerated.toDate ? log.dateGenerated.toDate() : new Date(log.dateGenerated);
                    } catch (dateError) {
                        console.error('Error parsing date for log:', log.id, dateError);
                        return false;
                    }

                    // Check if within date range
                    if (fromDate && logDate < fromDate) {
                        return false;
                    }
                    if (toDate && logDate > toDate) {
                        return false;
                    }

                    return true;
                });

                console.log(`After date filter: ${reportLogs.length} logs`);
            } catch (filterError) {
                console.error('Error in date filter:', filterError);
                throw new Error('Date filter failed: ' + filterError.message);
            }
        }

        // Sort by date generated (descending - newest first)
        reportLogs.sort((a, b) => {
            try {
                const dateA = a.dateGenerated?.toDate ? a.dateGenerated.toDate() : new Date(a.dateGenerated || 0);
                const dateB = b.dateGenerated?.toDate ? b.dateGenerated.toDate() : new Date(b.dateGenerated || 0);
                return dateB - dateA;
            } catch (sortError) {
                console.error('Error sorting:', sortError);
                return 0;
            }
        });

        console.log(`Final result: ${reportLogs.length} logs`);
        displayReportLogs();

    } catch (error) {
        console.error('Error loading report logs:', error);
        console.error('Error stack:', error.stack);
        reportLogList.innerHTML = `<p class="error">Error loading report logs: ${error.message || 'Unknown error'}. Please check console for details.</p>`;
    }
}

// Display Report Logs in Table
function displayReportLogs() {
    logCountSpan.textContent = `${reportLogs.length} log${reportLogs.length !== 1 ? 's' : ''}`;

    if (reportLogs.length === 0) {
        reportLogList.innerHTML = '<p>No report logs found.</p>';
        return;
    }

    let html = `
        <table class="report-log-table">
            <thead>
                <tr>
                    <th>Date Generated</th>
                    <th>Client</th>
                    <th>Institution</th>
                    <th>Reference ID</th>
                    <th>Report Cover</th>
                    <th>Date Received</th>
                    <th>Num Samples</th>
                    <th>Report Type</th>
                    <th>Generated By</th>
                </tr>
            </thead>
            <tbody>
    `;

    reportLogs.forEach(log => {
        const dateGenerated = log.dateGenerated?.toDate ? log.dateGenerated.toDate() : new Date(log.dateGenerated);
        const dateReceived = log.dateReceived ? (log.dateReceived.toDate ? log.dateReceived.toDate() : new Date(log.dateReceived)) : null;

        html += `
            <tr>
                <td>${dateGenerated.toLocaleString('en-GB')}</td>
                <td>${log.clientName || 'N/A'}</td>
                <td>${log.institution || 'N/A'}</td>
                <td>${log.referenceId || 'N/A'}</td>
                <td>${log.reportCover || 'N/A'}</td>
                <td>${dateReceived ? dateReceived.toLocaleDateString('en-GB') : 'N/A'}</td>
                <td>${log.numberOfSamples || 0}</td>
                <td>${log.reportType || 'N/A'}</td>
                <td>${log.generatedBy || 'N/A'}</td>
            </tr>
        `;
    });

    html += `
            </tbody>
        </table>
    `;

    reportLogList.innerHTML = html;
}

// Save Report Log to Firestore
async function saveReportLog(logData) {
    try {
        const user = auth.currentUser;
        const reportLog = {
            clientName: logData.clientName,
            institution: logData.institution,
            referenceId: logData.referenceId,
            reportCover: logData.reportCover,
            dateReceived: logData.dateReceived,
            dateGenerated: firebase.firestore.FieldValue.serverTimestamp(),
            numberOfSamples: logData.numberOfSamples,
            reportType: logData.reportType, // 'Excel' or 'PDF'
            generatedBy: user ? user.email : 'unknown',
            specimenType: logData.specimenType
        };

        await db.collection('report_logs').add(reportLog);
        console.log('Report log saved successfully');
    } catch (error) {
        console.error('Error saving report log:', error);
    }
}

// Export Report Logs to CSV
function exportReportLogs() {
    if (reportLogs.length === 0) {
        alert('No logs to export');
        return;
    }

    const headers = ['Date Generated', 'Client', 'Institution', 'Reference ID', 'Report Cover', 'Date Received', 'Num Samples', 'Report Type', 'Generated By'];
    const rows = reportLogs.map(log => {
        const dateGenerated = log.dateGenerated?.toDate ? log.dateGenerated.toDate() : new Date(log.dateGenerated);
        const dateReceived = log.dateReceived ? (log.dateReceived.toDate ? log.dateReceived.toDate() : new Date(log.dateReceived)) : null;

        return [
            dateGenerated.toLocaleString('en-GB'),
            log.clientName || '',
            log.institution || '',
            log.referenceId || '',
            log.reportCover || '',
            dateReceived ? dateReceived.toLocaleDateString('en-GB') : '',
            log.numberOfSamples || 0,
            log.reportType || '',
            log.generatedBy || ''
        ];
    });

    let csvContent = headers.join(',') + '\n';
    rows.forEach(row => {
        csvContent += row.map(cell => `"${cell}"`).join(',') + '\n';
    });

    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);
    link.setAttribute('href', url);
    link.setAttribute('download', `report_logs_${new Date().toISOString().split('T')[0]}.csv`);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
}

// Event Listeners for Report Log Page
logSearchBtn.addEventListener('click', loadReportLogs);
logClearBtn.addEventListener('click', () => {
    logClientFilter.value = '';
    logDateFrom.value = '';
    logDateTo.value = '';
    loadReportLogs();
});
exportLogBtn.addEventListener('click', exportReportLogs);
