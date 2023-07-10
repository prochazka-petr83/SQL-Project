/*
 * Výzkumné otázky:
 * 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
 */

CREATE OR REPLACE TABLE t_petr_prochazka_SQL_project_primary_final AS SELECT 
cpib.name AS industry_name, 
cpib.code AS industry_code, 
cp.value , 
cp.payroll_year
FROM czechia_payroll cp 
JOIN czechia_payroll_industry_branch cpib ON cp.industry_branch_code = cpib.code 
WHERE value_type_code = 5958 AND value IS NOT NULL AND cpib.code IS NOT NULL
GROUP BY cpib.name , cp.payroll_year 

SELECT * FROM t_petr_prochazka_SQL_project_primary_final

CREATE OR REPLACE VIEW t_test AS 
SELECT 
t1.*, 
t1.payroll_year +1 AS next_year, 
round ((t1.value-t2.value)/t2.value*100,2) AS growth
FROM t_petr_prochazka_sql_project_primary_final t1
JOIN t_petr_prochazka_sql_project_primary_final t2 ON t1.payroll_year = t2.payroll_year + 1 
GROUP BY t1.industry_name, t1.payroll_year ;

SELECT * FROM t_test tt WHERE growth <0;


/*
 *2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
 */

SELECT 
cpc.name AS product,
round (avg(cp.value),2) AS unit_price,
round (avg(cp2.value),2) AS average_payroll,
cp2.payroll_year ,
cpib.name AS branch_name,
round (avg(cp2.value) /avg(cp.value),2) AS  quantity
FROM czechia_price cp 
JOIN czechia_price_category cpc ON cp.category_code = cpc.code 
AND cpc.code = 111301 OR cpc.code = 114201
AND cp.region_code IS NULL 
JOIN czechia_payroll cp2 ON YEAR (cp.date_from) = cp2.payroll_year 
JOIN czechia_payroll_industry_branch cpib ON cp2.industry_branch_code = cpib.code 
AND cp2.value_type_code = 5958
GROUP BY cp2.payroll_year, cpc.name, cpib.name 
ORDER BY cp2.payroll_year; 


/*
 * 3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
 */

CREATE OR REPLACE VIEW t_test2 AS
SELECT 
cpc.name AS food_category,
round(avg(cp.value) - lag(avg(cp.value),1) OVER (ORDER BY YEAR (cp.date_from))/ lag(avg(cp.value), 1) OVER (ORDER BY YEAR (cp.date_from) * 100),2) AS price_growth,
YEAR (cp.date_from) AS beginning_year
FROM czechia_price cp 
JOIN czechia_price_category cpc ON cp.category_code = cpc.code 
GROUP BY cpc.name, year(cp.date_from)

SELECT * FROM t_test2 tt 

SELECT food_category,round(avg(price_growth),2) AS average_growth
FROM t_test2 tt 
GROUP BY food_category

/*
 * 4.Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
 */

/*
 * Růst mezd:
 */
CREATE OR REPLACE VIEW t_test3 AS 
SELECT 
avg(cp.value) AS average_payroll,
cp.payroll_year 
FROM czechia_payroll cp 
JOIN czechia_payroll_value_type cpvt ON cp.value_type_code = cpvt.code AND cpvt.code = 5958
GROUP BY cp.payroll_year 

SELECT 
payroll_year,
round((average_payroll - lag(average_payroll,1) OVER (ORDER BY payroll_year))/ lag(average_payroll,1) OVER (ORDER BY payroll_year) * 100,2) AS payroll_growth
FROM t_test3

/*
 * Růst cen potravin:
 */

CREATE OR REPLACE VIEW t_test4 AS 
SELECT 
round(avg(cp.value),2) AS average_price,
YEAR (cp.date_from) AS beginning_year
FROM czechia_price cp 
GROUP BY YEAR(cp.date_from)

SELECT 
beginning_year,
round((average_price - lag(average_price,1) OVER (ORDER BY beginning_year))/ lag(average_price,1) OVER (ORDER BY beginning_year) * 100,2) AS price_growth
FROM t_test4

/* 
 * Porovnání růstu cen potravin a mezd:
 */

CREATE OR REPLACE VIEW t_test5 AS 
SELECT 
payroll_year,
round((average_payroll - lag(average_payroll,1) OVER (ORDER BY payroll_year))/ lag(average_payroll,1) OVER (ORDER BY payroll_year) * 100,2) AS payroll_growth,
round((average_price - lag(average_price,1) OVER (ORDER BY beginning_year))/ lag(average_price,1) OVER (ORDER BY beginning_year) * 100,2) AS price_growth
FROM t_test3
JOIN t_test4 ON payroll_year = beginning_year 

SELECT *,
price_growth - payroll_growth AS difference 
FROM t_test5


/*
 * 5. Má výška HDP vliv na změny ve mzdách a cenách potravin? 
 * Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo násdujícím roce výraznějším růstem?
 */
CREATE OR REPLACE TABLE t_petr_prochazka_SQL_project_secondary_final AS SELECT
e.`year`, 
e.GDP,
round((e.GDP - lag (e .GDP, 1) OVER (ORDER BY e.`year`))/ lag(e.GDP, 1) OVER (ORDER BY e.`year`) * 100,2) AS GDP_growth 
FROM economies e
WHERE e.GDP IS NOT NULL AND e.country = 'Czech Republic' 
GROUP BY e.`year`


SELECT * FROM t_test5 tt
JOIN t_petr_prochazka_sql_project_secondary_final tp ON tt.payroll_year = tp.`year`  

 




