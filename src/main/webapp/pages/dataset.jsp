<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<!DOCTYPE html>
<!--
    dataset.jsp — M3: Dataset Record Browser
    
    Purpose:
      Displays all records in a paginated, searchable table.
      Each row shows the record's data and action buttons:
        - Edit    → redirect to edit.jsp
        - Delete  → POST to DatasetServlet (soft-delete, is_active = 0)
        - Restore → POST to DatasetServlet (reinstate, is_active = 1)
    
    Data passed from DatasetServlet:
      records      — List<RainfallRecord> for the current page
      currentPage  — current page number
      totalPages   — total number of pages
      totalCount   — total number of records
      search       — current search keyword
      msg          — optional status message from a previous action
-->
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Dataset Browser — M3</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body>
    <nav class="navbar">
        <a href="${pageContext.request.contextPath}/" class="brand">Rainfall Analysis</a>
        <a href="${pageContext.request.contextPath}/pages/dataset_home.jsp">M3 Import &amp; Data</a>
        <a href="${pageContext.request.contextPath}/pages/analysis.jsp">M1 &amp; M2 Analysis</a>
        <a href="${pageContext.request.contextPath}/export">M4 Export</a>
    </nav>

    <div class="container">
        <div class="page-title">Dataset Browser</div>
        <div class="page-subtitle">
            Total records: <strong>${totalCount}</strong>
            &nbsp;|&nbsp; Page ${currentPage} of ${totalPages}
            &nbsp;|&nbsp;
            <a href="${pageContext.request.contextPath}/pages/dataset_home.jsp" style="color:var(--accent)">
                Import new CSV
            </a>
        </div>

        <!-- Status message from previous action (import/delete/edit) -->
        <c:if test="${not empty msg}">
            <div class="alert alert-success">${msg}</div>
        </c:if>

        <!-- Delete All button — hard-deletes entire dataset -->
        <c:if test="${totalCount > 0}">
            <form method="POST"
                  action="${pageContext.request.contextPath}/dataset"
                  style="margin-bottom:20px;"
                  onsubmit="return confirm('WARNING: This will permanently delete ALL ' + '${totalCount}' + ' records from the database. This cannot be undone. Continue?')">
                <input type="hidden" name="action" value="deleteAll">
                <button type="submit" class="btn btn-danger">
                    Delete Entire Dataset (${totalCount} records)
                </button>
            </form>
        </c:if>

        <!-- Search form — filters records by PCODE or date keyword -->
        <form class="search-bar" action="${pageContext.request.contextPath}/dataset" method="GET">
            <input type="text"
                   name="search"
                   placeholder="Search by PCODE (e.g. MY01) or date..."
                   value="${search}">
            <button type="submit" class="btn btn-primary">Search</button>
            <c:if test="${not empty search}">
                <a href="${pageContext.request.contextPath}/dataset" class="btn btn-ghost">Clear</a>
            </c:if>
        </form>

        <!-- Records Table -->
        <div class="card" style="padding:0;">
            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Date</th>
                            <th>PCODE</th>
                            <th>rfh (mm)</th>
                            <th>rfh_avg</th>
                            <th>r1h</th>
                            <th>r3h</th>
                            <th>Version</th>
                            <th>Status</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:choose>
                            <c:when test="${empty records}">
                                <tr>
                                    <td colspan="10" style="text-align:center; color:var(--text-muted); padding:40px;">
                                        No records found. 
                                        <a href="${pageContext.request.contextPath}/pages/dataset_home.jsp" style="color:var(--accent)">
                                            Import a CSV first.
                                        </a>
                                    </td>
                                </tr>
                            </c:when>
                            <c:otherwise>
                                <c:forEach var="r" items="${records}">
                                    <tr>
                                        <td>${r.id}</td>
                                        <td>${r.recordDate}</td>
                                        <td>${r.pcode}</td>
                                        <td>
                                            <!-- Highlight high rainfall values -->
                                            <c:choose>
                                                <c:when test="${r.rfh > 100}">
                                                    <span style="color:var(--danger); font-weight:600;">
                                                        <fmt:formatNumber value="${r.rfh}" maxFractionDigits="2"/>
                                                    </span>
                                                </c:when>
                                                <c:otherwise>
                                                    <fmt:formatNumber value="${r.rfh}" maxFractionDigits="2"/>
                                                </c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td><fmt:formatNumber value="${r.rfhAvg}" maxFractionDigits="2"/></td>
                                        <td><fmt:formatNumber value="${r.r1h}"    maxFractionDigits="2"/></td>
                                        <td><fmt:formatNumber value="${r.r3h}"    maxFractionDigits="2"/></td>
                                        <td>${r.version}</td>
                                        <td>
                                            <c:choose>
                                                <c:when test="${r.isActive == 1}">
                                                    <span class="badge badge-active">Active</span>
                                                </c:when>
                                                <c:otherwise>
                                                    <span class="badge badge-deleted">Deleted</span>
                                                </c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td>
                                            <!-- Edit button — redirects to EditServlet GET -->
                                            <form method="POST"
                                                  action="${pageContext.request.contextPath}/dataset"
                                                  style="display:inline;">
                                                <input type="hidden" name="id"     value="${r.id}">
                                                <input type="hidden" name="action" value="edit">
                                                <button type="submit" class="btn btn-ghost btn-sm">Edit</button>
                                            </form>

                                            <!-- Soft-delete or Restore based on current is_active status -->
                                            <c:choose>
                                                <c:when test="${r.isActive == 1}">
                                                    <!-- Active → offer soft-delete -->
                                                    <form method="POST"
                                                          action="${pageContext.request.contextPath}/dataset"
                                                          style="display:inline;"
                                                          onsubmit="return confirm('Soft-delete record ${r.id}? It will be excluded from analysis.')">
                                                        <input type="hidden" name="id"     value="${r.id}">
                                                        <input type="hidden" name="action" value="delete">
                                                        <button type="submit" class="btn btn-danger btn-sm">Delete</button>
                                                    </form>
                                                </c:when>
                                                <c:otherwise>
                                                    <!-- Soft-deleted → offer restore -->
                                                    <form method="POST"
                                                          action="${pageContext.request.contextPath}/dataset"
                                                          style="display:inline;">
                                                        <input type="hidden" name="id"     value="${r.id}">
                                                        <input type="hidden" name="action" value="reinstate">
                                                        <button type="submit" class="btn btn-success btn-sm">Restore</button>
                                                    </form>
                                                </c:otherwise>
                                            </c:choose>
                                        </td>
                                    </tr>
                                </c:forEach>
                            </c:otherwise>
                        </c:choose>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Pagination controls -->
        <div class="pagination">
            <c:if test="${currentPage > 1}">
                <a href="${pageContext.request.contextPath}/dataset?page=${currentPage-1}&search=${search}">← Prev</a>
            </c:if>

            <%-- Show up to 7 page links around current page --%>
            <c:forEach begin="1" end="${totalPages}" var="p">
                <c:if test="${p >= currentPage-3 && p <= currentPage+3}">
                    <c:choose>
                        <c:when test="${p == currentPage}">
                            <span class="current">${p}</span>
                        </c:when>
                        <c:otherwise>
                            <a href="${pageContext.request.contextPath}/dataset?page=${p}&search=${search}">${p}</a>
                        </c:otherwise>
                    </c:choose>
                </c:if>
            </c:forEach>

            <c:if test="${currentPage < totalPages}">
                <a href="${pageContext.request.contextPath}/dataset?page=${currentPage+1}&search=${search}">Next →</a>
            </c:if>
        </div>
    </div>
</body>
</html>
