<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Export Reports - M4</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body>
    <nav class="navbar">
        <a href="${pageContext.request.contextPath}/" class="brand">Rainfall Analysis</a>
        <a href="${pageContext.request.contextPath}/pages/dataset_home.jsp">M3 Import &amp; Data</a>
        <a href="${pageContext.request.contextPath}/pages/analysis.jsp">M1 &amp; M2 Analysis</a>
        <a href="${pageContext.request.contextPath}/export" class="active">M4 Export</a>
    </nav>

    <div class="container">
        <div class="page-title">Module M4 - Report Generation &amp; Export</div>
        <div class="page-subtitle">
            Generate downloadable reports from M1 (Average) and/or M2 (Violations) analysis results.
        </div>

        <div class="grid-2">
            <div class="card">
                <div class="card-title">Generate Report</div>

                <div class="form-group">
                    <label>Analysis to Export</label>
                    <select id="analysisSelect">
                        <option value="both">Both M1 (Average) + M2 (Violations)</option>
                        <option value="m1">M1 only - Average Rainfall</option>
                        <option value="m2">M2 only - Threshold Violations</option>
                    </select>
                </div>

                <div class="form-group">
                    <label>Violation Threshold (mm) - for M2</label>
                    <input type="number" id="thresholdInput" value="100" min="0" step="0.1">
                    <small style="color:var(--text-muted);">Only used if M2 is selected.</small>
                </div>

                <div style="display:flex; gap:12px; margin-top:8px; flex-wrap:wrap;">
                    <button class="btn btn-primary" onclick="downloadReport('csv')">Download CSV</button>
                    <button class="btn btn-success" onclick="downloadReport('json')">Download JSON</button>
                </div>

                <div id="downloadMsg" class="alert alert-success" style="display:none; margin-top:16px;">
                    Download started! Page will refresh shortly to update export history.
                </div>

                <div class="alert alert-info" style="margin-top:20px;">
                    <strong>CSV</strong> export includes a summary header and full data rows.<br>
                    <strong>JSON</strong> export includes a summary object and a records array.
                </div>
            </div>

            <div class="card">
                <div class="card-title">What's Included</div>
                <table style="font-size:13px; width:100%;">
                    <thead>
                        <tr><th>Module</th><th>Metric</th><th>Source</th></tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td><span class="badge badge-active">M1</span></td>
                            <td>Average rfh (mm)</td>
                            <td>AVG(rfh) WHERE is_active=1</td>
                        </tr>
                        <tr>
                            <td><span class="badge badge-active">M2</span></td>
                            <td>Violation count</td>
                            <td>COUNT WHERE rfh &gt; threshold AND is_active=1</td>
                        </tr>
                        <tr>
                            <td><span class="badge badge-active">M2</span></td>
                            <td>Violation %</td>
                            <td>violations / total x 100</td>
                        </tr>
                        <tr>
                            <td>Data</td>
                            <td>All active records</td>
                            <td>id, date, pcode, rfh, rfh_avg, r1h, r3h, version</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Export History Log -->
        <div class="card">
            <div class="card-title">Export History</div>
            <c:choose>
                <c:when test="${empty exportLogs}">
                    <div style="color:var(--text-muted); font-size:13px; padding:20px 0; text-align:center;">
                        No exports yet. Generate your first report above.
                    </div>
                </c:when>
                <c:otherwise>
                    <div class="table-wrap">
                        <table>
                            <thead>
                                <tr>
                                    <th>#</th>
                                    <th>Format</th>
                                    <th>Analysis</th>
                                    <th>Timestamp</th>
                                    <th>Records</th>
                                </tr>
                            </thead>
                            <tbody>
                                <c:forEach var="log" items="${exportLogs}" varStatus="st">
                                    <tr>
                                        <td>${st.count}</td>
                                        <td>
                                            <c:choose>
                                                <c:when test="${log[0] == 'CSV'}">
                                                    <span class="badge badge-active">CSV</span>
                                                </c:when>
                                                <c:otherwise>
                                                    <span class="badge badge-ok">JSON</span>
                                                </c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td>${log[1]}</td>
                                        <td>${log[2]}</td>
                                        <td>${log[3]}</td>
                                    </tr>
                                </c:forEach>
                            </tbody>
                        </table>
                    </div>
                </c:otherwise>
            </c:choose>
        </div>
    </div>

    <a id="downloadAnchor" style="display:none;"></a>

    <%-- 
        Store context path in a JSP variable for use in the script tag.
        This avoids putting dollar-brace EL expressions inside JS code
        where JSP EL and JS variable syntax conflict.
    --%>
    <% String ctx = request.getContextPath(); %>

    <script>
        /*
         * CTX - context path injected safely via JSP scriptlet.
         * Do NOT use EL dollar-brace inside this script block —
         * JSP would try to evaluate JS variable names as EL expressions.
         */
        var CTX = '<%= ctx %>';

        /**
         * downloadReport(format)
         *
         * Builds the export URL and triggers download via a hidden anchor click.
         * Keeps the user on the page while the file downloads, then reloads
         * after 2 seconds so the export history table refreshes.
         */
        function downloadReport(format) {
            var analysis  = document.getElementById('analysisSelect').value;
            var threshold = document.getElementById('thresholdInput').value;

            if (!threshold || parseFloat(threshold) < 0) {
                threshold = '100';
            }

            var url = CTX + '/export?action=download'
                    + '&format='    + format
                    + '&analysis='  + analysis
                    + '&threshold=' + threshold;

            var anchor = document.getElementById('downloadAnchor');
            anchor.href = url;
            anchor.click();

            document.getElementById('downloadMsg').style.display = 'block';

            setTimeout(function() {
                window.location.href = CTX + '/export';
            }, 2000);
        }
    </script>
</body>
</html>
