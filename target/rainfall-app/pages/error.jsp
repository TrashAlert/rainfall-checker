<%@ page contentType="text/html;charset=UTF-8" language="java" isErrorPage="true" %>
<!DOCTYPE html>
<!--
    error.jsp — Custom Error Page
    
    Purpose:
      Displayed for all HTTP errors (400, 404, 500) and unhandled Java exceptions.
      Configured in web.xml via <error-page> elements.
      Ensures users never see a raw stack trace in the browser.
    
    JSP error page attributes used:
      pageContext.errorData.statusCode  — HTTP error code (400/404/500)
      pageContext.errorData.requestURI  — URL that caused the error
      pageContext.errorData.throwable   — The exception (if any)
-->
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Error — Rainfall Analysis</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <style>
        .error-box {
            max-width: 600px;
            margin: 80px auto;
            text-align: center;
        }
        .error-code {
            font-family: var(--font-mono);
            font-size: 80px;
            font-weight: 700;
            color: var(--danger);
            line-height: 1;
            margin-bottom: 12px;
        }
        .error-title {
            font-size: 22px;
            font-weight: 600;
            margin-bottom: 10px;
        }
        .error-msg {
            color: var(--text-muted);
            font-size: 14px;
            margin-bottom: 28px;
            font-family: var(--font-mono);
            background: var(--surface2);
            padding: 12px 20px;
            border-radius: var(--radius);
            border: 1px solid var(--border);
            word-break: break-word;
        }
    </style>
</head>
<body>
    <nav class="navbar">
        <a href="${pageContext.request.contextPath}/" class="brand">Rainfall Analysis</a>
        <a href="${pageContext.request.contextPath}/pages/dataset_home.jsp">M3 Import &amp; Data</a>
        <a href="${pageContext.request.contextPath}/pages/analysis.jsp">M1 &amp; M2 Analysis</a>
        <a href="${pageContext.request.contextPath}/export">M4 Export</a>
    </nav>

    <div class="container">
        <div class="error-box">

            <%-- Display the HTTP error code --%>
            <div class="error-code">
                ${pageContext.errorData.statusCode != 0 ? pageContext.errorData.statusCode : '500'}
            </div>

            <%-- Human-readable title based on error code --%>
            <div class="error-title">
                <%
                    int code = pageContext.getErrorData().getStatusCode();
                    if (code == 400) out.print("Bad Request");
                    else if (code == 404) out.print("Page Not Found");
                    else out.print("Internal Server Error");
                %>
            </div>

            <%-- Show the error message from the Servlet (sendError message) --%>
            <div class="error-msg">
                ${pageContext.errorData.throwable != null
                    ? pageContext.errorData.throwable.message
                    : "An unexpected error occurred. Please try again."}
            </div>

            <%-- Helpful description per error type --%>
            <%
                int statusCode = pageContext.getErrorData().getStatusCode();
                if (statusCode == 400) {
            %>
                <p style="color:var(--text-muted); font-size:13px; margin-bottom:24px;">
                    The request was missing required parameters or contained invalid data.
                    Please check your input and try again.
                </p>
            <% } else if (statusCode == 404) { %>
                <p style="color:var(--text-muted); font-size:13px; margin-bottom:24px;">
                    The record or resource you requested could not be found.
                    It may have been deleted or the ID is incorrect.
                </p>
            <% } else { %>
                <p style="color:var(--text-muted); font-size:13px; margin-bottom:24px;">
                    Something went wrong on the server. Please check that MySQL is running
                    and the database schema has been set up correctly.
                </p>
            <% } %>

            <div style="display:flex; gap:12px; justify-content:center; flex-wrap:wrap;">
                <a href="javascript:history.back()" class="btn btn-ghost">← Go Back</a>
                <a href="${pageContext.request.contextPath}/" class="btn btn-primary">Home</a>
            </div>
        </div>
    </div>
</body>
</html>
