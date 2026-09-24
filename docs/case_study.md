# Executive Revenue Intelligence Dashboard

*A flagship BI build: SQL Server data warehouse → Power BI executive reporting suite*

## Problem

Mid-market retail and multi-region businesses often track revenue across scattered spreadsheets and disconnected reports — one for sales, another for budget, another for store performance. Executives lose time reconciling numbers instead of making decisions, and "same-store" performance gets muddied by new store openings inflating growth numbers.

## Approach

- Designed and built a SQL Server star schema (fact + dimension tables) from the Contoso retail dataset, with a documented indexing strategy for query performance at scale
- Wrote stored procedures for YoY revenue variance and same-store growth — logic that's auditable at the database layer, not buried in DAX
- Built a 3-page Power BI report: an Exec Summary (single-screen KPIs), a Region/Product drill-down, and a Budget vs. Actual forecast page
- Used DAX time intelligence (rolling 12-month trends, YoY%, same-store growth) with conditional formatting so variances are visible at a glance without reading every number

## Result

- A single source of truth replacing manual spreadsheet reconciliation
- Same-store growth calculated correctly — new store openings no longer distort the headline growth number
- Query performance validated with before/after execution plans (index seek vs. table scan) on the core fact table
- Fully documented data model and DAX reference, so the solution is maintainable by another developer, not just its original builder

*[Add your own screenshots and Loom walkthrough link here once the report is built.]*
