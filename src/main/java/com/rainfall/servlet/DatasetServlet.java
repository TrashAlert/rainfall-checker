package com.rainfall.servlet;

import com.rainfall.dao.RainfallDAO;
import com.rainfall.model.RainfallRecord;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.util.List;

/**
 * DatasetServlet — Module M3 (Part 2): Dataset Management (CRUD + Soft-Delete)
 *
 * URL Mapping : /dataset
 * HTTP Methods:
 *   GET  — Browse/search/paginate records; display dataset management page
 *   POST — Handle actions: soft-delete, reinstate, or redirect to edit form
 *
 * Purpose:
 *   The central M3 module for viewing and managing the imported dataset.
 *   All CRUD operations are exposed through this single Servlet:
 *     - READ   : Paginated table of all records with search filter
 *     - UPDATE : Redirect to EditServlet for field corrections
 *     - SOFT-DELETE : Set is_active = 0 to exclude record from analysis
 *     - REINSTATE   : Set is_active = 1 to re-include a soft-deleted record
 *
 * Pagination:
 *   Default page size is 20 rows. Query param "page" controls current page.
 *   Query param "search" filters by PCODE or date.
 *
 * Error responses:
 *   400 — Missing or invalid action parameter
 *   404 — Record ID not found in database
 *   500 — Database error
 */
@WebServlet("/dataset")
public class DatasetServlet extends HttpServlet {

    private static final int PAGE_SIZE = 20;   // Records per page
    private final RainfallDAO dao = new RainfallDAO();

    /**
     * doGet()
     *
     * Loads the dataset browser page.
     * Reads "page" and "search" query parameters to fetch the right slice of records.
     * Passes records and pagination info to dataset.jsp via request attributes.
     */
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        try {
            // Read pagination and search parameters from the URL
            String search  = req.getParameter("search")  != null ? req.getParameter("search").trim()  : "";
            String pageStr = req.getParameter("page")    != null ? req.getParameter("page")            : "1";
            String msg     = req.getParameter("msg")     != null ? req.getParameter("msg")             : "";

            int page   = Math.max(1, Integer.parseInt(pageStr));
            int offset = (page - 1) * PAGE_SIZE;

            // Fetch the current page of records from the DB
            List<RainfallRecord> records = search.isEmpty()
                ? dao.getAllRecords(offset, PAGE_SIZE)
                : dao.searchRecords(search, offset, PAGE_SIZE);

            // Get total count for calculating total pages
            int totalCount = dao.getRecordCount(search);
            int totalPages = (int) Math.ceil((double) totalCount / PAGE_SIZE);

            // Pass data to the JSP for rendering
            req.setAttribute("records",    records);
            req.setAttribute("currentPage",page);
            req.setAttribute("totalPages", totalPages);
            req.setAttribute("totalCount", totalCount);
            req.setAttribute("search",     search);
            req.setAttribute("msg",        msg);

            req.getRequestDispatcher("/pages/dataset.jsp").forward(req, resp);

        } catch (NumberFormatException e) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid page number.");
        } catch (Exception e) {
            resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                           "Error loading dataset: " + e.getMessage());
        }
    }

    /**
     * doPost()
     *
     * Handles dataset management actions submitted via HTML form.
     * The hidden "action" field determines what to do:
     *   "delete"    — Soft-delete the record (is_active = 0)
     *   "reinstate" — Reinstate the record (is_active = 1)
     *   "edit"      — Redirect to the edit form for this record
     *
     * Required form fields:
     *   action — one of "delete", "reinstate", "edit"
     *   id     — the numeric record ID to act on
     *
     * Error responses:
     *   400 — Missing or unknown action, or non-numeric ID
     *   404 — No record found with the given ID
     *   500 — Database error
     */
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = req.getParameter("action");
        String idStr  = req.getParameter("id");

        // ── deleteAll does not need a record id — handle it first ─────────────
        if ("deleteAll".equals(action)) {
            try {
                int deleted = dao.deleteAll();
                resp.sendRedirect(req.getContextPath() +
                                  "/dataset?msg=All+records+deleted.+" + deleted + "+rows+removed.");
            } catch (Exception e) {
                resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                               "Delete all failed: " + e.getMessage());
            }
            return;
        }

        // All other actions require a record id
        if (action == null || idStr == null) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Missing action or id parameter.");
            return;
        }

        int id;
        try {
            id = Integer.parseInt(idStr);
        } catch (NumberFormatException e) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid record ID.");
            return;
        }

        try {
            switch (action) {

                case "delete":
                    // Soft-delete: mark is_active = 0 (keeps record in DB)
                    RainfallRecord rec = dao.getRecordById(id);
                    if (rec == null) {
                        resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Record not found.");
                        return;
                    }
                    dao.softDelete(id);
                    resp.sendRedirect(req.getContextPath() +
                                      "/dataset?msg=Record+" + id + "+soft-deleted.");
                    break;

                case "reinstate":
                    // Reinstate: mark is_active = 1
                    dao.reinstateRecord(id);
                    resp.sendRedirect(req.getContextPath() +
                                      "/dataset?msg=Record+" + id + "+reinstated.");
                    break;

                case "edit":
                    // Redirect to the edit form, passing the record ID
                    resp.sendRedirect(req.getContextPath() + "/edit?id=" + id);
                    break;

                default:
                    resp.sendError(HttpServletResponse.SC_BAD_REQUEST,
                                   "Unknown action: " + action);
            }

        } catch (Exception e) {
            resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                           "Dataset action failed: " + e.getMessage());
        }
    }
}
