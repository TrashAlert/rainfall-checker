<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<!--
    edit.jsp — M3: Edit Record Form
    
    Purpose:
      Displays a form pre-filled with the selected record's values.
      The user can correct rfh, date, or pcode and submit.
      On submit, EditServlet validates and saves the changes to DB.
    
    Data passed from EditServlet:
      record — the RainfallRecord object to edit
-->
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Edit Record — M3</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body>
    <nav class="navbar">
        <a href="${pageContext.request.contextPath}/" class="brand">🌧 Rainfall Analysis</a>
        <a href="${pageContext.request.contextPath}/pages/dataset_home.jsp">M3 Import &amp; Data</a>
        <a href="${pageContext.request.contextPath}/pages/analysis.jsp">M1 &amp; M2 Analysis</a>
        <a href="${pageContext.request.contextPath}/export">M4 Export</a>
    </nav>

    <div class="container">
        <div class="page-title">Edit Record #${record.id}</div>
        <div class="page-subtitle">
            Correct erroneous values. Only rfh, date, and PCODE are editable.
        </div>

        <div style="max-width:500px;">
            <div class="card">
                <!--
                    Form POSTs to /edit (EditServlet).
                    Hidden field "id" ensures we update the right record.
                -->
                <form action="${pageContext.request.contextPath}/edit" method="POST">
                    <input type="hidden" name="id" value="${record.id}">

                    <div class="form-group">
                        <label>Date</label>
                        <input type="text"
                               name="recordDate"
                               value="${record.recordDate}"
                               required
                               placeholder="e.g. 1/1/22">
                    </div>

                    <div class="form-group">
                        <label>PCODE (Province Code)</label>
                        <input type="text"
                               name="pcode"
                               value="${record.pcode}"
                               required
                               placeholder="e.g. MY01">
                    </div>

                    <div class="form-group">
                        <label>rfh — Rainfall Height (mm)</label>
                        <input type="number"
                               name="rfh"
                               value="${record.rfh}"
                               required
                               step="0.0001"
                               min="0"
                               placeholder="Must be >= 0">
                        <small style="color:var(--text-muted);">
                            This is the primary analysis field. Must be ≥ 0.
                        </small>
                    </div>

                    <!-- Read-only context fields (not editable) -->
                    <div class="card" style="background:var(--surface2); margin-bottom:16px;">
                        <div style="font-size:12px; color:var(--text-muted);">
                            <strong style="color:var(--text);">Non-editable fields (for reference)</strong><br><br>
                            ADM Level: ${record.admLevel} &nbsp;|&nbsp;
                            ADM ID: ${record.admId} &nbsp;|&nbsp;
                            Version: ${record.version} &nbsp;|&nbsp;
                            Status: 
                            <c:choose>
                                <c:when test="${record.isActive == 1}">
                                    <span class="badge badge-active">Active</span>
                                </c:when>
                                <c:otherwise>
                                    <span class="badge badge-deleted">Soft-Deleted</span>
                                </c:otherwise>
                            </c:choose>
                        </div>
                    </div>

                    <div style="display:flex; gap:12px;">
                        <button type="submit" class="btn btn-primary">Save Changes</button>
                        <a href="${pageContext.request.contextPath}/dataset" class="btn btn-ghost">Cancel</a>
                    </div>
                </form>
            </div>
        </div>
    </div>
</body>
</html>
