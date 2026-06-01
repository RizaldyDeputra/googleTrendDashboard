# 🌐 Global Trend Intelligence Dashboard
### Google Trends · Power BI · 5-Year Analysis · 42 Countries · 3.1M Data Points

---

## Overview

This dashboard was built to answer one business question: **which trends matter, where they are happening, and whether they are rising or falling.** It transforms raw Google Trends export data into a four-page interactive intelligence report covering 422 distinct trend terms, 40 countries, 986 sub-national regions, and 266 weeks of weekly data spanning March 2021 to April 2026.

Built entirely in Power BI Desktop using DAX measures, a custom star-schema data model, and 24 purpose-built KPI measures.

---

## Dashboard Pages

| Page | Title | Core Question Answered |
|------|-------|----------------------|
| 1 | Executive Overview | What is the overall health and trajectory of global trend activity? |
| 2 | Trend Momentum & Velocity | Which terms are accelerating, exploding, or fading — and how fast? |
| 3 | Geographic Hotspot Map | Where in the world is trend interest most concentrated? |
| 4 | Global vs Local & Lifecycle | Are trends genuinely global, or locally isolated — and at what stage of their lifecycle? |

---

## Data Source

**Source:** Google Trends via BigQuery public dataset (bigquery-public-data.google_trends)
**Method:** Pulled directly into Power BI via BigQuery connector, then cleaned, normalised, and loaded into Power BI
**Date range:** 28 March 2021 — 26 April 2026
**Geographic coverage:** 40 countries across Asia, Europe, Africa, the Americas, and Oceania
**Granularity:** Weekly scores (0–100 relative interest scale), sub-national regions, per-term

> Google Trends scores are **relative**, not absolute. A score of 100 represents peak interest for a term in a given period and geography. A score of 50 means half the search interest of the peak. Scores are not comparable across different terms in isolation — they are comparable across time for the same term, and across regions for the same term at the same time.

---

## Data Model

The model follows a **star schema** — one central fact table per analytical domain, supported by shared dimension tables.

### Fact Tables

#### `global_trend_momentum`
The primary fact table. One row per term per country per week.

| Column | Type | Description |
|--------|------|-------------|
| Term | Text | The search term or topic tracked |
| Country | Text | Country where the trend was measured |
| Week | Date | Week-ending date |
| Score | Integer | Google Trends relative interest score (0–100) |
| Gain (%) | Float | Week-on-week percentage gain in interest |
| Growth Category | Text | Classified growth pattern: Breakout / Explosive / Moderate |
| region_name | Text | Sub-national region within the country |

**Why it matters:** This is where trend velocity lives. The `Gain (%)` column is the heartbeat — terms capped at 5,000% gain are classified as Breakout, meaning Google Trends cannot measure their actual growth because they exceeded the scale ceiling in a single week.

---

#### `global_lifecycle`
Long-form historical fact table tracking every term's score across its full observable lifespan.

| Column | Type | Description |
|--------|------|-------------|
| Term | Text | The search term |
| Country | Text | Country of measurement |
| Date | Date | Specific date of measurement |
| Average_Score | Float | Score at that date |
| Growth | Float | Rate of change at that date (positive = rising, negative = declining) |

**3,121,747 rows.** This is the largest table in the model and the source of lifecycle maturity analysis. A negative `Growth` value on a high-scoring term means the trend has peaked and is declining — the term is at the back half of its lifecycle curve.

---

#### `regional_hotspot_analysis`
Regional-level aggregation of trend scores.

| Column | Type | Description |
|--------|------|-------------|
| Term | Text | The search term |
| Country | Text | Country |
| Region | Text | Sub-national province, state, or city region |
| Average_Score | Float | Average Google Trends score for this term in this region |
| Region_Rank | Integer | Rank of this region within its country for this term |

**986 distinct regions across 42 countries.** Used to identify sub-national hotspots — where within a country trend interest is most concentrated.

---

#### `global_vs_local`
One row per term, classifying each as genuinely global or locally isolated.

| Column | Type | Description |
|--------|------|-------------|
| Term | Text | The search term |
| Country_Coverage | Integer | Number of countries where this term has measurable search interest |
| Scope | Text | Global (≥2 countries) or Local (1 country only) |

**23,352 distinct terms.** Only 164 (0.7%) are classified Global. The remaining 99.3% trend in exactly one country — a critical finding for any business making audience or media decisions based on "trending topics."

---

#### `cross_country_trend`
Term-level cross-country comparison table.

| Column | Type | Description |
|--------|------|-------------|
| Term | Text | The search term |
| Country | Text | Country where the term trends |
| Average_Score | Float | Country-level average score for this term |
| Country_Rank | Integer | Rank of this country for this term (1 = highest scoring) |

Used to identify which terms generate search interest across multiple markets simultaneously — the foundation for multi-market campaign targeting.

---

### Dimension Tables

| Table | Purpose | Key Column |
|-------|---------|------------|
| `Dim_Date` | Calendar table for time-intelligence measures and slicers | Date |
| `Dim_Country` | Country lookup with geocoding metadata | Country |
| `Dim_Region` | Sub-national region lookup | Region |
| `Dim_Term` | Term lookup enabling cross-table filtering | Term |

---

## DAX Measures (24 total)

### Core KPIs
| Measure | Formula | Business Meaning |
|---------|---------|-----------------|
| `Total Trends` | `DISTINCTCOUNT(Term)` | Number of unique trend terms in current filter context |
| `Avg Growth %` | `DIVIDE(AVERAGE(Gain(%)), 100)` | Average week-on-week growth across all terms |
| `Trend Velocity` | `DIVIDE(SUM(Gain(%)), COUNT(Term))` | Composite speed measure — how fast trends are moving |
| `Avg Score` | `AVERAGE(Score)` | Mean Google Trends score in current context |
| `WoW Growth` | Current week avg vs prior week avg | Directional momentum indicator |
| `4-Week Rolling Avg Score` | 28-day rolling window average | Smoothed signal that removes single-week noise |

### Breakout Detection
| Measure | Formula | Business Meaning |
|---------|---------|-----------------|
| `Breakout Trend Count` | `CALCULATE(DISTINCTCOUNT(Term), GrowthCategory="Breakout")` | Terms that hit the 5,000% gain ceiling — viral events |
| `Explosive Trend Count` | `CALCULATE(DISTINCTCOUNT(Term), GrowthCategory="Explosive")` | Terms with 1,000–4,999% gain — fast-rising but measurable |
| `Moderate Trend Count` | `CALCULATE(DISTINCTCOUNT(Term), GrowthCategory="Moderate")` | Terms with organic, steady growth |

### Geographic Measures
| Measure | Formula | Business Meaning |
|---------|---------|-----------------|
| `Avg Regional Score` | `AVERAGE(regional_hotspot_analysis[Average_Score])` | Mean intensity across all tracked sub-national regions |
| `Peak Regional Score` | `MAXX(SUMMARIZE(...), avg_score)` | Highest score recorded in any single region |
| `Total Regions` | `DISTINCTCOUNT(Region)` | Number of sub-national hotspots tracked |
| `Country Coverage Ratio` | `DIVIDE(Total Countries, COUNTROWS(Dim_Country))` | Share of available countries where a term trends |

### Scope & Lifecycle Measures
| Measure | Formula | Business Meaning |
|---------|---------|-----------------|
| `Global Term Count` | `CALCULATE(DISTINCTCOUNT(Term), Scope="Global")` | Terms trending in 2+ countries |
| `Local Term Count` | `CALCULATE(DISTINCTCOUNT(Term), Scope="Local")` | Terms trending in exactly 1 country |
| `Global Trend %` | `DIVIDE(Global Term Count, DISTINCTCOUNT(Term))` | Share of portfolio that is genuinely cross-market |
| `Avg Global Coverage` | `CALCULATE(AVERAGE(Country_Coverage), Scope="Global")` | Average number of countries a global term spans |
| `Lifecycle Avg Score` | `AVERAGE(global_lifecycle[Average_Score])` | Mean score across all lifecycle observations |
| `Lifecycle Avg Growth` | `AVERAGE(global_lifecycle[Growth])` | Mean weekly directional change — positive = rising |
| `Lifecycle Term Count` | `DISTINCTCOUNT(global_lifecycle[Term])` | Distinct terms observable in lifecycle table |

---

## Key Findings

1. **99.3% of trends are local.** Of 23,352 terms tracked, only 164 are genuinely global (trending in 2+ countries). Businesses assuming their trending content resonates internationally are likely wrong by default.

2. **280 Breakout terms hit the gain measurement ceiling.** These represent events so viral that Google's 5,000% cap cannot measure their true growth — flash news events, sports results, celebrity moments. They appear and vanish within 1–2 weeks.

3. **Thailand, India, and Turkey are the deepest trend markets.** These three countries combine the highest avg regional scores (99.1, 99.0, 98.8) with the widest sub-national coverage (77, 36, and 81 regions respectively). Any content strategy targeting Southeast Asia or MENA should anchor in these markets.

4. **April 2026 represents a structural anomaly.** The week of 26 April 2026 saw avg score spike from a 5-year baseline of ~32 to 100 — a 3× deviation. Term volume simultaneously collapsed from 15,000 weekly terms in March to 4,100 in late April, suggesting a small number of hyper-dominant topics crowded out the entire trend pool.

5. **High-scoring countries are declining, low-scoring countries are rising.** In the lifecycle scatter: Thailand, Romania, and Vietnam (scores 52, 51, 47) all show negative weekly growth. UK, Germany, and Belgium (scores 20, 25, 28) show positive growth. Trend intensity and trend trajectory are inversely correlated at country level — markets that peaked first are now declining fastest.

6. **pam bondi reaches 34 countries** — the widest any single term spans in this dataset. For comparison, psg reaches 33 and real madrid reaches 32. Sports and political news dominate the genuinely global tier.

---

## Technical Stack

- **Tool:** Microsoft Power BI Desktop
- **Data model:** Star schema, 5 fact tables, 4 dimension tables
- **Query language:** DAX (24 custom measures)
- **Data source:** BigQuery public dataset (bigquery-public-data.google_trends)
- **Visuals:** Filled map, treemap, bubble scatter, multi-line chart, combo chart, decomposition tree, clustered bar, matrix, donut, KPI cards
- **Rows processed:** ~3.2 million across all tables

---

## Skills Demonstrated

- End-to-end data pipeline: raw export → cleaned model → published dashboard
- Star schema data modelling in Power BI
- Advanced DAX: time-intelligence, rolling averages, dynamic Top N, conditional measures, CALCULATE with multiple filter contexts
- Geographic data visualisation (filled map, regional hotspot analysis)
- Dashboard UX: cross-filter interaction design, drill-through, conditional formatting, slicer sync
- Data storytelling: translating 3M rows into 4 executive-ready pages with clear KPIs and narrative flow
- Anomaly detection and trend classification (Breakout / Explosive / Moderate)

---

