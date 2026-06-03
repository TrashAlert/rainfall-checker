package com.rainfall.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * DBConnection — Database Connection Utility
 * 
 * Purpose:
 *   Provides a single reusable method to get a MySQL database connection.
 *   All Servlets (M1, M2, M3, M4) call this class to avoid repeating
 *   connection logic in every file.
 *
 * Usage:
 *   Connection conn = DBConnection.getConnection();
 *
 * Configuration:
 *   Change DB_URL, DB_USER, DB_PASS below to match your MySQL setup.
 */
public class DBConnection {

    // ── Database configuration constants ──────────────────────────────────────
    private static final String DB_URL  = "jdbc:mysql://localhost:3306/rainfall_db?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";
private static final String DB_USER = "root";
private static final String DB_PASS = "abc123";

    /**
     * getConnection()
     * 
     * Loads the MySQL JDBC driver and returns an open Connection object.
     * The caller is responsible for closing the connection after use
     * (e.g. inside a try-with-resources block).
     *
     * @return  a live java.sql.Connection to rainfall_db
     * @throws  SQLException if the connection cannot be established
     */
    public static Connection getConnection() throws SQLException {
        try {
            // Load the MySQL JDBC driver class into memory
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new SQLException("MySQL JDBC Driver not found. Check pom.xml dependency.", e);
        }
        // Open and return the connection
        return DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
    }
}
