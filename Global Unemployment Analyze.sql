-- Chane the column type

ALTER TABLE public.disoccupazione 
ALTER COLUMN country TYPE varchar(100);

ALTER TABLE public.occupazione 
ALTER COLUMN country TYPE varchar(100);

ALTER TABLE public.mapping_list ALTER COLUMN "name" TYPE VARCHAR(100);

-- Change the column name

ALTER TABLE public.disoccupazione 
RENAME COLUMN unemployment TO unemployment_rate;

ALTER TABLE public.occupazione 
RENAME COLUMN employment TO employment_rate;

/* Create a raw_data: 
 -JOIN occupazione table and disoccupazione table
 - Add region field: LEFT JOIN mapping_list table
 OUTPUT: iso_code, country, region, sex, age, year, unemployment_rate, employment_rate
 Rename a list of countries following mappling_list to add region field on raw_data */

WITH clean_country AS 
			(SELECT *, 
	 			(CASE  WHEN country = 'Taiwan, China' THEN 'Taiwan, Province of China'
	  			WHEN country = 'Korea (the Democratic People''s Republic of)' THEN 'Korea, Democratic People''s Republic of'
	  			WHEN country = 'Venezuela (Bolivarian Republic of)' THEN 'Venezuela, Bolivarian Republic of'
	  			WHEN country = 'Palestine (State of)' THEN 'Palestine, State of'
	  			WHEN country = 'Macao, China' THEN 'Macao'
	  			WHEN country = 'Republic of Moldova' THEN 'Moldova, Republic of'
	  			WHEN country = 'Netherlands' THEN 'Netherlands, Kingdom of the'
	  			WHEN country = 'Hong Kong, China' THEN 'Hong Kong'
	  			WHEN country = 'Iran (Islamic Republic of)' THEN 'Iran, Islamic Republic of'
	  			WHEN country = 'Republic of Korea' THEN 'Korea, Republic of'
	  			WHEN country = 'Bolivia (Plurinational State of)' THEN 'Bolivia, Plurinational State of'
	  			ELSE country 
	 			 END) AS country_clean
	 			FROM global_data),
	  clean_mapping AS 
			 (SELECT name,
	  			(CASE WHEN name = 'Taiwan, Province of China' THEN 'Asia' 
	  			ELSE region
	  		 	END) AS region_clean
	 		 	FROM mapping_list)
SELECT c.iso_code,
		c.country_clean AS country,
		m.region_clean AS region,
		c.sex,
		c.age,
		c."year",
		ROUND((c.unemployment_rate/100) :: DECIMAL(10,2),2) AS unemployment_rate,
		ROUND((c.employment_rate/100) :: DECIMAL (10,2),2) AS employment_rate
FROM clean_country c
LEFT JOIN clean_mapping m ON c.country_clean = m.name;
 
	
--In which countries is the gap between male and female unemployment rates the widest?

-- 10 countries w highest unemployment gap between female and male
WITH female AS (
		SELECT country,
				region,
				sex,
				ROUND(AVG(unemployment_rate) :: DECIMAL (10,2),2) AS f_rate
		FROM global_data 
		WHERE sex = 'Female'
			AND age = '15+'
		GROUP BY country,region, sex),
male AS (
		SELECT country,
				sex,
				ROUND(AVG(unemployment_rate) :: DECIMAL (10,2),2) AS m_rate
		FROM global_data  
		WHERE sex = 'Male'
			AND age = '15+'
		GROUP BY country, sex)
SELECT f.country,
		f.region,
		f.f_rate,
		m.m_rate,
		ROUND((f.f_rate - m.m_rate) :: DECIMAL (10,2),2) AS gender_gap,
		ROUND(((f.f_rate - m.m_rate)/m.m_rate) :: DECIMAL (10,2),2) AS gap_percentage
FROM female f
LEFT JOIN male m ON f.country = m.country
WHERE region IS NOT NULL
ORDER BY gender_gap DESC;

-- Has this gap narrowed significantly since 1991?

WITH female AS (
		SELECT ROW_NUMBER() OVER() AS row_f,
				country,
				YEAR,
				ROUND(AVG(unemployment_rate):: DECIMAL (10,2),2) AS f_rate
		FROM global_data  
		WHERE sex = 'Female' AND age = '15+'
		GROUP BY country, year),
	male AS (
		SELECT ROW_NUMBER() OVER() AS row_m,
				country,
				YEAR,
				ROUND(AVG(unemployment_rate) :: DECIMAL (10,2),2) AS m_rate
		FROM global_data  
		WHERE sex = 'Male' AND age = '15+'
		GROUP BY country, year)
SELECT f.country,
		f.YEAR,
		f.f_rate,
		m.m_rate,
		f.f_rate - m.m_rate AS gender_gap,
		f.f_rate - m.m_rate/m.m_rate AS gap_percentage
FROM female f
LEFT JOIN male m ON f.row_f = m.row_m
ORDER BY country, YEAR;

--Which countries have experienced the highest volatility (frequent spikes and drops) in unemployment rates over the last 30 years? 
WITH cte_1 AS (
			SELECT country, 
				 ROUND(AVG(unemployment_rate)::NUMERIC,2) AS avg_rate
			FROM global_data
			WHERE sex = 'Total' AND age = '15+'
			GROUP BY country),
	cte_2 AS(	
			SELECT country, 
			ROUND(MAX(unemployment_rate)::NUMERIC, 2) AS highest_rate,
			ROUND(MIN(unemployment_rate):: NUMERIC, 2) AS lowest_rate,
			ROUND(CAST(MAX(unemployment_rate) - MIN(unemployment_rate) AS DECIMAL(10,2)),2) AS gap_rate
			FROM (SELECT country, YEAR, AVG(unemployment_rate) AS unemployment_rate
	  			  FROM global_data 
	  			  WHERE sex = 'Total' AND age = '15+'
	  			  GROUP BY country, YEAR)	  
			WHERE country IS NOT NULL 
			GROUP BY country)
SELECT cte_1.country, 
	   cte_2.highest_rate,
	   cte_2.lowest_rate,
	   cte_1.avg_rate,
	   cte_2.gap_rate,
	   ROUND(CAST(cte_2.gap_rate/cte_1.avg_rate AS DECIMAL(10,2)), 2) AS relative_volatility
FROM cte_1 
JOIN cte_2 ON cte_1.country = cte_2.country
ORDER BY relative_volatility DESC;
				  

-- TOP countries unemployment recovery rate after 5 year from Pandemic (2020) 
WITH un_2020 AS (SELECT country, 
						AVG(unemployment_rate) AS unemployment_2020
				FROM global_data 
				WHERE YEAR = 2020 AND sex = 'Total' AND age = '15+'
				GROUP BY country, YEAR),
	un_2025 AS (SELECT country, 
						AVG(unemployment_rate) AS unemployment_2025
				FROM global_data  
				WHERE YEAR = 2025 AND sex = 'Total' AND age = '15+'
				GROUP BY country, YEAR)			
SELECT  un_2020.country, 
		ROUND(un_2020.unemployment_2020 :: DECIMAL (10,2), 2) AS unemployment_2020, 
		ROUND(un_2025.unemployment_2025 :: DECIMAL (10,2), 2) AS unemployment_2025,
		ROUND(((un_2025.unemployment_2025 - un_2020.unemployment_2020)/un_2020.unemployment_2020) :: DECIMAL (10,2),2) AS recovery_rate
FROM un_2020 
LEFT JOIN un_2025 ON un_2020.country = un_2025.country
WHERE unemployment_2025 IS NOT NULL
ORDER BY recovery_rate DESC;

							