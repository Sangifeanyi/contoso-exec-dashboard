# Executive Revenue Intelligence Dashboard

*A flagship BI build: SQL Server data warehouse → Power BI executive reporting suite*

## Problem

Mid-market retail and multi-region businesses often track revenue across scattered spreadsheets and disconnected reports — one for sales, another for budget, another for store performance. Executives lose time reconciling numbers instead of making decisions, and "same-store" performance gets muddied by new store openings inflating or masking true growth.

## Approach

- Designed and built a SQL Server star schema (5 dimensions, 2 fact tables) from a 12.6-million-row retail dataset, with a documented indexing strategy for query performance at scale
- Wrote stored procedures for YoY revenue variance and same-store growth — logic that's auditable at the database layer, not buried in DAX
- Built a 3-page Power BI report: an Exec Summary (single-screen KPIs), a Region/Product drill-down with interactive slicers, and a Budget vs. Actual forecast page
- Used DAX time intelligence (rolling 12-month trends, YoY%, same-store growth) with conditional formatting so variances are visible at a glance without reading every number
- Batched the fact table load (500K rows per transaction) to work within production-realistic hardware constraints — a real-world engineering tradeoff, not just a demo shortcut

## Result

**Scale:** 12,627,608 fact rows loaded across 306 stores, 2,517 products, and 8 product categories, spanning 2007–2009.

**What the numbers showed:**
- Total revenue across the full period: **$2.71B**
- 2008 revenue: **$848.7M**, down **15.96% year-over-year** from 2007's $1.01B
- Same-store growth for 2008: **-15.96%** — confirming the decline was real, not an artifact of store closures or openings skewing the headline number
- Actuals landed **4.76% below** budget target for the period, with Home Appliances and Cameras/Camcorders as the largest revenue categories

**Technical outcomes:**
- A single source of truth replacing manual spreadsheet reconciliation, with Region and Product Category slicers letting stakeholders self-serve drill-downs instead of requesting new reports
- Same-store growth calculated correctly at the DAX layer, so a future store rollout won't silently distort the growth trend line
- Query performance validated with before/after execution plans (index seek vs. table scan) on the core fact table
- Fully documented data model, DAX reference, and load scripts (including recovery from a mid-load disk space failure via a resumable batched load) — so the solution is maintainable by another developer, not just its original builder

*Note: budget figures are synthetic (generated as actuals + a 5% assumed growth target), since this build uses a public demo dataset rather than a live client's own budget data. The variance methodology and DAX measures work identically against real budget figures.*

Full source (schema, stored procedures, load scripts, DAX reference) is on GitHub — link in the project listing.
