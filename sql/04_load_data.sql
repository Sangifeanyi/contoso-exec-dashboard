/* =========================================================
   04_load_data.sql
   =========================================================
   Loads ContosoExecBI (your clean star schema) from
   ContosoRetailDW (the raw Contoso sample), which must
   already be restored on the same SQL Server instance.

   Run 01_schema.sql first. Run this after.

   NOTE: If your Contoso restore names the fact table
   something other than FactOnlineSales, update the table
   name in the final INSERT below (verify with:
   SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_NAME LIKE '%Sales%';)
   ========================================================= */

USE ContosoExecBI;
GO

/* ---------- 1. DimDate ----------
   Generated directly from Contoso's DimDate.Datekey range
   using SQL Server date functions, rather than relying on
   Contoso's own (inconsistently formatted) fiscal columns.
   Assumes a fiscal year starting July 1 — adjust the
   FiscalQuarter/FiscalYear expressions below if your target
   client's fiscal year differs. */
INSERT INTO dbo.DimDate (DateKey, FullDate, DayOfWeek, DayName, MonthNumber, MonthName,
                         Quarter, Year, FiscalQuarter, FiscalYear, IsWeekend)
SELECT
    CONVERT(INT, CONVERT(VARCHAR(8), d.Datekey, 112))                          AS DateKey,
    CAST(d.Datekey AS DATE)                                                    AS FullDate,
    DATEPART(WEEKDAY, d.Datekey)                                               AS DayOfWeek,
    DATENAME(WEEKDAY, d.Datekey)                                               AS DayName,
    MONTH(d.Datekey)                                                           AS MonthNumber,
    DATENAME(MONTH, d.Datekey)                                                 AS MonthName,
    DATEPART(QUARTER, d.Datekey)                                               AS Quarter,
    YEAR(d.Datekey)                                                            AS Year,
    -- Fiscal year starts July 1: months Jul-Sep = FQ1, Oct-Dec = FQ2, Jan-Mar = FQ3, Apr-Jun = FQ4
    ((MONTH(d.Datekey) + 5) % 12) / 3 + 1                                      AS FiscalQuarter,
    CASE WHEN MONTH(d.Datekey) >= 7 THEN YEAR(d.Datekey) + 1 ELSE YEAR(d.Datekey) END AS FiscalYear,
    CASE WHEN DATEPART(WEEKDAY, d.Datekey) IN (1,7) THEN 1 ELSE 0 END          AS IsWeekend
FROM ContosoRetailDW.dbo.DimDate d;
GO

/* ---------- 2. DimProduct ----------
   Joins DimProduct -> DimProductSubcategory -> DimProductCategory
   to pull real category/subcategory names onto each product. */
INSERT INTO dbo.DimProduct (ProductKey, ProductName, SubcategoryName, CategoryName, UnitCost, UnitPrice)
SELECT
    p.ProductKey,
    p.ProductName,
    sc.ProductSubcategoryName,
    c.ProductCategoryName,
    p.UnitCost,
    p.UnitPrice
FROM ContosoRetailDW.dbo.DimProduct p
JOIN ContosoRetailDW.dbo.DimProductSubcategory sc ON p.ProductSubcategoryKey = sc.ProductSubcategoryKey
JOIN ContosoRetailDW.dbo.DimProductCategory c     ON sc.ProductCategoryKey   = c.ProductCategoryKey;
GO

/* ---------- 3. DimStore ----------
   Joins DimStore -> DimGeography for Region/Country, since
   Contoso doesn't store those directly on DimStore. */
INSERT INTO dbo.DimStore (StoreKey, StoreName, District, Region, Country, OpenDateKey, StoreType)
SELECT
    s.StoreKey,
    s.StoreName,
    g.CityName                                            AS District,
    ISNULL(g.StateProvinceName, g.RegionCountryName)       AS Region,
    g.RegionCountryName                                    AS Country,
    CONVERT(INT, CONVERT(VARCHAR(8), s.OpenDate, 112))      AS OpenDateKey,
    s.StoreType
FROM ContosoRetailDW.dbo.DimStore s
JOIN ContosoRetailDW.dbo.DimGeography g ON s.GeographyKey = g.GeographyKey
WHERE s.OpenDate IS NOT NULL;
GO

/* ---------- 4. DimPromotion ---------- */
INSERT INTO dbo.DimPromotion (PromotionKey, PromotionName, DiscountPct, StartDateKey, EndDateKey)
SELECT
    p.PromotionKey,
    p.PromotionName,
    p.DiscountPercent * 100.0                                          AS DiscountPct,  -- Contoso stores as decimal fraction
    CONVERT(INT, CONVERT(VARCHAR(8), p.StartDate, 112))                AS StartDateKey,
    CONVERT(INT, CONVERT(VARCHAR(8), p.EndDate, 112))                  AS EndDateKey
FROM ContosoRetailDW.dbo.DimPromotion p;
GO

/* ---------- 5. DimCurrency ----------
   Note the column swap: Contoso's "CurrencyName" column
   actually holds the 3-letter code (e.g. USD), and
   "CurrencyDescription" holds the full name (e.g. US Dollar). */
INSERT INTO dbo.DimCurrency (CurrencyKey, CurrencyCode, CurrencyName)
SELECT
    c.CurrencyKey,
    c.CurrencyName          AS CurrencyCode,
    c.CurrencyDescription   AS CurrencyName
FROM ContosoRetailDW.dbo.DimCurrency c;
GO

/* ---------- 6. FactSales ----------
   Loaded last, after all dimensions exist, so the foreign
   keys resolve. */
INSERT INTO dbo.FactSales (OrderDateKey, ProductKey, StoreKey, PromotionKey, CurrencyKey,
                           Quantity, UnitPrice, UnitCost, DiscountAmount)
SELECT
    CONVERT(INT, CONVERT(VARCHAR(8), f.DateKey, 112))  AS OrderDateKey,
    f.ProductKey,
    f.StoreKey,
    f.PromotionKey,  -- PromotionKey 1 = "No Discount" in Contoso, which is a valid row in DimPromotion, not NULL
    f.CurrencyKey,
    f.SalesQuantity                                    AS Quantity,
    f.UnitPrice,
    f.UnitCost,
    f.DiscountAmount
FROM ContosoRetailDW.dbo.FactOnlineSales f
-- Only load rows whose keys exist in the dimensions we just built, to avoid FK errors
WHERE f.StoreKey IN (SELECT StoreKey FROM dbo.DimStore)
  AND f.ProductKey IN (SELECT ProductKey FROM dbo.DimProduct);
GO

PRINT 'Data load complete.';
PRINT 'Row counts:';
SELECT 'DimDate' AS TableName, COUNT(*) AS Rows FROM dbo.DimDate
UNION ALL SELECT 'DimProduct', COUNT(*) FROM dbo.DimProduct
UNION ALL SELECT 'DimStore', COUNT(*) FROM dbo.DimStore
UNION ALL SELECT 'DimPromotion', COUNT(*) FROM dbo.DimPromotion
UNION ALL SELECT 'DimCurrency', COUNT(*) FROM dbo.DimCurrency
UNION ALL SELECT 'FactSales', COUNT(*) FROM dbo.FactSales;
