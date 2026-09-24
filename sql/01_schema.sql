/* =========================================================
   Executive Revenue Intelligence Dashboard
   01_schema.sql — Star schema DDL (SQL Server)
   =========================================================
   Grain: FactSales is one row per order line.
   Source: Contoso Retail DW sample dataset (Microsoft),
   reshaped into a clean star schema for reporting.
   ========================================================= */

IF DB_ID('ContosoExecBI') IS NULL
BEGIN
    CREATE DATABASE ContosoExecBI;
END
GO

USE ContosoExecBI;
GO

/* ---------- Dimension: Date ---------- */
CREATE TABLE dbo.DimDate (
    DateKey         INT         NOT NULL PRIMARY KEY,   -- yyyymmdd
    FullDate        DATE        NOT NULL,
    DayOfWeek       TINYINT     NOT NULL,
    DayName         VARCHAR(10) NOT NULL,
    MonthNumber     TINYINT     NOT NULL,
    MonthName       VARCHAR(10) NOT NULL,
    Quarter         TINYINT     NOT NULL,
    Year            SMALLINT    NOT NULL,
    FiscalQuarter   TINYINT     NOT NULL,               -- FY starts July 1 (adjust as needed)
    FiscalYear      SMALLINT    NOT NULL,
    IsWeekend       BIT         NOT NULL
);

/* ---------- Dimension: Product ---------- */
CREATE TABLE dbo.DimProduct (
    ProductKey      INT             NOT NULL PRIMARY KEY,
    ProductName     NVARCHAR(200)   NOT NULL,
    SubcategoryName NVARCHAR(100)   NOT NULL,
    CategoryName    NVARCHAR(100)   NOT NULL,
    UnitCost        DECIMAL(18,2)   NOT NULL,
    UnitPrice       DECIMAL(18,2)   NOT NULL
);

/* ---------- Dimension: Store ---------- */
CREATE TABLE dbo.DimStore (
    StoreKey        INT             NOT NULL PRIMARY KEY,
    StoreName       NVARCHAR(200)   NOT NULL,
    District        NVARCHAR(100)   NULL,
    Region          NVARCHAR(100)   NOT NULL,
    Country         NVARCHAR(100)   NOT NULL,
    OpenDateKey     INT             NOT NULL,           -- FK to DimDate, used for same-store logic
    StoreType       NVARCHAR(50)    NULL
);

/* ---------- Dimension: Promotion ---------- */
CREATE TABLE dbo.DimPromotion (
    PromotionKey    INT             NOT NULL PRIMARY KEY,
    PromotionName   NVARCHAR(200)   NOT NULL,
    DiscountPct     DECIMAL(5,2)    NOT NULL DEFAULT 0,
    StartDateKey    INT             NULL,
    EndDateKey      INT             NULL
);

/* ---------- Dimension: Currency ---------- */
CREATE TABLE dbo.DimCurrency (
    CurrencyKey     INT             NOT NULL PRIMARY KEY,
    CurrencyCode    CHAR(3)         NOT NULL,
    CurrencyName    NVARCHAR(50)    NOT NULL
);

/* ---------- Fact: Sales (grain = order line) ---------- */
CREATE TABLE dbo.FactSales (
    SalesKey        BIGINT          IDENTITY(1,1) PRIMARY KEY,
    OrderDateKey    INT             NOT NULL REFERENCES dbo.DimDate(DateKey),
    ProductKey      INT             NOT NULL REFERENCES dbo.DimProduct(ProductKey),
    StoreKey        INT             NOT NULL REFERENCES dbo.DimStore(StoreKey),
    PromotionKey    INT             NULL     REFERENCES dbo.DimPromotion(PromotionKey),
    CurrencyKey     INT             NOT NULL REFERENCES dbo.DimCurrency(CurrencyKey),
    Quantity        INT             NOT NULL,
    UnitPrice       DECIMAL(18,2)   NOT NULL,
    UnitCost        DECIMAL(18,2)   NOT NULL,
    DiscountAmount  DECIMAL(18,2)   NOT NULL DEFAULT 0,
    SalesAmount     AS (Quantity * UnitPrice - DiscountAmount) PERSISTED,
    CostAmount      AS (Quantity * UnitCost) PERSISTED
);

/* ---------- Fact: Budget (for the What-if / Forecast page) ---------- */
CREATE TABLE dbo.FactBudget (
    BudgetKey       BIGINT          IDENTITY(1,1) PRIMARY KEY,
    MonthDateKey    INT             NOT NULL REFERENCES dbo.DimDate(DateKey), -- use first-of-month keys
    ProductKey      INT             NOT NULL REFERENCES dbo.DimProduct(ProductKey),
    StoreKey        INT             NOT NULL REFERENCES dbo.DimStore(StoreKey),
    BudgetAmount    DECIMAL(18,2)   NOT NULL
);
GO

PRINT 'Schema created successfully.';
