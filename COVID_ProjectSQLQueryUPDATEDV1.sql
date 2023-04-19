SELECT *
FROM [COVID Project]..CovidDeaths$
ORDER BY 3,4

SELECT *
FROM [COVID Project]..CovidVaccinations$
ORDER BY 3,4

--Lets select the data we will use for this project!

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [COVID Project]..CovidDeaths$
ORDER BY 1,2

--Now lets see the correlation, Total Cases in correlation to Total Deaths

SELECT location, date, total_cases, (total_deaths/total_cases)*100 AS MortalityRate
FROM [COVID Project]..CovidDeaths$
ORDER BY 1,2

--Furthermore, lets see the Mortality Rate in areas we are curious about such as the United States

SELECT location, date, total_cases, (total_deaths/total_cases)*100 AS MortalityRate
FROM [COVID Project]..CovidDeaths$
WHERE location like '%States%'
ORDER BY 1,2

--Now lets see the amount of the population that has been infected in our hometown, the United States

SELECT location, date, total_cases, population, (total_cases/population)*100 AS ConfirmedInfectedPercent
FROM [COVID Project]..CovidDeaths$
WHERE location like '%States%'
ORDER BY 1,2

--Interesting! Lets see how countries with the highest infection count in proportion to population compare

SELECT location, population, MAX(total_cases) AS LargestInfectionCount, MAX(total_cases/population)*100 AS ConfirmedInfectedPercent
FROM [COVID Project]..CovidDeaths$
GROUP BY location, population,
ORDER BY ConfirmedInfectedPercent DESC

--Looks like the United States takes the 9th spot for countries with the highest infection count in proportion to population


--Does infection rate translate to mortalities? Lets see the mortality count in proportion to population in each country

SELECT location, MAX(CAST(total_deaths AS INT)) AS MortalityCount
FROM [COVID Project]..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY MortalityCount DESC

--The United States ranks #1 for total mortality count

--Lets go one step further and see the mortality count per continent

SELECT continent, MAX(CAST(total_deaths AS INT)) AS MortalityCount
FROM [COVID Project]..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY MortalityCount DESC

--Now lets look at the impacts of COVID globally by date

SELECT date,
SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS INT)) AS TotalDeaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS MortalityRate
FROM [COVID Project]..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

--Lets see vaccinations in proportion to population

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM [COVID Project]..CovidDeaths$ dea
JOIN [COVID Project]..CovidVaccinations$ vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--Lets visualize this better, lets see the amouunt of new vaccinations per day along with the rolling total Vaccination Count

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVacCount
FROM [COVID Project]..CovidDeaths$ dea
JOIN [COVID Project]..CovidVaccinations$ vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--Lets create a temp table in order to take this further and analyze the rolling number of new vaccinations and total world percentage of vaccinations
DROP TABLE IF EXISTS #PercentofPopulationVaccinated
CREATE TABLE #PercentofPopulationVaccinated

(continent nvarchar(255), 
location nvarchar(255), 
date datetime, population numeric, 
new_vaccinations numeric, 
RollingVacCount numeric)
INSERT INTO #PercentofPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVacCount
FROM [COVID Project]..CovidDeaths$ dea
JOIN [COVID Project]..CovidVaccinations$ vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

SELECT *, (RollingVacCount/population)*100 
FROM #PercentofPopulationVaccinated




--Lets create a view of our data

DROP VIEW IF EXISTS PercentofPopulationVaccinated

GO
CREATE VIEW PercentofPopulationVaccinated AS

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVacCount
FROM [COVID Project]..CovidDeaths$ dea
JOIN [COVID Project]..CovidVaccinations$ vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GO

SELECT * 
FROM PercentofPopulationVaccinated
