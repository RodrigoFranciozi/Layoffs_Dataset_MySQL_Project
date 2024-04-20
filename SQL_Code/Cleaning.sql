/*
The steps bellow will cover the following cleaning processes:

1. Remove Duplicates (if any)
2. Standardize the data
3. Null or blank values
*/

USE dbo;

-- It's a good practice to create a copy of the table instead of modifying the raw data
CREATE TABLE staging_layoffs
LIKE layoffs;

INSERT staging_layoffs
SELECT *
  FROM layoffs;


-- =======================
--  1. Duplicate removal
-- =======================


-- Using Row number to identify potential duplicates
WITH duplicates_identification AS (
SELECT *,
      ROW_NUMBER() OVER(PARTITION BY company,
									 location,
                                     industry,
                                     total_laid_off,
                                     percentage_laid_off,
                                     `date`,
                                     stage,
                                     country,
                                     funds_raised_millions
									 ) AS row_num
 FROM staging_layoffs
)
SELECT *
  FROM duplicates_identification
 WHERE row_num > 1;

-- My solution will be to create a temp table and delete the values from this staging
-- using the results from this temp table to repopulate the same staging without duplicates

CREATE TEMPORARY TABLE tmp_table AS
SELECT *,
       ROW_NUMBER() OVER(PARTITION BY company,
									 location,
                                     industry,
                                     total_laid_off,
                                     percentage_laid_off,
                                     `date`,
                                     stage,
                                     country,
                                     funds_raised_millions
									 ) AS row_num
  FROM staging_layoffs;

-- Disabling the safe updates so I can delete the data
SET SQL_SAFE_UPDATES = 0;

DELETE 
  FROM staging_layoffs;

INSERT INTO staging_layoffs
SELECT company,
	   location,
	   industry,
       total_laid_off,
       percentage_laid_off,
       `date`,
       stage,
       country,
       funds_raised_millions 
  FROM tmp_table 
 WHERE row_num = 1;


-- =======================
--    2. Standardizing
-- =======================


-- Making sure `company` has no spaces before the name
UPDATE staging_layoffs
   SET company = TRIM(company);

-- Potential same industries
UPDATE staging_layoffs
   SET industry = 'Crypto'
 WHERE industry like 'Crypto%'; 

-- US country seems to have a `.` sometimes
SELECT * 
  FROM staging_layoffs
WHERE country Like 'United States.';

UPDATE staging_layoffs
   SET country = TRIM(TRAILING '.' FROM country)
 WHERE country Like 'United States%';

-- Last but not least, dates :) 
UPDATE staging_layoffs
   SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y')
 WHERE `date` <> 'NULL';

UPDATE staging_layoffs
   SET `date` = CASE 
			    WHEN `date` = 'NULL' THEN NULL 
                ELSE `date` 
                 END;

-- Changing column type
ALTER TABLE staging_layoffs
MODIFY COLUMN `date` DATE;


-- =======================
--    3. NULL VALUES
-- =======================


-- Lets fill the blanks in industry

UPDATE staging_layoffs
   SET industry = NULL
 WHERE industry = '';
 
UPDATE staging_layoffs AS t1
  JOIN staging_layoffs AS t2
       ON t1.company = t2.company
   SET t1.industry = t2.industry
 WHERE t1.industry IS NULL
   AND t2.industry IS NOT NULL;