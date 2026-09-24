/* =========================================================
   06_resume_load.sql
   =========================================================
   Resumes the batched FactSales load after an interruption.
   2,500,000 rows already loaded successfully (SalesKey
   19560484 through 22060483). This picks up from there.

   Before running: make sure you've freed up disk space or
   given the data file room to grow (see accompanying advice).
   ========================================================= */

USE ContosoExecBI;
GO

DECLARE @BatchSize INT = 500000;
DECLARE @MaxKey BIGINT, @CurrentStart BIGINT, @RunningTotal BIGINT;

-- Resume point: change this if you stopped at a different batch
SET @CurrentStart = 22060484;

SELECT @MaxKey = MAX(OnlineSalesKey) FROM ContosoRetailDW.dbo.FactOnlineSales;

WHILE @CurrentStart <= @MaxKey
BEGIN
    INSERT INTO dbo.FactSales (OrderDateKey, ProductKey, StoreKey, PromotionKey, CurrencyKey,
                               Quantity, UnitPrice, UnitCost, DiscountAmount)
    SELECT
        CONVERT(INT, CONVERT(VARCHAR(8), f.DateKey, 112)) AS OrderDateKey,
        f.ProductKey,
        f.StoreKey,
        f.PromotionKey,
        f.CurrencyKey,
        f.SalesQuantity  AS Quantity,
        f.UnitPrice,
        f.UnitCost,
        f.DiscountAmount
    FROM ContosoRetailDW.dbo.FactOnlineSales f
    WHERE f.OnlineSalesKey >= @CurrentStart
      AND f.OnlineSalesKey < @CurrentStart + @BatchSize
      AND f.StoreKey IN (SELECT StoreKey FROM dbo.DimStore)
      AND f.ProductKey IN (SELECT ProductKey FROM dbo.DimProduct);

    CHECKPOINT;

    SELECT @RunningTotal = COUNT(*) FROM dbo.FactSales;
    PRINT 'Loaded batch starting at ' + CAST(@CurrentStart AS VARCHAR(20))
        + ' — running total: ' + CAST(@RunningTotal AS VARCHAR(20));

    SET @CurrentStart = @CurrentStart + @BatchSize;
END

PRINT 'Fact load complete.';
SELECT COUNT(*) AS TotalFactSalesRows FROM dbo.FactSales;
