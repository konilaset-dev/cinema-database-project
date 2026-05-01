----TRANSACTIONS(ACID)

BEGIN;

INSERT INTO orders_new (order_id, user_id, order_date, status)
VALUES (500, 1, CURRENT_DATE, 'reserved');

COMMIT;

BEGIN;

INSERT INTO orders_new (order_id, user_id, order_date, status)
VALUES (601, 1, CURRENT_DATE, 'reserved');
COMMIT;

ROLLBACK;
SELECT * FROM orders_new WHERE order_id = 601; 


BEGIN;                                             --Transaction: Booking_Process

INSERT INTO orders_new (order_id, user_id, order_date, status)
VALUES (602, 1, CURRENT_DATE, 'reserved');

SAVEPOINT sp1;

INSERT INTO order_items VALUES (602, 2, 'B70', 3000);

                                                  -- қате әрекет (орын бос емес)
INSERT INTO order_items VALUES (602, 2, 'B1', 3000);

ROLLBACK TO sp1;

--                                                    дұрыс билет
INSERT INTO order_items VALUES (602, 2, 'B71', 3000);

COMMIT;




--------------------------------------test jurgizu
BEGIN;

INSERT INTO orders_new VALUES (801, 1, CURRENT_DATE, 'reserved');

ROLLBACK;

SELECT * FROM orders_new WHERE order_id = 801;
