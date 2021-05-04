select *
from PortfolioProject..CovidDeaths$
order by 3,4

select *
from PortfolioProject..CovidVaccinations$
order by 3,4

--select data that we are going to be using

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths$
order by 1,2

-- looking at total cases vs total deaths
-- shows the likelihood of dying if you contract covid in your country
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100.0 as DeathPercent
from PortfolioProject..CovidDeaths$
where location like '%states'
order by 1,2

--looking at total cases vs population
select location, date, total_cases, population, (total_cases/population)*100.0 as CovidcasePercent
from PortfolioProject..CovidDeaths$
where location = 'India'
order by 1,2

--countries with the highest infection rate compared to population

select location, population, max(total_cases) as HighestInfectionCount, max((total_cases/population))*100.0 as InfectionPercent
from PortfolioProject..CovidDeaths$
group by location, population
order by InfectionPercent desc


-- countries with the highgest death counts per poulation

select location, max(cast(total_deaths as int)) as HighestDeathCount
from PortfolioProject..CovidDeaths$
where continent is not null   -- this helps in grouping out the countries only excluding the continents
group by location
order by HighestDeathCount desc 

-- let's break things down by continent

select location, max(cast(total_deaths as int)) as HighestDeathCount
from PortfolioProject..CovidDeaths$
where continent is null   
group by location
order by HighestDeathCount desc

-- showing the continent with the highest death count per population

select continent, max(cast(total_deaths as int)) as HighestDeathCount
from PortfolioProject..CovidDeaths$
where continent is not null   
group by continent
order by HighestDeathCount desc

--global numbers

-- per day deaths to cases 
select date, sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100.0  as DeathPercent
from PortfolioProject..CovidDeaths$
where continent is not null
group by date
order by 1,2

--overall deaths to cases
select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100.0  as DeathPercent
from PortfolioProject..CovidDeaths$
where continent is not null
order by 1,2



--looking at total populations vs vaccinations

select dea.continent, dea.location, dea.date, population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int))over(partition by dea.location order by dea.location, dea.date) as RollingCountVaccinations,
from PortfolioProject..CovidDeaths$ as dea
inner join PortfolioProject..CovidVaccinations$ as vac
on dea.location=vac.location
and dea.date=vac.date
where dea.continent is not null
order by 2,3


-- USE CTE

with PopvsVac as 
(
select dea.continent, dea.location, dea.date, population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int))over(partition by dea.location order by dea.location, dea.date) as RollingCountVaccinations
from PortfolioProject..CovidDeaths$ as dea
inner join PortfolioProject..CovidVaccinations$ as vac
on dea.location=vac.location
and dea.date=vac.date
where dea.continent is not null
--order by 2,3
)
select *, (RollingCountVaccinations/population)*100.0 as PercentVaccinated
from PopvsVac


--country with the max percent vaccination

with PopvsVac as 
(
select dea.continent, dea.location, dea.date, population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int))over(partition by dea.location order by dea.location, dea.date) as RollingCountVaccinations
from PortfolioProject..CovidDeaths$ as dea
inner join PortfolioProject..CovidVaccinations$ as vac
on dea.location=vac.location
and dea.date=vac.date
where dea.continent is not null
--order by 2,3
)
select location, max((RollingCountVaccinations/population)*100.0) as MaxPercentVaccinated
from PopvsVac
group by location
order by MaxPercentVaccinated desc

--here we can see some countries have their vaccinations percentage above 100. This might be because the double dose of a single person is counted as 2 rather than 1.

-- TEMP	 TABLE

drop table if exists #PercentPeopleVaccinated
create table #PercentPeopleVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingCountVaccinations numeric
)

insert into #PercentPeopleVaccinated
select dea.continent, dea.location, dea.date, population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int))over(partition by dea.location order by dea.location, dea.date) as RollingCountVaccinations
from PortfolioProject..CovidDeaths$ as dea
inner join PortfolioProject..CovidVaccinations$ as vac
on dea.location=vac.location
and dea.date=vac.date
where dea.continent is not null
--order by 2,3

select *, (RollingCountVaccinations/population)*100.0 as PercentVaccinated
from #PercentPeopleVaccinated

--creating view to store data for later visualisation

create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int))over(partition by dea.location order by dea.location, dea.date) as RollingCountVaccinations
from PortfolioProject..CovidDeaths$ as dea
inner join PortfolioProject..CovidVaccinations$ as vac
on dea.location=vac.location
and dea.date=vac.date
where dea.continent is not null
--order by 2,3

select *
from PercentPopulationVaccinated