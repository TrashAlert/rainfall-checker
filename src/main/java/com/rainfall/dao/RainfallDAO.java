package com.rainfall.dao;

import com.rainfall.model.RainfallRecord;
import com.rainfall.util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * RainfallDAO — Data Access Object
 *
 * Purpose:
 *   Handles ALL database operations for the rainfall_data table.
 *   Servlets call these methods instead of writing raw SQL themselves.
 *   This keeps the Servlet code clean and SQL in one place.
 *
 * Methods overview:
 *   insertRecord()      — M3: Save one parsed CSV row to DB
 *   getAllRecords()     — M3: Browse/paginate all records
 *   searchRecords()     — M3: Filter records by PCODE or date
 *   getRecordById()     — M3: Fetch single record for edit
 *   updateRecord()      — M3: Edit a record's rfh value
 *   softDelete()        — M3: Set is_active = 0 (exclude from analysis)
 *   reinstateRecord()   — M3: Set is_active = 1 (re-include in analysis)
 *   getActiveRecords()  — M1/M2: Fetch only active records for analysis
 *   getRecordCount()    — M3: Total record count
 *   logExport()         — M4: Save export log entry
 *   getExportLogs()     — M4: Retrieve export history
 *   logImport()         — M3: Save import summary
 */
public class RainfallDAO {

    // ── INSERT ────────────────────────────────────────────────────────────────

    /**
     * insertRecord(record)
     *
     * Saves one RainfallRecord object into the rainfall_data table.
     * Called by M3 (ImportServlet) for every valid CSV row.
     *
     * @param record  The parsed and validated RainfallRecord to persist
     * @throws SQLException if the INSERT query fails
     */
    public void insertRecord(RainfallRecord record) throws SQLException {
        String sql = "INSERT INTO rainfall_data " +
                     "(record_date, adm_level, adm_id, pcode, n_pixels, rfh, rfh_avg, " +
                     "r1h, r1h_avg, r3h, r3h_avg, rfq, r1q, r3q, version, is_active) " +
                     "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,1)";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1,  record.getRecordDate());
            ps.setInt   (2,  record.getAdmLevel());
            ps.setInt   (3,  record.getAdmId());
            ps.setString(4,  record.getPcode());
            ps.setInt   (5,  record.getNPixels());
            ps.setDouble(6,  record.getRfh());
            ps.setDouble(7,  record.getRfhAvg());
            ps.setDouble(8,  record.getR1h());
            ps.setDouble(9,  record.getR1hAvg());
            ps.setDouble(10, record.getR3h());
            ps.setDouble(11, record.getR3hAvg());
            ps.setDouble(12, record.getRfq());
            ps.setDouble(13, record.getR1q());
            ps.setDouble(14, record.getR3q());
            ps.setString(15, record.getVersion());

            ps.executeUpdate();
        }
    }

    // ── READ (Browse / Paginate) ───────────────────────────────────────────────

    /**
     * getAllRecords(offset, limit)
     *
     * Returns a page of ALL records (active and soft-deleted) for the
     * M3 dataset browser. Supports pagination via LIMIT and OFFSET.
     *
     * @param offset  Number of rows to skip (0 = first page)
     * @param limit   Maximum rows to return per page
     * @return  List of RainfallRecord objects
     * @throws SQLException
     */
    public List<RainfallRecord> getAllRecords(int offset, int limit) throws SQLException {
        String sql = "SELECT * FROM rainfall_data ORDER BY id DESC LIMIT ? OFFSET ?";
        return executeQuery(sql, limit, offset);
    }

    /**
     * searchRecords(keyword, offset, limit)
     *
     * Filters records by PCODE or date containing the keyword string.
     * Used by the search bar in the M3 dataset browser.
     *
     * @param keyword  Search text (e.g. "MY01" or "2022")
     * @param offset   Pagination offset
     * @param limit    Page size
     * @return  Filtered list of records
     * @throws SQLException
     */
    public List<RainfallRecord> searchRecords(String keyword, int offset, int limit) throws SQLException {
        String sql = "SELECT * FROM rainfall_data " +
                     "WHERE (pcode LIKE ? OR record_date LIKE ?) " +
                     "ORDER BY id DESC LIMIT ? OFFSET ?";
        String like = "%" + keyword + "%";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, like);
            ps.setString(2, like);
            ps.setInt   (3, limit);
            ps.setInt   (4, offset);
            return mapResultSet(ps.executeQuery());
        }
    }

    /**
     * getRecordById(id)
     *
     * Fetches a single record by its primary key.
     * Used by M3 EditServlet to pre-fill the edit form.
     *
     * @param id  Primary key of the record
     * @return    The matching RainfallRecord, or null if not found
     * @throws SQLException
     */
    public RainfallRecord getRecordById(int id) throws SQLException {
        String sql = "SELECT * FROM rainfall_data WHERE id = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            List<RainfallRecord> results = mapResultSet(ps.executeQuery());
            return results.isEmpty() ? null : results.get(0);
        }
    }

    // ── UPDATE ────────────────────────────────────────────────────────────────

    /**
     * updateRecord(id, newRfh, newDate, newPcode)
     *
     * Corrects erroneous field values for a specific record.
     * Only editable fields (rfh, date, pcode) are updated — metadata stays intact.
     *
     * @param id       ID of the record to update
     * @param newRfh   New rainfall height value
     * @param newDate  New date string
     * @param newPcode New province code
     * @throws SQLException
     */
    public void updateRecord(int id, double newRfh, String newDate, String newPcode)
            throws SQLException {
        String sql = "UPDATE rainfall_data SET rfh=?, record_date=?, pcode=? WHERE id=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setDouble(1, newRfh);
            ps.setString(2, newDate);
            ps.setString(3, newPcode);
            ps.setInt   (4, id);
            ps.executeUpdate();
        }
    }

    // ── SOFT DELETE & REINSTATE ───────────────────────────────────────────────

    /**
     * softDelete(id)
     *
     * Sets is_active = 0 for the given record.
     * The record remains in the database but is EXCLUDED from M1 and M2 analysis.
     * This is the core of the soft-delete mechanism required by the assignment.
     *
     * @param id  ID of the record to exclude
     * @throws SQLException
     */
    public void softDelete(int id) throws SQLException {
        setActiveFlag(id, 0);
    }

    /**
     * reinstateRecord(id)
     *
     * Sets is_active = 1 for a previously soft-deleted record,
     * re-including it in future analysis runs.
     *
     * @param id  ID of the record to reinstate
     * @throws SQLException
     */
    public void reinstateRecord(int id) throws SQLException {
        setActiveFlag(id, 1);
    }

    /**
     * setActiveFlag(id, flag)
     *
     * Internal helper that updates the is_active column.
     * Called by both softDelete() and reinstateRecord().
     *
     * @param id    Record ID
     * @param flag  1 = active, 0 = soft-deleted
     * @throws SQLException
     */
    private void setActiveFlag(int id, int flag) throws SQLException {
        String sql = "UPDATE rainfall_data SET is_active = ? WHERE id = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, flag);
            ps.setInt(2, id);
            ps.executeUpdate();
        }
    }

    // ── ANALYSIS QUERIES (M1 / M2) ────────────────────────────────────────────

    /**
     * getActiveRecords()
     *
     * Returns ALL records where is_active = 1.
     * Used by M1 (batch average) and M2 (batch threshold violations).
     * The is_active filter is MANDATORY — required by the assignment spec.
     *
     * @return  List of active RainfallRecord objects
     * @throws SQLException
     */
    public List<RainfallRecord> getActiveRecords() throws SQLException {
        String sql = "SELECT * FROM rainfall_data WHERE is_active = 1 ORDER BY id ASC";
        return executeQuery(sql);
    }

    /**
     * getAverageRfh()
     *
     * Computes the overall average of rfh (rainfall height) across all active records.
     * Used by M1 Batch Analysis — returns a single computed number from DB.
     *
     * @return  Average rfh value as a double
     * @throws SQLException
     */
    public double getAverageRfh() throws SQLException {
        String sql = "SELECT AVG(rfh) FROM rainfall_data WHERE is_active = 1";
        try (Connection conn = DBConnection.getConnection();
             Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            return rs.next() ? rs.getDouble(1) : 0.0;
        }
    }

    /**
     * getThresholdViolationCount(threshold)
     *
     * Counts how many active records have rfh > threshold.
     * Used by M2 Batch Analysis.
     *
     * @param threshold  The rainfall value (mm) to compare against (e.g. 100.0)
     * @return  Number of records that exceed the threshold
     * @throws SQLException
     */
    public int getThresholdViolationCount(double threshold) throws SQLException {
        String sql = "SELECT COUNT(*) FROM rainfall_data WHERE is_active = 1 AND rfh > ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setDouble(1, threshold);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? rs.getInt(1) : 0;
        }
    }

    // ── COUNT ─────────────────────────────────────────────────────────────────

    /**
     * getRecordCount(keyword)
     *
     * Returns total number of records matching the keyword search,
     * used for calculating the total pages in pagination.
     * Pass an empty string to get count of ALL records.
     *
     * @param keyword  Search filter string (empty = all records)
     * @return  Row count as integer
     * @throws SQLException
     */
    public int getRecordCount(String keyword) throws SQLException {
        String sql = keyword.isEmpty()
            ? "SELECT COUNT(*) FROM rainfall_data"
            : "SELECT COUNT(*) FROM rainfall_data WHERE pcode LIKE ? OR record_date LIKE ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            if (!keyword.isEmpty()) {
                String like = "%" + keyword + "%";
                ps.setString(1, like);
                ps.setString(2, like);
            }
            ResultSet rs = ps.executeQuery();
            return rs.next() ? rs.getInt(1) : 0;
        }
    }

    // ── EXPORT LOG (M4) ───────────────────────────────────────────────────────

    /**
     * logExport(exportType, analysis, recordCount)
     *
     * Inserts a new row into the export_log table every time M4 generates a report.
     * Keeps a permanent history of all exports with timestamp.
     *
     * @param exportType   "CSV" or "JSON"
     * @param analysis     Description of what was exported (e.g. "M1-Average")
     * @param recordCount  Number of records included in the export
     * @throws SQLException
     */
    public void logExport(String exportType, String analysis, int recordCount)
            throws SQLException {
        String sql = "INSERT INTO export_log (export_type, analysis, record_count) VALUES (?,?,?)";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, exportType);
            ps.setString(2, analysis);
            ps.setInt   (3, recordCount);
            ps.executeUpdate();
        }
    }

    /**
     * getExportLogs()
     *
     * Retrieves all rows from the export_log table, most recent first.
     * Displayed in M4's export history panel.
     *
     * @return  List of export log entries as String arrays [type, analysis, timestamp, count]
     * @throws SQLException
     */
    public List<String[]> getExportLogs() throws SQLException {
        String sql = "SELECT export_type, analysis, exported_at, record_count FROM export_log ORDER BY exported_at DESC";
        List<String[]> logs = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection();
             Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) {
                logs.add(new String[]{
                    rs.getString("export_type"),
                    rs.getString("analysis"),
                    rs.getString("exported_at"),
                    String.valueOf(rs.getInt("record_count"))
                });
            }
        }
        return logs;
    }

    // ── IMPORT LOG (M3) ───────────────────────────────────────────────────────

    /**
     * logImport(filename, total, imported, skipped)
     *
     * Records the outcome of a CSV import operation.
     * Lets the user review past imports in the M3 management panel.
     *
     * @param filename     Original file name uploaded by user
     * @param total        Total rows read from CSV
     * @param imported     Rows successfully saved to DB
     * @param skipped      Rows skipped due to validation errors
     * @throws SQLException
     */
    public void logImport(String filename, int total, int imported, int skipped)
            throws SQLException {
        String sql = "INSERT INTO import_log (filename, total_rows, imported_rows, skipped_rows) VALUES (?,?,?,?)";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, filename);
            ps.setInt   (2, total);
            ps.setInt   (3, imported);
            ps.setInt   (4, skipped);
            ps.executeUpdate();
        }
    }

    // ── PRIVATE HELPERS ───────────────────────────────────────────────────────

    /**
     * executeQuery(sql, params...)
     *
     * Generic helper — runs a parameterized SELECT and returns a List of records.
     * Avoids copy-pasting the same ResultSet loop in every method.
     *
     * @param sql     SQL SELECT statement with ? placeholders
     * @param params  Values to bind to the placeholders (int or String)
     * @return  List of RainfallRecord
     * @throws SQLException
     */
    private List<RainfallRecord> executeQuery(String sql, int... params) throws SQLException {
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) {
                ps.setInt(i + 1, params[i]);
            }
            return mapResultSet(ps.executeQuery());
        }
    }

    /**
     * mapResultSet(rs)
     *
     * Reads each row from a ResultSet and converts it into a RainfallRecord object.
     * All DAO SELECT methods use this to avoid duplicating column-mapping code.
     *
     * @param rs  An open ResultSet from a SELECT query
     * @return    List of populated RainfallRecord objects
     * @throws SQLException
     */
    private List<RainfallRecord> mapResultSet(ResultSet rs) throws SQLException {
        List<RainfallRecord> list = new ArrayList<>();
        while (rs.next()) {
            RainfallRecord r = new RainfallRecord();
            r.setId         (rs.getInt   ("id"));
            r.setRecordDate (rs.getString("record_date"));
            r.setAdmLevel   (rs.getInt   ("adm_level"));
            r.setAdmId      (rs.getInt   ("adm_id"));
            r.setPcode      (rs.getString("pcode"));
            r.setNPixels    (rs.getInt   ("n_pixels"));
            r.setRfh        (rs.getDouble("rfh"));
            r.setRfhAvg     (rs.getDouble("rfh_avg"));
            r.setR1h        (rs.getDouble("r1h"));
            r.setR1hAvg     (rs.getDouble("r1h_avg"));
            r.setR3h        (rs.getDouble("r3h"));
            r.setR3hAvg     (rs.getDouble("r3h_avg"));
            r.setRfq        (rs.getDouble("rfq"));
            r.setR1q        (rs.getDouble("r1q"));
            r.setR3q        (rs.getDouble("r3q"));
            r.setVersion    (rs.getString("version"));
            r.setIsActive   (rs.getInt   ("is_active"));
            list.add(r);
        }
        return list;
    }
}
