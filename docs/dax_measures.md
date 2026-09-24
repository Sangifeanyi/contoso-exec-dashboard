# DAX Measures Reference

Model relationships (all single-direction, star schema — no snowflaking):

- `FactSales[OrderDateKey]` → `DimDate[DateKey]`
- `FactSales[ProductKey]` → `DimProduct[ProductKey]`
- `FactSales[StoreKey]` → `DimStore[StoreKey]`
- `FactSales[PromotionKey]` → `DimPromotion[PromotionKey]`
- `FactBudget[MonthDateKey]` → `DimDate[DateKey]`

`DimDate` is marked as the model's Date Table (Modeling → Mark as Date Table) using `DimDate[FullDate]`, which is required for time-intelligence functions to work.

## Core measures

```dax
Revenue = SUM(FactSales[SalesAmount])

Cost = SUM(FactSales[CostAmount])

Gross Margin = [Revenue] - [Cost]

Gross Margin % =
DIVIDE([Gross Margin], [Revenue])
```

## Time intelligence

```dax
Revenue PY =
CALCULATE([Revenue], SAMEPERIODLASTYEAR(DimDate[FullDate]))

Revenue YoY % =
DIVIDE([Revenue] - [Revenue PY], [Revenue PY])

Revenue Rolling 12M =
CALCULATE(
    [Revenue],
    DATESINPERIOD(DimDate[FullDate], MAX(DimDate[FullDate]), -12, MONTH)
)
```

## Budget variance

```dax
Budget = SUM(FactBudget[BudgetAmount])

Budget Variance = [Revenue] - [Budget]

Budget Variance % = DIVIDE([Revenue] - [Budget], [Budget])
```

## Same-store growth

Requires a helper column on `DimStore`:

```dax
-- Calculated column on DimStore
Store Open 12M+ =
DimStore[OpenDate] <= EDATE(TODAY(), -12)
```

```dax
Same-Store Revenue =
CALCULATE([Revenue], DimStore[Store Open 12M+] = TRUE)

Same-Store Revenue PY =
CALCULATE([Revenue PY], DimStore[Store Open 12M+] = TRUE)

Same-Store Growth % =
DIVIDE([Same-Store Revenue] - [Same-Store Revenue PY], [Same-Store Revenue PY])
```

## Dynamic Top/Bottom N (for the drill-down page)

```dax
Product Rank =
RANKX(ALLSELECTED(DimProduct[ProductName]), [Revenue], , DESC)

Top N Revenue =
VAR N = 5
RETURN
IF([Product Rank] <= N, [Revenue], BLANK())
```

## Formatting notes for exec-facing visuals

- All `%` measures use `DIVIDE()`, never `/`, to avoid divide-by-zero errors blanking out a KPI card mid-presentation.
- Currency measures use the model-level format string `$#,##0,,"M"` on the Exec Summary page so large numbers read as "$4.2M" instead of "$4,200,000" — executives scan faster with fewer digits.
- Conditional formatting on variance measures: green ≥ 0%, red < 0%, applied via the built-in rules engine (not a calculated column) so it stays dynamic with filters.
