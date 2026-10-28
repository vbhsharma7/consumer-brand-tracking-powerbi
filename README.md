# Market Research Survey Data Modeling & End-to-End Power BI Project

## Consumer Brand Tracking Study

An end-to-end market research analytics portfolio project combining survey data modeling, data quality checks, SQL, Python, and Power BI.

## Goal
Build an end-to-end market research project using synthetic FMCG shampoo survey data, SQL Server, Python, and Power BI.

## Dataset
- 300 synthetic respondent IDs
- 3 fictional brands: Glow, PureCare, NatureFresh
- 2 survey waves: March 2026 and September 2026
- 4 measures: awareness, consideration, purchase, satisfaction
- Raw response CSV intentionally contains duplicate records and invalid satisfaction values for QC practice.
- All data is fictional and generated for learning. Do not present it as real market research.

## Files
- `dim_respondent.csv`: respondent demographics
- `dim_brand.csv`: brand lookup
- `dim_wave.csv`: research wave lookup
- `dim_question.csv`: question and metric definitions
- `fact_survey_response_raw.csv`: long-format raw responses, including deliberate quality issues
- `schema_and_queries.sql`: SQL Server schema and starter QC/metric queries
- `python_data_quality.py`: standalone Python validation/cleaning example
- `power_bi_measures.md`: starter DAX measures and dashboard plan
- `import_data.py`, `import_data_fixed.py`, and `import_all_csvs.py`: optional MySQL CSV import scripts. Set the `MYSQL_PASSWORD` environment variable before running them.

## Recommended build order
1. Open CSV files and inspect columns / row counts.
2. Run the Python quality-check script.
3. Create a SQL Server database and run `schema_and_queries.sql` table definitions.
4. Import the dimension CSVs and the cleaned fact CSV into SQL Server. For a beginner, SQL Server Import Flat File wizard or SSMS Import Data is fine. Ensure dates and numeric values use correct data types.
5. Run duplicate and range checks.
6. Connect Power BI Desktop to SQL Server and import the four dimensions and fact table.
7. Create relationships from each dimension's primary key to the corresponding fact foreign key (one-to-many, single direction).
8. Add the DAX measures in `power_bi_measures.md`.
9. Build the report pages described in that file.
10. Write a short README with findings, data limitations, and screenshots.

## Important modelling note
The fact table grain is one row per respondent × question × brand × wave. `NotAsked` responses are intentionally represented with null answer values. For metric denominators, use eligible respondents and valid responses, not all rows indiscriminately. This starter project uses synthetic data and simplified conditional routing; production market research may require separate eligibility/denominator logic.

## Suggested portfolio statement (after you complete it)
"Built an end-to-end consumer brand tracking analytics project using SQL Server, Python, and Power BI. Designed a star-schema model for respondent-level survey responses across brands and waves, implemented data-quality checks for duplicate records and invalid ratings, and developed KPIs for brand awareness, consideration, purchase, satisfaction, and wave-over-wave change using synthetic data."
