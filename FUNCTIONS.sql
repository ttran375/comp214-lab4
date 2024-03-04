-- Hands-On Assignments Part I

-- Assignment 6-1: Formatting Numbers as Currency
-- Many of the Brewbean’s application pages and reports generated from the database display
-- dollar amounts. Follow these steps to create a function that formats the number provided as
-- an argument with a dollar sign, commas, and two decimal places:
-- 1. Create a function named DOLLAR_FMT_SF with the following code:
-- CREATE OR REPLACE FUNCTION dollar_fmt_sf
-- (p_num NUMBER)
-- RETURN VARCHAR2
-- IS
-- lv_amt_txt VARCHAR2(20);
-- BEGIN
-- lv_amt_txt := TO_CHAR(p_num,'$99,999.99');
-- RETURN lv_amt_txt;
-- END;
-- 2. Test the function by running the following anonymous PL/SQL block. Your results should
-- match Figure 6-23.
-- DECLARE
-- lv_amt_num NUMBER(8,2) := 9999.55;
-- BEGIN
-- DBMS_OUTPUT.PUT_LINE(dollar_fmt_sf(lv_amt_num));
-- END;
-- 3. Test the function with the following SQL statement. Your results should match Figure 6-24.
-- SELECT dollar_fmt_sf(shipping), dollar_fmt_sf(total)
-- FROM bb_basket
-- WHERE idBasket = 3;
CREATE OR REPLACE FUNCTION dollar_fmt_sf (
  p_num NUMBER
) RETURN VARCHAR2 IS
  lv_amt_txt VARCHAR2(20);
BEGIN
  lv_amt_txt := TO_CHAR(p_num, '$99,999.99');
  RETURN lv_amt_txt;
END;
/

DECLARE
  lv_amt_num NUMBER(8, 2) := 9999.55;
BEGIN
  DBMS_OUTPUT.PUT_LINE(dollar_fmt_sf(lv_amt_num));
END;
/

SELECT
  dollar_fmt_sf(shipping),
  dollar_fmt_sf(total)
FROM
  bb_basket
WHERE
  idBasket = 3;

-- Assignment 6-2: Calculating a Shopper’s Total Spending
-- Many of the reports generated from the system calculate the total dollars in a shopper’s
-- purchases. Follow these steps to create a function named TOT_PURCH_SF that accepts a
-- shopper ID as input and returns the total dollars the shopper has spent with Brewbean’s. Use
-- the function in a SELECT statement that shows the shopper ID and total purchases for every
-- shopper in the database.
-- 1. Develop and run a CREATE FUNCTION statement to create the TOT_PURCH_SF function.
-- The function code needs a formal parameter for the shopper ID and to sum the TOTAL
-- column of the BB_BASKET table.
-- 2. Develop a SELECT statement, using the BB_SHOPPER table, to produce a list of each
-- shopper in the database and his or her total purchases.
-- Step 1: Create the function TOT_PURCH_SF
CREATE OR REPLACE FUNCTION TOT_PURCH_SF(
  shopper_id IN NUMBER
) RETURN NUMBER IS
  total_spent NUMBER(7, 2);
BEGIN
 -- Calculate the total dollars spent by the shopper
  SELECT
    SUM(b.Total) INTO total_spent
  FROM
    bb_basket b
  WHERE
    b.idShopper = shopper_id;
  RETURN total_spent;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 0; -- Return 0 if no data found
END;
/

-- Step 2: Use the function in a SELECT statement
SELECT
  idShopper,
  TOT_PURCH_SF(idShopper) AS Total_Purchases
FROM
  bb_shopper;

-- Assignment 6-3: Calculating a Shopper’s Total Number of Orders
-- Another commonly used statistic in reports is the total number of orders a shopper has placed.
-- Follow these steps to create a function named NUM_PURCH_SF that accepts a shopper ID and
-- returns a shopper’s total number of orders. Use the function in a SELECT statement to display
-- the number of orders for shopper 23.
-- 1. Develop and run a CREATE FUNCTION statement to create the NUM_PURCH_SF function.
-- The function code needs to tally the number of orders (using an Oracle built-in function)
-- by shopper. Keep in mind that the ORDERPLACED column contains a 1 if an order has
-- been placed.
-- 2. Create a SELECT query by using the NUM_PURCH_SF function on the IDSHOPPER column
-- of the BB_SHOPPER table. Be sure to select only shopper 23.
-- Step 1: Create the function NUM_PURCH_SF
CREATE OR REPLACE FUNCTION NUM_PURCH_SF(
  p_shopper_id IN NUMBER
) RETURN NUMBER AS
  v_total_orders NUMBER;
BEGIN
 -- Count the total number of orders for the specified shopper
  SELECT
    COUNT(*) INTO v_total_orders
  FROM
    bb_basket
  WHERE
    idShopper = p_shopper_id
    AND orderplaced = 1; -- considering 'orderplaced' column contains 1 for placed orders
  RETURN v_total_orders;
END;
/

-- Step 2: Use the function to display the number of orders for shopper 23
SELECT
  NUM_PURCH_SF(23) AS Total_Orders
FROM
  dual;

-- Assignment 6-4: Identifying the Weekday for an Order Date
-- The day of the week that baskets are created is often analyzed to determine consumershopping patterns. Create a function named DAY_ORD_SF that accepts an order date and
-- returns the weekday. Use the function in a SELECT statement to display each basket ID and the
-- weekday the order was created. Write a second SELECT statement, using this function to
-- display the total number of orders for each weekday. (Hint: Call the TO_CHAR function to retrieve
-- the weekday from a date.)
-- 1. Develop and run a CREATE FUNCTION statement to create the DAY_ORD_SF function. Use
-- the DTCREATED column of the BB_BASKET table as the date the basket is created. Call
-- the TO_CHAR function with the DAY option to retrieve the weekday for a date value.
-- 2. Create a SELECT statement that lists the basket ID and weekday for every basket.
-- 3. Create a SELECT statement, using a GROUP BY clause to list the total number of baskets
-- per weekday. Based on the results, what’s the most popular shopping day?
-- 1. Create the DAY_ORD_SF function
CREATE OR REPLACE FUNCTION DAY_ORD_SF(
  order_date IN DATE
) RETURN VARCHAR2 IS
BEGIN
  RETURN TO_CHAR(order_date, 'Day');
END;
/

-- 2. Use the function to display each basket ID and the weekday
SELECT
  idBasket,
  DAY_ORD_SF(dtCreated) AS weekday
FROM
  bb_basket;

-- 3. Use the function in another SELECT statement with a GROUP BY clause
--    to list the total number of baskets per weekday
SELECT
  DAY_ORD_SF(dtCreated) AS weekday,
  COUNT(*)              AS total_orders
FROM
  bb_basket
GROUP BY
  DAY_ORD_SF(dtCreated)
ORDER BY
  total_orders DESC;

-- Assignment 6-5: Calculating Days Between Ordering and Shipping
-- An analyst in the quality assurance office reviews the time elapsed between receiving an order
-- and shipping the order. Any orders that haven’t been shipped within a day of the order being
-- placed are investigated. Create a function named ORD_SHIP_SF that calculates the number of
-- days between the basket’s creation date and the shipping date. The function should return a
-- character string that states OK if the order was shipped within a day or CHECK if it wasn’t. If the
-- order hasn’t shipped, return the string Not shipped. The IDSTAGE column of the
-- BB_BASKETSTATUS table indicates a shipped item with the value 5, and the DTSTAGE
-- column is the shipping date. The DTORDERED column of the BB_BASKET table is the order
-- date. Review data in the BB_BASKETSTATUS table, and create an anonymous block to test all
-- three outcomes the function should handle.
CREATE OR REPLACE FUNCTION ORD_SHIP_SF(
  p_basket_id IN NUMBER
) RETURN VARCHAR2 AS
  v_ship_date  DATE;
  v_order_date DATE;
  v_days_diff  NUMBER;
  v_status_id  NUMBER;
BEGIN
 -- Retrieve shipping date and order date
  SELECT
    bs.dtstage,
    b.dtordered,
    bs.idstage INTO v_ship_date,
    v_order_date,
    v_status_id
  FROM
    bb_basketstatus bs
    JOIN bb_basket b
    ON bs.idbasket = b.idbasket
  WHERE
    b.idbasket = p_basket_id
    AND bs.idstage = 5; -- Assuming IDSTAGE 5 indicates shipped status
 -- If the order hasn't been shipped, return 'Not shipped'
  IF v_ship_date IS NULL THEN
    RETURN 'Not shipped';
  ELSE
 -- Calculate days difference
    v_days_diff := v_ship_date - v_order_date;
 -- If shipped within a day, return 'OK'
    IF v_days_diff <= 1 THEN
      RETURN 'OK';
    ELSE
      RETURN 'CHECK';
    END IF;
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 'No such basket found';
END;
/

-- Anonymous block to test the function
DECLARE
  v_result VARCHAR2(20);
BEGIN
 -- Test case 1: Order shipped within a day
  v_result := ORD_SHIP_SF(3); -- Assuming basket ID 3
  DBMS_OUTPUT.PUT_LINE('Result for Basket 3: '
                       || v_result);
 -- Test case 2: Order shipped after a day
  v_result := ORD_SHIP_SF(4); -- Assuming basket ID 4
  DBMS_OUTPUT.PUT_LINE('Result for Basket 4: '
                       || v_result);
 -- Test case 3: Order not yet shipped
  v_result := ORD_SHIP_SF(7); -- Assuming basket ID 7
  DBMS_OUTPUT.PUT_LINE('Result for Basket 7: '
                       || v_result);
END;
/

-- Assignment 6-6: Adding Descriptions for Order Status Codes
-- When a shopper returns to the Web site to check an order’s status, information from the
-- BB_BASKETSTATUS table is displayed. However, only the status code is available in the
-- BB_BASKETSTATUS table, not the status description. Create a function named STATUS_DESC_SF
-- that accepts a stage ID and returns the status description. The descriptions for stage IDs
-- are listed in Table 6-3. Test the function in a SELECT statement that retrieves all rows in the
-- BB_BASKETSTATUS table for basket 4 and displays the stage ID and its description.

-- Assignment 6-7: Calculating an Order’s Tax Amount
-- Create a function named TAX_CALC_SF that accepts a basket ID, calculates the tax amount
-- by using the basket subtotal, and returns the correct tax amount for the order. The tax is
-- determined by the shipping state, which is stored in the BB_BASKET table. The BB_TAX table
-- contains the tax rate for states that require taxes on Internet purchases. If the state isn’t listed
-- in the tax table or no shipping state is assigned to the basket, a tax amount of zero should be
-- applied to the order. Use the function in a SELECT statement that displays the shipping costs for
-- a basket that has tax applied and a basket with no shipping state.

-- Assignment 6-8: Identifying Sale Products
-- When a product is placed on sale, Brewbean’s records the sale’s start and end dates in
-- columns of the BB_PRODUCT table. A function is needed to provide sales information when a
-- shopper selects an item. If a product is on sale, the function should return the value ON SALE!.
-- However, if it isn’t on sale, the function should return the value Great Deal!. These values are
-- used on the product display page. Create a function named CK_SALE_SF that accepts a date and
-- product ID as arguments, checks whether the date falls within the product’s sale period, and returns
-- the corresponding string value. Test the function with the product ID 6 and two dates: 10-JUN-12
-- and 19-JUN-12. Verify your results by reviewing the product sales information.

-- Hands-On Assignments Part II

-- Assignment 6-9: Determining the Monthly Payment Amount
-- Create a function named DD_MTHPAY_SF that calculates and returns the monthly payment
-- amount for donor pledges paid on a monthly basis. Input values should be the number of
-- monthly payments and the pledge amount. Use the function in an anonymous PL/SQL block
-- to show its use with the following pledge information: pledge amount = $240 and monthly
-- payments = 12. Also, use the function in an SQL statement that displays information for all
-- donor pledges in the database on a monthly payment plan.

-- Assignment 6-10: Calculating the Total Project Pledge Amount
-- Create a function named DD_PROJTOT_SF that determines the total pledge amount for a project.
-- Use the function in an SQL statement that lists all projects, displaying project ID, project name,
-- and project pledge total amount. Format the pledge total to display zero if no pledges have been
-- made so far, and have it show a dollar sign, comma, and two decimal places for dollar values.

-- Assignment 6-11: Identifying Pledge Status
-- The DoGood Donor organization decided to reduce SQL join activity in its application by
-- eliminating the DD_STATUS table and replacing it with a function that returns a status description
-- based on the status ID value. Create this function and name it DD_PLSTAT_SF. Use the function
-- in an SQL statement that displays the pledge ID, pledge date, and pledge status for all pledges.
-- Also, use it in an SQL statement that displays the same values but for only a specified pledge.

-- Assignment 6-12: Determining a Pledge’s First Payment Date
-- Create a function named DD_PAYDATE1_SF that determines the first payment due date for a
-- pledge based on pledge ID. The first payment due date is always the first day of the month
-- after the date the pledge was made, even if a pledge is made on the first of a month. Keep in
-- mind that a pledge made in December should reflect a first payment date with the following
-- year. Use the function in an anonymous block.

-- Assignment 6-13: Determining a Pledge’s Final Payment Date
-- Create a function named DD_PAYEND_SF that determines the final payment date for a pledge
-- based on pledge ID. Use the function created in Assignment 6-12 in this new function to help
-- with the task. If the donation pledge indicates a lump sum payment, the final payment date is
-- the same as the first payment date. Use the function in an anonymous block.

-- Case Projects

-- Case 6-1: Updating Basket Data at Order Completion
-- A number of functions created in this chapter assume that the basket amounts, including
-- shipping, tax, and total, are already posted to the BB_BASKET table. However, the program
-- units for updating these columns when a shopper checks out haven’t been developed yet.
-- A procedure is needed to update the following columns in the BB_BASKET table when an order
-- is completed: ORDERPLACED, SUBTOTAL, SHIPPING, TAX, and TOTAL.
-- Construct three functions to perform the following tasks: calculating the subtotal by using
-- the BB_BASKETITEM table based on basket ID as input, calculating shipping costs based on
-- basket ID as input, and calculating the tax based on basket ID and subtotal as input. Use these
-- functions in a procedure.
-- A value of 1 entered in the ORDERPLACED column indicates that the shopper has
-- completed the order. The subtotal is determined by totaling the item lines of the BB_BASKETITEM
-- table for the applicable basket number. The shipping cost is based on the number of items in the
-- basket: 1 to 4 = $5, 5 to 9 = $8, and more than 10 = $11.
-- The tax is based on the rate applied by referencing the SHIPSTATE column of the
-- BB_BASKET table with the STATE column of the BB_TAX table. This rate should be multiplied
-- by the basket subtotal, which should be an INPUT parameter to the tax calculation because
-- the subtotal is being calculated in this same procedure. The total tallies all these amounts.
-- The only INPUT parameter for the procedure is a basket ID. The procedure needs to
-- update the correct row in the BB_BASKET table with all these amounts. To test, first set
-- all column values to NULL for basket 3 with the following UPDATE statement. Then call the
-- procedure for basket 3 and check the INSERT results.
-- UPDATE bb_basket
-- SET orderplaced = NULL,
-- Subtotal = NULL,
-- Tax = NULL,
-- Shipping = NULL,
-- Total = NULL
-- WHERE idBasket = 3;
-- COMMIT;

-- Case 6-2: Working with More Movies Rentals
-- More Movies receives numerous requests to check whether movies are in stock. The company
-- needs a function that retrieves movie stock information and formats a clear message to display
-- to users requesting information. The display should resemble the following: “Star Wars is
-- Available: 11 on the shelf.”
-- Use movie ID as the input value for this function. Assume the MOVIE_QTY column in the
-- MM_MOVIES table indicates the number of movies currently available for checkout.
