SET GLOBAL local_infile = 1;

SHOW GLOBAL VARIABLES LIKE 'local_infile';

USE ConsumerBrandTracking;

LOAD DATA LOCAL INFILE '"C:\Users\HP\Downloads\consumer_brand_tracking_project\consumer_brand_tracking_project\dim_brand.csv"'
INTO TABLE DimBrand
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;