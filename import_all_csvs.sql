USE consumerbrandtracking;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE dimrespondent;
TRUNCATE TABLE dimbrand;
TRUNCATE TABLE dimwave;
TRUNCATE TABLE dimquestion;
TRUNCATE TABLE factsurveyresponse;
SET FOREIGN_KEY_CHECKS = 1;

LOAD DATA LOCAL INFILE 'C:/Users/HP/Downloads/consumer_brand_tracking_project/consumer_brand_tracking_project/dim_respondent.csv'
INTO TABLE dimrespondent
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/HP/Downloads/consumer_brand_tracking_project/consumer_brand_tracking_project/dim_brand.csv'
INTO TABLE dimbrand
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/HP/Downloads/consumer_brand_tracking_project/consumer_brand_tracking_project/dim_wave.csv'
INTO TABLE dimwave
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/HP/Downloads/consumer_brand_tracking_project/consumer_brand_tracking_project/dim_question.csv'
INTO TABLE dimquestion
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

SET FOREIGN_KEY_CHECKS = 0;
LOAD DATA LOCAL INFILE 'C:/Users/HP/Downloads/consumer_brand_tracking_project/consumer_brand_tracking_project/fact_survey_response_clean.csv'
INTO TABLE factsurveyresponse
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
SET FOREIGN_KEY_CHECKS = 1;

SELECT 'dimrespondent', COUNT(*) FROM dimrespondent
UNION ALL
SELECT 'dimbrand', COUNT(*) FROM dimbrand
UNION ALL
SELECT 'dimwave', COUNT(*) FROM dimwave
UNION ALL
SELECT 'dimquestion', COUNT(*) FROM dimquestion
UNION ALL
SELECT 'factsurveyresponse', COUNT(*) FROM factsurveyresponse;
