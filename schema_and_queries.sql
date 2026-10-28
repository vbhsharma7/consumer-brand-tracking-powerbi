
-- Consumer Brand Tracking Study (SQL Server)
-- Grain: one row per respondent x question x brand x wave, where applicable.
-- Load CSV files into staging tables first, then insert into dimensions/fact table.

CREATE TABLE DimRespondent (
    RespondentID INT PRIMARY KEY,
    AgeGroup VARCHAR(20) NOT NULL,
    Gender VARCHAR(30) NOT NULL,
    Region VARCHAR(20) NOT NULL
);

CREATE TABLE DimBrand (
    BrandID INT PRIMARY KEY,
    BrandName VARCHAR(50) NOT NULL,
    Category VARCHAR(50) NOT NULL
);

CREATE TABLE DimWave (
    WaveID INT PRIMARY KEY,
    WaveName VARCHAR(50) NOT NULL,
    SurveyDate DATE NOT NULL
);

CREATE TABLE DimQuestion (
    QuestionID INT PRIMARY KEY,
    QuestionCode VARCHAR(30) NOT NULL UNIQUE,
    QuestionText VARCHAR(200) NOT NULL,
    MetricType VARCHAR(50) NOT NULL,
    QuestionType VARCHAR(30) NOT NULL
);

CREATE TABLE FactSurveyResponse (
    ResponseID INT PRIMARY KEY,
    RespondentID INT NOT NULL,
    QuestionID INT NOT NULL,
    BrandID INT NOT NULL,
    WaveID INT NOT NULL,
    ResponseValue VARCHAR(100) NULL,
    NumericValue DECIMAL(10,2) NULL,
    ResponseStatus VARCHAR(20) NOT NULL,
    CONSTRAINT FK_Response_Respondent FOREIGN KEY (RespondentID) REFERENCES DimRespondent(RespondentID),
    CONSTRAINT FK_Response_Question FOREIGN KEY (QuestionID) REFERENCES DimQuestion(QuestionID),
    CONSTRAINT FK_Response_Brand FOREIGN KEY (BrandID) REFERENCES DimBrand(BrandID),
    CONSTRAINT FK_Response_Wave FOREIGN KEY (WaveID) REFERENCES DimWave(WaveID)
);

-- Useful index for common filters and joins
CREATE INDEX IX_FactSurveyResponse_MetricLookup
ON FactSurveyResponse (WaveID, BrandID, QuestionID, RespondentID);

-- Initial QC checks
-- 1) Duplicate business grain (should return no rows after cleaning)
SELECT RespondentID, QuestionID, BrandID, WaveID, COUNT(*) AS RowCount
FROM FactSurveyResponse
GROUP BY RespondentID, QuestionID, BrandID, WaveID
HAVING COUNT(*) > 1;

-- 2) Invalid satisfaction scores (valid range is 1..5)
SELECT *
FROM FactSurveyResponse
WHERE QuestionID = 4
  AND NumericValue IS NOT NULL
  AND (NumericValue < 1 OR NumericValue > 5);

-- 3) Conditional logic check: consideration should only be asked if aware = Yes
-- Do this after pivoting responses or with a self-join in the validation query.

-- Example brand awareness metric by wave
SELECT
    w.WaveName,
    b.BrandName,
    COUNT(DISTINCT CASE WHEN f.ResponseValue = 'Yes' THEN f.RespondentID END) * 100.0
      / NULLIF(COUNT(DISTINCT f.RespondentID), 0) AS AwarenessPct
FROM FactSurveyResponse f
JOIN DimQuestion q ON q.QuestionID = f.QuestionID
JOIN DimBrand b ON b.BrandID = f.BrandID
JOIN DimWave w ON w.WaveID = f.WaveID
WHERE q.MetricType = 'Awareness'
  AND f.ResponseStatus = 'Valid'
GROUP BY w.WaveName, b.BrandName
ORDER BY w.WaveName, AwarenessPct DESC;
