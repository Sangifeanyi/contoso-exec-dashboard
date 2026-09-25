# Executive Revenue Intelligence Dashboard

A full-stack BI portfolio project: SQL Server data warehouse design → Power BI executive reporting suite, built on Microsoft's Contoso retail sample dataset.

&#x20;!\[Exec Summary](docs/screenshots/exec-summary.png)

&#x20;!\[Drill-down Page](docs/screenshots/drill-down.png)

&#x20;!\[Drill-down Page](docs/screenshots/forecast.png)

## Stack

* **SQL Server** — star schema design, indexing, stored procedures
* **Power BI** — data model, DAX time intelligence, 3-page executive report

## Project structure

```
contoso-exec-dashboard/
├── sql/
│   ├── 01\_schema.sql              # Star schema DDL
│   ├── 02\_indexes.sql             # Indexing strategy + before/after query notes
│   └── 03\_stored\_procedures.sql   # YoY revenue \& same-store growth procs
├── docs/
│   ├── data\_model.md              # ER diagram + ETL notes
│   ├── dax\_measures.md            # Full DAX measure reference
│   └── case\_study.md              # Problem / Approach / Result write-up
└── pbix/
    └── (add your .pbix file here once built)
```

## Setup

1. Download the [Contoso Retail DW sample](https://www.microsoft.com/en-us/download/details.aspx?id=18279)
2. Run `sql/01\_schema.sql` to create the database and star schema
3. Load the Contoso data into the schema (see `docs/data\_model.md` for ETL notes)
4. Run `sql/02\_indexes.sql` and `sql/03\_stored\_procedures.sql`
5. Open Power BI Desktop → Get Data → SQL Server → connect to `ContosoExecBI`
6. Import the DAX measures from `docs/dax\_measures.md`
7. Build the 3 report pages (Exec Summary, Drill-down, Forecast) — see `docs/case\_study.md` for the narrative framing

## Author

Ifeanyi Asangwor — Power BI \& SQL Server Consultant
[Contra](https://contra.com/ifeanyi_asangwor_upz2uzt7)

