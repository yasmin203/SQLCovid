SELECT * FROM CovidPortfolioProject..CovidDeaths
order by 3,4
--SELECT * FROM dbo.CovidVaccination order by 3,4

--selecting data that i will be using 

SELECT location,date,total_cases,new_cases,total_deaths,population
FROM CovidPortfolioProject..CovidDeaths Order By 1,2

--Selecting total cases Vs total death
SELECT location,date,total_cases,new_cases,total_deaths,
(CONVERT(float,total_deaths)/NULLIF(CONVERT(float,total_cases),0))*100 as death_percentage
FROM CovidPortfolioProject..CovidDeaths  Order By 1,2 
-- it is preaty accurate accourding to --https://www.worldometers.info/coronavirus/country/egypt 
SELECT location,date,total_cases,new_cases,total_deaths,(CONVERT(float,total_deaths)/NULLIF(CONVERT(float,total_cases),0))*100 as death_percentage
FROM CovidPortfolioProject..CovidDeaths WHERE location LIKE '%egypt%' Order By 1,2 

--Total Cases vs Population 
SELECT location,date,population,total_cases,
(CONVERT(float,total_cases)/NULLIF(CONVERT(float,population),0))*100 as TotalCasesPerPopulationPercentage
FROM CovidPortfolioProject..CovidDeaths WHERE location LIKE '%egypt%'  Order By 1,2 

--Total Cases vs Population 
SELECT location, date, population, total_cases,
(CONVERT(float,total_cases)/CONVERT(float,population))*100 AS TotalCasesPerPopulationPercentage,
dense_rank() OVER (PARTITION BY location ORDER BY total_cases desc) AS RankNumber
FROM CovidPortfolioProject..CovidDeaths

 

--Looking At Countries with Highst Infections Rate Compared To Population 
SELECT location,population,MAX(total_cases) as HieghestInfectionCount,
MAX((CONVERT(float,total_cases)/(NULLIF(CONVERT(float,population),0)))*100) as PercentageHighestInfectedCountries
FROM CovidPortfolioProject..CovidDeaths 
GROUP BY location,population
Order By PercentageHighestInfectedCountries desc

--Showing The Countries With Hieghest death count compared to population

SELECT location,MAX(cast(total_deaths as bigint)) as HieghestDeathsCount
FROM CovidPortfolioProject..CovidDeaths 
where continent is not null 
GROUP BY location
Order By HieghestDeathsCount desc

--Showing Total Deaths By Continent

SELECT continent,MAX(cast(total_deaths as bigint)) as DeathsCountPerContinent
FROM CovidPortfolioProject..CovidDeaths 
where continent is not null 
GROUP BY continent
Order By DeathsCountPerContinent desc


--death Count Per Continent
SELECT location,date,population,total_cases,
(CONVERT(float,total_cases)/NULLIF(CONVERT(float,population),0))*100 as TotalCasesPerPopulationPercentage
FROM CovidPortfolioProject..CovidDeaths 
WHERE location LIKE '%egypt%'  
Order By 1,2 

--Global Numbers
SELECT date AS Date, sum(cast(new_deaths as float)) AS TotalDeaths, sum(cast(new_cases as float)) AS TotalCases,
(sum(cast(new_deaths as float)) / sum(cast(new_cases as float)))*100 AS PercentageOfDeaths
FROM CovidPortfolioProject..CovidDeaths 
WHERE continent IS NOT NULL
GROUP BY date 
HAVING sum(cast(new_cases as float)) <> 0 
ORDER BY 1,2

--Total Deaths and Total Cases and the Deaths Percentage 
SELECT  sum(cast(new_deaths as float)) AS TotalDeaths, sum(cast(new_cases as float)) AS TotalCases,
(sum(cast(new_deaths as float)) / sum(cast(new_cases as float)))*100 AS PercentageOfDeaths
FROM CovidPortfolioProject..CovidDeaths 
WHERE continent IS NOT NULL
--GROUP BY date 
HAVING sum(cast(new_cases as float)) <> 0 
ORDER BY 1,2

 
--joining the two tables

SELECT * 
FROM CovidPortfolioProject..CovidDeaths as dea
join CovidPortfolioProject..CovidVaccination as vac
	on dea.location=vac.location 
	and dea.date=vac.date

---showing total people who have been vaccinated
SELECT dea.continent,dea.location,dea.population,vac.new_vaccinations,SUM(CONVERT(bigint,vac.new_vaccinations))
OVER(PARTITION BY dea.location
ORDER BY dea.location,dea.date desc ) AS RollingPeopleVaccinated
FROM CovidPortfolioProject..CovidDeaths AS dea
JOIN CovidPortfolioProject..CovidVaccination AS vac
	ON dea.location=vac.location 
	and dea.date=vac.date
	WHERE dea.continent is not null
	ORDER BY 2,3
---USING CTE
WITH PopvsVac (Continent,Location,Population,Date,new_vaccinations,RollingPeopleVaccinated)
as
(
SELECT dea.continent,dea.location,dea.population,dea.date,vac.new_vaccinations,SUM(CONVERT(bigint,vac.new_vaccinations))
OVER(PARTITION BY dea.location
ORDER BY dea.location,dea.date desc ) AS RollingPeopleVaccinated
FROM CovidPortfolioProject..CovidDeaths AS dea
JOIN CovidPortfolioProject..CovidVaccination AS vac
	ON dea.location=vac.location 
	and dea.date=vac.date
	WHERE dea.continent is not null
	--ORDER BY 2,3

)
select * ,(RollingPeopleVaccinated/Population)*100
from PopvsVac 

-- TEMP TABLE
-- Drop the temporary table if it exists
DROP TABLE IF EXISTS #PercentagePopulationVaccination;

-- Create the temporary table with the proper data types and column names
CREATE TABLE #PercentagePopulationVaccination
( continent nvarchar(255),
  location nvarchar(255),
  date datetime,
  population float,
  new_vaccinations float,
  RollingPeopleVaccinated float
);

-- Insert data into the temporary table from the join of CovidDeaths and CovidVaccination tables
-- Use aliases for the tables and columns to make the query more readable and consistent
-- Use the correct column names for the join condition and the order by clause
INSERT INTO #PercentagePopulationVaccination
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
  SUM(convert(float,vac.new_vaccinations))
  OVER(PARTITION BY dea.location
       ORDER BY dea.location, dea.date DESC) AS RollingPeopleVaccinated
FROM CovidPortfolioProject..CovidDeaths AS dea
JOIN CovidPortfolioProject..CovidVaccination AS vac
  ON dea.location = vac.location 
  AND dea.date = vac.date;

-- Select data from the temporary table and calculate the percentage of population vaccinated
-- Use parentheses around the division operation to ensure the correct order of evaluation
SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentageOfPopulationVaccinated
FROM #PercentagePopulationVaccination;

--Creating view for later visualization
create view  PercentagePopulationVaccination as
SELECT dea.continent,dea.location,dea.population,dea.date,vac.new_vaccinations,SUM(CONVERT(bigint,vac.new_vaccinations))
OVER(PARTITION BY dea.location
ORDER BY dea.location,dea.date desc ) AS RollingPeopleVaccinated
FROM CovidPortfolioProject..CovidDeaths AS dea
JOIN CovidPortfolioProject..CovidVaccination AS vac
	ON dea.location=vac.location 
	and dea.date=vac.date
	WHERE dea.continent is not null
	--ORDER BY 2,3
select * from PercentagePopulationVaccination