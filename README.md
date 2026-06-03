# Malaysia Rainfall Analysis — BITS 3515 Mini Project 2

## Project Overview
A Java web application for analysing Malaysia sub-national rainfall data.  
Dataset column used for analysis: **rfh** (rainfall height in mm).

---

## Project Structure

```
rainfall-app/
├── pom.xml                          ← Maven build config + dependencies
├── schema.sql                       ← MySQL database setup script
└── src/main/
    ├── java/com/rainfall/
    │   ├── util/
    │   │   └── DBConnection.java     ← MySQL connection helper
    │   ├── model/
    │   │   └── RainfallRecord.java   ← Data model (one CSV row)
    │   ├── dao/
    │   │   └── RainfallDAO.java      ← All DB queries (INSERT/SELECT/UPDATE)
    │   └── servlet/
    │       ├── ImportServlet.java    ← M3: CSV upload & parse
    │       ├── DatasetServlet.java   ← M3: Browse, soft-delete, reinstate
    │       ├── EditServlet.java      ← M3: Edit record
    │       ├── AnalysisM1Servlet.java ← M1: Average rfh (batch + SSE)
    │       ├── AnalysisM2Servlet.java ← M2: Threshold violations (batch + SSE)
    │       └── ExportServlet.java    ← M4: CSV/JSON report download
    └── webapp/
        ├── index.jsp                 ← Home page
        ├── css/style.css             ← Global stylesheet
        ├── WEB-INF/web.xml           ← Servlet config + error pages
        └── pages/
            ├── dataset_home.jsp      ← M3: Upload form
            ├── dataset.jsp           ← M3: Record browser table
            ├── edit.jsp              ← M3: Edit record form
            ├── analysis.jsp          ← M1 + M2: Analysis control panel
            ├── export.jsp            ← M4: Export panel + history log
            └── error.jsp             ← Custom 400/404/500 error page
```

---

## Setup Instructions

### Step 1 — Prerequisites
- Java JDK 11+
- Apache Maven 3.6+
- Apache Tomcat 9.x
- MySQL 8.x

### Step 2 — Database Setup
Open MySQL and import `schema.sql` into the database

This creates the `rainfall_db` database and all 3 tables:
- `rainfall_data` — main dataset table (with `is_active` flag)
- `import_log`    — tracks CSV import history
- `export_log`    — tracks M4 export history

### Step 3 — Build the WAR file
```bash
cd rainfall-app
mvn clean package
```
The file `target/rainfall-app.war` will be created

### Step 4 — Deploy to Tomcat
Copy the WAR to Tomcat's webapps folder:
```bash
cp target/rainfall-app.war /path/to/tomcat/webapps/
```
Start Tomcat. 
```bash
(tomcat location)/bin/startup.sh
```

Access at: `http://<YOUR_IP>:8080/rainfall-app/`

Stop Tomcat.
```bash
(tomcat location)/bin/shutdown.sh
```

---

## Module Summary

| Module | Servlet | URL | Description |
|--------|---------|-----|-------------|
| M3 | ImportServlet | POST /import | Upload & parse CSV |
| M3 | DatasetServlet | GET+POST /dataset | Browse, soft-delete, reinstate |
| M3 | EditServlet | GET+POST /edit | Correct record values |
| M1 | AnalysisM1Servlet | GET /analysis/m1 | Average rfh — batch & SSE |
| M2 | AnalysisM2Servlet | GET /analysis/m2 | Violations count — batch & SSE |
| M4 | ExportServlet | GET /export | Download CSV/JSON reports |

---

## Analysis Details

### M1 — Average Rainfall Intensity
- **Attribute**: `rfh` (rainfall height mm)
- **Batch**: `SELECT AVG(rfh) FROM rainfall_data WHERE is_active = 1`
- **Real-Time**: SSE stream, sends running average after each record

### M2 — Threshold Violation Detection
- **Attribute**: `rfh > 100mm` (very heavy rain)
- **Batch**: `SELECT COUNT(*) FROM rainfall_data WHERE is_active=1 AND rfh > 100`
- **Real-Time**: SSE stream, highlights each violating record live

### Soft-Delete Demo (for presentation)
1. Go to M3 Dataset Browser
2. Click **Delete** on any record → `is_active` set to 0
3. Run M1 or M2 Batch → count/average changes
4. Click **Restore** → record re-included in next analysis

---

## Error Handling

| Error | Code | Trigger Example |
|-------|------|----------------|
| Bad Request | 400 | Missing `mode` param in /analysis/m1 |
| Not Found | 404 | Edit a record ID that doesn't exist |
| Server Error | 500 | MySQL not running |

All errors show `error.jsp` — no raw stack traces visible to user.
# rainfall-checker
