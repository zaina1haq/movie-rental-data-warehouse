-- ============================================================
-- STEP 1: Create the Data Warehouse Database & Tables
-- Run this in phpMyAdmin → SQL tab
-- ============================================================

DROP DATABASE IF EXISTS sakila_dw;
CREATE DATABASE sakila_dw CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE sakila_dw;

-- -------------------------------------------------------
-- dim_date: one row per calendar day (populated by Python)
-- -------------------------------------------------------
CREATE TABLE dim_date (
    date_key        INT          NOT NULL PRIMARY KEY,  -- YYYYMMDD
    full_date       DATE         NOT NULL,
    day_of_week     TINYINT      NOT NULL,
    day_name        VARCHAR(10)  NOT NULL,
    day_of_month    TINYINT      NOT NULL,
    day_of_year     SMALLINT     NOT NULL,
    week_of_year    TINYINT      NOT NULL,
    month_number    TINYINT      NOT NULL,
    month_name      VARCHAR(10)  NOT NULL,
    quarter         TINYINT      NOT NULL,
    year            SMALLINT     NOT NULL,
    is_weekend      TINYINT(1)   NOT NULL DEFAULT 0
);

-- -------------------------------------------------------
-- dim_customer
-- -------------------------------------------------------
CREATE TABLE dim_customer (
    customer_key    INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    customer_id     SMALLINT     NOT NULL UNIQUE,
    full_name       VARCHAR(91)  NOT NULL,
    email           VARCHAR(50),
    address         VARCHAR(50),
    district        VARCHAR(20),
    city            VARCHAR(50),
    country         VARCHAR(50),
    postal_code     VARCHAR(10),
    phone           VARCHAR(20),
    is_active       TINYINT(1)   NOT NULL DEFAULT 1,
    create_date     DATE
);

-- -------------------------------------------------------
-- dim_film
-- -------------------------------------------------------
CREATE TABLE dim_film (
    film_key            INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
    film_id             SMALLINT      NOT NULL UNIQUE,
    title               VARCHAR(128)  NOT NULL,
    description         TEXT,
    release_year        YEAR,
    language            VARCHAR(20)   NOT NULL,
    rental_duration     TINYINT       NOT NULL,
    rental_rate         DECIMAL(4,2)  NOT NULL,
    film_length_min     SMALLINT,
    replacement_cost    DECIMAL(5,2)  NOT NULL,
    rating              VARCHAR(5),
    special_features    VARCHAR(255),
    category            VARCHAR(25)
);

-- -------------------------------------------------------
-- dim_store
-- -------------------------------------------------------
CREATE TABLE dim_store (
    store_key           INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    store_id            TINYINT      NOT NULL UNIQUE,
    manager_full_name   VARCHAR(91)  NOT NULL,
    address             VARCHAR(50),
    district            VARCHAR(20),
    city                VARCHAR(50),
    country             VARCHAR(50),
    postal_code         VARCHAR(10),
    phone               VARCHAR(20)
);

-- -------------------------------------------------------
-- dim_staff
-- -------------------------------------------------------
CREATE TABLE dim_staff (
    staff_key   INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    staff_id    TINYINT      NOT NULL UNIQUE,
    full_name   VARCHAR(91)  NOT NULL,
    email       VARCHAR(50),
    store_id    TINYINT      NOT NULL,
    is_active   TINYINT(1)   NOT NULL DEFAULT 1
);

-- -------------------------------------------------------
-- fact_rental
-- -------------------------------------------------------
CREATE TABLE fact_rental (
    rental_id               INT        NOT NULL PRIMARY KEY,
    rental_date_key         INT        NOT NULL,
    return_date_key         INT,
    customer_key            INT        NOT NULL,
    film_key                INT        NOT NULL,
    store_key               INT        NOT NULL,
    staff_key               INT        NOT NULL,
    rental_duration_days    INT,
    expected_duration_days  TINYINT    NOT NULL,
    is_late_return          TINYINT(1),
    days_late               INT,
    rental_count            TINYINT    NOT NULL DEFAULT 1,

    FOREIGN KEY (rental_date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (return_date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (customer_key)    REFERENCES dim_customer(customer_key),
    FOREIGN KEY (film_key)        REFERENCES dim_film(film_key),
    FOREIGN KEY (store_key)       REFERENCES dim_store(store_key),
    FOREIGN KEY (staff_key)       REFERENCES dim_staff(staff_key)
);

-- Performance indexes for fact_rental
CREATE INDEX idx_fact_rental_rental_date_key ON fact_rental(rental_date_key);
CREATE INDEX idx_fact_rental_return_date_key ON fact_rental(return_date_key);
CREATE INDEX idx_fact_rental_customer_key ON fact_rental(customer_key);
CREATE INDEX idx_fact_rental_film_key ON fact_rental(film_key);
CREATE INDEX idx_fact_rental_store_key ON fact_rental(store_key);
CREATE INDEX idx_fact_rental_staff_key ON fact_rental(staff_key);

-- -------------------------------------------------------
-- fact_payment
-- -------------------------------------------------------
CREATE TABLE fact_payment (
    payment_id          SMALLINT      NOT NULL PRIMARY KEY,
    payment_date_key    INT           NOT NULL,
    customer_key        INT           NOT NULL,
    staff_key           INT           NOT NULL,
    rental_id           INT,
    film_key            INT,
    store_key           INT,
    payment_amount      DECIMAL(5,2)  NOT NULL,
    payment_count       TINYINT       NOT NULL DEFAULT 1,

    FOREIGN KEY (payment_date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (customer_key)     REFERENCES dim_customer(customer_key),
    FOREIGN KEY (staff_key)        REFERENCES dim_staff(staff_key),
    FOREIGN KEY (film_key)         REFERENCES dim_film(film_key),
    FOREIGN KEY (store_key)        REFERENCES dim_store(store_key)
);

-- Performance indexes for fact_payment
CREATE INDEX idx_fact_payment_payment_date_key ON fact_payment(payment_date_key);
CREATE INDEX idx_fact_payment_customer_key ON fact_payment(customer_key);
CREATE INDEX idx_fact_payment_staff_key ON fact_payment(staff_key);
CREATE INDEX idx_fact_payment_rental_id ON fact_payment(rental_id);
CREATE INDEX idx_fact_payment_film_key ON fact_payment(film_key);
CREATE INDEX idx_fact_payment_store_key ON fact_payment(store_key);

-- -------------------------------------------------------
-- Verify everything
-- -------------------------------------------------------
SELECT table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'sakila_dw'
ORDER BY table_name;