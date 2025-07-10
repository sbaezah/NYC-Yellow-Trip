/* 
YELLOW TAXI TRIPDATA FROM PARQUET FILES
This script creates the YELLOW_TRIPDATA table in the NYC_YELLOW database.
It is designed to store trip data for yellow taxis in New York City.
The table includes various fields such as vendor ID, pickup and dropoff times,
passenger count, trip distance, rate code, location IDs, payment type, fare amounts,
and additional surcharges.
*/


/* 
LOADING DATA FROM PARQUET

COPY INTO "NYC_YELLOW"."TRIPS_BRONZE"."YELLOW_TRIPDATA"
FROM (
    SELECT $1:VendorID::NUMBER(38, 0), $1:tpep_pickup_datetime::NUMBER(38, 0), $1:tpep_dropoff_datetime::NUMBER(38, 0), $1:passenger_count::NUMBER(38, 0), $1:trip_distance::FLOAT, $1:RatecodeID::NUMBER(38, 0), $1:store_and_fwd_flag::VARCHAR, $1:PULocationID::NUMBER(38, 0), $1:DOLocationID::NUMBER(38, 0), $1:payment_type::NUMBER(38, 0), $1:fare_amount::FLOAT, $1:extra::FLOAT, $1:mta_tax::FLOAT, $1:tip_amount::FLOAT, $1:tolls_amount::FLOAT, $1:improvement_surcharge::FLOAT, $1:total_amount::FLOAT, $1:congestion_surcharge::FLOAT, $1:Airport_fee::FLOAT, $1:cbd_congestion_fee::FLOAT
    FROM '@"NYC_YELLOW"."TRIPS_BRONZE"."RAW"'
)
FILES = ('yellow_tripdata_2025-03.parquet')
FILE_FORMAT = (
    TYPE=PARQUET,
    REPLACE_INVALID_CHARACTERS=TRUE,
    BINARY_AS_TEXT=FALSE
)
ON_ERROR=ABORT_STATEMENT;

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