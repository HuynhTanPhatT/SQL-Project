select *
from [Porfolio Project].[dbo].[CovidDeaths$]
order by 3,4

select location,
date,
new_cases,
total_cases,
new_deaths,
total_deaths,
population
From [Porfolio Project].[dbo].[CovidDeaths$]
ORDER BY 1,2
						--( the number of deaths / number of cases = case fatality rate)
select location, date, total_cases, total_deaths, (total_deaths/total_cases) as Case_Fatality_Rate
From [Porfolio Project].[dbo].[CovidDeaths$]
--WHERE location like '%States%'
ORDER BY 1,2

--Show what percentage of Population got covid
select location, date, population, total_cases, (total_cases/ population)*100 as Population_Infected_Percentage --rate of inflection
From [Porfolio Project].[dbo].[CovidDeaths$]
--where location in ('United States')
order by 1,2--Highest infection rate combined with  population

select location, population, MAX(total_cases) as HighestInfectionCount, Max((total_cases/ population))*100 as HighestInfected_Percent
From [Porfolio Project].[dbo].[CovidDeaths$]
GROUP BY location, population
order by [HighestInfected_Percent] DESC;  

-- Showing countries or continent with highest Death Count per Population
select location,population,max(cast(total_deaths as INT)) as TotalDeathCount
From [Porfolio Project].[dbo].[CovidDeaths$]
where continent is not null
group by location,population
order by [TotalDeathCount] DESC;

-- Break things down with continent
select continent, max(cast(total_deaths as INT)) as TotalDeathCount
From [Porfolio Project].[dbo].[CovidDeaths$] 
where continent is not null
group by continent
order by [TotalDeathCount] DESC;

-- Showing the continents with the highest death count per population
select continent, population, (max(cast(total_deaths as INT)) / population )*100 as DeathPercent
From [Porfolio Project].[dbo].[CovidDeaths$] 
Where continent is not null
group by continent, population
order by DeathPercent DESC

--Global numbers
select cast(date as DATE) as InflectionDate,
max(cast(total_deaths as INT)) as TotalDeaths,max(total_cases) as TotalCases, (sum(cast(total_deaths as INT)) / sum(total_cases))*100 as DeathPercentage
From [Porfolio Project].[dbo].[CovidDeaths$] 
where continent is not null
Group by cast(date as DATE)
order by 1,2 DESC

select *
FROM [Porfolio Project].[dbo].[CovidVaccinations$]
order by 3,4

--Calculate the total vaccinations in each continent
select vac.continent,
max(cast(total_vaccinations as INT)) as total_vaccinations
from [Porfolio Project].[dbo].[CovidVaccinations$] vac
--where continent is not null
group by continent

--Created-New vaccinations per days
select dea.continent, dea.location,dea.date,
vac.new_vaccinations,
sum(cast(vac.new_vaccinations as INT)) over (Partition By dea.location order by dea.location, dea.date) as RollingPeopleVaccinated  
--(RollingPeopleVaccinated / population)*100                           
From [Porfolio Project].[dbo].[CovidDeaths$]  dea                                                 
	Inner Join [Porfolio Project].[dbo].[CovidVaccinations$] vac
	ON dea.location = vac.location and dea.date = vac.date
where dea.continent is not null  
ORDER BY 2,3


--CTE of RollingPeopleVaccinated 
with PercentVaccinated (
continent,location,date,population, new_vaccinations,
RollingPeopleVaccinated
)
as (
	select dea.continent, dea.location,dea.date, dea.population,
			vac.new_vaccinations, 
			sum(cast(vac.new_vaccinations as INT )) over (Partition By dea.location order by dea.location, dea.date) as RollingPeopleVaccinated  
	From [Porfolio Project].[dbo].[CovidDeaths$]  dea                                                 
	Join [Porfolio Project].[dbo].[CovidVaccinations$] vac
		ON dea.location = vac.location and dea.date = vac.date
	where dea.continent is not null  
)
select *, (RollingPeopleVaccinated / population)*100 as PercentPeopleVaccinated
FROM PercentVaccinated
order by 2,3 asc;

-- Create a  table
Drop table if exists #PercentVaccinated
create TABLE #PercentVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)
-- Import and transport data
insert into #PercentVaccinated ( dea.continent, dea.location,dea.date,dea.population,vac.new_vaccinations , vac.RollingPeopleVaccinated )
	select dea.continent, dea.location,dea.date, dea.population,
			vac.new_vaccinations, 
			sum(cast(vac.new_vaccinations as INT )) over (Partition By dea.location order by dea.location, dea.date) as RollingPeopleVaccinated  
	From [Porfolio Project].[dbo].[CovidDeaths$]  dea                                                 
	Join [Porfolio Project].[dbo].[CovidVaccinations$] vac
		ON dea.location = vac.location and dea.date = vac.date
	where dea.continent is not null  
select *, (RollingPeopleVaccinated / population)*100 as PercentPeopleVaccinated
FROM #PercentVaccinated
order by 2,3 asc;

--Create view
USE [Porfolio Project]
GO
Create View PercentVaccinated_1 as 
	select dea.continent, dea.location,dea.date, dea.population,
			vac.new_vaccinations, 
			sum(cast(vac.new_vaccinations as INT )) over (Partition By dea.location order by dea.location, dea.date) as RollingPeopleVaccinated  
	From [Porfolio Project].[dbo].[CovidDeaths$]  dea                                                 
	Join [Porfolio Project].[dbo].[CovidVaccinations$] vac
		ON dea.location = vac.location and dea.date = vac.date
	where dea.continent is not null

USE [Porfolio Project]
Go
Create View GlobalNumbers as
select cast(date as DATE) as InflectionDate,
max(cast(total_deaths as INT)) as TotalDeaths,max(total_cases) as TotalCases, (sum(cast(total_deaths as INT)) / sum(total_cases))*100 as DeathPercentage
From [Porfolio Project].[dbo].[CovidDeaths$] 
where continent is not null
Group by cast(date as DATE)
















