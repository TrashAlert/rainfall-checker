<%@ page contentType="text/html;charset=UTF-8" language="java" isELIgnored="true" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Analysis - M1 and M2</title>
    <link rel="stylesheet" href="<%=request.getContextPath()%>/css/style.css">
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
        <a href="<%=request.getContextPath()%>/" class="brand">Rainfall Analysis</a>
        <a href="<%=request.getContextPath()%>/pages/dataset_home.jsp">M3 Import &amp; Data</a>
        <a href="<%=request.getContextPath()%>/pages/analysis.jsp" class="active">M1 &amp; M2 Analysis</a>
        <a href="<%=request.getContextPath()%>/export">M4 Export</a>
    </nav>

    <div class="container">
        <div class="page-title">Analysis Control Panel</div>
        <div class="page-subtitle">
            All analysis runs on active records only (is_active = 1).
            Soft-deleted records are excluded automatically.
        </div>

        <div class="tab-bar">
            <button class="tab-btn active" onclick="switchTab('m1', this)">
                M1 - Average Rainfall Intensity
            </button>
            <button class="tab-btn" onclick="switchTab('m2', this)">
                M2 - Threshold Violations (100mm)
            </button>
        </div>

        <!-- M1 TAB -->
        <div id="tab-m1" class="tab-content active">

            <!-- Threshold input — same style as M2 -->
            <div class="card" style="margin-bottom:20px; padding:16px 24px;">
                <div style="display:flex; align-items:center; gap:16px; flex-wrap:wrap;">
                    <label style="margin:0; white-space:nowrap;">Threshold (mm):</label>
                    <input type="number" id="m1Threshold" value="100" min="0" step="0.1" style="width:120px;">
                    <small style="color:var(--text-muted);">Used to compare the computed average against — shown in results and stream log.</small>
                </div>
            </div>

            <div class="mode-row">
                <button class="btn btn-primary" onclick="runM1Batch()">Run Batch Analysis</button>
                <button class="btn btn-success" id="m1RtBtn" onclick="toggleM1Realtime()">Start Real-Time Stream</button>
            </div>

            <div id="m1BatchResult" style="display:none;">
                <div class="stat-grid">
                    <div class="stat-card">
                        <div class="stat-value" id="m1AvgVal">-</div>
                        <div class="stat-label">Average rfh (mm)</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value" id="m1CountVal">-</div>
                        <div class="stat-label">Active Records</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value" style="color:var(--text-muted);font-size:20px;" id="m1ThresholdDisplay">100.0 mm</div>
                        <div class="stat-label">Your Threshold</div>
                    </div>
                </div>
                <div id="m1BatchMsg" class="alert alert-info" style="display:none;"></div>
            </div>

            <div class="grid-2">
                <div class="card">
                    <div class="card-title">Live Running Average (rfh)</div>
                    <div class="big-counter" id="m1RunningAvg">-</div>
                    <div class="progress-info" id="m1Progress">Press Start Real-Time Stream to begin</div>
                    <div class="progress-bar-wrap">
                        <div class="progress-bar-fill" id="m1ProgressBar" style="width:0%"></div>
                    </div>
                </div>
                <div class="card">
                    <div class="card-title">Stream Log</div>
                    <div class="stream-log" id="m1Log">
                        <div style="color:var(--text-muted);">Waiting for stream...</div>
                    </div>
                </div>
            </div>
        </div>

        <!-- M2 TAB -->
        <div id="tab-m2" class="tab-content">

            <div class="card" style="margin-bottom:20px; padding:16px 24px;">
                <div style="display:flex; align-items:center; gap:16px; flex-wrap:wrap;">
                    <label style="margin:0; white-space:nowrap;">Threshold (mm):</label>
                    <input type="number" id="m2Threshold" value="100" min="0" step="0.1" style="width:120px;">
                    <small style="color:var(--text-muted);">Records with rfh above this value are counted as violations.</small>
                </div>
            </div>

            <div class="mode-row">
                <button class="btn btn-primary" onclick="runM2Batch()">Run Batch Analysis</button>
                <button class="btn btn-success" id="m2RtBtn" onclick="toggleM2Realtime()">Start Real-Time Stream</button>
            </div>

            <div id="m2BatchResult" style="display:none;">
                <div class="stat-grid">
                    <div class="stat-card">
                        <div class="stat-value" style="color:var(--danger);" id="m2ViolCount">-</div>
                        <div class="stat-label">Violations Found</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value" id="m2TotalCount">-</div>
                        <div class="stat-label">Active Records</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value" style="color:var(--warning);" id="m2Percent">-</div>
                        <div class="stat-label">% Violations</div>
                    </div>
                </div>
                <div id="m2ThresholdUsed" class="alert alert-info" style="display:none;"></div>
            </div>

            <div class="grid-2">
                <div class="card">
                    <div class="card-title">Live Violation Count</div>
                    <div class="violation-counter" id="m2LiveCount">0</div>
                    <div class="progress-info" id="m2Progress">Press Start Real-Time Stream to begin</div>
                    <div class="progress-bar-wrap">
                        <div class="progress-bar-fill" id="m2ProgressBar" style="width:0%; background:var(--danger);"></div>
                    </div>
                </div>
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
         * CTX - holds the servlet context path for building fetch/SSE URLs.
         * Assigned once here so all functions can build correct URLs.
         * All JS string building uses + concatenation (no template literals).
         */
        var CTX = '<%=request.getContextPath()%>';

        /* switchTab - shows the selected tab and hides the other */
        function switchTab(tabId, btnEl) {
            document.querySelectorAll('.tab-content').forEach(function(t) {
                t.classList.remove('active');
            });
            document.querySelectorAll('.tab-btn').forEach(function(b) {
                b.classList.remove('active');
            });
            document.getElementById('tab-' + tabId).classList.add('active');
            btnEl.classList.add('active');
        }

        /* Check URL param to open M2 tab directly if ?tab=m2 */
        var urlTab = new URLSearchParams(window.location.search).get('tab');
        if (urlTab === 'm2') {
            document.querySelectorAll('.tab-btn')[1].click();
        }

        /* =============================================================
         * M1 - Average Rainfall Intensity
         * =============================================================
         *
         * runM1Batch()
         * Sends GET /analysis/m1?mode=batch
         * Receives JSON: { average, count, threshold }
         * Displays results in stat cards and a contextual message.
         */
        function runM1Batch() {
            var threshold = parseFloat(document.getElementById('m1Threshold').value);

            if (isNaN(threshold) || threshold < 0) {
                alert('Please enter a valid threshold value (0 or greater).');
                return;
            }

            var btn = document.querySelector('[onclick="runM1Batch()"]');
            btn.textContent = 'Running...';
            btn.disabled = true;

            fetch(CTX + '/analysis/m1?mode=batch')
                .then(function(resp) {
                    if (!resp.ok) throw new Error('Server error: ' + resp.status);
                    return resp.json();
                })
                .then(function(data) {
                    document.getElementById('m1AvgVal').textContent          = data.average.toFixed(4) + ' mm';
                    document.getElementById('m1CountVal').textContent        = data.count.toLocaleString();
                    document.getElementById('m1ThresholdDisplay').textContent = threshold.toFixed(1) + ' mm';
                    document.getElementById('m1BatchResult').style.display   = 'block';

                    /* Compare the computed average against the user-set threshold */
                    var msgEl = document.getElementById('m1BatchMsg');
                    if (data.average > threshold) {
                        msgEl.textContent = 'Average rainfall (' + data.average.toFixed(4) + ' mm) exceeds the threshold of ' + threshold + ' mm.';
                        msgEl.className   = 'alert alert-error';
                    } else {
                        msgEl.textContent = 'Average rainfall (' + data.average.toFixed(4) + ' mm) is below the threshold of ' + threshold + ' mm.';
                        msgEl.className   = 'alert alert-success';
                    }
                    msgEl.style.display = 'block';
                })
                .catch(function(err) {
                    alert('Batch M1 failed: ' + err.message);
                })
                .finally(function() {
                    btn.textContent = 'Run Batch Analysis';
                    btn.disabled    = false;
                });
        }

        var m1Source  = null;
        var m1Running = false;

        /*
         * toggleM1Realtime()
         * Starts or stops the M1 SSE stream.
         */
        function toggleM1Realtime() {
            if (m1Running) { stopM1(); } else { startM1(); }
        }

        /*
         * startM1()
         * Opens an EventSource connection to /analysis/m1?mode=realtime.
         * Each SSE event contains: seq, date, pcode, rfh, runningAvg.
         * Updates the live running average counter on every event.
         */
        function startM1() {
            m1Running = true;
            document.getElementById('m1RtBtn').textContent = 'Stop Stream';
            document.getElementById('m1RtBtn').className   = 'btn btn-danger';
            document.getElementById('m1Log').innerHTML     = '';

            var threshold = parseFloat(document.getElementById('m1Threshold').value);

            if (isNaN(threshold) || threshold < 0) {
                alert('Please enter a valid threshold value.');
                stopM1();
                return;
            }

            appendLog('m1Log', 'Starting stream - threshold: rfh avg compared against ' + threshold + ' mm', 'log-done');

            /* Pass threshold so the server can include it in SSE events for context */
            m1Source = new EventSource(CTX + '/analysis/m1?mode=realtime&threshold=' + threshold);

            m1Source.onmessage = function(event) {
                try {
                    var d = JSON.parse(event.data);

                    if (d.done) {
                        /* Show final running average vs threshold comparison */
                        var finalAvg = parseFloat(document.getElementById('m1RunningAvg').textContent);
                        var verdict  = finalAvg > threshold
                            ? ' — ABOVE threshold of ' + threshold + ' mm'
                            : ' — below threshold of ' + threshold + ' mm';
                        appendLog('m1Log', 'Stream complete. Processed ' + d.total + ' records.' + verdict, 'log-done');
                        document.getElementById('m1Progress').textContent = 'Complete - ' + d.total + ' records processed';
                        document.getElementById('m1ProgressBar').style.width = '100%';
                        stopM1();
                        return;
                    }
                    if (d.error) {
                        appendLog('m1Log', 'Error: ' + d.error, 'log-violation');
                        stopM1();
                        return;
                    }

                    /* Update live running average */
                    document.getElementById('m1RunningAvg').textContent = d.runningAvg.toFixed(4) + ' mm';
                    document.getElementById('m1Progress').textContent   =
                        'Record ' + d.seq + ' | ' + d.pcode + ' | rfh: ' + d.rfh.toFixed(2) + ' mm';

                    /* Log first 100 records — mark if individual rfh exceeds threshold */
                    if (d.seq <= 100) {
                        var over    = d.rfh > threshold;
                        var logClass = over ? 'log-violation' : 'log-normal';
                        var marker   = over ? ' [ABOVE THRESHOLD]' : '';
                        appendLog('m1Log',
                            '[' + d.seq + '] ' + d.date + ' | ' + d.pcode +
                            ' | rfh=' + d.rfh.toFixed(2) + ' | avg=' + d.runningAvg.toFixed(4) + marker,
                            logClass);
                    } else if (d.seq === 101) {
                        appendLog('m1Log', '... (remaining records streaming silently)', 'log-done');
                    }
                } catch(e) { /* ignore malformed events */ }
            };

            m1Source.onerror = function() {
                appendLog('m1Log', 'Connection error or stream ended.', 'log-violation');
                stopM1();
            };
        }

        function stopM1() {
            m1Running = false;
            if (m1Source) { m1Source.close(); m1Source = null; }
            document.getElementById('m1RtBtn').textContent = 'Start Real-Time Stream';
            document.getElementById('m1RtBtn').className   = 'btn btn-success';
        }

        /* =============================================================
         * M2 - Threshold Violation Detection
         * =============================================================
         *
         * runM2Batch()
         * Reads threshold from input, sends GET /analysis/m2?mode=batch&threshold=X.
         * Receives JSON: { violationCount, totalRecords, percentage, threshold }
         * Displays violation stats and confirms which threshold was used.
         */
        function runM2Batch() {
            var threshold = parseFloat(document.getElementById('m2Threshold').value);

            if (isNaN(threshold) || threshold < 0) {
                alert('Please enter a valid threshold value (0 or greater).');
                return;
            }

            var btn = document.querySelector('[onclick="runM2Batch()"]');
            btn.textContent = 'Running...';
            btn.disabled    = true;

            fetch(CTX + '/analysis/m2?mode=batch&threshold=' + threshold)
                .then(function(resp) {
                    if (!resp.ok) throw new Error('Server error: ' + resp.status);
                    return resp.json();
                })
                .then(function(data) {
                    document.getElementById('m2ViolCount').textContent  = data.violationCount.toLocaleString();
                    document.getElementById('m2TotalCount').textContent = data.totalRecords.toLocaleString();
                    document.getElementById('m2Percent').textContent    = data.percentage.toFixed(2) + '%';
                    document.getElementById('m2BatchResult').style.display = 'block';

                    /* Confirm which threshold produced these results */
                    var used = document.getElementById('m2ThresholdUsed');
                    used.textContent     = 'Results for threshold: rfh > ' + data.threshold + ' mm';
                    used.style.display   = 'block';
                })
                .catch(function(err) {
                    alert('Batch M2 failed: ' + err.message);
                })
                .finally(function() {
                    btn.textContent = 'Run Batch Analysis';
                    btn.disabled    = false;
                });
        }

        var m2Source  = null;
        var m2Running = false;

        /* toggleM2Realtime - starts or stops the M2 SSE stream */
        function toggleM2Realtime() {
            if (m2Running) { stopM2(); } else { startM2(); }
        }

        /*
         * startM2()
         * Opens SSE to /analysis/m2?mode=realtime&threshold=X.
         * Each event: seq, date, pcode, rfh, isViolation, violationCount, threshold.
         * Highlights violations in red and increments the live counter.
         */
        function startM2() {
            m2Running = true;
            document.getElementById('m2RtBtn').textContent  = 'Stop Stream';
            document.getElementById('m2RtBtn').className    = 'btn btn-danger';
            document.getElementById('m2Log').innerHTML      = '';
            document.getElementById('m2LiveCount').textContent = '0';

            var threshold = parseFloat(document.getElementById('m2Threshold').value);

            if (isNaN(threshold) || threshold < 0) {
                alert('Please enter a valid threshold value.');
                stopM2();
                return;
            }

            appendLog('m2Log', 'Starting stream - threshold: rfh > ' + threshold + ' mm', 'log-done');

            m2Source = new EventSource(CTX + '/analysis/m2?mode=realtime&threshold=' + threshold);

            m2Source.onmessage = function(event) {
                try {
                    var d = JSON.parse(event.data);

                    if (d.done) {
                        appendLog('m2Log',
                            'Done. ' + d.total + ' records checked. ' + d.violationCount + ' violations.',
                            'log-done');
                        document.getElementById('m2Progress').textContent =
                            'Complete - ' + d.violationCount + ' violations found';
                        document.getElementById('m2ProgressBar').style.width = '100%';
                        stopM2();
                        return;
                    }
                    if (d.error) {
                        appendLog('m2Log', 'Error: ' + d.error, 'log-violation');
                        stopM2();
                        return;
                    }

                    /* Update live counter */
                    document.getElementById('m2LiveCount').textContent  = d.violationCount;
                    document.getElementById('m2Progress').textContent   =
                        'Record ' + d.seq + ' | ' + d.pcode + ' | rfh: ' + d.rfh.toFixed(2) + ' mm';

                    /* Log violations in red; log every 10th normal record */
                    if (d.seq <= 200) {
                        if (d.isViolation) {
                            appendLog('m2Log',
                                '[' + d.seq + '] ' + d.date + ' | ' + d.pcode +
                                ' | rfh=' + d.rfh.toFixed(2) + ' > ' + d.threshold + ' VIOLATION',
                                'log-violation');
                        } else if (d.seq % 10 === 0) {
                            appendLog('m2Log',
                                '[' + d.seq + '] ' + d.date + ' | ' + d.pcode +
                                ' | rfh=' + d.rfh.toFixed(2) + ' ok',
                                'log-normal');
                        }
                    }
                } catch(e) { /* ignore malformed events */ }
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
            document.getElementById('m2RtBtn').className   = 'btn btn-success';
        }

        /*
         * appendLog(logId, message, cssClass)
         * Adds a row to a stream-log div and auto-scrolls to the bottom.
         */
        function appendLog(logId, message, cssClass) {
            var log = document.getElementById(logId);
            var row = document.createElement('div');
            row.className   = 'log-row ' + (cssClass || '');
            row.textContent = message;
            log.appendChild(row);
            log.scrollTop   = log.scrollHeight;
        }
    </script>
</body>
</html>
