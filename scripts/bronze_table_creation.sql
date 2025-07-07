/* 
YELLOW TAXI TRIPDATA FROM PARQUET FILES
This script creates the YELLOW_TRIPDATA table in the NYC_YELLOW database.
It is designed to store trip data for yellow taxis in New York City.
The table includes various fields such as vendor ID, pickup and dropoff times,
passenger count, trip distance, rate code, location IDs, payment type, fare amounts,
and additional surcharges.
*/

use database NYC_YELLOW; 
create TABLE IF NOT EXISTS YELLOW_TRIPDATA (
	VENDORID NUMBER(38,0),
	TPEP_PICKUP_DATETIME NUMBER(38,0),
	TPEP_DROPOFF_DATETIME NUMBER(38,0),
	PASSENGER_COUNT NUMBER(38,0),
	TRIP_DISTANCE FLOAT,
	RATECODEID NUMBER(38,0),
	STORE_AND_FWD_FLAG VARCHAR(16777216),
	PULOCATIONID NUMBER(38,0),
	DOLOCATIONID NUMBER(38,0),
	PAYMENT_TYPE NUMBER(38,0),
	FARE_AMOUNT FLOAT,
	EXTRA FLOAT,
	MTA_TAX FLOAT,
	TIP_AMOUNT FLOAT,
	TOLLS_AMOUNT FLOAT,
	IMPROVEMENT_SURCHARGE FLOAT,
	TOTAL_AMOUNT FLOAT,
	CONGESTION_SURCHARGE FLOAT,
	AIRPORT_FEE FLOAT,
	CBD_CONGESTION_FEE FLOAT
);



/* 
ZONE LOOKUP TABLE
This script creates the ZONE_LOOKUP table in the NYC_YELLOW database.
It is designed to store information about different zones in New York City,
including location IDs, boroughs, zones, and service zones.
The table includes fields for location ID, borough name, zone name, and service zone name.    
*/

ZONE_LOOKUP (
	LOCATIONID NUMBER(38,0),
	BOROUGH VARCHAR(),
	ZONE VARCHAR(),
	SERVICE_ZONE VARCHAR()
);