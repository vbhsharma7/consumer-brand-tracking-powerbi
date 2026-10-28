------------------------------------------------------------
-- Consumer Brand Tracking SQL Starter
-- New SQL script for the survey analytics project
------------------------------------------------------------

USE ConsumerBrandTracking;
GO

IF OBJECT_ID('dbo.FactSurveyResponse', 'U') IS NOT NULL DROP TABLE dbo.FactSurveyResponse;
IF OBJECT_ID('dbo.DimQuestion', 'U') IS NOT NULL DROP TABLE dbo.DimQuestion;
IF OBJECT_ID('dbo.DimBrand', 'U') IS NOT NULL DROP TABLE dbo.DimBrand;
IF OBJECT_ID('dbo.DimWave', 'U') IS NOT NULL DROP TABLE dbo.DimWave;
IF OBJECT_ID('dbo.DimRespondent', 'U') IS NOT NULL DROP TABLE dbo.DimRespondent;
GO

CREATE TABLE dbo.DimRespondent (
    RespondentID INT NOT NULL PRIMARY KEY,
    AgeGroup VARCHAR(20) NOT NULL,
    Gender VARCHAR(30) NOT NULL,
    Region VARCHAR(30) NOT NULL
);

CREATE TABLE dbo.DimBrand (
    BrandID INT NOT NULL PRIMARY KEY,
    BrandName VARCHAR(50) NOT NULL,
    Category VARCHAR(50) NOT NULL
);

CREATE TABLE dbo.DimWave (
    WaveID INT NOT NULL PRIMARY KEY,
    WaveName VARCHAR(50) NOT NULL,
    SurveyDate DATE NOT NULL
);

CREATE TABLE dbo.DimQuestion (
    QuestionID INT NOT NULL PRIMARY KEY,
    QuestionCode VARCHAR(30) NOT NULL UNIQUE,
    QuestionText VARCHAR(250) NOT NULL,
    MetricType VARCHAR(50) NOT NULL,
    QuestionType VARCHAR(50) NOT NULL
);

CREATE TABLE dbo.FactSurveyResponse (
    ResponseID INT NOT NULL PRIMARY KEY,
    RespondentID INT NOT NULL,
    QuestionID INT NOT NULL,
    BrandID INT NOT NULL,
    WaveID INT NOT NULL,
    ResponseValue VARCHAR(50) NULL,
    NumericValue DECIMAL(10,2) NULL,
    ResponseStatus VARCHAR(20) NOT NULL,
    CONSTRAINT FK_Fact_Respondent FOREIGN KEY (RespondentID) REFERENCES dbo.DimRespondent(RespondentID),
    CONSTRAINT FK_Fact_Question FOREIGN KEY (QuestionID) REFERENCES dbo.DimQuestion(QuestionID),
    CONSTRAINT FK_Fact_Brand FOREIGN KEY (BrandID) REFERENCES dbo.DimBrand(BrandID),
    CONSTRAINT FK_Fact_Wave FOREIGN KEY (WaveID) REFERENCES dbo.DimWave(WaveID)
);

CREATE INDEX IX_FactSurveyResponse_WaveBrandQuestion
    ON dbo.FactSurveyResponse (WaveID, BrandID, QuestionID, RespondentID);
GO

------------------------------------------------------------
-- Example load pattern for imported CSV files
-- Replace file paths with your local SQL Server import locations.
------------------------------------------------------------
-- BULK INSERT dbo.DimRespondent
-- FROM 'C:\data\dim_respondent.csv'
-- WITH (
--     FIRSTROW = 2,
--     FIELDTERMINATOR = ',',
--     ROWTERMINATOR = '\n',
--     TABLOCK
-- );
--
-- BULK INSERT dbo.DimBrand
-- FROM 'C:\data\dim_brand.csv'
-- WITH (
--     FIRSTROW = 2,
--     FIELDTERMINATOR = ',',
--     ROWTERMINATOR = '\n',
--     TABLOCK
-- );
--
-- BULK INSERT dbo.DimWave
-- FROM 'C:\data\dim_wave.csv'
-- WITH (
--     FIRSTROW = 2,
--     FIELDTERMINATOR = ',',
--     ROWTERMINATOR = '\n',
--     TABLOCK
-- );
--
-- BULK INSERT dbo.DimQuestion
-- FROM 'C:\data\dim_question.csv'
-- WITH (
--     FIRSTROW = 2,
--     FIELDTERMINATOR = ',',
--     ROWTERMINATOR = '\n',
--     TABLOCK
-- );
--
-- BULK INSERT dbo.FactSurveyResponse
-- FROM 'C:\data\fact_survey_response_clean.csv'
-- WITH (
--     FIRSTROW = 2,
--     FIELDTERMINATOR = ',',
--     ROWTERMINATOR = '\n',
--     TABLOCK
-- );
GO

------------------------------------------------------------
-- Data quality checks
------------------------------------------------------------

-- 1) Duplicate grain check
SELECT
    RespondentID,
    QuestionID,
    BrandID,
    WaveID,
    COUNT(*) AS DuplicateRows
FROM dbo.FactSurveyResponse
GROUP BY RespondentID, QuestionID, BrandID, WaveID
HAVING COUNT(*) > 1;

-- 2) Invalid satisfaction scores
SELECT *
FROM dbo.FactSurveyResponse
WHERE QuestionID = 4
  AND NumericValue IS NOT NULL
  AND (NumericValue < 1 OR NumericValue > 5);

-- 3) Null/invalid response values in valid rows
SELECT *
FROM dbo.FactSurveyResponse
WHERE ResponseStatus = 'Valid'
  AND ResponseValue IS NULL
  AND QuestionID IN (1,2,3);

------------------------------------------------------------
-- Standard KPI queries
------------------------------------------------------------

-- Awareness by wave and brand
SELECT
    w.WaveName,
    b.BrandName,
    COUNT(DISTINCT CASE WHEN f.ResponseValue = 'Yes' THEN f.RespondentID END) * 100.0 / NULLIF(COUNT(DISTINCT f.RespondentID), 0) AS AwarenessPct
FROM dbo.FactSurveyResponse f
JOIN dbo.DimQuestion q
    ON q.QuestionID = f.QuestionID
JOIN dbo.DimBrand b
    ON b.BrandID = f.BrandID
JOIN dbo.DimWave w
    ON w.WaveID = f.WaveID
WHERE q.MetricType = 'Awareness'
  AND f.ResponseStatus = 'Valid'
GROUP BY w.WaveName, b.BrandName
ORDER BY w.WaveName, AwarenessPct DESC;

-- Consideration among aware respondents
SELECT
    w.WaveName,
    b.BrandName,
    COUNT(DISTINCT CASE WHEN f.ResponseValue = 'Yes' THEN f.RespondentID END) * 100.0 /
        NULLIF(COUNT(DISTINCT CASE WHEN aware.ResponseValue = 'Yes' THEN aware.RespondentID END), 0) AS ConsiderationAmongAwarePct
FROM dbo.FactSurveyResponse f
JOIN dbo.DimQuestion q
    ON q.QuestionID = f.QuestionID
JOIN dbo.DimBrand b
    ON b.BrandID = f.BrandID
JOIN dbo.DimWave w
    ON w.WaveID = f.WaveID
LEFT JOIN dbo.FactSurveyResponse aware
    ON aware.RespondentID = f.RespondentID
   AND aware.BrandID = f.BrandID
   AND aware.WaveID = f.WaveID
   AND aware.QuestionID = 1
WHERE q.MetricType = 'Consideration'
  AND f.ResponseStatus = 'Valid'
  AND aware.ResponseValue = 'Yes'
GROUP BY w.WaveName, b.BrandName
ORDER BY w.WaveName, ConsiderationAmongAwarePct DESC;

-- Purchase rate among those who consider the brand
SELECT
    w.WaveName,
    b.BrandName,
    COUNT(DISTINCT CASE WHEN f.ResponseValue = 'Yes' THEN f.RespondentID END) * 100.0 /
        NULLIF(COUNT(DISTINCT CASE WHEN consider.ResponseValue = 'Yes' THEN consider.RespondentID END), 0) AS PurchaseAmongConsiderersPct
FROM dbo.FactSurveyResponse f
JOIN dbo.DimQuestion q
    ON q.QuestionID = f.QuestionID
JOIN dbo.DimBrand b
    ON b.BrandID = f.BrandID
JOIN dbo.DimWave w
    ON w.WaveID = f.WaveID
LEFT JOIN dbo.FactSurveyResponse consider
    ON consider.RespondentID = f.RespondentID
   AND consider.BrandID = f.BrandID
   AND consider.WaveID = f.WaveID
   AND consider.QuestionID = 2
WHERE q.MetricType = 'Purchase'
  AND f.ResponseStatus = 'Valid'
  AND consider.ResponseValue = 'Yes'
GROUP BY w.WaveName, b.BrandName
ORDER BY w.WaveName, PurchaseAmongConsiderersPct DESC;

-- Satisfaction average by brand and wave
SELECT
    w.WaveName,
    b.BrandName,
    AVG(f.NumericValue) AS AvgSatisfactionScore,
    COUNT(f.NumericValue) AS ValidRatings
FROM dbo.FactSurveyResponse f
JOIN dbo.DimQuestion q
    ON q.QuestionID = f.QuestionID
JOIN dbo.DimBrand b
    ON b.BrandID = f.BrandID
JOIN dbo.DimWave w
    ON w.WaveID = f.WaveID
WHERE q.MetricType = 'Satisfaction'
  AND f.ResponseStatus = 'Valid'
  AND f.NumericValue BETWEEN 1 AND 5
GROUP BY w.WaveName, b.BrandName
ORDER BY w.WaveName, AvgSatisfactionScore DESC;

------------------------------------------------------------
-- Example wave-over-wave delta query
------------------------------------------------------------
WITH AwarenessBase AS (
    SELECT
        w.WaveName,
        b.BrandName,
        COUNT(DISTINCT CASE WHEN f.ResponseValue = 'Yes' THEN f.RespondentID END) * 100.0 /
            NULLIF(COUNT(DISTINCT f.RespondentID), 0) AS AwarenessPct
    FROM dbo.FactSurveyResponse f
    JOIN dbo.DimQuestion q ON q.QuestionID = f.QuestionID
    JOIN dbo.DimBrand b ON b.BrandID = f.BrandID
    JOIN dbo.DimWave w ON w.WaveID = f.WaveID
    WHERE q.MetricType = 'Awareness'
      AND f.ResponseStatus = 'Valid'
    GROUP BY w.WaveName, b.BrandName
)
SELECT
    BrandName,
    MAX(CASE WHEN WaveName = 'March 2026' THEN AwarenessPct END) AS Awareness_March_2026,
    MAX(CASE WHEN WaveName = 'September 2026' THEN AwarenessPct END) AS Awareness_September_2026,
    MAX(CASE WHEN WaveName = 'September 2026' THEN AwarenessPct END)
      - MAX(CASE WHEN WaveName = 'March 2026' THEN AwarenessPct END) AS ChangeVsPriorWave
FROM AwarenessBase
GROUP BY BrandName
ORDER BY BrandName;

------------------------------------------------------------
-- Optional summary view
CREATE VIEW dbo.vwBrandTrackingSummary AS
SELECT
    w.WaveName,
    b.BrandName,
    q.MetricType,
    COUNT(DISTINCT CASE WHEN f.ResponseValue = 'Yes' THEN f.RespondentID END) AS YesResponses,
    COUNT(DISTINCT f.RespondentID) AS DistinctRespondents,
    AVG(CAST(f.NumericValue AS DECIMAL(10,2))) AS AvgNumericValue
FROM dbo.FactSurveyResponse f
JOIN dbo.DimQuestion q ON q.QuestionID = f.QuestionID
JOIN dbo.DimBrand b ON b.BrandID = f.BrandID
JOIN dbo.DimWave w ON w.WaveID = f.WaveID
GROUP BY w.WaveName, b.BrandName, q.MetricType;
GO
