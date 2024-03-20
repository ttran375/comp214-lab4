-- Assignment 9-1: Creating a Trigger to Handle Product Restocking
-- Brewbean’s has a couple of columns in the product table to assist in inventory tracking. The
-- REORDER column contains the stock level at which the product should be reordered. If the
-- stock falls to this level, Brewbean’s wants the application to insert a row in the
-- BB_PRODUCT_REQUEST table automatically to alert the ordering clerk that additional
-- inventory is needed. Brewbean’s currently uses the reorder level amount as the quantity that
-- should be ordered. This task can be handled by using a trigger.
-- 1. Take out some scrap paper and a pencil. Think about the tasks the triggers needs to
-- perform, including checking whether the new stock level falls below the reorder point. If so,
-- check whether the product is already on order by viewing the product request table; if not,
-- enter a new product request. Try to write the trigger code on paper. Even though you learn
-- a lot by reviewing code, you improve your skills faster when you create the code on
-- your own.
-- 2. Open the c9reorder.txt file in the Chapter09 folder. Review this trigger code, and
-- determine how it compares with your code.
-- 3. In SQL Developer, create the trigger with the provided code.
-- 4. Test the trigger with product ID 4. First, run the query shown in Figure 9-36 to verify the
-- current stock data for this product. Notice that a sale of one more item should initiate
-- a reorder.
-- FIGURE 9-36 Checking stock data
-- 5. Run the UPDATE statement shown in Figure 9-37. It should cause the trigger to fire. Notice
-- the query to check whether the trigger fired and whether a product stock request was
-- inserted in the BB_PRODUCT_REQUEST table.
-- 6. Issue a ROLLBACK statement to undo these DML actions to restore data to its original state
-- for use in later assignments.
-- 7. Run the following statement to disable this trigger so that it doesn’t affect other projects:
-- ALTER TRIGGER bb_reorder_trg DISABLE;
-- Run script to create trigger
CREATE OR REPLACE TRIGGER bb_reorder_trg AFTER
  UPDATE OF stock ON bb_product FOR EACH ROW
DECLARE
  v_onorder_num NUMBER(4);
BEGIN
  IF :NEW.stock <= :NEW.reorder THEN
    SELECT
      SUM(qty) INTO v_onorder_num
    FROM
      bb_product_request
    WHERE
      idProduct = :NEW.idProduct
      AND dtRecd IS NULL;
    IF v_onorder_num IS NULL THEN
      v_onorder_num := 0;
    END IF;

    IF v_onorder_num = 0 THEN
      INSERT INTO bb_product_request (
        idRequest,
        idProduct,
        dtRequest,
        qty
      ) VALUES (
        bb_prodreq_seq.NEXTVAL,
        :NEW.idProduct,
        SYSDATE,
        :NEW.reorder
      );
    END IF;
  END IF;
END;
/

-- Show that sale of one more of product 4
-- should initiate a reorder
SELECT
  stock,
  reorder
FROM
  bb_product
WHERE
  idProduct = 4;

/

-- Show that 4 is not currently up for reorder
SELECT
  idproduct,
  idrequest,
  dtrequest,
  qty
FROM
  bb_product_request;

/

-- Set stock equal to reorder number,
-- so trigger will fire
UPDATE bb_product
SET
  stock = 25
WHERE
  idProduct = 4;

/

-- Show that trigger fired
SELECT
  idproduct,
  idrequest,
  dtrequest,
  qty
FROM
  bb_product_request;

/

-- Rollback changes/disable trigger
ROLLBACK;

-- DROP TRIGGER bb_reorder_trg;

/

-- Assignment 9-2: Updating Stock Information When a Product Request Is Filled
-- Brewbean’s has a BB_PRODUCT_REQUEST table where requests to refill stock levels are
-- inserted automatically via a trigger. After the stock level falls below the reorder level, this trigger
-- fires and enters a request in the table. This procedure works great; however, when store clerks
-- record that the product request has been filled by updating the table’s DTRECD and COST
-- columns, they want the stock level in the product table to be updated. Create a trigger named
-- BB_REQFILL_TRG to handle this task, using the following steps as a guideline:
-- 1. In SQL Developer, run the following INSERT statement to create a product request you can
-- use in this assignment:
-- INSERT INTO bb_product_request (idRequest, idProduct, dtRequest, qty)
-- VALUES (3, 5, SYSDATE, 45);
-- COMMIT;
-- 2. Create the trigger (BB_REQFILL_TRG) so that it fires when a received date is entered in the
-- BB_PRODUCT_REQUEST table. This trigger needs to modify the STOCK column in the
-- BB_PRODUCT table to reflect the increased inventory.
-- 3. Now test the trigger. First, query the stock and reorder data for product 5, as shown in
-- Figure 9-38.
-- Stock level currently
-- below reorder level
-- Current request for
-- a quantity of 45
-- FIGURE 9-38 Querying the data for product 5 stock and reorder amount
-- An UPDATE statement
-- that records receiving a
-- request res the trigger.
-- Order received
-- Stock level increased
-- FIGURE 9-39 Updating the product request
-- 4. Now update the product request to record it as fulfilled by using the UPDATE statement
-- shown in Figure 9-39.
-- 5. Issue queries to verify that the trigger fired and the stock level of product 5 has been
-- modified correctly. Then issue a ROLLBACK statement to undo the modifications.
-- 6. If you aren’t doing Assignment 9-3, disable the trigger so that it doesn’t affect
-- other assignments.
-- create product request
INSERT INTO bb_product_request (
  idrequest,
  idproduct,
  dtrequest,
  qty
) VALUES (
  3,
  5,
  sysdate,
  45
);

/

-- Creat trigger to handle updating stock
CREATE OR REPLACE TRIGGER bb_reqfill_trg AFTER
  UPDATE OF dtrecd ON bb_product_request FOR EACH ROW
BEGIN
 /* update bb_product and set stock equal to
      the new qty (from bb_product_update) plus
      the old stock, where the id equals the
      id referenced by the update that fired 
      the trigger. */
  UPDATE bb_product
  SET
    stock = :new.qty + stock
  WHERE
    idproduct = :new.idproduct;
END;
/

-- show that product 5 is below reorder amount
SELECT
  stock,
  reorder
FROM
  bb_product
WHERE
  idproduct = 5;

/

-- Show that 5 is currently up for reorder
SELECT
  idproduct,
  idrequest,
  dtrequest,
  cost,
  qty
FROM
  bb_product_request;

/

-- Do update and fire trigger
UPDATE bb_product_request
SET
  dtrecd = sysdate,
  cost = 225
WHERE
  idproduct = 5;

/

-- show that order was fulfilled
SELECT
  idproduct,
  idrequest,
  dtrequest,
  cost,
  qty
FROM
  bb_product_request;

/

-- show that trigger fired and stock was updated
SELECT
  stock,
  reorder
FROM
  bb_product
WHERE
  idproduct = 5;

/

-- Undo all our effort
ROLLBACK;

-- DROP TRIGGER bb_reqfill_trg;

/

-- Assignment 9-3: Updating the Stock Level If a Product Fulfillment Is Canceled
-- The Brewbean’s developers have made progress on the inventory-handling processes;
-- however, they hit a snag when a store clerk incorrectly recorded a product request as fulfilled.
-- When the product request was updated to record a DTRECD value, the product’s stock level
-- was updated automatically via an existing trigger, BB_REQFILL_TRG. If the clerk empties the
-- DTRECD column to indicate that the product request hasn’t been filled, the product’s stock
-- level needs to be corrected or reduced, too. Modify the BB_REQFILL_TRG trigger to solve
-- this problem.
-- 1. Modify the trigger code from Assignment 9-2 as needed. Add code to check whether the
-- DTRECD column already has a date in it and is now being set to NULL.
-- 2. Issue the following DML actions to create and update rows that you can use to test
-- the trigger:
-- INSERT INTO bb_product_request (idRequest, idProduct, dtRequest, qty,
-- dtRecd, cost)
-- VALUES (4, 5, SYSDATE, 45, '15-JUN-2012',225);
-- UPDATE bb_product
-- SET stock = 86
-- WHERE idProduct = 5;
-- COMMIT;
-- 3. Run the following UPDATE statement to test the trigger, and issue queries to verify that the
-- data has been modified correctly.
-- UPDATE bb_product_request
-- SET dtRecd = NULL
-- WHERE idRequest = 4;
-- 4. Be sure to run the following statement to disable this trigger so that it doesn’t affect other
-- assignments:
-- ALTER TRIGGER bb_reqfill_trg DISABLE;
CREATE OR REPLACE TRIGGER BB_REQFILL_TRG AFTER
  UPDATE OF DTRECD ON BB_PRODUCT_REQUEST FOR EACH ROW
DECLARE
  v_qty NUMBER;
BEGIN
  IF :OLD.DTRECD IS NOT NULL AND :NEW.DTRECD IS NULL THEN
 -- Product request is being marked as not filled
 -- Adjust the product stock level
    SELECT
      qty INTO v_qty
    FROM
      bb_product_request
    WHERE
      idRequest = :OLD.idRequest;
    UPDATE bb_product
    SET
      stock = stock + v_qty
    WHERE
      idProduct = :OLD.idProduct;
  END IF;
END;
/

ALTER TRIGGER BB_REQFILL_TRG DISABLE;

-- Assignment 9-4: Updating Stock Levels When an Order Is Canceled
-- At times, customers make mistakes in submitting orders and call to cancel an order. Brewbean’s
-- wants to create a trigger that automatically updates the stock level of all products associated
-- with a canceled order and updates the ORDERPLACED column of the BB_BASKET table to
-- zero, reflecting that the order wasn’t completed. Create a trigger named BB_ORDCANCEL_TRG to
-- perform this task, taking into account the following points:
-- • The trigger needs to fire when a new status record is added to the
-- BB_BASKETSTATUS table and when the IDSTAGE column is set to 4,
-- which indicates an order has been canceled.
--  Each basket can contain multiple items in the BB_BASKETITEM table, so a
-- CURSOR FOR loop might be a suitable mechanism for updating each item’s stock
-- level.
-- • Keep in mind that coffee can be ordered in half or whole pounds.
-- • Use basket 6, which contains two items, for testing.
-- 1. Run this INSERT statement to test the trigger:
-- INSERT INTO bb_basketstatus (idStatus, idBasket, idStage, dtStage)
-- VALUES (bb_status_seq.NEXTVAL, 6, 4, SYSDATE);
-- 2. Issue queries to confirm that the trigger has modified the basket’s order status and product
-- stock levels correctly.
-- 3. Be sure to run the following statement to disable this trigger so that it doesn’t affect other
-- assignments:

CREATE OR REPLACE TRIGGER BB_ORDCANCEL_TRG AFTER
  INSERT ON bb_basketstatus FOR EACH ROW WHEN (NEW.idStage = 4)
DECLARE
  v_qty_ordered NUMBER;
BEGIN
 -- Retrieving the quantity ordered for the canceled order
  SELECT
    SUM(bi.Quantity) INTO v_qty_ordered
  FROM
    bb_basketitem bi
  WHERE
    bi.idBasket = :NEW.idBasket;
 -- Updating the stock levels of the products associated with the canceled order
  FOR item IN (
    SELECT
      bi.idProduct,
      SUM(bi.Quantity) AS total_quantity
    FROM
      bb_basketitem bi
    WHERE
      bi.idBasket = :NEW.idBasket
    GROUP BY
      bi.idProduct
  ) LOOP
    UPDATE bb_product
    SET
      stock = stock + item.total_quantity
    WHERE
      idProduct = item.idProduct;
  END LOOP;
 -- Updating ORDERPLACED column of BB_BASKET table to zero
  UPDATE bb_basket
  SET
    orderplaced = 0
  WHERE
    idBasket = :NEW.idBasket;
END;
/

INSERT INTO bb_basketstatus (
  idStatus,
  idBasket,
  idStage,
  dtStage
) VALUES (
  bb_status_seq.NEXTVAL,
  6,
  4,
  SYSDATE
);

ALTER TRIGGER BB_REQFILL_TRG DISABLE;

-- Assignment 9-5: Processing Discounts
-- Brewbean’s is offering a new discount for return shoppers: Every fifth completed order gets a
-- 10% discount. The count of orders for a shopper is placed in a packaged variable named
-- pv_disc_num during the ordering process. This count needs to be tested at checkout to
-- determine whether a discount should be applied. Create a trigger named BB_DISCOUNT_TRG
-- so that when an order is confirmed (the ORDERPLACED value is changed from 0 to 1), the
-- pv_disc_num packaged variable is checked. If it’s equal to 5, set a second variable named
-- pv_disc_txt to Y. This variable is used in calculating the order summary so that a discount is
-- applied, if necessary.
-- Create a package specification named DISC_PKG containing the necessary packaged
-- variables. Use an anonymous block to initialize the packaged variables to use for testing the
-- trigger. Test the trigger with the following UPDATE statement:
-- UPDATE bb_basket
-- SET orderplaced = 1
-- WHERE idBasket = 13;
-- If you need to test the trigger multiple times, simply reset the ORDERPLACED column to 0
-- for basket 13 and then run the UPDATE again. Also, disable this trigger when you’re finished so
-- that it doesn’t affect other assignments.

CREATE OR REPLACE PACKAGE DISC_PKG AS
  pv_disc_num NUMBER := 0; -- Packaged variable to store the count of orders
  pv_disc_txt VARCHAR2(1) := 'N'; -- Packaged variable to indicate whether a discount should be applied
END DISC_PKG;
/

CREATE OR REPLACE TRIGGER BB_DISCOUNT_TRG AFTER
  UPDATE OF ORDERPLACED ON bb_basket FOR EACH ROW
BEGIN
  IF :NEW.ORDERPLACED = 1 THEN
    IF DISC_PKG.pv_disc_num = 5 THEN
      DISC_PKG.pv_disc_txt := 'Y';
    END IF;
  END IF;
END;
/

DECLARE
  v_dummy NUMBER;
BEGIN
  DISC_PKG.pv_disc_num := 5; -- Set the count of orders to 5 for testing
  DISC_PKG.pv_disc_txt := 'N'; -- Reset the discount indicator variable
  SELECT
    1 INTO v_dummy
  FROM
    dual
  WHERE
    DISC_PKG.pv_disc_txt = 'Y'; -- This will raise an exception if the trigger sets pv_disc_txt to 'Y'
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL; -- This is expected if the trigger does not set pv_disc_txt to 'Y'
END;
/

UPDATE bb_basket
SET
  orderplaced = 1
WHERE
  idBasket = 13;

ALTER TRIGGER BB_DISCOUNT_TRG DISABLE;

-- Assignment 9-6: Using Triggers to Maintain Referential Integrity
-- At times, Brewbean’s has changed the ID numbers for existing products. In the past, developers
-- had to add a new product row with the new ID to the BB_PRODUCT table, modify all the
-- corresponding BB_BASKETITEM and BB_PRODUCTOPTION table rows, and then delete the
-- original product row. Can a trigger be developed to avoid all these steps and handle the update
-- of the BB_BASKETITEM and BB_PRODUCTOPTION table rows automatically for a change in
-- product ID? If so, create the trigger and test it by issuing an UPDATE statement that changes the
-- IDPRODUCT 7 to 22. Do a rollback to return the data to its original state, and disable the new
-- trigger after you have finished this assignment.

CREATE OR REPLACE TRIGGER trg_update_product_id BEFORE
  UPDATE OF idProduct ON BB_PRODUCT FOR EACH ROW
BEGIN
 -- Update BB_BASKETITEM table
  UPDATE BB_BASKETITEM
  SET
    idProduct = :NEW.idProduct
  WHERE
    idProduct = :OLD.idProduct;
 -- Update BB_PRODUCTOPTION table
  UPDATE BB_PRODUCTOPTION
  SET
    idProduct = :NEW.idProduct
  WHERE
    idProduct = :OLD.idProduct;
END;
/

UPDATE BB_PRODUCT
SET
  idProduct = 22
WHERE
  idProduct = 7;

ROLLBACK;

ALTER TRIGGER trg_update_product_id DISABLE;

-- Assignment 9-7: Updating Summary Data Tables
-- The Brewbean’s owner uses several summary sales data tables every day to monitor business
-- activity. The BB_SALES_SUM table holds the product ID, total sales in dollars, and total
-- quantity sold for each product. A trigger is needed so that every time an order is confirmed or
-- the ORDERPLACED column is updated to 1, the BB_SALES_SUM table is updated
-- accordingly. Create a trigger named BB_SALESUM_TRG that performs this task. Before testing,
-- reset the ORDERPLACED column to 0 for basket 3, as shown in the following code, and use
-- this basket to test the trigger:
-- UPDATE bb_basket
-- SET orderplaced = 0
-- WHERE idBasket = 3;
-- Notice that the BB_SALES_SUM table already contains some data. Test the trigger with
-- the following UPDATE statement, and confirm that the trigger is working correctly:
-- UPDATE bb_basket
-- SET orderplaced = 1
-- WHERE idBasket = 3;
-- Do a rollback and disable the trigger when you’re finished so that it doesn’t affect other
-- assignments.
CREATE TABLE BB_SALES_SUM (
  idProduct NUMBER(2),
  TotalSales NUMBER(6, 2),
  TotalQtySold NUMBER(5)
);

ALTER TABLE BB_SALES_SUM ADD CONSTRAINT pk_bb_sales_sum PRIMARY KEY (idProduct);

UPDATE bb_basket
SET
  orderplaced = 0
WHERE
  idBasket = 3;

CREATE OR REPLACE TRIGGER BB_SALESUM_TRG AFTER
  UPDATE OF orderplaced ON bb_basket FOR EACH ROW WHEN (NEW.orderplaced = 1)
BEGIN
  FOR cur IN (
    SELECT
      idProduct,
      SUM(Price * Quantity) AS TotalSales,
      SUM(Quantity)         AS TotalQty
    FROM
      bb_basketItem
    WHERE
      idBasket = :NEW.idBasket
    GROUP BY
      idProduct
  ) LOOP
    UPDATE BB_SALES_SUM
    SET
      TotalSales = TotalSales + cur.TotalSales,
      TotalQtySold = TotalQtySold + cur.TotalQty
    WHERE
      idProduct = cur.idProduct;
    IF SQL%NOTFOUND THEN
      INSERT INTO BB_SALES_SUM (
        idProduct,
        TotalSales,
        TotalQtySold
      ) VALUES (
        cur.idProduct,
        cur.TotalSales,
        cur.TotalQty
      );
    END IF;
  END LOOP;
END;
/

UPDATE bb_basket
SET
  orderplaced = 1
WHERE
  idBasket = 3;

ROLLBACK;

ALTER TRIGGER BB_SALESUM_TRG DISABLE;

-- Assignment 9-8: Maintaining an Audit Trail of Product Table Changes
-- The accuracy of product table data is critical, and the Brewbean’s owner wants to have an audit
-- file containing information on all DML activity on the BB_PRODUCT table. This information
-- should include the ID of the user performing the DML action, the date, the original values of the
-- changed row, and the new values. This audit table needs to track specific columns of concern,
-- including PRODUCTNAME, PRICE, SALESTART, SALEEND, and SALEPRICE. Create a table
-- named BB_PRODCHG_AUDIT to hold the relevant data, and then create a trigger named
-- BB_AUDIT_TRG that fires an update to this table whenever a specified column in the
-- BB_PRODUCT table changes.
-- TIP
-- Multiple columns can be listed in a trigger’s OF clause by separating them with commas.
-- Be sure to issue the following command. If you created the SALES_DATE_TRG trigger in the
-- chapter, it conflicts with this assignment.
-- ALTER TRIGGER sales_date_trg DISABLE;
-- Use the following UPDATE statement to test the trigger:
-- UPDATE bb_product
-- SET salestart = '05-MAY-2012',
-- saleend = '12-MAY-2012'
-- saleprice = 9
-- WHERE idProduct = 10;
-- When you’re finished, do a rollback and disable the trigger so that it doesn’t affect other
-- assignments.

CREATE TABLE BB_PRODCHG_AUDIT (
  AUDIT_ID NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  USER_ID VARCHAR2(30),
  ACTION_DATE TIMESTAMP,
  PRODUCT_ID NUMBER(10),
  OLD_PRODUCTNAME VARCHAR2(255),
  NEW_PRODUCTNAME VARCHAR2(255),
  OLD_PRICE NUMBER,
  NEW_PRICE NUMBER,
  OLD_SALESTART DATE,
  NEW_SALESTART DATE,
  OLD_SALEEND DATE,
  NEW_SALEEND DATE,
  OLD_SALEPRICE NUMBER,
  NEW_SALEPRICE NUMBER
);

CREATE OR REPLACE TRIGGER BB_AUDIT_TRG AFTER
  UPDATE OF PRODUCTNAME, PRICE, SALESTART, SALEEND, SALEPRICE ON BB_PRODUCT FOR EACH ROW
BEGIN
  INSERT INTO BB_PRODCHG_AUDIT (
    USER_ID,
    ACTION_DATE,
    PRODUCT_ID,
    OLD_PRODUCTNAME,
    NEW_PRODUCTNAME,
    OLD_PRICE,
    NEW_PRICE,
    OLD_SALESTART,
    NEW_SALESTART,
    OLD_SALEEND,
    NEW_SALEEND,
    OLD_SALEPRICE,
    NEW_SALEPRICE
  ) VALUES (
    USER,
    SYSTIMESTAMP,
    :OLD.IDPRODUCT,
    :OLD.PRODUCTNAME,
    :NEW.PRODUCTNAME,
    :OLD.PRICE,
    :NEW.PRICE,
    :OLD.SALESTART,
    :NEW.SALESTART,
    :OLD.SALEEND,
    :NEW.SALEEND,
    :OLD.SALEPRICE,
    :NEW.SALEPRICE
  );
END;
/

UPDATE BB_PRODUCT
SET
  SALESTART = '05-MAY-2012',
  SALEEND = '12-MAY-2012',
  SALEPRICE = 9
WHERE
  IDPRODUCT = 10;

ROLLBACK;

ALTER TRIGGER BB_AUDIT_TRG DISABLE;
