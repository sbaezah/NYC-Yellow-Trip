/*
dim_time 

*/

CREATE OR REPLACE TABLE DIM_TIME (
    TIME_SK           NUMBER(6,0) NOT NULL PRIMARY KEY, -- Surrogate Key, e.g., 134530 for 1:45:30 PM
    TIME_VALUE        TIME NOT NULL,                    -- The actual time value, e.g., '13:45:30'
    HOUR_24           TINYINT NOT NULL,                 -- Hour in 24-hour format (0-23)
    HOUR_12           TINYINT NOT NULL,                 -- Hour in 12-hour format (1-12)
    MINUTE_OF_HOUR    TINYINT NOT NULL,                 -- Minute of the hour (0-59)
    SECOND_OF_MINUTE  TINYINT NOT NULL,                 -- Second of the minute (0-59)
    AM_PM             VARCHAR(2) NOT NULL,              -- 'AM' or 'PM'
    TIME_OF_DAY       VARCHAR(10) NOT NULL,             -- e.g., 'Morning', 'Afternoon', 'Evening', 'Night'
    QUARTER_HOUR_NAME VARCHAR(10) NOT NULL              -- e.g., '13:45' for the start of the quarter-hour block
);


INSERT INTO DIM_TIME (
    TIME_SK,
    TIME_VALUE,
    HOUR_24,
    MINUTE_OF_HOUR,
    SECOND_OF_MINUTE,
    AM_PM,
    HOUR_12,
    TIME_OF_DAY,
    QUARTER_HOUR_NAME
)
-- Use a CTE to generate a row for each second of the day
WITH ALL_SECONDS AS (
    SELECT
-- Add the sequence number (0-86399) as seconds to the time '00:00:00'
      DATEADD(SECOND,seq4()*1, TIME_FROM_PARTS(0, 0, 0)) AS full_time
    FROM
      TABLE(GENERATOR(ROWCOUNT => 86400)) -- 86400 seconds in a day
)
SELECT
-- Surrogate Key in HH24MISS format, e.g., 134530
    TO_NUMBER(TO_CHAR(s.full_time, 'HH24MISS')) AS TIME_SK,

-- The actual TIME value
    s.full_time AS TIME_VALUE,

    -- Hour in 24-hour format
    HOUR(s.full_time) AS HOUR_24,

    -- Minute of the hour
    MINUTE(s.full_time) AS MINUTE_OF_HOUR,

    -- Second of the minute
    SECOND(s.full_time) AS SECOND_OF_MINUTE,

    -- AM or PM
    TO_CHAR(s.full_time, 'AM') AS AM_PM,

    -- Hour in 12-hour format (as a number)
    CASE
        WHEN HOUR(s.full_time) = 0 THEN 12
        WHEN HOUR(s.full_time) > 12 THEN HOUR(s.full_time) - 12
        ELSE HOUR(s.full_time)
    END AS HOUR_12,

    -- Categorize time of day based on the 24-hour clock
    CASE
        WHEN HOUR(s.full_time) BETWEEN 6 AND 11 THEN 'Morning'
        WHEN HOUR(s.full_time) BETWEEN 12 AND 16 THEN 'Afternoon'
        WHEN HOUR(s.full_time) BETWEEN 17 AND 20 THEN 'Evening'
        ELSE 'Night'
    END AS TIME_OF_DAY,

    -- Format as HH24:MM for the start of the quarter-hour block
    TO_CHAR(s.full_time, 'HH24:') || LPAD(FLOOR(MINUTE(s.full_time) / 15) * 15, 2, '0') AS QUARTER_HOUR_NAME
FROM ALL_SECONDS s
ORDER BY s.full_time;



/*
===================================================================================================================
*/


/* 
DIM_DATE
This table contains the date dimension, which includes various attributes of each date.

*/

CREATE OR REPLACE TABLE DIM_DATE (
    DATE_SK              NUMBER(8,0) NOT NULL PRIMARY KEY, -- Surrogate Key, e.g., 20231027
    DATE_VALUE           DATE NOT NULL UNIQUE,             -- The actual date value, e.g., '2023-10-27'
    FULL_DATE_DESC       VARCHAR(35) NOT NULL,             -- e.g., 'Tuesday, October 27, 2023'
    DAY_OF_WEEK          TINYINT NOT NULL,                 -- Sunday=0, Monday=1, ..., Saturday=6
    DAY_OF_WEEK_NAME     VARCHAR(9) NOT NULL,              -- 'Sunday', 'Monday', ...
    DAY_OF_MONTH         TINYINT NOT NULL,                 -- 1-31
    DAY_OF_YEAR          SMALLINT NOT NULL,                -- 1-366
    WEEK_OF_YEAR         TINYINT NOT NULL,                 -- 1-53 (ISO standard)
    MONTH_OF_YEAR        TINYINT NOT NULL,                 -- 1-12
    MONTH_NAME           VARCHAR(9) NOT NULL,              -- 'January', 'February', ...
    MONTH_ABBREVIATION   VARCHAR(3) NOT NULL,              -- 'Jan', 'Feb', ...
    QUARTER_OF_YEAR      TINYINT NOT NULL,                 -- 1-4
    YEAR                 SMALLINT NOT NULL,
    -- Useful flags
    IS_WEEKEND_FLAG      BOOLEAN NOT NULL,                 -- TRUE if Saturday or Sunday
    IS_MONTH_END_FLAG    BOOLEAN NOT NULL,                 -- TRUE if it's the last day of the month
    IS_HOLIDAY_FLAG      BOOLEAN NOT NULL,                 -- TRUE if it's a federal or government holiday
    -- Fiscal Calendar Attributes (example: Fiscal year starts in July)
    -- This section can be customized for your business needs.
    FISCAL_YEAR          SMALLINT NOT NULL,
    FISCAL_QUARTER       TINYINT NOT NULL,
    FISCAL_MONTH_OF_YEAR TINYINT NOT NULL,
    FISCAL_QUARTER_NAME  VARCHAR(10) NOT NULL              -- e.g., 'FY2024-Q1'
);



-- Set variables for the date range you want to generate
-- SET START_DATE = '2024-01-01';
-- SET END_DATE = '2026-12-31';

-- Use a CTE and the GENERATOR to create a sequence of dates
INSERT INTO DIM_DATE (
    DATE_SK,
    DATE_VALUE,
    FULL_DATE_DESC,
    DAY_OF_WEEK,
    DAY_OF_WEEK_NAME,
    DAY_OF_MONTH,
    DAY_OF_YEAR,
    WEEK_OF_YEAR,
    MONTH_OF_YEAR,
    MONTH_NAME,
    MONTH_ABBREVIATION,
    QUARTER_OF_YEAR,
    YEAR,
    IS_WEEKEND_FLAG,
    IS_MONTH_END_FLAG,
    IS_HOLIDAY_FLAG,
    FISCAL_YEAR,
    FISCAL_QUARTER,
    FISCAL_MONTH_OF_YEAR,
    FISCAL_QUARTER_NAME
)
WITH DATE_RANGE AS (
  SELECT
    DATEADD(day, seq4(), TO_DATE('2024-01-01')) AS generated_date
  FROM
    TABLE(GENERATOR(ROWCOUNT => 1096))
)
SELECT
    -- Surrogate Key (YYYYMMDD format)
    TO_NUMBER(TO_CHAR(d.generated_date, 'YYYYMMDD')) AS DATE_SK,

    -- Core Date Attributes
    d.generated_date AS DATE_VALUE,
    TO_CHAR(d.generated_date, 'DY, MON DD, YYYY') AS FULL_DATE_DESC,
    DAYOFWEEK(d.generated_date) AS DAY_OF_WEEK,
    DECODE(DAYOFWEEK(d.generated_date), 0, 'Sunday', 1, 'Monday', 2, 'Tuesday', 3, 'Wednesday', 4, 'Thursday', 5, 'Friday', 6, 'Saturday') AS DAY_OF_WEEK_NAME,
    DAY(d.generated_date) AS DAY_OF_MONTH,
    DAYOFYEAR(d.generated_date) AS DAY_OF_YEAR,
    WEEKOFYEAR(d.generated_date) AS WEEK_OF_YEAR,
    MONTH(d.generated_date) AS MONTH_OF_YEAR,
    MONTHNAME(d.generated_date) AS MONTH_NAME,
    TO_CHAR(d.generated_date, 'MON') AS MONTH_ABBREVIATION,
    QUARTER(d.generated_date) AS QUARTER_OF_YEAR,
    YEAR(d.generated_date) AS YEAR,

    -- Flags
    (DAYOFWEEK(d.generated_date) IN (0, 6)) AS IS_WEEKEND_FLAG,
    (d.generated_date = LAST_DAY(d.generated_date, 'month')) AS IS_MONTH_END_FLAG,
    false AS IS_HOLIDAY_FLAG,

    -- Fiscal calculations (assuming fiscal year starts July 1st)
    -- To change the fiscal start month, adjust the '6' in ADD_MONTHS.
    -- For Feb start, use 11. For Oct start, use 3, etc.
    YEAR(ADD_MONTHS(d.generated_date, 6)) AS FISCAL_YEAR,
    QUARTER(ADD_MONTHS(d.generated_date, 6)) AS FISCAL_QUARTER,
    MONTH(ADD_MONTHS(d.generated_date, 6)) AS FISCAL_MONTH_OF_YEAR,
    'FY' || TO_CHAR(YEAR(ADD_MONTHS(d.generated_date, 6))) || '-Q' || TO_CHAR(QUARTER(ADD_MONTHS(d.generated_date, 6))) AS FISCAL_QUARTER_NAME

FROM DATE_RANGE d
ORDER BY d.generated_date;



/*
====================================================================================================================
 */


 /*
 DIM_ZONE
  */

  CREATE OR REPLACE TABLE DIM_ZONE (
    LOCATIONID           NUMBER(38,0) NOT NULL PRIMARY KEY,
    BOROUGH_NAME         VARCHAR(150) NOT NULL,
    ZONE_NAME            VARCHAR(150) NOT NULL,
    SERVICE_ZONE_NAME    VARCHAR(150) NOT NULL
    );



INSERT INTO DIM_ZONE (
    LOCATIONID,
    BOROUGH_NAME,
    ZONE_NAME,
    SERVICE_ZONE_NAME
)

SELECT
ZL.LOCATIONID,
ZL.BOROUGH,
ZL.ZONE,
ZL.SERVICE_ZONE
FROM NYC_YELLOW.TRIPS_BRONZE.ZONE_LOOKUP AS ZL
WHERE
ZL.LOCATIONID IS NOT NULL
ORDER BY ZL.LOCATIONID
;


/* 
DIM_VENDOR
This table contains the vendor dimension, which includes information about the taxi vendors.
*/

CREATE OR REPLACE TABLE DIM_VENDOR (
    VENDORID             NUMBER(38,0) NOT NULL PRIMARY KEY,
    VENDOR_NAME          VARCHAR(150) NOT NULL,
    VENDOR_SHORT_NAME    VARCHAR(150) NOT NULL
    );



INSERT INTO DIM_VENDOR (
    VENDORID,
    VENDOR_NAME,
    VENDOR_SHORT_NAME
)

  VALUES
    (1, 'Creative Mobile Technologies, LLC', 'Creative'),
    (2, ' Curb Mobility, LLC', 'Curb'),
    (6, 'Myle Technologies Inc', 'Myle'),
    (7, 'Helix', 'Helix'),
    (99, 'UNKNOWN/NULL', 'UNKNOWN/NULL');


/*
DIM_RATECODE
This table contains the rate code dimension, which includes information about the taxi rates.
 */

 CREATE OR REPLACE TABLE DIM_RATECODE (
    RATECODE             NUMBER(38,0) NOT NULL PRIMARY KEY,
    RATECODE_NAME        VARCHAR(150) NOT NULL
    );



INSERT INTO DIM_RATECODE (
    RATECODEID,
    RATECODE_NAME
)

  VALUES
    (1, 'Standard rate'),
    (2, 'JFK'),
    (3, 'Newark'),
    (4, 'Nassau or Westchester'),
    (5, 'Negotiated fare'),
    (6, 'Group ride'),
    (99, 'Null/unknown');


/* 
DIM_PAYMENT_TYPE
This table contains the payment type dimension, which includes information about the payment methods used in taxi rides.
*/
CREATE OR REPLACE TABLE DIM_PAYMENT_TYPE (
    PAYMENT_TYPE_ID      NUMBER(38,0) NOT NULL PRIMARY KEY,
    PAYMENT_TYPE_NAME    VARCHAR(150) NOT NULL
    );



INSERT INTO DIM_PAYMENT_TYPE (
    PAYMENT_TYPE_ID,
    PAYMENT_TYPE_NAME
)

  VALUES
    (0, 'Flex Fare trip'),
    (1, 'Credit card'),
    (2, 'Cash'),
    (3, 'No charge'),
    (4, 'Dispute'),
    (5, 'Unknown'),
    (6, 'Voided trip');



    /*
    DIM_RATECODE
    */

    CREATE OR REPLACE TABLE DIM_RATECODE (
    RATECODEID             NUMBER(38,0) NOT NULL PRIMARY KEY,
    RATECODE_NAME        VARCHAR(150) NOT NULL
    );



INSERT INTO DIM_RATECODE (
    RATECODEID,
    RATECODE_NAME
)

  VALUES
    (1, 'Standard rate'),
    (2, 'JFK'),
    (3, 'Newark'),
    (4, 'Nassau or Westchester'),
    (5, 'Negotiated fare'),
    (6, 'Group ride'),
    (99, 'Null/unknown');



/* 
DIM_VENDOR
*/

CREATE OR REPLACE TABLE DIM_VENDOR (
    VENDORID             NUMBER(38,0) NOT NULL PRIMARY KEY,
    VENDOR_NAME          VARCHAR(150) NOT NULL,
    VENDOR_SHORT_NAME    VARCHAR(150) NOT NULL
    );



INSERT INTO DIM_VENDOR (
    VENDORID,
    VENDOR_NAME,
    VENDOR_SHORT_NAME
)

  VALUES
    (1, 'Creative Mobile Technologies, LLC', 'Creative'),
    (2, 'Curb Mobility, LLC', 'Curb'),
    (6, 'Myle Technologies Inc', 'Myle'),
    (7, 'Helix', 'Helix'),
    (99, 'UNKNOWN/NULL', 'UNKNOWN/NULL');



/*
DIM_ZONE
This table contains the zone dimension, which includes information about the taxi zones in New York City.
*/

CREATE OR REPLACE TABLE DIM_ZONE (
    LOCATIONID           NUMBER(38,0) NOT NULL PRIMARY KEY,
    BOROUGH_NAME         VARCHAR(150) NOT NULL,
    ZONE_NAME            VARCHAR(150) NOT NULL,
    SERVICE_ZONE_NAME    VARCHAR(150) NOT NULL
    );



INSERT INTO DIM_ZONE (
    LOCATIONID,
    BOROUGH_NAME,
    ZONE_NAME,
    SERVICE_ZONE_NAME
)

SELECT
ZL.LOCATIONID,
ZL.BOROUGH,
ZL.ZONE,
ZL.SERVICE_ZONE
FROM NYC_YELLOW.TRIPS_BRONZE.ZONE_LOOKUP AS ZL
WHERE
ZL.LOCATIONID IS NOT NULL
ORDER BY ZL.LOCATIONID
;


/*
DIM_DATE
This table contains the date dimension, which includes various attributes of each date.
*/


CREATE OR REPLACE TABLE DIM_DATE (
    DATE_SK              NUMBER(8,0) NOT NULL PRIMARY KEY, -- Surrogate Key, e.g., 20231027
    DATE_VALUE           DATE NOT NULL UNIQUE,             -- The actual date value, e.g., '2023-10-27'
    FULL_DATE_DESC       VARCHAR(35) NOT NULL,             -- e.g., 'Tuesday, October 27, 2023'
    DAY_OF_WEEK          TINYINT NOT NULL,                 -- Sunday=0, Monday=1, ..., Saturday=6
    DAY_OF_WEEK_NAME     VARCHAR(9) NOT NULL,              -- 'Sunday', 'Monday', ...
    DAY_OF_MONTH         TINYINT NOT NULL,                 -- 1-31
    DAY_OF_YEAR          SMALLINT NOT NULL,                -- 1-366
    WEEK_OF_YEAR         TINYINT NOT NULL,                 -- 1-53 (ISO standard)
    MONTH_OF_YEAR        TINYINT NOT NULL,                 -- 1-12
    MONTH_NAME           VARCHAR(9) NOT NULL,              -- 'January', 'February', ...
    MONTH_ABBREVIATION   VARCHAR(3) NOT NULL,              -- 'Jan', 'Feb', ...
    QUARTER_OF_YEAR      TINYINT NOT NULL,                 -- 1-4
    YEAR                 SMALLINT NOT NULL,
    -- Useful flags
    IS_WEEKEND_FLAG      BOOLEAN NOT NULL,                 -- TRUE if Saturday or Sunday
    IS_MONTH_END_FLAG    BOOLEAN NOT NULL,                 -- TRUE if it's the last day of the month
    IS_HOLIDAY_FLAG      BOOLEAN NOT NULL,                 -- TRUE if it's a federal or government holiday
    -- Fiscal Calendar Attributes (example: Fiscal year starts in July)
    -- This section can be customized for your business needs.
    FISCAL_YEAR          SMALLINT NOT NULL,
    FISCAL_QUARTER       TINYINT NOT NULL,
    FISCAL_MONTH_OF_YEAR TINYINT NOT NULL,
    FISCAL_QUARTER_NAME  VARCHAR(10) NOT NULL              -- e.g., 'FY2024-Q1'
);



-- Set variables for the date range you want to generate
-- SET START_DATE = '2024-01-01';
-- SET END_DATE = '2026-12-31';

-- Use a CTE and the GENERATOR to create a sequence of dates
INSERT INTO DIM_DATE (
    DATE_SK,
    DATE_VALUE,
    FULL_DATE_DESC,
    DAY_OF_WEEK,
    DAY_OF_WEEK_NAME,
    DAY_OF_MONTH,
    DAY_OF_YEAR,
    WEEK_OF_YEAR,
    MONTH_OF_YEAR,
    MONTH_NAME,
    MONTH_ABBREVIATION,
    QUARTER_OF_YEAR,
    YEAR,
    IS_WEEKEND_FLAG,
    IS_MONTH_END_FLAG,
    IS_HOLIDAY_FLAG,
    FISCAL_YEAR,
    FISCAL_QUARTER,
    FISCAL_MONTH_OF_YEAR,
    FISCAL_QUARTER_NAME
)
WITH DATE_RANGE AS (
  SELECT
    DATEADD(day, seq4(), TO_DATE('2024-01-01')) AS generated_date
  FROM
    TABLE(GENERATOR(ROWCOUNT => 1096))
)
SELECT
    -- Surrogate Key (YYYYMMDD format)
    TO_NUMBER(TO_CHAR(d.generated_date, 'YYYYMMDD')) AS DATE_SK,

    -- Core Date Attributes
    d.generated_date AS DATE_VALUE,
    TO_CHAR(d.generated_date, 'DY, MON DD, YYYY') AS FULL_DATE_DESC,
    DAYOFWEEK(d.generated_date) AS DAY_OF_WEEK,
    DECODE(DAYOFWEEK(d.generated_date), 0, 'Sunday', 1, 'Monday', 2, 'Tuesday', 3, 'Wednesday', 4, 'Thursday', 5, 'Friday', 6, 'Saturday') AS DAY_OF_WEEK_NAME,
    DAY(d.generated_date) AS DAY_OF_MONTH,
    DAYOFYEAR(d.generated_date) AS DAY_OF_YEAR,
    WEEKOFYEAR(d.generated_date) AS WEEK_OF_YEAR,
    MONTH(d.generated_date) AS MONTH_OF_YEAR,
    MONTHNAME(d.generated_date) AS MONTH_NAME,
    TO_CHAR(d.generated_date, 'MON') AS MONTH_ABBREVIATION,
    QUARTER(d.generated_date) AS QUARTER_OF_YEAR,
    YEAR(d.generated_date) AS YEAR,

    -- Flags
    (DAYOFWEEK(d.generated_date) IN (0, 6)) AS IS_WEEKEND_FLAG,
    (d.generated_date = LAST_DAY(d.generated_date, 'month')) AS IS_MONTH_END_FLAG,
    false AS IS_HOLIDAY_FLAG,

    -- Fiscal calculations (assuming fiscal year starts July 1st)
    -- To change the fiscal start month, adjust the '6' in ADD_MONTHS.
    -- For Feb start, use 11. For Oct start, use 3, etc.
    YEAR(ADD_MONTHS(d.generated_date, 6)) AS FISCAL_YEAR,
    QUARTER(ADD_MONTHS(d.generated_date, 6)) AS FISCAL_QUARTER,
    MONTH(ADD_MONTHS(d.generated_date, 6)) AS FISCAL_MONTH_OF_YEAR,
    'FY' || TO_CHAR(YEAR(ADD_MONTHS(d.generated_date, 6))) || '-Q' || TO_CHAR(QUARTER(ADD_MONTHS(d.generated_date, 6))) AS FISCAL_QUARTER_NAME

FROM DATE_RANGE d
ORDER BY d.generated_date;



/*
DIM_TIME
This table contains the time dimension, which includes various attributes of each time.
*/
CREATE OR REPLACE TABLE DIM_TIME (
    TIME_SK           NUMBER(6,0) NOT NULL PRIMARY KEY, -- Surrogate Key, e.g., 134530 for 1:45:30 PM
    TIME_VALUE        TIME NOT NULL,                    -- The actual time value, e.g., '13:45:30'
    HOUR_24           TINYINT NOT NULL,                 -- Hour in 24-hour format (0-23)
    HOUR_12           TINYINT NOT NULL,                 -- Hour in 12-hour format (1-12)
    MINUTE_OF_HOUR    TINYINT NOT NULL,                 -- Minute of the hour (0-59)
    SECOND_OF_MINUTE  TINYINT NOT NULL,                 -- Second of the minute (0-59)
    AM_PM             VARCHAR(2) NOT NULL,              -- 'AM' or 'PM'
    TIME_OF_DAY       VARCHAR(10) NOT NULL,             -- e.g., 'Morning', 'Afternoon', 'Evening', 'Night'
    QUARTER_HOUR_NAME VARCHAR(10) NOT NULL              -- e.g., '13:45' for the start of the quarter-hour block
);


INSERT INTO DIM_TIME (
    TIME_SK,
    TIME_VALUE,
    HOUR_24,
    MINUTE_OF_HOUR,
    SECOND_OF_MINUTE,
    AM_PM,
    HOUR_12,
    TIME_OF_DAY,
    QUARTER_HOUR_NAME
)
-- Use a CTE to generate a row for each second of the day
WITH ALL_SECONDS AS (
    SELECT
      -- Add the sequence number (0-86399) as seconds to the time '00:00:00'
      DATEADD(SECOND,seq4()*1, TIME_FROM_PARTS(0, 0, 0)) AS full_time
    FROM
      TABLE(GENERATOR(ROWCOUNT => 86400)) -- 86400 seconds in a day
)
SELECT
    -- Surrogate Key in HH24MISS format, e.g., 134530
    TO_NUMBER(TO_CHAR(s.full_time, 'HH24MISS')) AS TIME_SK,

    -- The actual TIME value
    s.full_time AS TIME_VALUE,

    -- Hour in 24-hour format
    HOUR(s.full_time) AS HOUR_24,

    -- Minute of the hour
    MINUTE(s.full_time) AS MINUTE_OF_HOUR,

    -- Second of the minute
    SECOND(s.full_time) AS SECOND_OF_MINUTE,

    -- AM or PM
    TO_CHAR(s.full_time, 'AM') AS AM_PM,

    -- Hour in 12-hour format (as a number)
    CASE
        WHEN HOUR(s.full_time) = 0 THEN 12
        WHEN HOUR(s.full_time) > 12 THEN HOUR(s.full_time) - 12
        ELSE HOUR(s.full_time)
    END AS HOUR_12,

    -- Categorize time of day based on the 24-hour clock
    CASE
        WHEN HOUR(s.full_time) BETWEEN 6 AND 11 THEN 'Morning'
        WHEN HOUR(s.full_time) BETWEEN 12 AND 16 THEN 'Afternoon'
        WHEN HOUR(s.full_time) BETWEEN 17 AND 20 THEN 'Evening'
        ELSE 'Night'
    END AS TIME_OF_DAY,

    -- Format as HH24:MM for the start of the quarter-hour block
    TO_CHAR(s.full_time, 'HH24:') || LPAD(FLOOR(MINUTE(s.full_time) / 15) * 15, 2, '0') AS QUARTER_HOUR_NAME
FROM ALL_SECONDS s
ORDER BY s.full_time;

