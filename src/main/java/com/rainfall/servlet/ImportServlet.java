package com.rainfall.servlet;

import com.rainfall.dao.RainfallDAO;
import com.rainfall.model.RainfallRecord;
import org.apache.commons.fileupload.FileItem;
import org.apache.commons.fileupload.disk.DiskFileItemFactory;
import org.apache.commons.fileupload.servlet.ServletFileUpload;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.*;
import java.util.List;

/**
 * ImportServlet — Module M3 (Part 1): CSV File Import & Preprocessing
 *
 * URL Mapping : /import
 * HTTP Method : POST (multipart/form-data file upload)
 *
 * Purpose:
 *   Handles the upload of a rainfall CSV file from the browser.
 *   For each row in the CSV:
 *     1. Parses the raw text into a RainfallRecord object
 *     2. Validates mandatory fields (non-null date, numeric rfh >= 0)
 *     3. Persists valid records to the database via RainfallDAO
 *     4. Skips and counts invalid rows without crashing
 *   After processing, redirects to the dataset browser with a status message.
 *
 * Expected CSV column order (0-indexed):
 *   0=date, 1=adm_level, 2=adm_id, 3=PCODE, 4=n_pixels,
 *   5=rfh, 6=rfh_avg, 7=r1h, 8=r1h_avg, 9=r3h, 10=r3h_avg,
 *   11=rfq, 12=r1q, 13=r3q, 14=version
 */
@WebServlet("/import")
public class ImportServlet extends HttpServlet {

    private final RainfallDAO dao = new RainfallDAO();

    /**
     * doPost()
     *
     * Entry point for the CSV file upload form.
     * Validates that a file was attached, then processes it row by row.
     * Stops saving records once the user-specified rowLimit is reached.
     *
     * Form fields expected:
     *   csvFile  — the uploaded CSV file
     *   rowLimit — (optional) max number of valid rows to import; blank = no limit
     *
     * Error responses:
     *   400 — No file attached, or rowLimit is not a positive number
     *   500 — Server-side parsing or DB error
     */
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Verify the request is a multipart file upload
        if (!ServletFileUpload.isMultipartContent(req)) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Expected a file upload request.");
            return;
        }

        int totalRows    = 0;
        int importedRows = 0;
        int skippedRows  = 0;
        String filename  = "unknown";

        // -1 means no limit (import everything)
        int rowLimit = -1;

        try {
            // Set up Apache Commons FileUpload to handle the multipart form
            DiskFileItemFactory factory = new DiskFileItemFactory();
            ServletFileUpload upload = new ServletFileUpload(factory);
            List<FileItem> items = upload.parseRequest(req);

            InputStream csvStream = null;

            // Loop through all form fields — find the file and the rowLimit value
            for (FileItem item : items) {
                if (item.isFormField() && item.getFieldName().equals("rowLimit")) {
                    // Read the rowLimit text field
                    String limitStr = item.getString().trim();
                    if (!limitStr.isEmpty()) {
                        try {
                            rowLimit = Integer.parseInt(limitStr);
                            // Reject nonsensical limit values
                            if (rowLimit < 1) {
                                resp.sendError(HttpServletResponse.SC_BAD_REQUEST,
                                               "Row limit must be at least 1.");
                                return;
                            }
                        } catch (NumberFormatException e) {
                            resp.sendError(HttpServletResponse.SC_BAD_REQUEST,
                                           "Row limit must be a valid whole number.");
                            return;
                        }
                    }
                }
                if (!item.isFormField() && item.getFieldName().equals("csvFile")) {
                    filename  = item.getName();
                    csvStream = item.getInputStream();
                }
            }

            // Return 400 if no file was found in the request
            if (csvStream == null) {
                resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "No CSV file found in the request.");
                return;
            }

            // Read and process the CSV file line by line
            BufferedReader reader = new BufferedReader(new InputStreamReader(csvStream));
            String line;
            boolean isHeader = true;

            while ((line = reader.readLine()) != null) {
                // Skip the header row (first line)
                if (isHeader) { isHeader = false; continue; }
                // Skip empty lines
                if (line.trim().isEmpty()) continue;

                // Stop reading if the import limit has been reached
                if (rowLimit != -1 && importedRows >= rowLimit) break;

                totalRows++;

                // Attempt to parse and save this row
                RainfallRecord record = parseAndValidate(line);
                if (record != null) {
                    dao.insertRecord(record);
                    importedRows++;
                } else {
                    skippedRows++;  // Row failed validation — skip it
                }
            }

            // Log the import summary to the import_log table
            dao.logImport(filename, totalRows, importedRows, skippedRows);

        } catch (Exception e) {
            // 500 for any unexpected server error during import
            resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                           "Import failed: " + e.getMessage());
            return;
        }

        // Build redirect message — mention limit if one was applied
        String limitMsg = (rowLimit != -1)
            ? "+.+Row+limit+of+" + rowLimit + "+applied."
            : "";

        // Redirect back to the dataset browser with a success summary
        resp.sendRedirect(req.getContextPath() +
                          "/dataset?msg=Imported+" + importedRows +
                          "+records.+Skipped+" + skippedRows + "+invalid+rows." + limitMsg);
    }

    /**
     * parseAndValidate(line)
     *
     * Converts one CSV line into a RainfallRecord object after validation.
     *
     * Validation rules applied:
     *   - Date field must not be blank
     *   - rfh (rainfall height) must be a valid non-negative number
     *   - Line must have at least 15 columns
     *
     * @param line  Raw CSV line string
     * @return      A populated RainfallRecord if valid, or null if invalid
     */
    private RainfallRecord parseAndValidate(String line) {
        // Split on comma; handle trailing commas by allowing empty last field
        String[] cols = line.split(",", -1);

        // Minimum column check — need at least 15 fields
        if (cols.length < 15) return null;

        try {
            String date = cols[0].trim();

            // Date must not be blank
            if (date.isEmpty()) return null;

            double rfh = parseDouble(cols[5]);

            // Rainfall cannot be negative — indicates bad/corrupt data
            if (rfh < 0) return null;

            // Build the record object from parsed values
            RainfallRecord r = new RainfallRecord();
            r.setRecordDate(date);
            r.setAdmLevel  (parseInt  (cols[1]));
            r.setAdmId     (parseInt  (cols[2]));
            r.setPcode     (cols[3].trim());
            r.setNPixels   (parseInt  (cols[4]));
            r.setRfh       (rfh);
            r.setRfhAvg    (parseDouble(cols[6]));
            r.setR1h       (parseDouble(cols[7]));
            r.setR1hAvg    (parseDouble(cols[8]));
            r.setR3h       (parseDouble(cols[9]));
            r.setR3hAvg    (parseDouble(cols[10]));
            r.setRfq       (parseDouble(cols[11]));
            r.setR1q       (parseDouble(cols[12]));
            r.setR3q       (parseDouble(cols[13]));
            r.setVersion   (cols[14].trim());

            return r;

        } catch (Exception e) {
            // Any parse exception means the row is malformed — skip it
            return null;
        }
    }

    /** Safely parses a string to double; returns 0.0 on failure */
    private double parseDouble(String s) {
        try { return Double.parseDouble(s.trim()); }
        catch (Exception e) { return 0.0; }
    }

    /** Safely parses a string to int; returns 0 on failure */
    private int parseInt(String s) {
        try { return Integer.parseInt(s.trim()); }
        catch (Exception e) { return 0; }
    }
}
