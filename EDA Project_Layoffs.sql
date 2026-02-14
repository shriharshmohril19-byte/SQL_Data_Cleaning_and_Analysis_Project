-- Exploratory Data Analysis

-- 1. Max laid off & the percentage of layoffs
SELECT MAX(total_laid_off), MAX(percentage_laid_off) 
FROM layoffs_staging2;

-- 2. 100% layoffs in descending order of funds raised
SELECT * 
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- 3. Total layoffs per company in order of Max to min
SELECT company, SUM(total_laid_off) AS Layoff_com_tot
FROM layoffs_staging2
GROUP BY company
ORDER BY Layoff_com_tot DESC;

-- 4. Date range of layoffs
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2; 

-- 5. Total layoffs per industry in descending order
SELECT industry, SUM(total_laid_off) AS Layoff_ind_tot
FROM layoffs_staging2
GROUP BY industry
ORDER BY Layoff_ind_tot DESC;

-- 6. Total layoffs per country in descending order
SELECT country, SUM(total_laid_off) AS Layoff_country_tot
FROM layoffs_staging2
GROUP BY country
ORDER BY Layoff_country_tot DESC;

-- 7. Total layoffs per year in descending order
SELECT YEAR(`date`), SUM(total_laid_off) AS Layoff_country_tot
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY YEAR(`date`) DESC;

-- 8. Total of layoffs per month per year
SELECT SUBSTRING(`date`,1,7) AS `MONTH`, SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY `MONTH` ASC;

-- 9. Rolling total of layoffs per month per year using CTE
WITH Rolling_Total AS
(
SELECT SUBSTRING(`date`,1,7) AS `MONTH`, SUM(total_laid_off) AS Total_lay_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY `MONTH` ASC
)
SELECT `MONTH`, Total_lay_off,
SUM(Total_lay_off) OVER(ORDER BY `MONTH`) AS roll_tot
FROM Rolling_Total;

-- 10. Total laid off by company per year
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC;

-- 11. Ranking the total laid off by company per year -- Top 5
WITH Company_Year (Company, Years, Total_Laid_Off) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
), Company_Year_Rank AS
(
SELECT *,
DENSE_RANK() OVER (PARTITION BY Years ORDER BY Total_Laid_Off DESC)
AS Ranking
FROM Company_Year
WHERE Years IS NOT NULL
)
SELECT * 
FROM Company_Year_Rank
WHERE Ranking <= 5;

-- 12. Ranking the total laid off by industry & country per year -- Top 5
WITH Industry_Year (Industry, Years, Total_Laid_Off, Country) AS
(
SELECT industry, YEAR(`date`), SUM(total_laid_off), country
FROM layoffs_staging2
GROUP BY industry, YEAR(`date`), country
), Industry_Year_Rank AS
(
SELECT *,
DENSE_RANK() OVER (PARTITION BY Years ORDER BY Total_Laid_Off DESC)
AS Ranking
FROM Industry_Year
WHERE Years IS NOT NULL
)
SELECT * 
FROM Industry_Year_Rank
WHERE Ranking <= 5;

-- -- 