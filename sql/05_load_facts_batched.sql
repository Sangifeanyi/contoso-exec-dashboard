/* =========================================================
   05_load_facts_batched.sql
   =========================================================
   Replaces step 6 of 04_load_data.sql. Loads FactSales in
   chunks instead of one 12-million-row transaction, so the
   transaction log never has to hold more than one batch's
   worth of changes at a time.

   Run this INSTEAD of the FactSales insert in 04_load_data.sql
   (i.e. if 04_load_data.sql already failed partway through,
   just run this script — the dimension tables it needs are
   already loaded).
   ========================================================= */

USE ContosoExecBI;
GO

-- Recommended before running: reduces log pressure further
ALTER DATABASE ContosoExecBI SET RECOVERY SIMPLE;
GO

DECLARE @BatchSize INT = 500000;
DECLARE @MinKey BIGINT, @MaxKey BIGINT, @CurrentStart BIGINT, @RunningTotal BIGINT;

SELECT @MinKey = MIN(OnlineSalesKey), @MaxKey = MAX(OnlineSalesKey)
FROM ContosoRetailDW.dbo.FactOnlineSales;

SET @CurrentStart = @MinKey;

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

    -- Forces the log to actually be reused between batches (SIMPLE recovery model)
    CHECKPOINT;

    SELECT @RunningTotal = COUNT(*) FROM dbo.FactSales;
    PRINT 'Loaded batch starting at SalesKey ' + CAST(@CurrentStart AS VARCHAR(20))
        + ' — running total: ' + CAST(@RunningTotal AS VARCHAR(20));

    SET @CurrentStart = @CurrentStart + @BatchSize;
END

PRINT 'Fact load complete.';
SELECT COUNT(*) AS TotalFactSalesRows FROM dbo.FactSales;
