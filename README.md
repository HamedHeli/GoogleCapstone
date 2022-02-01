![alt text](Logo.png)

# GoogleCapstone: Cyclistic
Cylistic, a bike-share company in Chicago, wants to know who annual members and casual riders are different. They have concluded that members are more profitable for the company and so they want to encourage casual riders to become members. The project description can be found [here](Description.pdf). 

In this case study, I used data to theorize the main difference between how members and casual riders are using the bikes. I was then able to suggest action plan to convert casual riders to annual members. 

### Importing Data
First, we downloaded the data from [link](https://divvy-tripdata.s3.amazonaws.com/index.html). Data include the rider information from July 2013 - Dec 2021. All data are downloded and tranferred into SQL using SSIS and SSMS tools. 

### Data Cleaning
Data are cleaning in SQL ([SQL codes](SQL/SQLQuery.sql)):
  * Mismatched/inconsistent data are replaced so that column data are consistent 
  * Extra spaces and characters are removed from the names
  * Null cells are filled, as much as possible, by grouping data in other rows in a CTE
  * Duplicate data are removed
  * Data are checked for integrity and accuracy.

### Data Processing 
Date are processed in Python and initial insights are derived ([Python code](Python/Bike_Sharing.ipynb))

#### Observations:
  * Number of memebrs increase when pandemic started.
  * Memebrs are using bikes more on weekends while casual riders are riding more on weekdays.
  * Trip duration for members is taking longer than casual riders 
  * Common stations for members are cloes to Chicago attractions, cloes to Mishigan Lake, while casual riders use stations distributed across the city
  * Memebrs are slightly younger than casual riders.

#### Hypothesis:
Memebrs are using bikes for leisure activities while casual riders are using bikes for commuting to work.

#### Action Plan:
  * Increasing the number of stations near the Chicago's attractions, especially those around the Mishigan Lake.
  * Providing tandem (twin) bikes which are appropriate for leisure activities. 
  * Seting 20-minute limit for casual riders on weekends, after which the rental fee increases.
  * Equipping bikes with saddles that are more appropriate for women riders.  

### Data Visualization
Date are visualized in Tableau ([Tableau link](https://public.tableau.com/app/profile/hamed7970/viz/GoogleCapstone_16422249161910/Dashboard1))
