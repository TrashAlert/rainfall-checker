<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<!--
    analysis.jsp — M1 & M2: Analysis Control Panel
    
    Purpose:
      Single page hosting both M1 (Average Rainfall) and M2 (Threshold Violations).
      Each module has two buttons: "Run Batch" and "Start Real-Time Stream".
    
    M1 Batch:
      Calls GET /analysis/m1?mode=batch → returns JSON → displays stats.
    
    M1 Real-Time:
      Opens EventSource to GET /analysis/m1?mode=realtime
      → receives SSE events → updates running average display live.
    
    M2 Batch:
      Calls GET /analysis/m2?mode=batch&threshold=100 → returns JSON.
    
    M2 Real-Time:
      Opens EventSource to GET /analysis/m2?mode=realtime&threshold=100
      → receives SSE events → highlights violations live.
    
    All analysis respects is_active = 1 (enforced in DAO queries).
-->
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Analysis — M1 &amp; M2</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <style>
        .tab-bar {
            display: flex;
            gap: 4px;
            border-bottom: 1px solid var(--border);
            margin-bottom: 28px;
        }
        .tab-btn {
            padding: 10px 20px;
            background: none;
            border: none;
            color: var(--text-muted);
            font-size: 13px;
            cursor: pointer;
            border-bottom: 2px solid transparent;
            margin-bottom: -1px;
            transition: color 0.2s;
            font-family: var(--font-body);
        }
        .tab-btn.active { color: var(--accent); border-bottom-color: var(--accent); }
        .tab-content { display: none; }
        .tab-content.active { display: block; }

        .mode-row {
            display: flex;
            gap: 12px;
            margin-bottom: 20px;
            flex-wrap: wrap;
        }
        .progress-info {
            font-size: 12px;
            color: var(--text-muted);
            font-family: var(--font-mono);
            margin-top: 8px;
        }
    </style>
</head>
<body>
    <nav class="navbar">
        <a href="${pageContext.request.contextPath}/" class="brand">Rainfall Analysis</a>
        <a href="${pageContext.request.contextPath}/pages/dataset_home.jsp">M3 Import &amp; Data</a>
        <a href="${pageContext.request.contextPath}/pages/analysis.jsp" class="active">M1 &amp; M2 Analysis</a>
        <a href="${pageContext.request.contextPath}/export">M4 Export</a>
    </nav>

    <div class="container">
        <div class="page-title">Analysis Control Panel</div>
        <div class="page-subtitle">
            All analysis runs on active records only (is_active = 1). 
            Soft-deleted records are excluded automatically.
        </div>

        <!-- Tab bar to switch between M1 and M2 -->
        <div class="tab-bar">
            <button class="tab-btn active" onclick="switchTab('m1', this)">
                M1 — Average Rainfall Intensity
            </button>
            <button class="tab-btn" onclick="switchTab('m2', this)">
                M2 — Threshold Violations (100mm)
            </button>
        </div>

        <!-- ════════════════════════════════════════════════════════
             M1 TAB — Average Rainfall Intensity
             ════════════════════════════════════════════════════════ -->
        <div id="tab-m1" class="tab-content active">

            <!-- M1 Control Buttons -->
            <div class="mode-row">
                <button class="btn btn-primary" onclick="runM1Batch()">
                    ▶ Run Batch Analysis
                </button>
                <button class="btn btn-success" id="m1RtBtn" onclick="toggleM1Realtime()">
                    Start Real-Time Stream
                </button>
            </div>

            <!-- M1 Batch Results -->
            <div id="m1BatchResult" style="display:none;">
                <div class="stat-grid">
                    <div class="stat-card">
                        <div class="stat-value" id="m1AvgVal">—</div>
                        <div class="stat-label">Average rfh (mm)</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value" id="m1CountVal">—</div>
                        <div class="stat-label">Active Records</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value" style="color:var(--text-muted);font-size:20px;">100.0 mm</div>
                        <div class="stat-label">Heavy Rain Threshold</div>
                    </div>
                </div>
                <div id="m1BatchMsg" class="alert alert-info" style="display:none;"></div>
            </div>

            <div class="grid-2">
                <!-- M1 Real-Time Live Counter -->
                <div class="card">
                    <div class="card-title">Live Running Average (rfh)</div>
                    <div class="big-counter" id="m1RunningAvg">—</div>
                    <div class="progress-info" id="m1Progress">Press "Start Real-Time Stream" to begin</div>
                    <div class="progress-bar-wrap">
                        <div class="progress-bar-fill" id="m1ProgressBar" style="width:0%"></div>
                    </div>
                </div>

                <!-- M1 Stream Log -->
                <div class="card">
                    <div class="card-title">Stream Log</div>
                    <div class="stream-log" id="m1Log">
                        <div style="color:var(--text-muted);">Waiting for stream...</div>
                    </div>
                </div>
            </div>
        </div>

        <!-- ════════════════════════════════════════════════════════
             M2 TAB — Threshold Violations
             ════════════════════════════════════════════════════════ -->
        <div id="tab-m2" class="tab-content">

            <!-- M2 Threshold Setting -->
            <div class="card" style="margin-bottom:20px; padding:16px 24px;">
                <div style="display:flex; align-items:center; gap:16px; flex-wrap:wrap;">
                    <label style="margin:0; white-space:nowrap;">Threshold (mm):</label>
                    <input type="number"
                           id="m2Threshold"
                           value="100"
                           min="0"
                           step="0.1"
                           style="width:120px;">
                    <small style="color:var(--text-muted);">Records with rfh above this value are counted as violations.</small>
                </div>
            </div>

            <!-- M2 Control Buttons -->
            <div class="mode-row">
                <button class="btn btn-primary" onclick="runM2Batch()">
                    ▶ Run Batch Analysis
                </button>
                <button class="btn btn-success" id="m2RtBtn" onclick="toggleM2Realtime()">
                    Start Real-Time Stream
                </button>
            </div>

            <!-- M2 Batch Results -->
            <div id="m2BatchResult" style="display:none;">
                <div class="stat-grid">
                    <div class="stat-card">
                        <div class="stat-value" style="color:var(--danger);" id="m2ViolCount">—</div>
                        <div class="stat-label">Violations Found</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value" id="m2TotalCount">—</div>
                        <div class="stat-label">Active Records</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value" style="color:var(--warning);" id="m2Percent">—</div>
                        <div class="stat-label">% Violations</div>
                    </div>
                </div>
            </div>

            <div class="grid-2">
                <!-- M2 Real-Time Violation Counter -->
                <div class="card">
                    <div class="card-title">Live Violation Count</div>
                    <div class="violation-counter" id="m2LiveCount">0</div>
                    <div class="progress-info" id="m2Progress">Press "Start Real-Time Stream" to begin</div>
                    <div class="progress-bar-wrap">
                        <div class="progress-bar-fill" id="m2ProgressBar" style="width:0%; background:var(--danger);"></div>
                    </div>
                </div>

                <!-- M2 Violations Stream Log -->
                <div class="card">
                    <div class="card-title">Violations Log</div>
                    <div class="stream-log" id="m2Log">
                        <div style="color:var(--text-muted);">Waiting for stream...</div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        /*
         * ── Tab Switching ────────────────────────────────────────────────
         * Switches between M1 and M2 tabs.
         * Stops any active SSE stream when switching away.
         */
        function switchTab(tabId, btnEl) {
            document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
            document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
            document.getElementById('tab-' + tabId).classList.add('active');
            btnEl.classList.add('active');
        }

        // ── Check initial tab from URL param
        const urlTab = new URLSearchParams(window.location.search).get('tab');
        if (urlTab === 'm2') {
            document.querySelectorAll('.tab-btn')[1].click();
        }

        /*
         * ══════════════════════════════════════════════════════════════
         * M1 — Average Rainfall Intensity
         * ══════════════════════════════════════════════════════════════
         */

        /**
         * runM1Batch()
         * 
         * Sends a GET request to /analysis/m1?mode=batch.
         * On success, parses the JSON response and updates the stat cards.
         * Shows an interpretive message based on whether average > 100mm.
         */
        function runM1Batch() {
            fetch('${pageContext.request.contextPath}/analysis/m1?mode=batch')
                .then(resp => {
                    // Handle non-2xx responses from server
                    if (!resp.ok) throw new Error('Server error: ' + resp.status);
                    return resp.json();
                })
                .then(data => {
                    document.getElementById('m1AvgVal').textContent   = data.average.toFixed(4) + ' mm';
                    document.getElementById('m1CountVal').textContent  = data.count.toLocaleString();
                    document.getElementById('m1BatchResult').style.display = 'block';

                    // Show contextual message
                    const msgEl = document.getElementById('m1BatchMsg');
                    if (data.average > 100) {
                        msgEl.textContent = '⚠ Average rainfall exceeds the 100mm threshold — indicates very heavy rain on average.';
                        msgEl.className = 'alert alert-error';
                    } else {
                        msgEl.textContent = '✓ Average rainfall is below the 100mm threshold.';
                        msgEl.className = 'alert alert-success';
                    }
                    msgEl.style.display = 'block';
                })
                .catch(err => {
                    alert('Batch M1 failed: ' + err.message);
                });
        }

        // SSE connection holder for M1
        let m1Source = null;
        let m1Running = false;

        /**
         * toggleM1Realtime()
         * 
         * Starts or stops the M1 real-time SSE stream.
         * On start: opens EventSource, listens for data events.
         * Each event contains running average — UI updates on each arrival.
         * On stop: closes the connection.
         */
        function toggleM1Realtime() {
            if (m1Running) {
                stopM1();
            } else {
                startM1();
            }
        }

        function startM1() {
            m1Running = true;
            document.getElementById('m1RtBtn').textContent = '⏹ Stop Stream';
            document.getElementById('m1RtBtn').className = 'btn btn-danger';
            document.getElementById('m1Log').innerHTML = '';

            // Open the SSE connection to the M1 real-time endpoint
            m1Source = new EventSource('${pageContext.request.contextPath}/analysis/m1?mode=realtime');

            let totalRecords = 0;

            // Called for every SSE event from the server
            m1Source.onmessage = function(event) {
                try {
                    const d = JSON.parse(event.data);

                    if (d.done) {
                        // Stream finished — show completion
                        appendLog('m1Log', `✓ Stream complete. Processed ${d.total} records.`, 'log-done');
                        document.getElementById('m1Progress').textContent =
                            'Complete — ' + d.total + ' records processed';
                        document.getElementById('m1ProgressBar').style.width = '100%';
                        stopM1();
                        return;
                    }

                    if (d.error) {
                        appendLog('m1Log', 'Error: ' + d.error, 'log-violation');
                        stopM1();
                        return;
                    }

                    // Update the live running average display
                    document.getElementById('m1RunningAvg').textContent = d.runningAvg.toFixed(4) + ' mm';
                    document.getElementById('m1Progress').textContent =
                        `Record ${d.seq} | ${d.pcode} | rfh: ${d.rfh.toFixed(2)} mm`;

                    // Log the record (first 100 shown to avoid overflow)
                    if (d.seq <= 100) {
                        appendLog('m1Log',
                            `[${d.seq}] ${d.date} | ${d.pcode} | rfh=${d.rfh.toFixed(2)} | avg=${d.runningAvg.toFixed(4)}`,
                            'log-normal');
                    } else if (d.seq === 101) {
                        appendLog('m1Log', '... (remaining records streaming silently)', 'log-done');
                    }

                } catch (e) {
                    // Ignore malformed events
                }
            };

            m1Source.onerror = function() {
                appendLog('m1Log', '⚠ Connection error or stream ended.', 'log-violation');
                stopM1();
            };
        }

        function stopM1() {
            m1Running = false;
            if (m1Source) { m1Source.close(); m1Source = null; }
            document.getElementById('m1RtBtn').textContent = 'Start Real-Time Stream';
            document.getElementById('m1RtBtn').className = 'btn btn-success';
        }

        /*
         * ══════════════════════════════════════════════════════════════
         * M2 — Threshold Violation Detection
         * ══════════════════════════════════════════════════════════════
         */

        /**
         * runM2Batch()
         * 
         * Sends a GET to /analysis/m2?mode=batch&threshold=<value>.
         * Displays violation count, total records, and percentage.
         */
        function runM2Batch() {
            const threshold = document.getElementById('m2Threshold').value || '100';
            fetch(`${pageContext.request.contextPath}/analysis/m2?mode=batch&threshold=${threshold}`)
                .then(resp => {
                    if (!resp.ok) throw new Error('Server error: ' + resp.status);
                    return resp.json();
                })
                .then(data => {
                    document.getElementById('m2ViolCount').textContent  = data.violationCount.toLocaleString();
                    document.getElementById('m2TotalCount').textContent = data.totalRecords.toLocaleString();
                    document.getElementById('m2Percent').textContent    = data.percentage.toFixed(2) + '%';
                    document.getElementById('m2BatchResult').style.display = 'block';
                })
                .catch(err => {
                    alert('Batch M2 failed: ' + err.message);
                });
        }

        let m2Source = null;
        let m2Running = false;

        /**
         * toggleM2Realtime()
         * 
         * Starts or stops the M2 SSE stream.
         * Each event says whether the current record is a violation.
         * Violations are highlighted in red in the log.
         * The live counter increments each time a violation is detected.
         */
        function toggleM2Realtime() {
            if (m2Running) {
                stopM2();
            } else {
                startM2();
            }
        }

        function startM2() {
            m2Running = true;
            document.getElementById('m2RtBtn').textContent = '⏹ Stop Stream';
            document.getElementById('m2RtBtn').className = 'btn btn-danger';
            document.getElementById('m2Log').innerHTML = '';
            document.getElementById('m2LiveCount').textContent = '0';

            const threshold = document.getElementById('m2Threshold').value || '100';
            m2Source = new EventSource(
                `${pageContext.request.contextPath}/analysis/m2?mode=realtime&threshold=${threshold}`
            );

            m2Source.onmessage = function(event) {
                try {
                    const d = JSON.parse(event.data);

                    if (d.done) {
                        appendLog('m2Log',
                            `✓ Done. ${d.total} records checked. ${d.violationCount} violations.`,
                            'log-done');
                        document.getElementById('m2Progress').textContent =
                            'Complete — ' + d.violationCount + ' violations found';
                        document.getElementById('m2ProgressBar').style.width = '100%';
                        stopM2();
                        return;
                    }

                    if (d.error) {
                        appendLog('m2Log', 'Error: ' + d.error, 'log-violation');
                        stopM2();
                        return;
                    }

                    // Update live violation counter
                    document.getElementById('m2LiveCount').textContent = d.violationCount;
                    document.getElementById('m2Progress').textContent =
                        `Record ${d.seq} | ${d.pcode} | rfh: ${d.rfh.toFixed(2)} mm`;

                    // Log violations prominently, normal records quietly (first 100 only)
                    if (d.seq <= 200) {
                        if (d.isViolation) {
                            appendLog('m2Log',
                                `[${d.seq}] ${d.date} | ${d.pcode} | rfh=${d.rfh.toFixed(2)} > ${d.threshold} VIOLATION`,
                                'log-violation');
                        } else if (d.seq % 10 === 0) {
                            // Log every 10th normal record to avoid flooding
                            appendLog('m2Log',
                                `[${d.seq}] ${d.date} | ${d.pcode} | rfh=${d.rfh.toFixed(2)} ok`,
                                'log-normal');
                        }
                    }

                } catch (e) {
                    // Ignore malformed events
                }
            };

            m2Source.onerror = function() {
                appendLog('m2Log', 'Connection error or stream ended.', 'log-violation');
                stopM2();
            };
        }

        function stopM2() {
            m2Running = false;
            if (m2Source) { m2Source.close(); m2Source = null; }
            document.getElementById('m2RtBtn').textContent = 'Start Real-Time Stream';
            document.getElementById('m2RtBtn').className = 'btn btn-success';
        }

        /*
         * appendLog(logId, message, cssClass)
         * 
         * Helper: adds a line to a stream-log div and auto-scrolls to bottom.
         * Keeps the UI updated in real time without page refresh.
         */
        function appendLog(logId, message, cssClass) {
            const log = document.getElementById(logId);
            const row = document.createElement('div');
            row.className = 'log-row ' + (cssClass || '');
            row.textContent = message;
            log.appendChild(row);
            log.scrollTop = log.scrollHeight;  // Auto-scroll to latest entry
        }
    </script>
</body>
</html>
