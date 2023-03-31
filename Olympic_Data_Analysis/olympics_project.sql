-- SET sql_mode = "";
-- show variables like "secure_file_priv"; 


-- Creating a table
create table athlete (
ID bigint,
Name varchar(200), 
Sex varchar(60), 
Age varchar(60), 
Height varchar(60), 
Weight varchar(60), 
Team varchar(200), 
NOC varchar(200), 
Games varchar(200), 
Year int, 
Season varchar(200), 
City varchar(200), 
Sport varchar(200), 
Event varchar(200), 
Medal varchar(60));


LOAD DATA INFILE "D:/Dataengineering/sql_project/athlete_events.CSV " INTO TABLE athlete
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

CREATE TABLE IF NOT EXISTS OLYMPICS_NOC_REGIONS
(
    noc         VARCHAR(200),
    region      VARCHAR(200),
    notes       VARCHAR(200)
);

select * from NOC_REGIONS;

select * from athlete;

-- Q1.How many olympics games have been held?
SELECT COUNT(DISTINCT Games) AS total_olympic_games
FROM athlete;

-- Q2.List down all Olympics games held so far.
SELECT DISTINCT Year, Season, City
FROM athlete
ORDER BY Year;

-- Q3. Mention the total no of nations who participated in each olympics game? 
WITH country_list AS (
						SELECT a.Games, n.region 		
						FROM athlete a
                        JOIN noc_regions n
                        ON a.NOC = n.NOC
                        GROUP BY a.Games, n.region
                        )
SELECT Games, 
		COUNT(*)AS total_no_of_countries
FROM country_list
GROUP BY Games
ORDER BY Games;


-- Q4. Which year saw the highest and lowest no of countries participating in olympics?
WITH country_list AS (
						SELECT a.Games, n.region 		
						FROM athlete a
                        JOIN noc_regions n
                        ON a.NOC = n.NOC
                        GROUP BY a.Games, n.region
                        ),
total_count AS (
				SELECT Games, 
					   COUNT(*)AS total_no_of_countries
				FROM country_list
				GROUP BY Games
			   )
SELECT FIRST_VALUE(Games)OVER(ORDER BY total_no_of_countries) AS lowest_country, 
	   FIRST_VALUE(Games)OVER(ORDER BY total_no_of_countries DESC) AS highest_country
FROM total_count
LIMIT 1;


-- Q5. Which nation has participated in all of the olympic games?
WITH country_list AS (
						SELECT a.Games, n.region
						FROM athlete a
                        JOIN noc_regions n
                        ON a.NOC = n.NOC
                        GROUP BY a.Games, n.region
                        
					 ),
      countries_participated AS(
									SELECT DISTINCT region,
											COUNT(*)OVER(PARTITION BY region) AS total_games
									FROM country_list
								)
SELECT region, total_games
FROM countries_participated 
WHERE total_games IN (SELECT COUNT(distinct games) 
						from athlete ) ;
                        
                        
  -- Q6. Identify the sport which was played in all summer olympics  
  WITH sport_list AS (
						SELECT Games, Sport
						FROM athlete a
                        WHERE Season = 'summer'
                        GROUP BY Games, Sport
                        
					 ),
      sports_participated AS(
									SELECT DISTINCT Sport,
											COUNT(*)OVER(PARTITION BY Sport) AS total_games
									FROM sport_list
								)
SELECT Sport, total_games
FROM sports_participated 
WHERE total_games IN (SELECT COUNT(distinct games) 
						from sport_list ) ;
                        
                        
-- Q7. Which Sports were just played only once in the olympics?                      
	   WITH sport_list AS (
						SELECT DISTINCT Games, Sport
						FROM athlete a
					 ),
      sports_participated AS(
									SELECT DISTINCT Sport, Games,
											COUNT(*)OVER(PARTITION BY Sport) AS total_games
									FROM sport_list
								)
    SELECT DISTINCT Sport AS Sports_played_once, Games
	FROM sports_participated
    WHERE total_games =1;
    
       
-- Q8. Fetch the total no of sports played in each olympic games.
       WITH sport_list AS (
						SELECT DISTINCT Games, Sport
						FROM athlete a
					   )
          SELECT DISTINCT Games,
				COUNT(*)OVER(PARTITION BY Games) AS total_sport_played
          FROM sport_list ;
    
    
 -- Q9. Fetch details of the oldest athletes to win a gold medal.   
       WITH gold_winner_list AS( 
								   SELECT Name, Sex,
										 CAST(CASE WHEN Age ='NA' THEN 0 ELSE AGE END AS UNSIGNED) AS Age, 
										 Team, Games, Sport, City, Medal
								   FROM athlete
								   WHERE Medal = 'gold'
								),
       ranking AS (
				   SELECT *,
						 RANK()OVER(ORDER BY Age DESC) AS rnk
				   FROM gold_winner_list
				  )
	SELECT *
	FROM ranking							
	WHERE rnk = 1;
    
    
   -- Q.10 Find the Ratio of male and female athletes participated in all olympic games.
  WITH gender AS(                
				SELECT SUM(CASE WHEN Sex ='F' THEN 1 ELSE 0 END )AS female,
						SUM(CASE WHEN Sex ='M' THEN 1 ELSE 0 END )AS male
				FROM athlete
			  )
 SELECT CONCAT('1', ':', ROUND(male/female,2)) AS ratio
 FROM gender;
   
   
-- Q11. Fetch the top 5 athletes who have won the most gold medals.
  WITH gold_cnt AS(
					  SELECT Name, team, Medal,
							COUNT(*) AS cnt
					  FROM athlete
					  WHERE Medal ='gold'
                      GROUP BY Name, Team
					),
medal_rnk AS(
				SELECT Name, team, cnt,
						DENSE_RANK()OVER(ORDER BY cnt DESC) AS rnk
				 FROM gold_cnt
			 )
 SELECT Name, team, cnt
 FROM medal_rnk            
 WHERE rnk <=5;


-- Q12.Fetch the top 5 athletes who have won the most medals (gold/silver/bronze). 
WITH total_medal AS( 
					SELECT Name, Team,
							COUNT(*) AS cnt
					FROM athlete
					WHERE Medal IN ('gold', 'bronze', 'silver')
					GROUP BY Name, Team 
                   ),
	medal_rnk AS (
					SELECT Name, Team, cnt,
							DENSE_RANK()OVER(ORDER BY  cnt DESC) AS rnk
                     FROM total_medal
                   )  
 SELECT Name, Team, cnt
 FROM medal_rnk
 WHERE rnk<=5;
 
 
-- Q13. Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won. 
WITH countries AS(
					SELECT nr.region, a.Medal,
							COUNT(a.Medal)OVER(PARTITION BY nr.region) AS cnt
					FROM athlete a
					JOIN noc_regions nr
					ON a.NOC = nr.NOC
                    WHERE a.Medal NOT IN ('NA')
				),
  country_rank AS(
					SELECT region, cnt,
							DENSE_RANK()OVER(ORDER BY cnt DESC) AS rnk
					FROM countries
                   ) 
SELECT DISTINCT region,
		cnt AS total_medals
FROM country_rank
WHERE rnk<=5; 


-- Q14. List down total gold, silver and broze medals won by each country.
    WITH countries AS(
					SELECT nr.region, 
						   CASE WHEN a.Medal = 'Bronze' THEN 1 ELSE 0 END AS Bronze,
                           CASE WHEN a.Medal = 'Silver' THEN 1 ELSE 0 END AS Silver,
                           CASE WHEN a.Medal = 'Gold' THEN 1 ELSE 0 END AS Gold
					FROM athlete a
					JOIN noc_regions nr
					ON a.NOC = nr.NOC
                    WHERE a.Medal NOT IN ('NA') 
                  )  
SELECT region,
	   SUM(Gold) AS gold,
       SUM(Silver) AS Silver,
	   SUM(Bronze) AS Bronze
FROM countries
GROUP BY region       
ORDER BY SUM(Gold) DESC,SUM(Silver) DESC; 


-- Q15. List down total gold, silver and broze medals won by each country corresponding to each olympic games.
WITH countries AS(
					SELECT a.Games, nr.region, 
						   CASE WHEN a.Medal = 'Bronze' THEN 1 ELSE 0 END AS Bronze,
                           CASE WHEN a.Medal = 'Silver' THEN 1 ELSE 0 END AS Silver,
                           CASE WHEN a.Medal = 'Gold' THEN 1 ELSE 0 END AS Gold
					FROM athlete a
					JOIN noc_regions nr
					ON a.NOC = nr.NOC
                    WHERE a.Medal NOT IN ('NA') 
                  )  
 SELECT Games, region,
	   SUM(Gold) AS gold,
       SUM(Silver) AS Silver,
	   SUM(Bronze) AS Bronze
FROM countries
GROUP BY Games, region       
ORDER BY Games;  


-- Q16. Identify which country won the most gold, most silver and most bronze medals in each olympic games.
WITH countries AS(
					SELECT a.Games, nr.region, 
						   CASE WHEN a.Medal = 'Bronze' THEN 1 ELSE 0 END AS Bronze,
                           CASE WHEN a.Medal = 'Silver' THEN 1 ELSE 0 END AS Silver,
                           CASE WHEN a.Medal = 'Gold' THEN 1 ELSE 0 END AS Gold
					FROM athlete a
					JOIN noc_regions nr
					ON a.NOC = nr.NOC
                    WHERE a.Medal NOT IN ('NA') 
                  ) , 
 t2 AS(
		 SELECT Games, region,
			   SUM(Gold) AS gold,
			   SUM(Silver) AS Silver,
			   SUM(Bronze) AS Bronze
		FROM countries
		GROUP BY Games, region       
	 )
 SELECT DISTINCT Games,
		CONCAT(FIRST_VALUE(region)OVER(PARTITION BY Games ORDER BY gold DESC), '-'  
				, FIRST_VALUE(gold)OVER(PARTITION BY Games ORDER BY gold DESC))	AS max_gold,
        CONCAT(FIRST_VALUE(region)OVER(PARTITION BY Games ORDER BY Silver DESC), '-'  
				, FIRST_VALUE(Silver)OVER(PARTITION BY Games ORDER BY Silver DESC)) AS max_silver,
        CONCAT(FIRST_VALUE(region)OVER(PARTITION BY Games ORDER BY Bronze DESC), '-'  
				, FIRST_VALUE(Bronze)OVER(PARTITION BY Games ORDER BY Bronze DESC)) AS max_bronze
 FROM t2
 ORDER BY Games;
 
 
-- Q17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games. 
 WITH countries AS(
					SELECT a.Games, nr.region, COUNT(*)OVER(PARTITION BY Games, region ) AS cnt, 
						   CASE WHEN a.Medal = 'Bronze' THEN 1 ELSE 0 END AS Bronze,
                           CASE WHEN a.Medal = 'Silver' THEN 1 ELSE 0 END AS Silver,
                           CASE WHEN a.Medal = 'Gold' THEN 1 ELSE 0 END AS Gold
					FROM athlete a
					JOIN noc_regions nr
					ON a.NOC = nr.NOC
                    WHERE a.Medal NOT IN ('NA') 
                  ) , 
 t2 AS(
		 SELECT Games, region,
			   SUM(Gold) AS gold,
			   SUM(Silver) AS Silver,
			   SUM(Bronze) AS Bronze,
               cnt
		FROM countries
		GROUP BY Games, region       
	 )
 SELECT DISTINCT Games,
		CONCAT(FIRST_VALUE(region)OVER(PARTITION BY Games ORDER BY gold DESC), '-'  
				, FIRST_VALUE(gold)OVER(PARTITION BY Games ORDER BY gold DESC))	AS max_gold,
        CONCAT(FIRST_VALUE(region)OVER(PARTITION BY Games ORDER BY Silver DESC), '-'  
				, FIRST_VALUE(Silver)OVER(PARTITION BY Games ORDER BY Silver DESC)) AS max_silver,
        CONCAT(FIRST_VALUE(region)OVER(PARTITION BY Games ORDER BY Bronze DESC), '-'  
				, FIRST_VALUE(Bronze)OVER(PARTITION BY Games ORDER BY Bronze DESC)) AS max_bronze,
         CONCAT(FIRST_VALUE(region)OVER(PARTITION BY Games ORDER BY cnt DESC), '-'  
				, FIRST_VALUE(cnt)OVER(PARTITION BY Games ORDER BY cnt DESC)) AS max_medals      
 FROM t2
 ORDER BY Games;
 
 
 
-- Q18. Which countries have never won gold medal but have won silver/bronze medals? 
 WITH countries AS(
					SELECT nr.region, a.medal,
							CASE WHEN a.Medal = 'Gold' THEN 1 ELSE 0 END AS Gold,
                            CASE WHEN a.Medal = 'Silver' THEN 1 ELSE 0 END AS Silver,
						   CASE WHEN a.Medal = 'Bronze' THEN 1 ELSE 0 END AS Bronze
					FROM athlete a
					JOIN noc_regions nr
					ON a.NOC = nr.NOC
                    WHERE a.Medal NOT IN ('NA') 
                  ) ,
   t2 AS(
		 SELECT region,
			   SUM(Gold) AS gold,
			   SUM(Silver) AS silver,
			   SUM(Bronze) AS bronze
		FROM countries
		 GROUP BY region
       )
SELECT  region,
		gold,silver,bronze
FROM t2
WHERE gold = 0 AND (silver > 0 OR bronze > 0)
ORDER BY region;
        
        
-- 	Q19. In which Sport/event, India has won highest medals.
WITH medal_list AS(
						SELECT a.Team, a.Sport,
								COUNT(*) AS medal_cnt
                        FROM athlete a 
                        WHERE a.Team = 'india' AND a.Medal != 'NA'
                        GROUP BY a.Team, a.Sport
                       ) 
 SELECT *
 FROM medal_list
 ORDER BY medal_cnt DESC
 LIMIT 1;
   
   
-- Q20. Break down all olympic games where india won medal for Hockey and how many medals in each olympic games.   
	SELECT Team, Sport, Games,
			COUNT(*) AS total_medals
    FROM athlete
    WHERE Team = 'India' AND Sport='Hockey' AND Medal!='NA'
    GROUP BY Games
    ORDER BY COUNT(*) DESC;
        