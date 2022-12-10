/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/


select * 
from PortfolioProject.dbo.FcovidDeath
where continent is not null
order by location, date				-- [order by 3,4]: 테이블의 3,4번째 컬럼 기준으로 정렬하겠다는 말
									-- [order by name, name] : name으로 지정해놔야 나중에 변경사항있을 때 혼동안되고 좋다.


select * 
from PortfolioProject.dbo.FcovidVaccination
order by location, date		


select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject.dbo.FcovidDeath
where continent is not null
order by  location, date



	--Looking at Total Cases vs Total Deaths
	--Likelihood of dying if you contract covid in your country

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage		--Aliasing
from PortfolioProject.dbo.FcovidDeath
where location like '%korea%' and continent is not null
order by  location, date



	--Looking at Total Cases vs Population
	--shows what percentage of population got covid

select location, date, population, total_cases, (total_cases/population)*100 as PercentagePopulationInfected		--Aliasing
from PortfolioProject.dbo.FcovidDeath
--where location like '%korea%'
where continent is not null
order by  location, date



	--Looking at Countries with Highest Infection Rate compared to Population

select location, population, MAX( total_cases) as HighestInfectionCount, MAX(total_cases/population)*100 as PercentagePopulationInfected		--Aliasing
from PortfolioProject.dbo.FcovidDeath
where continent is not null
group by location, population
order by  PercentagePopulationInfected desc



	--look at how many people actually died 
	--showing countries with highest death count per population

select location, population, MAx(cast(total_deaths as int)) as TotalDeath, max(cast(total_deaths as int)/population*100) as PercentagePopulationDeath	--Aliasing
from PortfolioProject.dbo.FcovidDeath
where continent is not null
group by location , population
order by PercentagePopulationDeath desc --PercentagePopulationDeath desc

		--import한 total_deaths(nvarchar(255),null) :navarchar-문자형태라 cast로 data type을 int로 변경해줘야 결과값이 제대로 나온다.
		--MAx(cast(total_deaths as int))



	-- it's breaking it out by continents -TotalDeath
	--Showing continents with the highest death count per population - deathRate

select continent, MAx(cast(total_deaths as int)) as TotalDeath, max(cast(total_deaths as int)/population*100) as PercentagePopulationDeath	--Aliasing
from PortfolioProject.dbo.FcovidDeath
where continent is not null
group by continent
order by PercentagePopulationDeath desc




	--Global numbers

select /*date,*/ sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, 
				(sum(cast(new_deaths as int))/sum(new_cases))*100 as DeathPercentage		--Aliasing
from PortfolioProject.dbo.FcovidDeath
where continent is not null
--group by date
order by 1,2

		--Function안에 function기능은 못쓴다.ex) sum(max(totla_cases))
		--the sum of all the new cases which adds up to the total cases 


	--Looking at Total Population vs Vaccinations

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	,Sum(cast(vac.new_vaccinations as bigint)) over (Partition by dea.location order by dea.location,dea.date)
	as RollingPeopleVaccinated
													--location에 의해 Sum구분
													--order by location/date해야 날짜별로 잘 구분되게 나온다.
from PortfolioProject.dbo.FcovidDeath dea
join PortfolioProject.dbo.FcovidVaccination vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null
order by 2,3
				--data tye 변환 : cast or convert 로
				-->cast(vac.new_vaccinations as int) or convert(int, vac.new_vaccionations)




		--CTE 설정 및 이용 :RollingPeopleVaccinated를 table로 간단히 이용해서 rate구하려고		
		--Looking at Total Population vs Vaccinations
with PopvsVcc(continent,location,date,population,new_vaccination, RollingPeopleVaccinted)	--아래column 수6개 일치하게 작성해야한다.
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	,Sum(cast(vac.new_vaccinations as bigint)) over (Partition by dea.location order by dea.location,dea.date)
	as RollingPeopleVaccinated

from PortfolioProject.dbo.FcovidDeath dea
join PortfolioProject.dbo.FcovidVaccination vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
) 
select *, (RollingPeopleVaccinted/population)*100 as PercentPeopleVaccinated
from PopvsVcc



		
		--TEMP TABLE 이용하는방법 ::RollingPeopleVaccinated를 table로 간단히 이용해서 rate구하려고	

Drop table if exists #PercentPopulationVaccinated	-- I highly recommend just adding this
create table #PercentPopulationVaccinated
(
continent nvarchar(255),			--아래column 수6개 일치하게 작성해야한다.
location nvarchar(255),			-- we have to specify the data type
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric

)
Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	,Sum(cast(vac.new_vaccinations as bigint)) over (Partition by dea.location order by dea.location,dea.date)
	as RollingPeopleVaccinated
													--location에 의해 Sum구분
													--order by location/date해야 날짜별로 잘 구분되게 나온다.
from PortfolioProject.dbo.FcovidDeath dea
join PortfolioProject.dbo.FcovidVaccination vac
	on dea.location = vac.location 
	and dea.date = vac.date
--where dea.continent is not null
--order by 2,3

select *, (RollingPeopleVaccinated/population)*100 as PercentPeopleVaccinated
from #PercentPopulationVaccinated



		--Create View to store data for later visualizations

Create View PercentpopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	,Sum(cast(vac.new_vaccinations as bigint)) over (Partition by dea.location order by dea.location,dea.date)
	as RollingPeopleVaccinated
													--location에 의해 Sum구분
													--order by location/date해야 날짜별로 잘 구분되게 나온다.
from PortfolioProject.dbo.FcovidDeath dea
join PortfolioProject.dbo.FcovidVaccination vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
