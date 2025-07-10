/* 

*/
CREATE or REPLACE TABLE NYC_YELLOW.TRIPS_GOLD.FACT_TRIP (
	VENDORID               NUMBER(38,0),
	PICKUP_DATE_SK         NUMBER(8,0),
    PICKUP_TIME_SK         NUMBER(6,0),
    DROPOFF_DATE_SK        NUMBER(8,0),
    DROPOFF_TIME_SK        NUMBER(6,0),
	PASSENGER_COUNT        NUMBER(38,0),
    DURATION_SECONDS       NUMBER(38,0),
    DURATION_MINUTES       FLOAT,
	TRIP_DISTANCE          FLOAT,
    TRIP_DISTANCE_MT       FLOAT,
    TRIP_DISTANCE_KM       FLOAT,
	RATECODEID             NUMBER(38,0),
	STORE_AND_FWD_FLAG     VARCHAR(10),
	PULOCATIONID           NUMBER(38,0),
	DOLOCATIONID           NUMBER(38,0),
	PAYMENT_TYPE_ID        NUMBER(38,0),
	FARE_AMOUNT            FLOAT,
	EXTRA                  FLOAT,
	MTA_TAX                FLOAT,
	TIP_AMOUNT             FLOAT,
	TOLLS_AMOUNT           FLOAT,
	IMPROVEMENT_SURCHARGE  FLOAT,
	TOTAL_AMOUNT           FLOAT,
	CONGESTION_SURCHARGE   FLOAT,
	AIRPORT_FEE            FLOAT,
	CBD_CONGESTION_FEE     FLOAT,
    TIP_PERC               FLOAT
);

INSERT INTO NYC_YELLOW.TRIPS_GOLD.FACT_TRIP (VENDORID, PICKUP_DATE_SK, PICKUP_TIME_SK, DROPOFF_DATE_SK, DROPOFF_TIME_SK, PASSENGER_COUNT, DURATION_SECONDS,
 DURATION_MINUTES, TRIP_DISTANCE, TRIP_DISTANCE_MT, TRIP_DISTANCE_KM, RATECODEID, STORE_AND_FWD_FLAG, PULOCATIONID,
 DOLOCATIONID, PAYMENT_TYPE_ID, FARE_AMOUNT, EXTRA, MTA_TAX, TIP_AMOUNT, TOLLS_AMOUNT, IMPROVEMENT_SURCHARGE,
 TOTAL_AMOUNT, CONGESTION_SURCHARGE, AIRPORT_FEE, CBD_CONGESTION_FEE, TIP_PERC)

WITH fact_trip as (
select 
tr.VENDORID,
TO_NUMBER(REPLACE(CAST(TO_DATE(tr.pickup_datetime) AS CHAR(10)),'-','')) AS PICKUP_DATE_SK,
TO_NUMBER(REPLACE(CAST(TO_TIME(tr.pickup_datetime) AS CHAR(8)),':','')) AS PICKUP_TIME_SK,
TO_NUMBER(REPLACE(CAST(TO_DATE(tr.dropoff_datetime) AS CHAR(10)),'-','')) AS DROPOFF_DATE_SK,
TO_NUMBER(REPLACE(CAST(TO_TIME(tr.dropoff_datetime) AS CHAR(8)),':','')) AS DROPOFF_TIME_SK,
IFNULL(tr.passenger_count,1) AS PASSENGER_COUNT,
timediff(second,tr.pickup_datetime,tr.dropoff_datetime) as DURATION_SECONDS,
timediff(minute,tr.pickup_datetime,tr.dropoff_datetime) as DURATION_MINUTES,
IFNULL(tr.trip_distance,0) AS TRIP_DISTANCE,
tr.TRIP_DISTANCE_MT,
tr.TRIP_DISTANCE_KM,
IFNULL(tr.ratecodeid,99) AS RATECODEID,
IFNULL(tr.store_and_fwd_flag,'N') AS STORE_AND_FWD_FLAG,
tr.pulocationid,
tr.dolocationid,
IFNULL(tr.payment_type,5) AS PAYMENT_TYPE,
tr.fare_amount,
tr.extra,
tr.mta_tax,
tr.tip_amount,
tr.tolls_amount,
tr.improvement_surcharge,
tr.total_amount,
IFNULL(tr.congestion_surcharge,0) AS CONGESTION_SURCHARGE,
IFNULL(tr.airport_fee,0) AS AIRPORT_FEE,
tr.cbd_congestion_fee,
case    when ifnull(tr.total_amount,0) > 0 and ifnull(tr.tip_amount,0) <= ifnull(tr.total_amount,0) 
        then ifnull(tr.tip_amount,0)/tr.TOTAL_AMOUNT 
        when ifnull(tr.total_amount,0) > 0 and ifnull(tr.tip_amount,0) >= ifnull(tr.total_amount,0)
        then 1
        else 0 end TIP_PERC
from NYC_YELLOW.TRIPS_SILVER.TRIP_CLEANED as tr
)

select 
VENDORID,
PICKUP_DATE_SK,
PICKUP_TIME_SK,
DROPOFF_DATE_SK,
DROPOFF_TIME_SK,
PASSENGER_COUNT,
DURATION_SECONDS,
DURATION_MINUTES,
TRIP_DISTANCE,
TRIP_DISTANCE_MT,
TRIP_DISTANCE_KM,
RATECODEID,
STORE_AND_FWD_FLAG,
PULOCATIONID,
DOLOCATIONID,
PAYMENT_TYPE,
FARE_AMOUNT,
EXTRA,
MTA_TAX,
TIP_AMOUNT,
TOLLS_AMOUNT,
IMPROVEMENT_SURCHARGE,
TOTAL_AMOUNT,
CONGESTION_SURCHARGE,
AIRPORT_FEE,
CBD_CONGESTION_FEE,
TIP_PERC
from fact_trip;