/****** Script for SelectTopNRows command from SSMS  ******/
-- Data are imported from several folders using SSIS and SSMS tools (check https://www.youtube.com/watch?v=yaFf_pYsMgM&t=287s).


----------------------------
--- IMPORTING DATA INTO ONE TABLE WITH CONSISTENT COLUMN NAMES
----------------------------



IF OBJECT_ID('Bike_Sharing..bike_share_2013_2021', 'U') IS NOT NULL 
DROP TABLE Bike_Sharing..bike_share_2013_2021;
SELECT *
	INTO [Bike_Sharing].[dbo].[bike_share_2013_2021]
FROM (

SELECT 
	REPLACE(trip_id,'"','') AS trip_id, 
	bike_type = 'classic_bike', -- All bikes from 2013-2019 are considered to be classic_bike
	CAST(SUBSTRING(REPLACE(REPLACE(starttime, '"', ''),'-','/'),1,
						CHARINDEX(' ', REPLACE(REPLACE(starttime, '"', ''),'-','/'))-1) AS DATE) AS startdate,

	CAST(SUBSTRING(REPLACE(REPLACE(stoptime, '"', ''),'-','/'),1,
						CHARINDEX(' ', REPLACE(REPLACE(stoptime, '"', ''),'-','/'))-1) AS DATE) AS stopdate,
	
	CAST(REPLACE(SUBSTRING(starttime,CHARINDEX(' ', starttime),LEN(starttime)),'"','') AS TIME) AS starttime, 
	CAST(REPLACE(SUBSTRING(stoptime,CHARINDEX(' ', stoptime),LEN(stoptime)),'"','') AS TIME) AS stoptime,

	CAST(REPLACE(tripduration,'"','') AS INT) AS tripduration_sec,
	replace(from_station_id,'"','') AS from_station_id,
	replace(from_station_name,'"','') AS from_station_name, 
	replace(to_Station_id,'"','') AS to_station_id,
	replace(to_Station_name,'"','') AS to_station_name, 
	from_lat = NULL,
	from_lng = NULL,
	to_lat = NULL,
	to_lng = NULL,
	replace(usertype,'"','') AS membership, 
	replace(gender, '"','') AS gender,	
	CAST(REPLACE(birthday,'"', '') AS INT) AS birthday_year


FROM 
  
	[Bike_Sharing].[dbo].[2013_2019]
	
	

UNION ALL



SELECT 

	ride_id AS trip_id,
	rideable_type AS bike_type, 
	
	CAST(SUBSTRING(started_at,1,CHARINDEX(' ', started_at)-1) AS DATE) AS startdate,
	
	CAST(SUBSTRING(ended_at,1,CHARINDEX(' ', ended_at)-1) AS DATE) AS stopdate,

	CAST(SUBSTRING(started_at,CHARINDEX(' ', started_at),LEN(started_at)) AS time) AS starttime, 

	CAST(SUBSTRING(ended_at,CHARINDEX(' ', ended_at),LEN(ended_at)) AS time) AS stoptime,

	(DATEDIFF(SECOND, 
		CAST(SUBSTRING(started_at,1,CHARINDEX(' ', started_at)-1) AS DATE),
		CAST(SUBSTRING(ended_at,1,CHARINDEX(' ', ended_at)-1) AS DATE))
	    + DATEDIFF (SECOND, 
		CAST(SUBSTRING(started_at,CHARINDEX(' ', started_at),LEN(started_at)) AS time),  
	    CAST(SUBSTRING(ended_at,CHARINDEX(' ', ended_at),LEN(ended_at)) AS time))) AS tripduration_sec,
	
	replace(start_station_id,'"','') AS from_station_id,
	replace(start_station_name,'"','') AS from_station_name, 
	replace(end_station_id,'"','') AS to_station_id,
	replace(end_station_name,'"','') AS to_station_name,
	ROUND (replace(start_lat,'"',''),2) AS from_lat,
	ROUND (replace(start_lng,'"',''),2) AS from_lng,
	ROUND (replace(end_lat,'"',''),2) AS to_lat,
	ROUND (replace(end_lng,'"',''),2) AS to_lng,
	replace(member_casual,'"','') AS memebeship,
	gender = NULL,
	birthday_year = NULL

FROM 
  
	[Bike_Sharing].[dbo].[2020_2021])s





------------------------------------
-- CHECK CONSISTENCY AND INTEGRITY 
------------------------------------

-- Removing zero from Birthday
UPDATE Bike_Sharing..bike_share_2013_2021
SET birthday_year = NULL WHERE birthday_year = 0
UPDATE Bike_Sharing..bike_share_2013_2021
SET gender = NULL WHERE gender = ''


-- OPTIONS FOR GENDER
SELECT DISTINCT
gender
FROM Bike_Sharing..bike_share_2013_2021
------------------- MEN AND FEMALE

-- OPTIONS FOR membership
SELECT DISTINCT
membership
FROM Bike_Sharing..bike_share_2013_2021
------------------- member, Dependent, Subscriber, casual, Customer
------------------- Based on the file, we assume that customer = memebr and Subscriber = causual; (we are not sure about Dependent)  


-- change Dependent, Subscriber, and Customer to memebr 
UPDATE Bike_Sharing..bike_share_2013_2021
SET membership = (CASE 
						
						WHEN membership = 'Subscriber' THEN 'casual'
						WHEN membership = 'Customer' THEN 'member'
						ELSE membership
				  END)

-- check for consistency of station_id and station_names
--SELECT    
--	COUNT (DISTINCT from_station_name),
--	COUNT (DISTINCT from_station_id) 
--FROM Bike_Sharing..bike_share_2013_2021
---------------------- the station_id is not unique for each station_name; we should remove the station_id then 


-- Removing the station_ids from the table. 
ALTER TABLE Bike_Sharing..bike_share_2013_2021
DROP COLUMN from_station_id, to_station_id



-- Gathering all stations and latitude and longitudes in a single table, Stations. 
IF OBJECT_ID('Bike_Sharing..Stations', 'U') IS NOT NULL 
DROP TABLE Bike_Sharing..Stations


SELECT DISTINCT
	TRIM(SUBSTRING(station_name, 1, 
	   
	   CASE WHEN CHARINDEX ('(', station_name) = 0 THEN LEN (station_name)
			ELSE CHARINDEX ('(', station_name)-1 END) +
	   CASE WHEN CHARINDEX (')', station_name) = 0 THEN ''
	        ELSE SUBSTRING (station_name, CHARINDEX(')', station_name)+2 , LEN (station_name)) END) AS station_name_new,
	ROUND (AVG (station_lat),2) AS station_latitude, 
	ROUND (AVG (station_lng),2) AS station_longitude 
INTO Bike_Sharing..Stations
FROM
(

SELECT 
	name AS station_name, 
	ROUND (latitude,2) AS station_lat,
	ROUND (longitude,2) AS station_lng


FROM [Bike_Sharing].[dbo].[stations_2013_2017]

UNION ALL 

SELECT 
	from_station_name AS station_name,
	ROUND (from_lat,2) AS station_lat,
	ROUND (from_lng,2) AS station_lng

FROM [Bike_Sharing].[dbo].[bike_share_2013_2021])S

WHERE station_lat <> '' AND station_name <> ''

GROUP BY TRIM(SUBSTRING(station_name, 1, 
	   
	   CASE WHEN CHARINDEX ('(', station_name) = 0 THEN LEN (station_name)
			ELSE CHARINDEX ('(', station_name)-1 END) +
	   CASE WHEN CHARINDEX (')', station_name) = 0 THEN ''
	        ELSE SUBSTRING (station_name, CHARINDEX(')', station_name)+2 , LEN (station_name)) END)

ORDER BY station_name_new
-- It seems that some stations have more than one name (they have an extra parentheses in their name); 
-- Removing parentheses to make the names consistent 


UPDATE Bike_Sharing..bike_share_2013_2021 
SET
	from_station_name = 

	  TRIM(SUBSTRING(from_station_name, 1,  
	   CASE WHEN CHARINDEX ('(', from_station_name) = 0 THEN LEN (from_station_name)
			ELSE CHARINDEX ('(', from_station_name)-1 END) +
	   CASE WHEN CHARINDEX (')', from_station_name) = 0 THEN ''
	        ELSE SUBSTRING (from_station_name, CHARINDEX(')', from_station_name)+2 , LEN (from_station_name)) END),
			
	to_station_name = 	  
	   
	   TRIM(SUBSTRING(to_station_name, 1,  
	   CASE WHEN CHARINDEX ('(', to_station_name) = 0 THEN LEN (to_station_name)
			ELSE CHARINDEX ('(', to_station_name)-1 END) +
	   CASE WHEN CHARINDEX (')', to_station_name) = 0 THEN ''
	        ELSE SUBSTRING (to_station_name, CHARINDEX(')', to_station_name)+2 , LEN (to_station_name)) END)
WHERE 1=1 


--------------------------It seems that some stations have more than one name (besides those with extra parentheses):
----------------------------------------: Wells St & Concord Ln , Wells St & Concord Pl  
----------------------------------------: Paulina Ave & North Ave, Paulina  Ave & North Ave

UPDATE Bike_Sharing..bike_share_2013_2021 
SET from_station_name = 'Wells St & Concord Ln' WHERE from_station_name = 'Wells St & Concord Pl' 
UPDATE Bike_Sharing..bike_share_2013_2021 
SET from_station_name = 'Paulina Ave & North Ave' WHERE from_station_name = 'Paulina  Ave & North Ave' 
UPDATE Bike_Sharing..bike_share_2013_2021 
SET to_station_name = 'Wells St & Concord Ln' WHERE to_station_name = 'Wells St & Concord Pl' 
UPDATE Bike_Sharing..bike_share_2013_2021 
SET to_station_name = 'Paulina Ave & North Ave' WHERE to_station_name = 'Paulina  Ave & North Ave' 




		
-- Assign latitude and longitude to the station_names with NULL from_lat, from_lng, to_lat, and to_lng

UPDATE 
	table_1 
SET 
	table_1.from_lat = table_2.station_latitude,
	table_1.from_lng = table_2.station_longitude

FROM Bike_Sharing..bike_share_2013_2021 AS table_1
LEFT JOIN 
[Bike_Sharing].[dbo].[Stations] AS table_2

ON 
table_1.from_Station_name = table_2.station_name_new
WHERE table_1.from_lat IS NULL 



UPDATE 
	table_1 
SET 
	table_1.to_lat = table_2.station_latitude,
	table_1.to_lng = table_2.station_longitude

FROM Bike_Sharing..bike_share_2013_2021 AS table_1
LEFT JOIN 
[Bike_Sharing].[dbo].[Stations] AS table_2

ON 
table_1.to_station_name = table_2.station_name_new
WHERE table_1.to_lat IS NULL 


--- There are four stations without latitudes and longitudes
----------------------------------BBB ~ Divvy Parts Testing
----------------------------------DIVVY Map Frame B/C Station
----------------------------------LBS - BBB La Magie
----------------------------------Special Events
----------------------------------TS ~ DIVVY PARTS TESTING

-- Making sure that each station location is assigned to unique lat, lng. 

UPDATE Table_3

SET 
Table_3.from_lat = Table_4.from_lat,
Table_3.from_lng = Table_4.from_lng

FROM 

Bike_Sharing..bike_share_2013_2021 AS Table_3
LEFT JOIN

(SELECT DISTINCT
from_station_name,
ROUND (AVG(CAST(from_lat AS FLOAT)),2) AS from_lat,
ROUND (AVG(CAST(from_lng AS FLOAT)),2) AS from_lng
FROM Bike_Sharing..bike_share_2013_2021
WHERE from_station_name <> '' 
GROUP BY from_station_name) AS Table_4

ON Table_3.from_station_name = Table_4.from_station_name


UPDATE Table_6

SET 
Table_6.to_lat = Table_5.to_lat,
Table_6.to_lng = Table_5.to_lng

FROM 

Bike_Sharing..bike_share_2013_2021 AS Table_6
LEFT JOIN

(SELECT DISTINCT
from_station_name,
ROUND (AVG(CAST(to_lat AS FLOAT)),2) AS to_lat,
ROUND (AVG(CAST(to_lng AS FLOAT)),2) AS to_lng
FROM Bike_Sharing..bike_share_2013_2021
WHERE from_station_name <> '' 
GROUP BY from_station_name) AS Table_5

ON Table_6.from_station_name = Table_5.from_station_name

---- DATA RANGE
-- Range of longitudes and latitudes

SELECT 
MIN (from_lat),
MIN (from_lng),
MAX (from_lat),
MAX (from_lng), 
MIN (to_lat),
MIN (to_lng),
MAX (to_lat),
MAX (to_lng)

FROM Bike_Sharing..bike_share_2013_2021

--------- lat: 41.65 - 42.06 
--------- lng: -87.53 - -87.83 GOOD


-- range of trip duration 
--SELECT
--*
--FROM Bike_Sharing..bike_share_2013_2021
--WHERE 

--tripduration_sec < 0
------------------------ It seems that some of the data (#10812) have negative tripduration 
------------------------ potentially since the startdate/time and stopdate/time are input interchangeably  

UPDATE Bike_Sharing..bike_share_2013_2021
SET startdate = stopdate, stopdate = startdate
WHERE startdate > stopdate

UPDATE Bike_Sharing..bike_share_2013_2021
SET starttime = stoptime, stoptime = starttime
WHERE starttime > stoptime

UPDATE Bike_Sharing..bike_share_2013_2021
SET tripduration_sec = DATEDIFF(SECOND, startdate, stopdate) + DATEDIFF(SECOND, starttime, stoptime)
WHERE tripduration_sec < 0

SELECT 
*
FROM Bike_Sharing..bike_share_2013_2021
WHERE starttime > stoptime OR startdate > stopdate OR tripduration_sec < 0
 
------------------------- Doucble check for negative tripdurations: Good

SELECT 

MIN(startdate),  MAX(stopdate), MIN (starttime),  MAX(stoptime)
FROM Bike_Sharing..bike_share_2013_2021

------------------------- Dates are from 2013-06-27 to 2021-12-02 and Times are from 00:00:00 to 23:59:59: Good

SELECT 
birthday_year, COUNT(*)

FROM Bike_Sharing..bike_share_2013_2021
WHERE birthday_year <> ''
GROUP BY birthday_year 
ORDER BY birthday_year

----------------------- Birthday_years are starting rom 1759! to 2017; it seems that there might be problems in inserting the birthday_years
----------------------- we d onot change the birthday_year column but just keep this in mind 


SELECT DISTINCT 

bike_type, COUNT (*)

FROM Bike_Sharing..bike_share_2013_2021
GROUP BY bike_type

------------------------ docked_bike	#3273737          classic_bike	#23336521               electric_bike	#2394460

-- Finally search for duplicated
SELECT DISTINCT 
COUNT (*)
FROM Bike_Sharing..bike_share_2013_2021
SELECT 
COUNT (*)
FROM Bike_Sharing..bike_share_2013_2021
--------------------------- Both show 29004718 rows of date : Good

SELECT 
*
FROM Bike_Sharing..bike_share_2013_2021
WHERE ISNUMERIC(from_lat) = 0 AND from_lat <> ''
--------------------------- format for latitudes and longitudes are correct: Good
--------------------------- format for other columns already checked : Good


--Export results. 
SELECT *
FROM Bike_Sharing..bike_share_2013_2021
WHERE membership <> ''
---- 29,0004,718 Rows
