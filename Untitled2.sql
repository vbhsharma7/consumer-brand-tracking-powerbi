USE ConsumerBrandTracking;

LOAD DATA LOCAL INFILE '"C:\Users\HP\Downloads\consumer_brand_tracking_project\consumer_brand_tracking_project\dim_brand.csv"'
INTO TABLE DimBrand
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

USE ConsumerBrandTracking;

SELECT 'DimRespondent' AS TableName, COUNT(*) AS TotalRows
FROM DimRespondent
UNION ALL
SELECT 'DimBrand', COUNT(*) FROM DimBrand
UNION ALL
SELECT 'DimWave', COUNT(*) FROM DimWave
UNION ALL 
SELECT 'DimQuestion', COUNT(*) FROM DimQuestion
UNION ALL
SELECT 'FactSurveyResponse', COUNT(*) FROM FactSurveyResponse;