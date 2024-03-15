
SELECT *
FROM [dbo].[CovidDeaths]
WHERE [continent] IS NOT NULL
ORDER BY 3,4;

--Choose the data set for use.

SELECT location, 
date, 
total_cases, 
new_cases, 
total_deaths,
population
FROM [dbo].[CovidDeaths]
WHERE [continent] IS NOT NULL
ORDER BY 1,2;

--Analyzing the correlation between total cases and total deaths (Turkey).

SELECT 
location, 
date, 
total_cases, 
total_deaths,
FORMAT((CAST(total_deaths AS float) / NULLIF(total_cases, 0)) * 100, '0.0000') AS DeathPercentage
FROM [dbo].[CovidDeaths]
WHERE location = 'Turkey' AND 
[continent] IS NOT NULL
ORDER BY 1,2;

--Comparing the total number of cases with the population (Turkey).

SELECT
location,
date,
total_cases,
population,
FORMAT(CAST(total_cases AS float) / (CAST(population AS float))*100, '0.0000') AS PercentPopulationInfected
FROM [dbo].[CovidDeaths]
WHERE location LIKE '%Turkey%' 
AND [continent] IS NOT NULL
ORDER BY 1,2;

--Analyzing countries with the highest infection rates relative to their populations (Turkey).

SELECT
location,
population,
MAX(total_cases) AS the_peak_infection_count,
MAX(CAST(total_cases AS float) / CAST(population AS float) * 100) AS PercentPopulationInfected
FROM [dbo].[CovidDeaths]
WHERE [continent] IS NOT NULL
--WHERE location = 'Turkey'
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

--Presenting nations with the greatest number of deaths relative to their populations.

SELECT
location,
MAX(cast(Total_Deaths as int)) AS Total_Death_Count
FROM [dbo].[CovidDeaths]
WHERE [continent] IS NOT NULL
GROUP BY location
ORDER BY Total_Death_Count DESC;

--Presenting continents with the greatest number of deaths per capita.

SELECT
continent,
MAX(cast(Total_Deaths as int)) AS Total_Death_Count
FROM [dbo].[CovidDeaths]
WHERE [continent] IS NOT NULL
GROUP BY continent
ORDER BY Total_Death_Count DESC;

--Global totals.

SELECT 
date,
SUM(ISNULL(CAST(new_cases AS int), 0)) AS total_cases, 
SUM(ISNULL(CAST(new_deaths AS int), 0)) AS total_deaths,
(SUM(ISNULL(CAST(new_deaths AS float), 0))/NULLIF(SUM(ISNULL(CAST(new_cases AS float), 0)), 0)) * 100 AS DeathPercentage
FROM [dbo].[CovidDeaths]
WHERE[continent] IS NOT NULL
AND location ='Turkey'
GROUP BY [date]
ORDER BY [date];

--Analyzing the relationship between total population and vaccination rates.
--Displaying the proportion of the population that has been partially vaccinated against COVID-19.

SELECT 
dea.continent,
dea.location,
dea.date,
dea.population,
vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS ongoing_vaccination_progress
FROM [dbo].[CovidDeaths] dea
JOIN [dbo].[CovidVaccinations] vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--Use CTE

WITH population_vs_vaccinated
(continent,
location,
date,
population,
new_vaccinations,
ongoing_vaccination_progress)
AS
(
SELECT 
dea.continent,
dea.location,
dea.date,
dea.population,
vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS float))OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS ongoing_vaccination_progress
FROM [dbo].[CovidDeaths] dea
JOIN [dbo].[CovidVaccinations] vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, 
FORMAT((ongoing_vaccination_progress/population)*100, '0.000') AS how_many_people_vaccinated
FROM population_vs_vaccinated;

--Session specific table

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
ongoing_vaccination_progress numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT 
dea.continent, 
dea.location, 
dea.date, 
dea.population, 
vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) AS ongoing_vaccination_progress
FROM [dbo].[CovidDeaths] dea
JOIN [dbo].[CovidVaccinations] vac
	ON dea.location = vac.location
	AND dea.date = vac.date

SELECT *, (ongoing_vaccination_progress/Population)*100
FROM #PercentPopulationVaccinated;

-- Creating View to store data for Tableau

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, 
dea.location, 
dea.date, 
dea.population, 
vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) AS ongoing_vaccination_progress
FROM [dbo].[CovidDeaths] dea
JOIN [dbo].[CovidVaccinations] vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT * 
FROM PercentPopulationVaccinated;


