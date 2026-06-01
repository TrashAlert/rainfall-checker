<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<!--
    dataset_home.jsp — M3: Dataset Import Home Page
    
    Purpose:
      Provides the file upload form for importing a CSV dataset.
      After upload, the ImportServlet processes the file and redirects
      to dataset.jsp (the record browser) with a status message.
-->
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Import Dataset — M3</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body>
    <nav class="navbar">
        <a href="${pageContext.request.contextPath}/" class="brand">Rainfall Analysis</a>
        <a href="${pageContext.request.contextPath}/pages/dataset_home.jsp" class="active">M3 Import &amp; Data</a>
        <a href="${pageContext.request.contextPath}/pages/analysis.jsp">M1 &amp; M2 Analysis</a>
        <a href="${pageContext.request.contextPath}/export">M4 Export</a>
    </nav>

    <div class="container">
        <div class="page-title">Module M3 — Data Management</div>
        <div class="page-subtitle">Import your CSV dataset, then browse, edit, and manage records.</div>

        <div class="grid-2">
            <!-- Upload Card -->
            <div class="card">
                <div class="card-title">Import CSV Dataset</div>
                <p style="color:var(--text-muted); font-size:13px; margin-bottom:20px;">
                    Upload the Malaysia rainfall CSV file. The system will parse, validate, 
                    and store all valid records. Invalid rows are skipped and counted.
                </p>

                <!--
                    Form submits to /import (ImportServlet) via POST.
                    enctype="multipart/form-data" is required for file uploads.
                -->
                <form action="${pageContext.request.contextPath}/import"
                      method="POST"
                      enctype="multipart/form-data">

                    <div class="form-group">
                        <label>CSV File</label>
                        <input type="file"
                               name="csvFile"
                               accept=".csv"
                               required
                               id="fileInput">
                    </div>

                    <div id="fileInfo" style="color:var(--text-muted);font-size:12px;margin-bottom:16px;display:none;">
                        Selected: <span id="fileName"></span>
                    </div>

                    <button type="submit" class="btn btn-primary" id="importBtn">
                        Import Dataset
                    </button>
                </form>

                <div class="alert alert-info" style="margin-top:20px;">
                    <strong>Expected CSV columns:</strong><br>
                    date, adm_level, adm_id, PCODE, n_pixels, rfh, rfh_avg, 
                    r1h, r1h_avg, r3h, r3h_avg, rfq, r1q, r3q, version
                </div>
            </div>

            <!-- Validation Rules Card -->
            <div class="card">
                <div class="card-title">Preprocessing &amp; Validation Rules</div>
                <table style="font-size:13px;">
                    <thead>
                        <tr>
                            <th>Rule</th>
                            <th>Condition</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>Date check</td>
                            <td>date column not blank</td>
                            <td><span class="badge badge-active">Accept</span></td>
                        </tr>
                        <tr>
                            <td>rfh range</td>
                            <td>rfh &ge; 0</td>
                            <td><span class="badge badge-active">Accept</span></td>
                        </tr>
                        <tr>
                            <td>Negative rfh</td>
                            <td>rfh &lt; 0</td>
                            <td><span class="badge badge-deleted">Skip row</span></td>
                        </tr>
                        <tr>
                            <td>Column count</td>
                            <td>&lt; 15 columns</td>
                            <td><span class="badge badge-deleted">Skip row</span></td>
                        </tr>
                        <tr>
                            <td>Parse error</td>
                            <td>Non-numeric in numeric field</td>
                            <td><span class="badge badge-deleted">Skip row</span></td>
                        </tr>
                        <tr>
                            <td>is_active</td>
                            <td>All imported records</td>
                            <td><span class="badge badge-active">Set to 1</span></td>
                        </tr>
                    </tbody>
                </table>

                <div style="margin-top:20px;">
                    <a href="${pageContext.request.contextPath}/dataset"
                       class="btn btn-ghost">
                        Browse Existing Records →
                    </a>
                </div>
            </div>
        </div>
    </div>

    <script>
        // Show selected filename before upload
        document.getElementById('fileInput').addEventListener('change', function() {
            if (this.files.length > 0) {
                document.getElementById('fileName').textContent = this.files[0].name;
                document.getElementById('fileInfo').style.display = 'block';
            }
        });

        // Show loading state on submit
        document.querySelector('form').addEventListener('submit', function() {
            document.getElementById('importBtn').textContent = 'Importing...';
            document.getElementById('importBtn').disabled = true;
        });
    </script>
</body>
</html>
