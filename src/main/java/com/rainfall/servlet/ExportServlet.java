package com.rainfall.servlet;

import com.rainfall.dao.RainfallDAO;
import com.rainfall.model.RainfallRecord;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.*;
import java.util.List;

/**
 * ExportServlet — Module M4: Report Generation and Export
 *
 * URL Mapping : /export
 * HTTP Methods:
 *   GET (action=page) — Show the M4 export panel (export.jsp)
 *   GET (action=download) — Stream a downloadable file to the browser
 *
 * Query Parameters:
 *   action    — "page" (show UI) or "download" (generate file)
 *   format    — "csv" or "json"
 *   analysis  — "m1" (average) or "m2" (violations) or "both"
 *   threshold — (optional) violation threshold for M2, default 100.0
 *
 * Purpose:
 *   M4 assembles analysis results from M1 and M2 batch computations
 *   and generates downloadable reports in CSV or JSON format.
 *   Every export is logged to the export_log table with a timestamp.
 *   The export panel also shows the full export history.
 *
 * File streaming:
 *   Uses correct Content-Disposition headers so the browser triggers
 *   a file download dialog instead of displaying raw text.
 *
 * Error responses:
 *   400 — Missing or invalid format/analysis parameters
 *   500 — Database or file streaming error
 */
@WebServlet("/export")
public class ExportServlet extends HttpServlet {

    private static final double DEFAULT_THRESHOLD = 100.0;
    private final RainfallDAO dao = new RainfallDAO();

    /**
     * doGet()
     *
     * Routes to either the export UI page or the file download handler
     * based on the "action" parameter.
     */
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = req.getParameter("action");

        if ("download".equals(action)) {
            handleDownload(req, resp);
        } else {
            // Default: show the export panel page
            showExportPage(req, resp);
        }
    }

    /**
     * showExportPage()
     *
     * Loads export history from the DB and passes it to export.jsp.
     * The JSP renders the export form and the history table.
     */
    private void showExportPage(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            List<String[]> logs = dao.getExportLogs();
            req.setAttribute("exportLogs", logs);
            req.getRequestDispatcher("/pages/export.jsp").forward(req, resp);
        } catch (Exception e) {
            resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                           "Error loading export page: " + e.getMessage());
        }
    }

    /**
     * handleDownload()
     *
     * Generates and streams a report file to the browser.
     *
     * Steps:
     *   1. Parse format (csv/json) and analysis (m1/m2/both) parameters
     *   2. Fetch active records from DB
     *   3. Compute analysis results (average, violations, or both)
     *   4. Build the file content as a String
     *   5. Set Content-Disposition header to trigger browser download dialog
     *   6. Stream the content to the response output
     *   7. Log the export to export_log table
     *
     * @throws IOException if file streaming fails
     */
    private void handleDownload(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        String format    = req.getParameter("format");
        String analysis  = req.getParameter("analysis");

        // Validate required parameters
        if (format == null || (!format.equals("csv") && !format.equals("json"))) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST,
                           "Invalid format. Use 'csv' or 'json'.");
            return;
        }
        if (analysis == null || (!analysis.equals("m1") && !analysis.equals("m2")
                                  && !analysis.equals("both"))) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST,
                           "Invalid analysis. Use 'm1', 'm2', or 'both'.");
            return;
        }

        double threshold = DEFAULT_THRESHOLD;
        String threshStr = req.getParameter("threshold");
        if (threshStr != null && !threshStr.isEmpty()) {
            try { threshold = Double.parseDouble(threshStr); }
            catch (NumberFormatException e) { /* use default */ }
        }

        try {
            List<RainfallRecord> records = dao.getActiveRecords();
            int count = records.size();

            // Compute M1 and/or M2 results
            double average        = computeAverage(records);
            int    violationCount = computeViolations(records, threshold);

            // Build the file content string
            String content;
            String filename;

            if ("csv".equals(format)) {
                content  = buildCSV(records, analysis, average, violationCount,
                                    threshold, count);
                filename = "rainfall_report_" + analysis + ".csv";
                resp.setContentType("text/csv");
            } else {
                content  = buildJSON(records, analysis, average, violationCount,
                                     threshold, count);
                filename = "rainfall_report_" + analysis + ".json";
                resp.setContentType("application/json");
            }

            // Set headers to trigger browser's "Save As" dialog
            resp.setHeader("Content-Disposition",
                           "attachment; filename=\"" + filename + "\"");
            resp.setCharacterEncoding("UTF-8");

            // Stream content to the browser
            PrintWriter writer = resp.getWriter();
            writer.write(content);
            writer.flush();

            // Log this export event to the database
            dao.logExport(format.toUpperCase(), analysis.toUpperCase(), count);

        } catch (Exception e) {
            resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                           "Export failed: " + e.getMessage());
        }
    }

    // ── Report Builders ───────────────────────────────────────────────────────

    /**
     * buildCSV()
     *
     * Constructs the full CSV content string for the export.
     * Includes a summary header section, then a row-by-row data table.
     *
     * @param records        Active records
     * @param analysis       Which analysis was requested (m1/m2/both)
     * @param average        Computed average rfh
     * @param violations     Computed violation count
     * @param threshold      Threshold used for M2
     * @param total          Total active record count
     * @return  CSV string ready to write to response
     */
    private String buildCSV(List<RainfallRecord> records, String analysis,
                             double average, int violations,
                             double threshold, int total) {

        StringBuilder sb = new StringBuilder();

        // Summary section
        sb.append("# Malaysia Rainfall Analysis Report\n");
        sb.append("# Total Active Records,").append(total).append("\n");

        if (!analysis.equals("m2")) {
            sb.append("# M1 - Average Rainfall (rfh),").append(String.format("%.4f", average)).append(" mm\n");
        }
        if (!analysis.equals("m1")) {
            sb.append("# M2 - Threshold (>").append(threshold).append("mm) Violations,")
              .append(violations).append("\n");
        }
        sb.append("#\n");

        // Column headers for data rows
        sb.append("id,date,pcode,rfh,rfh_avg,r1h,r3h,version,is_active\n");

        // Data rows
        for (RainfallRecord r : records) {
            sb.append(r.getId()).append(",")
              .append(r.getRecordDate()).append(",")
              .append(r.getPcode()).append(",")
              .append(String.format("%.4f", r.getRfh())).append(",")
              .append(String.format("%.4f", r.getRfhAvg())).append(",")
              .append(String.format("%.4f", r.getR1h())).append(",")
              .append(String.format("%.4f", r.getR3h())).append(",")
              .append(r.getVersion()).append(",")
              .append(r.getIsActive()).append("\n");
        }

        return sb.toString();
    }

    /**
     * buildJSON()
     *
     * Constructs the full JSON content string for the export.
     * Includes a "summary" object and a "records" array.
     *
     * @return  JSON string ready to write to response
     */
    private String buildJSON(List<RainfallRecord> records, String analysis,
                              double average, int violations,
                              double threshold, int total) {

        StringBuilder sb = new StringBuilder();
        sb.append("{\n");
        sb.append("  \"report\": \"Malaysia Rainfall Analysis\",\n");
        sb.append("  \"totalActiveRecords\": ").append(total).append(",\n");
        sb.append("  \"summary\": {\n");

        if (!analysis.equals("m2")) {
            sb.append("    \"m1_averageRfh\": ").append(String.format("%.4f", average)).append(",\n");
        }
        if (!analysis.equals("m1")) {
            sb.append("    \"m2_threshold\": ").append(threshold).append(",\n");
            sb.append("    \"m2_violationCount\": ").append(violations).append(",\n");
            double pct = total > 0 ? (double) violations / total * 100 : 0;
            sb.append("    \"m2_violationPercentage\": ").append(String.format("%.2f", pct)).append("\n");
        } else {
            // Remove trailing comma from last m1 line
            int lastComma = sb.lastIndexOf(",");
            if (lastComma != -1) sb.deleteCharAt(lastComma);
        }

        sb.append("  },\n");
        sb.append("  \"records\": [\n");

        for (int i = 0; i < records.size(); i++) {
            RainfallRecord r = records.get(i);
            sb.append("    {")
              .append("\"id\":").append(r.getId()).append(",")
              .append("\"date\":\"").append(r.getRecordDate()).append("\",")
              .append("\"pcode\":\"").append(r.getPcode()).append("\",")
              .append("\"rfh\":").append(String.format("%.4f", r.getRfh())).append(",")
              .append("\"rfhAvg\":").append(String.format("%.4f", r.getRfhAvg())).append(",")
              .append("\"r1h\":").append(String.format("%.4f", r.getR1h())).append(",")
              .append("\"r3h\":").append(String.format("%.4f", r.getR3h())).append(",")
              .append("\"version\":\"").append(r.getVersion()).append("\",")
              .append("\"isActive\":").append(r.getIsActive())
              .append("}");
            if (i < records.size() - 1) sb.append(",");
            sb.append("\n");
        }

        sb.append("  ]\n");
        sb.append("}\n");
        return sb.toString();
    }

    // ── Computation Helpers ───────────────────────────────────────────────────

    /**
     * computeAverage(records)
     * Calculates the mean rfh value across all provided records.
     * Returns 0.0 if the list is empty.
     */
    private double computeAverage(List<RainfallRecord> records) {
        if (records.isEmpty()) return 0.0;
        double sum = 0;
        for (RainfallRecord r : records) sum += r.getRfh();
        return sum / records.size();
    }

    /**
     * computeViolations(records, threshold)
     * Counts how many records have rfh > threshold.
     */
    private int computeViolations(List<RainfallRecord> records, double threshold) {
        int count = 0;
        for (RainfallRecord r : records) {
            if (r.getRfh() > threshold) count++;
        }
        return count;
    }
}
