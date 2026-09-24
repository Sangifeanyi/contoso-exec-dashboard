/* =========================================================
   02_indexes.sql — Performance indexing
   =========================================================
   Rationale (this is the piece worth screenshotting for your
   case study — a query plan before/after comparison):

   FactSales will be queried almost exclusively by:
     - date range (dashboards default to "last 12 months")
     - store/region (drill-down page)
     - product/category (drill-down page)

   Without indexes, SQL Server does a full clustered index
   scan on FactSales for every one of these filters once the
   table is in the millions-of-rows range. The composite
   indexes below let the optimizer seek instead of scan.
   ========================================================= */

USE ContosoExecBI;
GO

-- Covers "revenue by date range" queries (most common exec-page query)
CREATE NONCLUSTERED INDEX IX_FactSales_OrderDate
    ON dbo.FactSales (OrderDateKey)
    INCLUDE (SalesAmount, CostAmount, StoreKey, ProductKey);
GO

-- Covers store/region drill-down + same-store growth calc
CREATE NONCLUSTERED INDEX IX_FactSales_Store_Date
    ON dbo.FactSales (StoreKey, OrderDateKey)
    INCLUDE (SalesAmount, CostAmount);
GO

-- Covers product/category drill-down
CREATE NONCLUSTERED INDEX IX_FactSales_Product_Date
    ON dbo.FactSales (ProductKey, OrderDateKey)
    INCLUDE (SalesAmount, CostAmount);
GO

/* To document the before/after for your case study:
   1. Run this query and capture the actual execution plan (Ctrl+M in SSMS)
      BEFORE creating the indexes above.
   2. Re-run it AFTER. Screenshot both — look for the change from
      "Clustered Index Scan" to "Index Seek".

   SELECT s.Region, SUM(f.SalesAmount) AS Revenue
   FROM dbo.FactSales f
   JOIN dbo.DimStore s ON f.StoreKey = s.StoreKey
   JOIN dbo.DimDate d ON f.OrderDateKey = d.DateKey
   WHERE d.Year = 2025
   GROUP BY s.Region;
*/
