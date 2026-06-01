package com.rainfall.model;

/**
 * RainfallRecord — Data Model (Plain Java Object)
 *
 * Purpose:
 *   Represents one row from the rainfall_data table.
 *   Used to carry data between the DAO layer (database) and
 *   the Servlet layer (HTTP response / JSP display).
 *
 * Fields match the columns in the rainfall_data table.
 */
public class RainfallRecord {

    private int    id;
    private String recordDate;   // Date string from CSV (e.g. "1/1/22")
    private int    admLevel;     // Administrative level
    private int    admId;        // Administrative area numeric ID
    private String pcode;        // Province/State code (e.g. "MY01")
    private int    nPixels;      // Number of satellite pixels in the area
    private double rfh;          // Rainfall height in mm — KEY analysis field
    private double rfhAvg;       // Long-term average rainfall height
    private double r1h;          // 1-month accumulated rainfall
    private double r1hAvg;       // 1-month average
    private double r3h;          // 3-month accumulated rainfall
    private double r3hAvg;       // 3-month average
    private double rfq;          // Rainfall anomaly quantile
    private double r1q;          // 1-month quantile
    private double r3q;          // 3-month quantile
    private String version;      // Dataset version tag (e.g. "final")
    private int    isActive;     // Soft-delete flag: 1 = active, 0 = deleted

    // ── Constructors ──────────────────────────────────────────────────────────

    /** Default constructor (required for frameworks and DAO) */
    public RainfallRecord() {}

    // ── Getters & Setters ─────────────────────────────────────────────────────

    public int    getId()          { return id; }
    public void   setId(int id)    { this.id = id; }

    public String getRecordDate()              { return recordDate; }
    public void   setRecordDate(String d)      { this.recordDate = d; }

    public int    getAdmLevel()                { return admLevel; }
    public void   setAdmLevel(int a)           { this.admLevel = a; }

    public int    getAdmId()                   { return admId; }
    public void   setAdmId(int a)              { this.admId = a; }

    public String getPcode()                   { return pcode; }
    public void   setPcode(String p)           { this.pcode = p; }

    public int    getNPixels()                 { return nPixels; }
    public void   setNPixels(int n)            { this.nPixels = n; }

    public double getRfh()                     { return rfh; }
    public void   setRfh(double r)             { this.rfh = r; }

    public double getRfhAvg()                  { return rfhAvg; }
    public void   setRfhAvg(double r)          { this.rfhAvg = r; }

    public double getR1h()                     { return r1h; }
    public void   setR1h(double r)             { this.r1h = r; }

    public double getR1hAvg()                  { return r1hAvg; }
    public void   setR1hAvg(double r)          { this.r1hAvg = r; }

    public double getR3h()                     { return r3h; }
    public void   setR3h(double r)             { this.r3h = r; }

    public double getR3hAvg()                  { return r3hAvg; }
    public void   setR3hAvg(double r)          { this.r3hAvg = r; }

    public double getRfq()                     { return rfq; }
    public void   setRfq(double r)             { this.rfq = r; }

    public double getR1q()                     { return r1q; }
    public void   setR1q(double r)             { this.r1q = r; }

    public double getR3q()                     { return r3q; }
    public void   setR3q(double r)             { this.r3q = r; }

    public String getVersion()                 { return version; }
    public void   setVersion(String v)         { this.version = v; }

    public int    getIsActive()                { return isActive; }
    public void   setIsActive(int a)           { this.isActive = a; }

    /**
     * toString()
     * Returns a simple string representation useful for debugging.
     */
    @Override
    public String toString() {
        return "RainfallRecord{id=" + id + ", date=" + recordDate +
               ", pcode=" + pcode + ", rfh=" + rfh + ", isActive=" + isActive + "}";
    }
}
