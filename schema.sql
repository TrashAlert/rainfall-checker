-- ============================================================
-- Database Schema for Malaysia Rainfall Analysis Application
-- Course: BITS 3515 TCP/IP Programming
-- Description: Creates all tables needed for the web app
-- ============================================================

CREATE DATABASE IF NOT EXISTS rainfall_db;
USE rainfall_db;

-- ============================================================
-- MAIN TABLE: rainfall_data
-- Stores each imported row from the CSV dataset.
-- is_active = 1 means the record is included in analysis.
-- is_active = 0 means it has been soft-deleted (excluded).
-- ============================================================
CREATE TABLE IF NOT EXISTS rainfall_data (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    record_date VARCHAR(20)    NOT NULL,          -- Date from CSV (e.g. "1/1/22")
    adm_level   INT,                               -- Administrative level
    adm_id      INT,                               -- Administrative area ID
    pcode       VARCHAR(10),                       -- Province/State code (e.g. MY01)
    n_pixels    INT,                               -- Number of pixels in area
    rfh         DOUBLE,                            -- Rainfall height (mm) — main analysis field
    rfh_avg     DOUBLE,                            -- Average rainfall height
    r1h         DOUBLE,                            -- 1-month rainfall
    r1h_avg     DOUBLE,                            -- 1-month average
    r3h         DOUBLE,                            -- 3-month rainfall
    r3h_avg     DOUBLE,                            -- 3-month average
    rfq         DOUBLE,                            -- Rainfall quantile
    r1q         DOUBLE,                            -- 1-month quantile
    r3q         DOUBLE,                            -- 3-month quantile
    version     VARCHAR(20),                       -- Dataset version (e.g. "final")
    is_active   TINYINT(1) DEFAULT 1,              -- Soft-delete flag: 1=active, 0=deleted
    imported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- When this record was imported
);

-- ============================================================
-- EXPORT LOG TABLE: export_log
-- M4: Tracks every report that was exported (CSV or JSON).
-- ============================================================
CREATE TABLE IF NOT EXISTS export_log (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    export_type  VARCHAR(10) NOT NULL,             -- "CSV" or "JSON"
    analysis     VARCHAR(50),                      -- Which analysis was exported (M1/M2)
    exported_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    record_count INT                               -- How many records were in the export
);

-- ============================================================
-- IMPORT LOG TABLE: import_log
-- M3: Tracks each CSV file import attempt.
-- ============================================================
CREATE TABLE IF NOT EXISTS import_log (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    filename     VARCHAR(255),                     -- Uploaded file name
    total_rows   INT,                              -- Total rows in CSV
    imported_rows INT,                             -- Successfully imported rows
    skipped_rows INT,                              -- Rows skipped due to validation errors
    imported_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
