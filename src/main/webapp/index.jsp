<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<!--
    index.jsp — Home / Landing Page
    
    Purpose:
      Application entry point. Shows an overview of all 4 modules
      with navigation cards to each module.
-->
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Malaysia Rainfall Analysis — BITS3515</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <style>
        .hero {
            text-align: center;
            padding: 60px 0 40px;
        }
        .hero h1 {
            font-family: var(--font-mono);
            font-size: 32px;
            font-weight: 700;
            color: var(--accent);
            margin-bottom: 10px;
        }
        .hero p { color: var(--text-muted); font-size: 15px; }

        .module-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-top: 40px;
        }
        .module-card {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: var(--radius);
            padding: 28px 24px;
            text-decoration: none;
            color: var(--text);
            transition: border-color 0.2s, transform 0.15s;
            display: block;
        }
        .module-card:hover {
            border-color: var(--accent);
            transform: translateY(-3px);
        }
        .module-tag {
            font-family: var(--font-mono);
            font-size: 11px;
            font-weight: 700;
            color: var(--accent);
            text-transform: uppercase;
            letter-spacing: 0.1em;
            margin-bottom: 10px;
        }
        .module-title {
            font-size: 16px;
            font-weight: 600;
            margin-bottom: 8px;
        }
        .module-desc {
            font-size: 12px;
            color: var(--text-muted);
            line-height: 1.6;
        }
    </style>
</head>
<body>
    <!-- Navigation -->
    <nav class="navbar">
        <a href="${pageContext.request.contextPath}/" class="brand">Rainfall Analysis</a>
        <a href="${pageContext.request.contextPath}/pages/dataset_home.jsp">M3 Import &amp; Data</a>
        <a href="${pageContext.request.contextPath}/pages/analysis.jsp">M1 &amp; M2 Analysis</a>
        <a href="${pageContext.request.contextPath}/export">M4 Export</a>
    </nav>

    <div class="container">
        <div class="hero">
            <h1>Malaysia Rainfall Analysis</h1>
            <p>BITS 3515 TCP/IP Programming — Mini Project 2</p>
            <p style="margin-top:8px; color: var(--text-muted); font-size:12px;">
                Dataset: Malaysia Sub-National Rainfall (5-Year) &nbsp;|&nbsp; 
                Analysis: rfh (rainfall height, mm)
            </p>
        </div>

        <div class="module-grid">
            <!-- M1 -->
            <a href="${pageContext.request.contextPath}/pages/analysis.jsp?tab=m1" class="module-card">
                <div class="module-tag">M1 — Analysis A</div>
                <div class="module-title">Average Rainfall Intensity</div>
                <div class="module-desc">
                    Computes the overall average rfh (rainfall height in mm) 
                    across all active records. Supports Batch and Real-Time (SSE) modes.
                </div>
            </a>

            <!-- M2 -->
            <a href="${pageContext.request.contextPath}/pages/analysis.jsp?tab=m2" class="module-card">
                <div class="module-tag">M2 — Analysis B</div>
                <div class="module-title">Threshold Violation Detection</div>
                <div class="module-desc">
                    Counts records where rfh &gt; 100mm (very heavy rain threshold).
                    Supports Batch summary and Real-Time live alert streaming.
                </div>
            </a>

            <!-- M3 -->
            <a href="${pageContext.request.contextPath}/pages/dataset_home.jsp" class="module-card">
                <div class="module-tag">M3 — Data Management</div>
                <div class="module-title">Import, Browse &amp; Manage</div>
                <div class="module-desc">
                    Upload CSV dataset, browse all records, search/filter, 
                    edit erroneous values, and soft-delete records from analysis.
                </div>
            </a>

            <!-- M4 -->
            <a href="${pageContext.request.contextPath}/export" class="module-card">
                <div class="module-tag">M4 — Export &amp; Reports</div>
                <div class="module-title">Report Generation</div>
                <div class="module-desc">
                    Export M1 and/or M2 analysis results as CSV or JSON files.
                    Maintains a full export history log with timestamps.
                </div>
            </a>
        </div>
    </div>
</body>
</html>
