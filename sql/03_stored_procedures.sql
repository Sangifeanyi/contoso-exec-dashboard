/* =========================================================
   03_stored_procedures.sql
   =========================================================
   These pre-aggregate at the SQL layer rather than leaving
   all the work to DAX. Note: for the main Power BI model,
   import the tables directly (not via these procs) so Power
   BI can use query folding. Use these procs for:
     - a documented "here's how I think about performance"
       artifact in your case study
     - any ad-hoc reporting outside Power BI (e.g. a scheduled
       email export)
   ========================================================= */

USE ContosoExecBI;
GO

-- ---------------------------------------------------------
-- sp_YoY_RevenueByRegion
-- Returns current vs prior year revenue and variance % by region
-- ---------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_YoY_RevenueByRegion
    @CurrentYear INT
AS
BEGIN
    SET NOCOUNT ON;

    WITH Yearly AS (
        SELECT
            s.Region,
            d.Year,
            SUM(f.SalesAmount) AS Revenue
        FROM dbo.FactSales f
        JOIN dbo.DimStore s ON f.StoreKey = s.StoreKey
        JOIN dbo.DimDate d  ON f.OrderDateKey = d.DateKey
        WHERE d.Year IN (@CurrentYear, @CurrentYear - 1)
        GROUP BY s.Region, d.Year
    )
    SELECT
        cur.Region,
        cur.Revenue        AS CurrentYearRevenue,
        prev.Revenue       AS PriorYearRevenue,
        cur.Revenue - prev.Revenue AS RevenueChange,
        CASE WHEN prev.Revenue = 0 THEN NULL
             ELSE ROUND((cur.Revenue - prev.Revenue) * 100.0 / prev.Revenue, 1)
        END AS PctChange
    FROM Yearly cur
    LEFT JOIN Yearly prev
        ON cur.Region = prev.Region AND prev.Year = cur.Year - 1
    WHERE cur.Year = @CurrentYear
    ORDER BY cur.Revenue DESC;
END
GO

-- ---------------------------------------------------------
-- sp_SameStoreGrowth
-- Compares revenue for stores open > 12 months as of @AsOfDate,
-- avoiding the classic BI mistake of letting new-store openings
-- inflate apparent growth.
-- ---------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_SameStoreGrowth
    @AsOfDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CutoffDate DATE = DATEADD(MONTH, -12, @AsOfDate);
    DECLARE @PriorAsOf  DATE = DATEADD(YEAR, -1, @AsOfDate);

    WITH EligibleStores AS (
        SELECT s.StoreKey, s.StoreName, s.Region
        FROM dbo.DimStore s
        JOIN dbo.DimDate d ON s.OpenDateKey = d.DateKey
        WHERE d.FullDate <= @CutoffDate
    ),
    CurrentPeriod AS (
        SELECT f.StoreKey, SUM(f.SalesAmount) AS Revenue
        FROM dbo.FactSales f
        JOIN dbo.DimDate d ON f.OrderDateKey = d.DateKey
        WHERE d.FullDate BETWEEN DATEADD(MONTH, -12, @AsOfDate) AND @AsOfDate
        GROUP BY f.StoreKey
    ),
    PriorPeriod AS (
        SELECT f.StoreKey, SUM(f.SalesAmount) AS Revenue
        FROM dbo.FactSales f
        JOIN dbo.DimDate d ON f.OrderDateKey = d.DateKey
        WHERE d.FullDate BETWEEN DATEADD(MONTH, -12, @PriorAsOf) AND @PriorAsOf
        GROUP BY f.StoreKey
    )
    SELECT
        es.StoreName,
        es.Region,
        cp.Revenue AS CurrentPeriodRevenue,
        pp.Revenue AS PriorPeriodRevenue,
        CASE WHEN pp.Revenue IS NULL OR pp.Revenue = 0 THEN NULL
             ELSE ROUND((cp.Revenue - pp.Revenue) * 100.0 / pp.Revenue, 1)
        END AS SameStoreGrowthPct
    FROM EligibleStores es
    LEFT JOIN CurrentPeriod cp ON es.StoreKey = cp.StoreKey
    LEFT JOIN PriorPeriod pp   ON es.StoreKey = pp.StoreKey
    ORDER BY SameStoreGrowthPct DESC;
END
GO

PRINT 'Stored procedures created successfully.';
