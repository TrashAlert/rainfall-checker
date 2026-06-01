package com.rainfall.servlet;

import com.rainfall.dao.RainfallDAO;
import com.rainfall.model.RainfallRecord;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;

/**
 * EditServlet — Module M3: Record Edit (Update)
 *
 * URL Mapping : /edit
 * HTTP Methods:
 *   GET  — Show the edit form pre-filled with the record's current values
 *   POST — Save the updated values to the database
 *
 * Purpose:
 *   Allows the user to correct erroneous field values in an existing record.
 *   Only the editable fields (rfh, date, pcode) can be changed;
 *   metadata fields like adm_id and version remain unchanged.
 *
 * Error responses:
 *   400 — Missing or invalid id / form fields
 *   404 — No record found with the given id
 *   500 — Database error
 */
@WebServlet("/edit")
public class EditServlet extends HttpServlet {

    private final RainfallDAO dao = new RainfallDAO();

    /**
     * doGet()
     *
     * Loads the record from the database by its ID and
     * passes it to edit.jsp to pre-fill the edit form.
     */
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String idStr = req.getParameter("id");
        if (idStr == null) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Missing id parameter.");
            return;
        }

        try {
            int id = Integer.parseInt(idStr);
            RainfallRecord record = dao.getRecordById(id);

            if (record == null) {
                resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Record not found.");
                return;
            }

            // Pass the record to the JSP for pre-filling the form
            req.setAttribute("record", record);
            req.getRequestDispatcher("/pages/edit.jsp").forward(req, resp);

        } catch (NumberFormatException e) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid record ID.");
        } catch (Exception e) {
            resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                           "Error loading record: " + e.getMessage());
        }
    }

    /**
     * doPost()
     *
     * Reads the updated values from the submitted form and saves them to the DB.
     * Redirects to the dataset browser with a confirmation message on success.
     *
     * Expected form fields:
     *   id        — record primary key (hidden field)
     *   rfh       — new rainfall height value (must be >= 0)
     *   recordDate — new date string
     *   pcode     — new province code
     */
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String idStr  = req.getParameter("id");
        String rfhStr = req.getParameter("rfh");
        String date   = req.getParameter("recordDate");
        String pcode  = req.getParameter("pcode");

        // Validate all required fields are present
        if (idStr == null || rfhStr == null || date == null || pcode == null) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Missing form fields.");
            return;
        }

        try {
            int    id  = Integer.parseInt(idStr.trim());
            double rfh = Double.parseDouble(rfhStr.trim());

            // rfh must be a non-negative value
            if (rfh < 0) {
                resp.sendError(HttpServletResponse.SC_BAD_REQUEST,
                               "Rainfall value (rfh) cannot be negative.");
                return;
            }

            // Verify the record exists before updating
            if (dao.getRecordById(id) == null) {
                resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Record not found.");
                return;
            }

            // Persist the updated values
            dao.updateRecord(id, rfh, date.trim(), pcode.trim());

            resp.sendRedirect(req.getContextPath() +
                              "/dataset?msg=Record+" + id + "+updated+successfully.");

        } catch (NumberFormatException e) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid numeric value.");
        } catch (Exception e) {
            resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                           "Update failed: " + e.getMessage());
        }
    }
}
