/* =========================================================
   07_generate_synthetic_budget.sql
   =========================================================
   FactBudget has no real Contoso source data, so this
   generates plausible budget figures: each product/store/
   month's budget = that same period's actual revenue plus a
   flat growth assumption (i.e. "what the budget target
   should have been, given a 5% growth goal").

   IMPORTANT: This is illustrative data for demo purposes,
   not a real forecasting model. Say so plainly in your case
   study — "budget figures are synthetic, generated as actuals
   + assumed growth" is a normal, honest caveat for a
   portfolio piece and doesn't undercut the technical work
   (the DAX variance measures work identically against real
   budget data).
   ========================================================= */

USE ContosoExecBI;
GO

-- Clear any previous run
TRUNCATE TABLE dbo.FactBudget;
GO

DECLARE @GrowthAssumption DECIMAL(5,4) = 0.05;  -- 5% assumed YoY growth target

INSERT INTO dbo.FactBudget (MonthDateKey, ProductKey, StoreKey, BudgetAmount)
SELECT
    -- First-of-month key for the SAME period as the actuals (avoids any risk of
    -- the key falling outside DimDate's populated range)
    d.Year * 10000 + d.MonthNumber * 100 + 1                     AS MonthDateKey,
    f.ProductKey,
    f.StoreKey,
    SUM(f.SalesAmount) * (1 + @GrowthAssumption) AS BudgetAmount
FROM dbo.FactSales f
JOIN dbo.DimDate d ON f.OrderDateKey = d.DateKey
GROUP BY d.Year, d.MonthNumber, f.ProductKey, f.StoreKey;
GO

PRINT 'Synthetic budget data generated.';
SELECT COUNT(*) AS TotalBudgetRows FROM dbo.FactBudget;
