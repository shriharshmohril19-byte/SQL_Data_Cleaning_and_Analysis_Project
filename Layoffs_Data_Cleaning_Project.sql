-- DATA CLEANING PROJECT
-- 1. Remove duplicates
-- 2. Standardize the data
-- 3. Null or blank values
-- 4. Remove columns if needed

SELECT * 
FROM layoffs;

-- Creating a duplicate table and inserting the values from raw data table to keep the raw data safe

CREATE TABLE layoffs_staging
LIKE layoffs;
SELECT * 
FROM layoffs_staging;

INSERT INTO layoffs_staging
SELECT *
FROM layoffs;

-- 1. Remove Duplicates
-- Step-1 - Finding row mumbers, partitioned over all columns to find the duplicates, ie, if row_id>1, then its a duplicate
SELECT *,
ROW_NUMBER() 
OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions)
AS row_id
FROM layoffs_staging;

-- Step-2 - PRINTING THE DUPLICATES USING CTE.
WITH duplicate_cte AS 
(SELECT *,
ROW_NUMBER() 
OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions)
AS row_id
FROM layoffs_staging
)
SELECT * 
FROM duplicate_cte
WHERE row_id>1;
-- However, it is not possible to update a CTE, ie, not possible to delete the duplicates from the CTE. Hence, we look at another method.
-- Creating a new table and inserting the values into this table, and then deleting the duplicates from it.

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_id` INT 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() 
OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions)
AS row_id
FROM layoffs_staging;

SELECT *
FROM layoffs_staging2;

-- Step-3 - DELETING THE ROWS WHERE row_id>1
DELETE
FROM layoffs_staging2
WHERE row_id > 1;
-- Hence, the duplicate rows are deleted.
SELECT *
FROM layoffs_staging2;


-- 2. STADARDIZING THE DATA
SELECT DISTINCT company
FROM layoffs_staging2; -- Uneven spacing observed in the company column
-- Step - 1: TRIM the white spaces and UPDATE in the table.

SELECT company, TRIM(COMPANY)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(COMPANY);

-- Step-2: industry column
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1; -- Crypto and CryptoCurrency are the same thing, needs to be updated

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT *
FROM layoffs_staging2;

-- Step-3: country column
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1; -- 'United States' and 'United States.' need to be fixed

UPDATE layoffs_staging2
SET country = 'United States'
WHERE country LIKE 'United States%'; -- Method-1

SELECT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%'; -- Method-2

-- Step-4: Checking and updating the format and data types of columns, like date
-- date column is of 'text' (string) datatype, we need to change it to 'date' datatype. 
-- For this we will use STR_TO_DATE(column_name, current_date_format ('%m/%d/%Y' etc.))

SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

SELECT `date`
FROM layoffs_staging2; -- Date format successfully changed, However datatype is still 'text'

-- Changing the data type to 'date'
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE; -- datatype successfully changed

-- 3. DEALING WITH NULL OR BLANK VALUES
SELECT *
FROM layoffs_staging2
WHERE company ='Airbnb'; -- Airbnb belongs to Travel industry

UPDATE layoffs_staging2
SET industry ='Travel'
WHERE company = 'Airbnb';

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL;

SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = ' ')
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging2
SET industry = NULL 
WHERE industry = ' ';

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = ' ')
AND t2.industry IS NOT NULL;

-- 4. REMOVING UNWANTED COLUMNS AND FIELDS

ALTER TABLE layoffs_staging2
DROP COLUMN row_id;

DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL; -- SINCE WE DONT HAVE DATA TO POPULATE THESE NULL VALUES