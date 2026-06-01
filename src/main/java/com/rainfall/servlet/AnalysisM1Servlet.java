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
 * AnalysisM1Servlet — Module M1: Average Rainfall Intensity Analysis
 *
 * URL Mapping : /analysis/m1
 * HTTP Methods: GET
 *
 * Query Parameters:
 *   mode — "batch" or "realtime"
 *
 * Purpose:
 *   Implements two analysis modes for the M1 topic:
 *   "Overall Average Rainfall Intensity (rfh)"
 *
 *   BATCH MODE (?mode=batch):
 *     Queries ALL active records in one DB call, computes the average rfh,
 *     and returns a complete JSON summary in a single HTTP response.
 *     The JSP renders the full result at once.
 *
 *   REAL-TIME MODE (?mode=realtime):
 *     Uses Server-Sent Events (SSE) to stream records one by one.
 *     For each record sent, the frontend updates a running average live.
 *     The Servlet holds the HTTP connection open and sends one event per
 *     record with a 50ms delay to simulate a live data feed.
 *
 * Important: ALL queries filter by is_active = 1 (mandatory requirement).
 *
 * Error responses:
 *   400 — Missing or invalid mode parameter
 *   500 — Database or streaming error
 */
@WebServlet("/analysis/m1")
public class AnalysisM1Servlet extends HttpServlet {

    private static final double THRESHOLD = 100.0;  // mm — used for context display
    private final RainfallDAO dao = new RainfallDAO();

    /**
     * doGet()
     *
     * Routes the request to batch or real-time analysis based on the "mode" parameter.
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

        switch (mode) {
            case "batch":    handleBatch(req, resp);    break;
            case "realtime": handleRealtime(req, resp); break;
            default:
                resp.sendError(HttpServletResponse.SC_BAD_REQUEST,
                               "Invalid mode. Use 'batch' or 'realtime'.");
        }
    }

    /**
     * handleBatch()
     *
     * BATCH ANALYSIS — Average Rainfall Intensity
     *
     * Steps:
     *   1. Call dao.getAverageRfh() which runs: SELECT AVG(rfh) WHERE is_active=1
     *   2. Also count active records for context
     *   3. Return a JSON object with average, count, and threshold info
     *
     * Response format (JSON):
     *   { "average": 85.3, "count": 4201, "threshold": 100.0 }
     */
    private void handleBatch(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        try {
            double average = dao.getAverageRfh();
            List<RainfallRecord> records = dao.getActiveRecords();
            int count = records.size();

            resp.setContentType("application/json");
            resp.setCharacterEncoding("UTF-8");

            // Build simple JSON manually (no external library needed for this)
            String json = String.format(
                "{\"average\":%.4f,\"count\":%d,\"threshold\":%.1f,\"mode\":\"batch\"}",
                average, count, THRESHOLD
            );

            resp.getWriter().write(json);

        } catch (Exception e) {
            resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                           "Batch analysis failed: " + e.getMessage());
        }
    }

    /**
     * handleRealtime()
     *
     * REAL-TIME SIMULATED ANALYSIS — Streaming Running Average via SSE
     *
     * Uses Server-Sent Events (SSE):
     *   - Sets content type to "text/event-stream"
     *   - Loops through all active records one at a time
     *   - Sends one SSE event per record containing:
     *       id    : record number (1-based)
     *       date  : record date
     *       rfh   : current record's rainfall value
     *       avg   : running average so far (sum of rfh / records seen)
     *   - Sleeps 50ms between records to simulate a live stream
     *   - Sends a final "done" event when all records are processed
     *
     * The frontend (analysis.jsp JS) listens for these events and
     * updates the running average display after each one arrives.
     *
     * SSE event format:
     *   data: {"seq":1,"date":"1/1/22","rfh":144.5,"runningAvg":144.5}
     */
    private void handleRealtime(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        // SSE requires these specific headers
        resp.setContentType("text/event-stream");
        resp.setCharacterEncoding("UTF-8");
        resp.setHeader("Cache-Control", "no-cache");
        resp.setHeader("Connection",    "keep-alive");
        resp.setHeader("X-Accel-Buffering", "no");  // Disable Nginx buffering if behind proxy

        PrintWriter writer = resp.getWriter();

        try {
            List<RainfallRecord> records = dao.getActiveRecords();

            double runningSum = 0.0;
            int seq = 0;

            for (RainfallRecord r : records) {
                seq++;
                runningSum += r.getRfh();
                double runningAvg = runningSum / seq;

                // Format one SSE event — "data:" prefix is required by SSE protocol
                String eventData = String.format(
                    "data: {\"seq\":%d,\"date\":\"%s\",\"pcode\":\"%s\"," +
                    "\"rfh\":%.4f,\"runningAvg\":%.4f}\n\n",
                    seq,
                    r.getRecordDate(),
                    r.getPcode(),
                    r.getRfh(),
                    runningAvg
                );

                writer.write(eventData);
                writer.flush();  // Push the event to the browser immediately

                // 50ms delay between events simulates a live data stream
                Thread.sleep(50);
            }

            // Signal the frontend that streaming is complete
            writer.write("data: {\"done\":true,\"total\":" + seq + "}\n\n");
            writer.flush();

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        } catch (Exception e) {
            // Send an error event so the frontend can handle it gracefully
            writer.write("data: {\"error\":\"" + e.getMessage() + "\"}\n\n");
            writer.flush();
        }
    }
}
