USE dbo;


-- Companies that lost all their employees
SELECT *
  FROM staging_layoffs
 WHERE percentage_laid_off = 1
 ORDER BY total_laid_off DESC;

-- What about the range of our data?
-- Very close of the pandemic start
SELECT MIN(`date`) AS min_date,
	   MAX(`date`) AS max_date
  FROM staging_layoffs;

-- Amount of people every company laid off
SELECT company,
	   SUM(total_laid_off) AS amount
  FROM staging_layoffs
 GROUP BY company
 ORDER BY 2 DESC;
 
-- Amount of people every industry laid off
SELECT industry,
	   SUM(total_laid_off) AS amount
  FROM staging_layoffs
 GROUP BY industry
 ORDER BY 2 DESC;

-- Amount of people every country laid off
SELECT country,
	   SUM(total_laid_off) AS amount
  FROM staging_layoffs
 GROUP BY country
 ORDER BY 2 DESC;

-- What if we take a look at the years
SELECT YEAR(`date`) AS year,
	   SUM(total_laid_off) AS amount
  FROM staging_layoffs
 GROUP BY YEAR(`date`)
 ORDER BY 1 DESC;

-- Evaluating the rolling sum about the total layoffs
WITH rolling_sum AS (
SELECT SUBSTRING(`date`, 1, 7) AS YYYY_MM,
	   SUM(total_laid_off) AS amount
  FROM staging_layoffs
 WHERE SUBSTRING(`date`, 1, 7)  IS NOT NULL
 GROUP BY SUBSTRING(`date`, 1, 7)
 ORDER BY 1
)
SELECT YYYY_MM,
	   amount,
       SUM(amount) OVER(ORDER BY YYYY_MM) AS rolling_total
  FROM rolling_sum;
  
  
-- Lets evaluate the amount laid off by company and year creating a rank
WITH Company_Year AS (
SELECT company,
	   YEAR(`date`) AS year,
       SUM(total_laid_off) AS amount
  FROM staging_layoffs
 GROUP BY company, YEAR(`date`)
),
Company_Year_Rank AS (
SELECT *,
	   DENSE_RANK() OVER(PARTITION BY year ORDER BY amount DESC) AS ranking
  FROM Company_Year
 WHERE year IS NOT NULL
 ORDER BY ranking
 )
 SELECT *
   FROM Company_Year_Rank
  WHERE ranking <= 5
  ORDER BY year;