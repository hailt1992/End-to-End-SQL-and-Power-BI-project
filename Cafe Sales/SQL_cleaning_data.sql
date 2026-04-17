/* Replace space, UNKNOWN and ERROR value to NULL for the fields: 
item, quantity, price_per_unit, total_spent, payment_menthod, location, transaction_date*/

UPDATE dirty_cafe_sales 
SET item = NULL 
WHERE item = '' OR item = 'UNKNOWN' OR item = 'ERROR'

UPDATE dirty_cafe_sales 
SET quantity = NULL
WHERE quantity = '' OR quantity = 'UNKNOWN' OR quantity = 'ERROR'

UPDATE dirty_cafe_sales 
SET price_per_unit = NULL 
WHERE price_per_unit = '' OR price_per_unit = 'UNKNOWN' OR price_per_unit = 'ERROR'

UPDATE dirty_cafe_sales 
SET total_spent = NULL
WHERE total_spent = '' OR total_spent = 'UNKNOWN' OR total_spent = 'ERROR'

UPDATE dirty_cafe_sales 
SET payment_menthod = NULL
WHERE payment_menthod = '' OR payment_menthod = 'UNKNOWN' OR payment_menthod = 'ERROR'

UPDATE dirty_cafe_sales 
SET location = NULL
WHERE location = '' OR location = 'UNKNOWN' OR location = 'ERROR'

UPDATE dirty_cafe_sales 
SET transaction_date = NULL
WHERE transaction_date = '' OR transaction_date = 'UNKNOWN' OR transaction_date = 'ERROR'

-- Check NULL values: 

SELECT  COUNT (CASE WHEN transaction_date IS NULL THEN 1 END) AS missing_transaction_date,
		COUNT (CASE WHEN payment_menthod IS NULL THEN 1 END) AS missing_payment_menthod,
		COUNT (CASE WHEN location IS NULL THEN 1 END) AS missing_location,
		COUNT (CASE WHEN item IS NULL THEN 1 END) AS missing_item,
        COUNT (CASE WHEN price_per_unit IS NULL THEN 1 END) AS missing_price_per_unit,
        COUNT (CASE WHEN quantity IS NULL THEN 1 END) AS missing_quantity,
        COUNT (CASE WHEN total_spent IS NULL THEN 1 END) AS missing_total_spent
FROM dirty_cafe_sales dcs 

SELECT * FROM dirty_cafe_sales 

/*RESULT: number of blank + UNKNOWN + ERROR value for each field
 Date | Payment_menthod | Location | Item | Unit_price | Quantity | Total | 
  460 |      3178       |    3961  |  969 |    533     |    479   |  502  | */

-- Fill NULL value by Joining menu table 

UPDATE dirty_cafe_sales d
SET price_per_unit = m.price
FROM menu m 
WHERE d.item = m.item AND d.price_per_unit IS NULL

UPDATE dirty_cafe_sales d
SET item = m.item
FROM menu m 
WHERE d.price_per_unit = m.price AND d.item IS NULL

-- Change data type from varchar to float

ALTER TABLE dirty_cafe_sales 
ALTER COLUMN quantity TYPE float
USING quantity :: float,
ALTER COLUMN price_per_unit TYPE float
USING price_per_unit :: float,
ALTER COLUMN total_spent TYPE float
USING total_spent :: float

-- Calculate price_per_unit, quantity and total_spent fields for missing data

UPDATE dirty_cafe_sales 
SET price_per_unit = total_spent/quantity
WHERE price_per_unit IS NULL


UPDATE dirty_cafe_sales 
SET quantity = total_spent/price_per_unit
WHERE quantity IS NULL

UPDATE dirty_cafe_sales 
SET total_spent = quantity*price_per_unit
WHERE total_spent IS NULL

-- Check NULL value: 

SELECT  COUNT (CASE WHEN transaction_date IS NULL THEN 1 END) AS missing_transaction_date,
		COUNT (CASE WHEN payment_menthod IS NULL THEN 1 END) AS missing_payment_menthod,
		COUNT (CASE WHEN location IS NULL THEN 1 END) AS missing_location,
		COUNT (CASE WHEN item IS NULL THEN 1 END) AS missing_item,
        COUNT (CASE WHEN price_per_unit IS NULL THEN 1 END) AS missing_price_per_unit,
        COUNT (CASE WHEN quantity IS NULL THEN 1 END) AS missing_quantity,
        COUNT (CASE WHEN total_spent IS NULL THEN 1 END) AS missing_total_spent
FROM dirty_cafe_sales dcs 

/*RESULT: number of blank + UNKNOWN + ERROR value for each field
 Date | Payment_menthod | Location | Item | Unit_price | Quantity | Total | 
  460 |       3178      |    3961  |   6  |     6      |     23   |   23  | */

SELECT * FROM dirty_cafe_sales 
WHERE item IS NULL OR quantity IS NULL OR price_per_unit IS NULL OR total_spent IS NULL 


