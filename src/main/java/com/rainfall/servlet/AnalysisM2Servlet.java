package com.rainfall.servlet;

import com.rainfall.dao.RainfallDAO;
import com.rainfall.model.RainfallRecord;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;

/**
 * AnalysisM2Servlet — Module M2: Threshold Violation Detection
 *
 * URL Mapping : /analysis/m2
 * HTTP Methods: GET
 *
 * Query Parameters:
 *   mode      — "batch" or "realtime"
 *   threshold — (optional) violation threshold in mm, default = 100.0
 *
 * Purpose:
 *   Implements two analysis modes for M2 topic:
 *   "Total Number of Threshold Violations (rfh > 100mm)"
 *
 *   BATCH MODE (?mode=batch):
 *     Queries the DB for count of records where rfh > threshold AND is_active=1.
 *     Returns a complete JSON summary: total violations, percentage, threshold used.
 *
 *   REAL-TIME MODE (?mode=realtime):
 *     Streams active records via SSE one at a time.
 *     For each record, checks if rfh exceeds the threshold.
 *     Sends a running violation count and a flag indicating if current record is a violation.
 *     Frontend highlights violations as they appear.
 *
 * Important: ALL queries filter by is_active = 1 (mandatory requirement).
 * This is DIFFERENT from M1 — uses threshold logic, not average logic.
 *
 * Error responses:
 *   400 — Missing or invalid mode/threshold parameter
 *   500 — Database or streaming error
 */
@WebServlet("/analysis/m2")
public class AnalysisM2Servlet extends HttpServlet {

    private static final double DEFAULT_THRESHOLD = 100.0;  // mm — very heavy rain
    private final RainfallDAO dao = new RainfallDAO();

    /**
     * doGet()
     *
     * Reads the "mode" and optional "threshold" parameters, then routes accordingly.
     */
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String mode = req.getParameter("mode");

        if (mode == null) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST,
                           "Missing 'mode' parameter. Use ?mode=batch or ?mode=realtime");
            return;
        }

        // Parse threshold, falling back to default if not provided or invalid
        double threshold = DEFAULT_THRESHOLD;
        String threshStr = req.getParameter("threshold");
        if (threshStr != null && !threshStr.isEmpty()) {
            try {
                threshold = Double.parseDouble(threshStr);
                if (threshold < 0) {
                    resp.sendError(HttpServletResponse.SC_BAD_REQUEST,
                                   "Threshold cannot be negative.");
                    return;
                }
            } catch (NumberFormatException e) {
                resp.sendError(HttpServletResponse.SC_BAD_REQUEST,
                               "Invalid threshold value: " + threshStr);
                return;
            }
        }

        switch (mode) {
            case "batch":    handleBatch(req, resp, threshold);    break;
            case "realtime": handleRealtime(req, resp, threshold); break;
            default:
                resp.sendError(HttpServletResponse.SC_BAD_REQUEST,
                               "Invalid mode. Use 'batch' or 'realtime'.");
        }
    }

    /**
     * handleBatch()
     *
     * BATCH ANALYSIS — Total Threshold Violations
     *
     * Steps:
     *   1. Call dao.getThresholdViolationCount(threshold) 
     *      → runs: SELECT COUNT(*) WHERE is_active=1 AND rfh > threshold
     *   2. Get total active record count for percentage calculation
     *   3. Return JSON with violationCount, totalRecords, percentage, threshold
     *
     * Response format (JSON):
     *   { "violationCount": 312, "totalRecords": 4201, 
     *     "percentage": 7.43, "threshold": 100.0, "mode": "batch" }
     */
    private void handleBatch(HttpServletRequest req, HttpServletResponse resp,
                              double threshold) throws IOException {
        try {
            int violationCount = dao.getThresholdViolationCount(threshold);
            List<RainfallRecord> all = dao.getActiveRecords();
            int totalRecords = all.size();
            double percentage = totalRecords > 0
                ? (double) violationCount / totalRecords * 100.0
                : 0.0;

            resp.setContentType("application/json");
            resp.setCharacterEncoding("UTF-8");

            String json = String.format(
                "{\"violationCount\":%d,\"totalRecords\":%d," +
                "\"percentage\":%.2f,\"threshold\":%.1f,\"mode\":\"batch\"}",
                violationCount, totalRecords, percentage, threshold
            );

            resp.getWriter().write(json);

        } catch (Exception e) {
            resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                           "Batch M2 analysis failed: " + e.getMessage());
        }
    }

    /**
     * handleRealtime()
     *
     * REAL-TIME SIMULATED ANALYSIS — Live Threshold Violation Detection via SSE
     *
     * Streams each active record via Server-Sent Events.
     * For each record:
     *   - Checks if rfh > threshold
     *   - If yes: marks as "violation" and increments violation counter
     *   - Sends an SSE event with current record details + running violation count
     *
     * The frontend displays:
     *   - A live counter of violations found so far
     *   - Highlights each violating record in red as it arrives
     *   - Shows "ALERT" badge for violation records
     *
     * SSE event format:
     *   data: {"seq":5,"date":"2/1/22","pcode":"MY01","rfh":145.7,
     *          "isViolation":true,"violationCount":1,"threshold":100.0}
     */
    private void handleRealtime(HttpServletRequest req, HttpServletResponse resp,
                                 double threshold) throws IOException {

        resp.setContentType("text/event-stream");
        resp.setCharacterEncoding("UTF-8");
        resp.setHeader("Cache-Control", "no-cache");
        resp.setHeader("Connection",    "keep-alive");
        resp.setHeader("X-Accel-Buffering", "no");

        PrintWriter writer = resp.getWriter();

        try {
            List<RainfallRecord> records = dao.getActiveRecords();

            int violationCount = 0;
            int seq = 0;

            for (RainfallRecord r : records) {
                seq++;
                boolean isViolation = r.getRfh() > threshold;
                if (isViolation) violationCount++;

                String eventData = String.format(
                    "data: {\"seq\":%d,\"date\":\"%s\",\"pcode\":\"%s\"," +
                    "\"rfh\":%.4f,\"isViolation\":%b," +
                    "\"violationCount\":%d,\"threshold\":%.1f}\n\n",
                    seq,
                    r.getRecordDate(),
                    r.getPcode(),
                    r.getRfh(),
                    isViolation,
                    violationCount,
                    threshold
                );

                writer.write(eventData);
                writer.flush();

                Thread.sleep(200);
            }

            // Final event — stream complete, send totals
            writer.write(String.format(
                "data: {\"done\":true,\"total\":%d,\"violationCount\":%d}\n\n",
                seq, violationCount
            ));
            writer.flush();

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        } catch (Exception e) {
            writer.write("data: {\"error\":\"" + e.getMessage() + "\"}\n\n");
            writer.flush();
        }
    }
}
