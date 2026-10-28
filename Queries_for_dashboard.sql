-- Dashboard-ready queries for the Consumer Brand Tracking project.
-- SQL Server; assumes the dbo dimensions and fact table from
-- new_sql_brand_tracking.sql and the cleaned fact_survey_response_clean.csv.
-- Rates use valid responses to each question as their denominators.

USE ConsumerBrandTracking;
GO

------------------------------------------------------------
-- 1) Executive overview: core KPIs by wave and brand
------------------------------------------------------------
WITH MetricResponses AS (
    SELECT
        w.WaveID,
        w.WaveName,
        w.SurveyDate,
        b.BrandID,
        b.BrandName,
        q.MetricType,
        f.RespondentID,
        f.ResponseValue,
        f.NumericValue
    FROM dbo.FactSurveyResponse AS f
    INNER JOIN dbo.DimQuestion AS q
        ON q.QuestionID = f.QuestionID
    INNER JOIN dbo.DimBrand AS b
        ON b.BrandID = f.BrandID
    INNER JOIN dbo.DimWave AS w
        ON w.WaveID = f.WaveID
    WHERE f.ResponseStatus = 'Valid'
)
SELECT
    WaveID,
    WaveName,
    SurveyDate,
    BrandID,
    BrandName,
    COUNT(DISTINCT CASE WHEN MetricType = 'Awareness' THEN RespondentID END)
        AS AwarenessEligible,
    COUNT(DISTINCT CASE
        WHEN MetricType = 'Awareness' AND ResponseValue = 'Yes' THEN RespondentID
    END) AS AwarenessYes,
    100.0 * COUNT(DISTINCT CASE
        WHEN MetricType = 'Awareness' AND ResponseValue = 'Yes' THEN RespondentID
    END) / NULLIF(COUNT(DISTINCT CASE
        WHEN MetricType = 'Awareness' THEN RespondentID
    END), 0) AS AwarenessPct,
    COUNT(DISTINCT CASE WHEN MetricType = 'Consideration' THEN RespondentID END)
        AS ConsiderationEligible,
    COUNT(DISTINCT CASE
        WHEN MetricType = 'Consideration' AND ResponseValue = 'Yes' THEN RespondentID
    END) AS ConsiderationYes,
    100.0 * COUNT(DISTINCT CASE
        WHEN MetricType = 'Consideration' AND ResponseValue = 'Yes' THEN RespondentID
    END) / NULLIF(COUNT(DISTINCT CASE
        WHEN MetricType = 'Consideration' THEN RespondentID
    END), 0) AS ConsiderationPct,
    COUNT(DISTINCT CASE WHEN MetricType = 'Purchase' THEN RespondentID END)
        AS PurchaseEligible,
    COUNT(DISTINCT CASE
        WHEN MetricType = 'Purchase' AND ResponseValue = 'Yes' THEN RespondentID
    END) AS PurchaseYes,
    100.0 * COUNT(DISTINCT CASE
        WHEN MetricType = 'Purchase' AND ResponseValue = 'Yes' THEN RespondentID
    END) / NULLIF(COUNT(DISTINCT CASE
        WHEN MetricType = 'Purchase' THEN RespondentID
    END), 0) AS PurchasePct,
    AVG(CASE WHEN MetricType = 'Satisfaction'
        AND NumericValue BETWEEN 1 AND 5 THEN NumericValue END) AS AverageSatisfaction,
    COUNT(CASE WHEN MetricType = 'Satisfaction'
        AND NumericValue BETWEEN 1 AND 5 THEN 1 END) AS SatisfactionRatings
FROM MetricResponses
GROUP BY WaveID, WaveName, SurveyDate, BrandID, BrandName
ORDER BY SurveyDate, BrandName;
GO

------------------------------------------------------------
-- 2) Wave-over-wave change in awareness, in percentage points
------------------------------------------------------------
WITH AwarenessByWave AS (
    SELECT
        w.WaveID,
        w.WaveName,
        w.SurveyDate,
        b.BrandID,
        b.BrandName,
        100.0 * COUNT(DISTINCT CASE WHEN f.ResponseValue = 'Yes'
            THEN f.RespondentID END)
            / NULLIF(COUNT(DISTINCT f.RespondentID), 0) AS AwarenessPct
    FROM dbo.FactSurveyResponse AS f
    INNER JOIN dbo.DimQuestion AS q
        ON q.QuestionID = f.QuestionID
    INNER JOIN dbo.DimBrand AS b
        ON b.BrandID = f.BrandID
    INNER JOIN dbo.DimWave AS w
        ON w.WaveID = f.WaveID
    WHERE q.MetricType = 'Awareness'
      AND f.ResponseStatus = 'Valid'
    GROUP BY w.WaveID, w.WaveName, w.SurveyDate, b.BrandID, b.BrandName
)
SELECT
    BrandID,
    BrandName,
    WaveName,
    SurveyDate,
    AwarenessPct,
    AwarenessPct - LAG(AwarenessPct) OVER (
        PARTITION BY BrandID ORDER BY SurveyDate, WaveID
    ) AS AwarenessChangePp
FROM AwarenessByWave
ORDER BY BrandName, SurveyDate;
GO

------------------------------------------------------------
-- 3) Consumer segment comparison: valid-response rates
------------------------------------------------------------
SELECT
    w.WaveName,
    b.BrandName,
    r.AgeGroup,
    r.Region,
    q.MetricType,
    COUNT(DISTINCT f.RespondentID) AS ValidRespondents,
    COUNT(DISTINCT CASE WHEN f.ResponseValue = 'Yes'
        THEN f.RespondentID END) AS YesRespondents,
    100.0 * COUNT(DISTINCT CASE WHEN f.ResponseValue = 'Yes'
        THEN f.RespondentID END)
        / NULLIF(COUNT(DISTINCT f.RespondentID), 0) AS YesResponsePct,
    AVG(CASE WHEN q.MetricType = 'Satisfaction'
        AND f.NumericValue BETWEEN 1 AND 5 THEN f.NumericValue END)
        AS AverageSatisfaction
FROM dbo.FactSurveyResponse AS f
INNER JOIN dbo.DimQuestion AS q
    ON q.QuestionID = f.QuestionID
INNER JOIN dbo.DimRespondent AS r
    ON r.RespondentID = f.RespondentID
INNER JOIN dbo.DimBrand AS b
    ON b.BrandID = f.BrandID
INNER JOIN dbo.DimWave AS w
    ON w.WaveID = f.WaveID
WHERE f.ResponseStatus = 'Valid'
GROUP BY w.WaveName, b.BrandName, r.AgeGroup, r.Region, q.MetricType
ORDER BY w.WaveName, b.BrandName, q.MetricType, r.AgeGroup, r.Region;
GO

------------------------------------------------------------
-- 4) Data quality summary for the loaded fact table
-- The clean fact table cannot report excluded raw-file rows.
------------------------------------------------------------
SELECT
    COUNT(*) AS LoadedFactRows,
    COUNT(DISTINCT ResponseID) AS DistinctResponseIDs,
    SUM(CASE WHEN ResponseStatus = 'NotAsked' THEN 1 ELSE 0 END) AS NotAskedRows,
    SUM(CASE WHEN ResponseStatus = 'Flagged' THEN 1 ELSE 0 END) AS FlaggedRows,
    SUM(CASE
        WHEN q.MetricType = 'Satisfaction'
         AND f.NumericValue IS NOT NULL
         AND (f.NumericValue < 1 OR f.NumericValue > 5)
        THEN 1 ELSE 0
    END) AS InvalidSatisfactionRows
FROM dbo.FactSurveyResponse AS f
LEFT JOIN dbo.DimQuestion AS q
    ON q.QuestionID = f.QuestionID;
GO

-- Duplicate business-grain rows; expected to return no rows for clean data.
SELECT
    RespondentID,
    QuestionID,
    BrandID,
    WaveID,
    COUNT(*) AS DuplicateRows
FROM dbo.FactSurveyResponse
GROUP BY RespondentID, QuestionID, BrandID, WaveID
HAVING COUNT(*) > 1;
GO
