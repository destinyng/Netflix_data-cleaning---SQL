/* INTRODUCTION: Netflix is a popular streaming service that offers a vast catalog of movies, TV shows, and original contents.
The data consist of contents added to Netflix from 2008 to 2021. This dataset will be cleaned with MSSQL and visualized with Tableau. 
The purpose of this dataset is to test my data cleaning and visualization skills.
*/

-- View dataset
SELECT *
FROM netflix;


-- Since show_id column is unique in the table. Check show_id column for any DUPLICATES
SELECT show_id, COUNT(*)
FROM netflix
GROUP BY show_id
HAVING COUNT(*) > 1;
-- There is no duplicates


-- Check every column for NULL values
SELECT
    COUNT(CASE WHEN show_id IS NULL THEN 1 END) AS showid_nulls,
    COUNT(CASE WHEN type IS NULL THEN 1 END) AS type_nulls,
    COUNT(CASE WHEN title IS NULL THEN 1 END) AS title_nulls,
    COUNT(CASE WHEN director IS NULL THEN 1 END) AS direction_nulls,
    COUNT(CASE WHEN country IS NULL THEN 1 END) AS country_nulls,
    COUNT(CASE WHEN date_added IS NULL THEN 1 END) AS dateadded_nulls,
    COUNT(CASE WHEN release_year IS NULL THEN 1 END) AS releaseyear_nulls,
    COUNT(CASE WHEN rating IS NULL THEN 1 END) AS rating_nulls,
    COUNT(CASE WHEN duration IS NULL THEN 1 END) AS duration_nulls,
    COUNT(CASE WHEN listed_in IS NULL THEN 1 END) AS listedin_nulls
FROM netflix;
-- Null values for director: 2634, country: 831, date_added: 10, rating: 4, duration: 3


-- DIRECTOR COLUMN:
-- Since director column nulls is about 30% of the whole column, I will not delete them.
-- I will find another column to populate it. I will find the relationship between the cast column and director column.
WITH dir_cast AS (
    SELECT title, CONCAT(director , '--', movie_cast) AS director_cast
    FROM netflix
)
SELECT director_cast, COUNT(*)
FROM dir_cast
GROUP BY director_cast
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;

UPDATE netflix
SET director = 'Alastair Fothergill'
WHERE movie_cast = 'David Attenborough'
AND director IS NULL;

UPDATE netflix
SET director = 'Mark Thornton, Todd Kauffman'
WHERE movie_cast = 'Michela Luci, Jamie Watson, Eric Peterson, Anna Claire Bartlam, Nicolas Aqui, Cory Doran, Julie Lemieux, Derek McGrath'
AND director IS NULL;
-- Populate the rest of Null values from director to 'Not Given'
UPDATE netflix
SET director = 'Not Given'
WHERE director IS NULL;


-- COUNTRY COLUMN:
-- Populate the country using the director column
SELECT COALESCE(nt.country,nt2.country) 
FROM netflix  AS nt
JOIN netflix AS nt2 
ON nt.director = nt2.director 
AND nt.show_id <> nt2.show_id
WHERE nt.country IS NULL;

WITH CountryFill AS (
    SELECT
        nt.show_id,
        nt.director,
        nt2.country AS new_country
    FROM netflix AS nt
    JOIN netflix AS nt2 ON nt.director = nt2.director AND nt.show_id <> nt2.show_id
    WHERE nt.country IS NULL AND nt2.country IS NOT NULL
)
UPDATE netflix 
SET country = cf.new_country
FROM CountryFill AS cf
WHERE netflix.show_id = cf.show_id;

-- After that, confirm if there are still directors linked to coutnry that refuse to update
SELECT director, country, date_added
FROM netflix
WHERE country IS NULL;

--Populate the rest of the NULL in country to 'Not Given'
UPDATE netflix
SET country = 'Not Given'
WHERE country IS NULL;


-- DATE_ADDED COLUMN:
-- Date_added column only has 10 null values so delete them will not affect to our analysis and visualization
SELECT show_id, date_added
FROM netflix
WHERE date_added IS NULL;

-- Delete null values from date_added column
DELETE FROM netflix
WHERE show_id IN ('s6796', 's6067', 's6175', 's6807', 's6902', 's7255', 's7197', 's7407', 's7848', 's8183');


-- RATING COLUMN:
-- Delete null values from rating column because there are only 4 null values
SELECT show_id, rating
FROM netflix
WHERE rating IS NULL;

DELETE FROM netflix
WHERE show_id IN ('s5990','s6828','s7313','s7538');


-- DURATION COLUMN:
-- Delete null values from duration column because there are only 3 null values
SELECT show_id, duration
FROM netflix
WHERE duration IS NULL;

DELETE FROM netflix
WHERE show_id IN (SELECT show_id FROM netflix WHERE duration IS NULL);

-- DOUBLE CHECK If there is still any NULL values in table
SELECT
    COUNT(CASE WHEN show_id IS NOT NULL THEN 1 END) AS showid_nulls,
    COUNT(CASE WHEN type IS NOT NULL THEN 1 END) AS type_nulls,
    COUNT(CASE WHEN title IS NOT NULL THEN 1 END) AS title_nulls,
    COUNT(CASE WHEN director IS NOT NULL THEN 1 END) AS direction_nulls,
    COUNT(CASE WHEN country IS NOT NULL THEN 1 END) AS country_nulls,
    COUNT(CASE WHEN date_added IS NOT NULL THEN 1 END) AS dateadded_nulls,
    COUNT(CASE WHEN release_year IS NOT NULL THEN 1 END) AS releaseyear_nulls,
    COUNT(CASE WHEN rating IS NOT NULL THEN 1 END) AS rating_nulls,
    COUNT(CASE WHEN duration IS NOT NULL THEN 1 END) AS duration_nulls,
    COUNT(CASE WHEN listed_in IS NOT NULL THEN 1 END) AS listedin_nulls
FROM netflix;
-- Total number of rows are the same in all columns.


-- Drop 2 columns: movie_cast and content_description because I will not use them for analysis and visualization
ALTER TABLE netflix
DROP COLUMN movie_cast

ALTER TABLE netflix
DROP COLUMN content_description


-- MODIFY COUNTRY COLUMN:
-- Since in country column, there are some records with muitple countries. For visualization, I only need one country per row  
-- Take the country column and retain the first country by the left which I believe is the original country of the movie
SELECT country, CASE 
    WHEN CHARINDEX(',', country) > 0 THEN SUBSTRING(country, 1, CHARINDEX(',', country) - 1)
    ELSE country 
    END
FROM netflix;

-- Add new column as country1
ALTER TABLE netflix 
ADD country1 nvarchar(MAX);

UPDATE netflix 
SET country1 = CASE 
    WHEN CHARINDEX(',', country) > 0 THEN SUBSTRING(country, 1, CHARINDEX(',', country) - 1)
    ELSE country 
    END
FROM netflix;

-- Delete a old country column
ALTER TABLE netflix
DROP COLUMN country;



