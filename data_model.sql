use olympics;

CREATE TABLE raw_data 
(
    ID INT,
    Athlete_Name VARCHAR(255),
    Sex CHAR(1),
    Age  VARCHAR(255),
    Height VARCHAR(255),
    Weight VARCHAR(255),
    Team VARCHAR(255),
    NOC VARCHAR(3),
    Games VARCHAR(255),
    GAME_Year INT,
    Season VARCHAR(255),
    City VARCHAR(255),
    Sport VARCHAR(255),
    game_Event VARCHAR(255),
    Medal VARCHAR(255)
);




SHOW VARIABLES LIKE 'secure_file_priv';

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\dataset_olympics.csv'
INTO TABLE raw_data
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(ID, Athlete_Name, Sex, Age, Height, Weight, Team, NOC, Games, GAME_Year, Season, City, Sport, game_Event, Medal);
;



/* create athlete fact table */

create table athletes as
select 
	row_number() over (order by athlete_name) as athlete_id
    , a.* 
from (
	select distinct athlete_name, sex from raw_data
) as a
;

select * from athletes
;



/* create games fact table */

create table games as
select 
	row_number() over (order by games) as games_id
    , a.* 
from (
	select distinct games, game_year, season, city from raw_data
) as a
;

select * from games
;


/* create sport fact table */ 

create table sport as
select
	row_number() over (order by game_event) as event_id
    , a.*
from (
	select distinct sport, game_event from raw_data
) as a
;

select * from sport
;


/* create country table */

create table country as
select 
	row_number() over (order by team) as country_id
    , a.*
from (
	select distinct team, noc from raw_data 
) as a
;

select * from country
;


/* create athlete game dimension table */

create table athlete_game as

/* select relevant columns from raw data */
with r as (
select 
	distinct athlete_name, age, weight, height, team, games
from raw_data 
) 

select 
	ath.athlete_id
    , c.country_id
    , g.games_id
    , r.age
    , r.weight
    , r.height
from r

/* join to athlete fact table */
join athletes as ath on
	r.athlete_name = ath.athlete_name
    
/* join to country fact table */
join country c on
	r.team = c.team
    
/* join to games table */
join games g on
	r.games=g.games
;

select * from athlete_game
;


/* create games and events link table */

create table games_events as

with r as (
select 
	distinct games, game_event
from raw_data
)

select 
	row_number() over (order by games_id) as games_event_link
    , a.games_id
    , a.event_id
from (

	select games_id, event_id from r

	join games g on
		r.games = g.games

	join sport s on
		r.game_event = s.game_event
) a
;

select * from games_events
;


/* create results table */

create table results as

with r as (
	select distinct athlete_name, games, game_event, medal from raw_data
)

select 
	athlete_id
    , games_event_link
    , medal
 from r

/* join to athletes table */
join athletes ath on
	r.athlete_name = ath.athlete_name

/* join to games table */
join games g on
	r.games=g.games
    
/* join to sport table */
join sport s on
	r.game_event = s.game_event

/* join to game event link */
join games_events ge on
	g.games_id = ge.games_id 
    and
    s.event_id = ge.event_id
;

select * from results
;


