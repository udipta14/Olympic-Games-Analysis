select * from [dbo].[athlete_event]
select * from [dbo].[noc_regions]

-- Rename the "Year" column to "Years"
EXEC sp_rename '[dbo].[athlete_event].[Year]', 'Years', 'COLUMN'

-- Updating 'SIN' to 'SGP' in noc_regions table as 'Singapore' NOC is 'SGP' in athlete_event table.
update noc_regions
set NOC = 'SGP'
where NOC = 'SIN'

-- Q.1. How many olympics games have been held?
select count(distinct Games) as No_of_Games
from athlete_event

-- Q.2. List down all Olympics games held so far.
select distinct Games as Names_of_Games
from athlete_event

--Q.3. Mention the total no of nations who participated in each olympics game?

select ae.Games, count(nr.region) as No_of_participated_nations
from athlete_event ae
join noc_regions nr
on ae.NOC = nr.NOC
group by ae.Games



--Q.4. Which year saw the highest and lowest no of countries participating in olympics?

WITH CTE AS
(
    SELECT ae.Years, COUNT(nr.region) AS no_of_nations
    FROM athlete_event ae
    JOIN noc_regions nr ON ae.NOC = nr.NOC
    GROUP BY ae.Years
)
SELECT Years, no_of_nations
FROM CTE
WHERE no_of_nations = (SELECT MAX(no_of_nations) FROM CTE)
   OR no_of_nations = (SELECT MIN(no_of_nations) FROM CTE);

-- ALTERNATE
SELECT Years, no_of_nations
FROM (
    SELECT ae.Years, COUNT(nr.region) AS no_of_nations
    FROM athlete_event ae
    JOIN noc_regions nr ON ae.NOC = nr.NOC
    GROUP BY ae.Years
) AS Subquery
WHERE no_of_nations = (
    SELECT MAX(no_of_nations)
    FROM (
        SELECT ae.Years, COUNT(nr.region) AS no_of_nations
        FROM athlete_event ae
        JOIN noc_regions nr ON ae.NOC = nr.NOC
        GROUP BY ae.Years
    ) AS MaxSubquery
)
OR no_of_nations = (
    SELECT MIN(no_of_nations)
    FROM (
        SELECT ae.Years, COUNT(nr.region) AS no_of_nations
        FROM athlete_event ae
        JOIN noc_regions nr ON ae.NOC = nr.NOC
        GROUP BY ae.Years
    ) AS MinSubquery
)

--Q.5. Which nation has participated in all of the olympic games?
SELECT nr.region, count(distinct ae.Games) as total_no_of_games
FROM noc_regions nr
JOIN athlete_event ae 
ON nr.NOC = ae.NOC
GROUP BY nr.region
HAVING count(distinct ae.Games) = (
    SELECT MAX(total_no_of_games)
    FROM (
        SELECT count(distinct ae.Games) as total_no_of_games
        FROM noc_regions nr
        JOIN athlete_event ae 
		ON nr.NOC = ae.NOC
        GROUP BY nr.region
    ) AS Subquery
)


--ALTERNATE
WITH GamesCount AS (
    SELECT nr.region, COUNT(DISTINCT ae.Games) AS total_no_of_games
    FROM noc_regions nr
    JOIN athlete_event ae 
	ON nr.NOC = ae.NOC
    GROUP BY nr.region
)
SELECT region, total_no_of_games
FROM GamesCount
WHERE total_no_of_games = (SELECT MAX(total_no_of_games) FROM GamesCount)

--Q.6. Identify the sport which was played in all summer olympics.
select distinct Season, Sport
from athlete_event
where Season = 'Summer'

--Q.7. Which Sports were just played only once in the olympics?
select Sport, count(Sport) as played_once
from athlete_event
group by Sport
having count(Sport) = 1
order by count(Sport)

--Q.8. Fetch the total no of sports played in each olympic games.
select Games, count(distinct Sport) as no_of_sports_played
from athlete_event
group by Games

--Q.9. Fetch details of the oldest athletes to win a gold medal.
SELECT *
FROM athlete_event
WHERE Medal = 'Gold'
  AND Age = (
    SELECT MAX(Age)
    FROM athlete_event
    WHERE Medal = 'Gold'
  )

--Q.10. Find the Ratio of male and female athletes participated in all olympic games.
SELECT
    SUM(CASE WHEN Sex = 'M' THEN 1 ELSE 0 END) AS No_of_Male,
    SUM(CASE WHEN Sex = 'F' THEN 1 ELSE 0 END) AS No_of_Female,
    CONVERT(DECIMAL (4,2), SUM(CASE WHEN Sex = 'M' THEN 1 ELSE 0 END) * 1.0 / SUM(CASE WHEN Sex = 'F' THEN 1 ELSE 0 END)) AS Male_to_Female_Ratio
FROM athlete_event;

--Q.11. Fetch the top 5 athletes who have won the most gold medals.
WITH RankedAthletes AS (
    SELECT
        Name,
        COUNT(Medal) AS No_of_Gold,
        DENSE_RANK() OVER (ORDER BY COUNT(Medal) DESC) AS GoldRank
    FROM athlete_event
    WHERE Medal = 'Gold'
    GROUP BY Name
)
SELECT Name, No_of_Gold
FROM RankedAthletes
WHERE GoldRank <= 5
ORDER BY GoldRank

--Q.12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
WITH RankedAthletes AS (
    SELECT
        Name,
        COUNT(Medal) AS No_of_Medals,
        DENSE_RANK() OVER (ORDER BY COUNT(Medal) DESC) AS MedalRank
    FROM athlete_event
    WHERE Medal != 'NA'
    GROUP BY Name
)
SELECT Name, No_of_Medals
FROM RankedAthletes
WHERE MedalRank <= 5
ORDER BY MedalRank

--Q.13. Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
 WITH RankedAthletes AS (
    SELECT
        nr.region,
        COUNT(ae.Medal) AS No_of_Medals,
        DENSE_RANK() OVER (ORDER BY COUNT(ae.Medal) DESC) AS MedalRank
    FROM noc_regions nr
	join athlete_event ae
	on nr.NOC = ae.NOC
    WHERE ae.Medal != 'NA'
    GROUP BY nr.region
)
SELECT region, No_of_Medals
FROM RankedAthletes
WHERE MedalRank <= 5
ORDER BY MedalRank

--Q.14. List down total gold, silver and broze medals won by each country.

select n.region ,t1.No_of_Gold, t1.No_of_Silver , t1.No_of_Bronze
from
(
select NOC,
SUM(CASE WHEN Medal = 'Gold' THEN 1 ELSE 0 END) AS No_of_Gold,
SUM(CASE WHEN Medal = 'Silver' THEN 1 ELSE 0 END) AS No_of_Silver,
SUM(CASE WHEN Medal = 'Bronze' THEN 1 ELSE 0 END) AS No_of_Bronze
from athlete_event
group by NOC
) t1
join noc_regions as n
on t1.NOC = n.NOC
order by 2 DESC, 3 DESC, 4 DESC

--ALTERNATE

SELECT country, Gold, Silver, Bronze 
FROM 
(
    SELECT n.NOC, n.region AS country, ae.Medal
    FROM athlete_event AS ae
    JOIN noc_regions AS n ON ae.NOC = n.NOC
) AS source_table
PIVOT
(
    count(Medal) FOR Medal IN (Gold, Silver, Bronze) 
) AS pivotTable
ORDER BY Gold DESC, Silver DESC, Bronze DESC

--Q.15. List down total gold, silver and bronze medals won by each country corresponding to each olympic games.
select t1.Games, n.region ,t1.No_of_Gold, t1.No_of_Silver , t1.No_of_Bronze
from
(
select Games,NOC,
SUM(CASE WHEN Medal = 'Gold' THEN 1 ELSE 0 END) AS No_of_Gold,
SUM(CASE WHEN Medal = 'Silver' THEN 1 ELSE 0 END) AS No_of_Silver,
SUM(CASE WHEN Medal = 'Bronze' THEN 1 ELSE 0 END) AS No_of_Bronze
from athlete_event
group by Games,NOC
) t1
join noc_regions as n
on t1.NOC = n.NOC
order by 1

--Q.16. Identify which country won the most gold, most silver and most bronze medals in each olympic games.
select TOP 1 n.region ,t1.No_of_Gold, t1.No_of_Silver , t1.No_of_Bronze
from
(
select NOC,
SUM(CASE WHEN Medal = 'Gold' THEN 1 ELSE 0 END) AS No_of_Gold,
SUM(CASE WHEN Medal = 'Silver' THEN 1 ELSE 0 END) AS No_of_Silver,
SUM(CASE WHEN Medal = 'Bronze' THEN 1 ELSE 0 END) AS No_of_Bronze
from athlete_event
group by NOC
) t1
join noc_regions as n
on t1.NOC = n.NOC
order by 2 DESC, 3 DESC, 4 DESC

--Q.17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.
select TOP 1 t1.Games, n.region ,t1.No_of_Gold, t1.No_of_Silver , t1.No_of_Bronze, 
t1.No_of_Gold+t1.No_of_Silver+t1.No_of_Bronze as Total_Medals
from
(
select Games,NOC,
SUM(CASE WHEN Medal = 'Gold' THEN 1 ELSE 0 END) AS No_of_Gold,
SUM(CASE WHEN Medal = 'Silver' THEN 1 ELSE 0 END) AS No_of_Silver,
SUM(CASE WHEN Medal = 'Bronze' THEN 1 ELSE 0 END) AS No_of_Bronze
from athlete_event
group by Games,NOC
) t1
join noc_regions as n
on t1.NOC = n.NOC
order by 3 DESC, 4 DESC, 5 DESC, 6 DESC

--ALTERNATE

WITH MedalCounts AS (
    SELECT
        ae.Games,
        nr.region,
        ae.NOC,
        SUM(CASE WHEN Medal = 'Gold' THEN 1 ELSE 0 END) AS No_of_Gold,
        SUM(CASE WHEN Medal = 'Silver' THEN 1 ELSE 0 END) AS No_of_Silver,
        SUM(CASE WHEN Medal = 'Bronze' THEN 1 ELSE 0 END) AS No_of_Bronze
    FROM athlete_event AS ae
    JOIN noc_regions AS nr ON ae.NOC = nr.NOC
    GROUP BY ae.Games, nr.region, ae.NOC
)
SELECT TOP 1 WITH TIES Games, region, No_of_Gold, No_of_Silver, No_of_Bronze, (No_of_Gold+No_of_Silver+No_of_Bronze) as Total_Medals
FROM MedalCounts
ORDER BY No_of_Gold DESC, No_of_Silver DESC, No_of_Bronze DESC, Total_Medals DESC;

--Q.18. Which countries have never won gold medal but have won silver/bronze medals?
select nr.region,
SUM(CASE WHEN ae.Medal = 'Gold' THEN 1 ELSE 0 END) AS No_of_Gold,
SUM(CASE WHEN ae.Medal = 'Silver' THEN 1 ELSE 0 END) AS No_of_Silver,
SUM(CASE WHEN ae.Medal = 'Bronze' THEN 1 ELSE 0 END) AS No_of_Bronze
from noc_regions nr
join athlete_event ae
on nr.NOC = ae.NOC
group by nr.region
having SUM(CASE WHEN ae.Medal = 'Gold' THEN 1 ELSE 0 END) = 0  
AND (SUM(CASE WHEN ae.Medal = 'Silver' THEN 1 ELSE 0 END) + SUM(CASE WHEN ae.Medal = 'Bronze' THEN 1 ELSE 0 END)) > 0


--Q.19. In which Sport/event, INDIA has won highest medals.
select TOP 1 nr.region as Country, ae.Sport, ae.Event, count(ae.Medal) as Highest_Medals
from noc_regions nr
join athlete_event ae
on nr.NOC = ae.NOC
where nr.region = 'India' and ae.Medal != 'NA'
group by nr.region, ae.Sport, ae.Event
order by Highest_Medals DESC

--Q.20. Break down all olympic games where india won medal for Hockey and how many medals in each olympic games.
select nr.region as Country, ae.Games, ae.Sport, ae.Event, count(ae.Medal) as Highest_Medals
from noc_regions nr
join athlete_event ae
on nr.NOC = ae.NOC
where nr.region = 'India' and ae.Medal != 'NA'
group by nr.region, ae.Games, ae.Sport, ae.Event
order by Highest_Medals DESC







