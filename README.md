# cinema-database-project
Cinema ticket booking database project (PostgreSQL)

------------------------------------------------------------PROCEDURES
CREATE OR REPLACE PROCEDURE create_booking(
    p_user_name VARCHAR,
    p_movie_title VARCHAR,
    p_hall VARCHAR,
    p_time TIMESTAMP,
    p_seat VARCHAR,
    p_price NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO cinema(
        user_name, movie_title, hall, session_time, seat_number, ticket_price, status
    )
    VALUES ( p_user_name, p_movie_title, p_hall, p_time, p_seat, p_price, 'reserved'
    );
END;
$$;
CALL create_booking('Damira','Avatar 2','Hall 1','2026-05-15 18:00','B4',3000)

-----------------------------------------------------------------------------2--ПРОЦЕДУРА
CREATE OR REPLACE PROCEDURE make_payment(
    p_user_name VARCHAR,
    p_movie_title VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE cinema
    SET status = 'reserved'
    WHERE user_name = p_user_name 
	AND movie_title = p_movie_title;
END;
$$;
CALL make_payment('Asan','Batman');
SELECT * FROM cinema
------------------------------------------------------------------------3--ПРОЦЕДУРА
CREATE OR REPLACE PROCEDURE make_students_paid()
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE cinema_data
    SET status = 'paid'
    WHERE ticket_price = 1500;

    RAISE NOTICE '1500 төлегендердің статусы жаңартылды';
END;
$$;
CALL make_students_paid()

-------------------------------------------------------------------------4--ПРОЦЕДУРА

CREATE OR REPLACE PROCEDURE delete_row(p_id INT)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM cinema
    WHERE id = p_id;
END;
$$;
CALL delete_row(7);
SELECT * FROM cinema;

---------------------------------------------------------FUNCTIONS
CREATE OR REPLACE FUNCTION total_income()
RETURNS NUMERIC(10,2) 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN (
        SELECT COALESCE(SUM(ticket_price),0)
        FROM cinema
        WHERE status = 'paid'
    );
END;
$$;
SELECT * FROM total_income()
----------------------------------------------------------------2 function
CREATE OR REPLACE FUNCTION booking_count(p_user_name VARCHAR)
RETURNS INT AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)
        FROM cinema
        WHERE user_name = p_user_name
    );
END;
$$ LANGUAGE plpgsql;
SELECT booking_count('Damira')

-----------------------------------------------------------------ФУНКЦИЯ--3
CREATE OR REPLACE FUNCTION calculate_user_total(p_user_name VARCHAR)
RETURNS NUMERIC(10,2)
LANGUAGE plpgsql
AS $$
DECLARE
    total_amount NUMERIC(10,2);
BEGIN
    SELECT SUM(ticket_price) INTO total_amount
    FROM cinema
    WHERE user_name = p_user_name  AND status = 'paid';

    IF total_amount IS NULL THEN
        RETURN 0;
    END IF;

    RETURN total_amount;
END;
$$;
SELECT calculate_user_total('Damira')

--------------------------------------------------------------TRIGGERS: ROW LEVEL
CREATE OR REPLACE FUNCTION prevent_double_booking()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM order_items
        WHERE session_id = NEW.session_id
          AND seat_number = NEW.seat_number
    ) THEN
        RAISE EXCEPTION 'This seat is already booked!';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_no_double
BEFORE INSERT ON order_items
FOR EACH ROW
EXECUTE FUNCTION prevent_double_booking();

INSERT INTO order_items VALUES (5, 2, 'B1', 3000);
INSERT INTO order_items VALUES (6, 2, 'B1', 3000);
------------------------------------------------------------------LOG LEVEL

CREATE TABLE booking_log (
    id SERIAL PRIMARY KEY,
    action TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION log_booking()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO booking_log(action)
    VALUES (
        'New booking: seat ' || NEW.seat_number ||
        ', session ' || NEW.session_id
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_log
AFTER INSERT ON order_items
FOR EACH ROW
EXECUTE FUNCTION log_booking();
INSERT INTO order_items VALUES (10, 2, 'B9', 3000);

INSERT INTO orders_new (order_id, user_id, order_date, status)
VALUES (11, 1, '2026-05-15', 'reserved');

SELECT * FROM booking_log;
----------------------------------------------------------STATEMENT LEVEL

CREATE OR REPLACE FUNCTION statement_log()
RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE 'order_items table modified';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_statement ON order_items;

CREATE TRIGGER trg_statement
AFTER INSERT ON order_items
FOR EACH STATEMENT
EXECUTE FUNCTION statement_log();

INSERT INTO order_items VALUES (2, 2, 'B99', 3000);


------------------------------------------------------------INSTEAD OF TRIGGER
CREATE OR REPLACE VIEW simple_view AS
SELECT 
    o.order_id,
    o.user_id,
    oi.session_id,
    oi.seat_number,
    oi.ticket_price,
    o.status
FROM orders_new o
JOIN order_items oi ON o.order_id = oi.order_id;

CREATE OR REPLACE FUNCTION instead_insert()
RETURNS TRIGGER AS $$
BEGIN
    -- 1. orders_new ішіне қосу (егер жоқ болса)
    INSERT INTO orders_new(order_id, user_id, order_date, status)
    VALUES (NEW.order_id, NEW.user_id, CURRENT_DATE, NEW.status)
    ON CONFLICT (order_id) DO NOTHING;

    -- 2. order_items ішіне қосу
    INSERT INTO order_items(order_id, session_id, seat_number, ticket_price)
    VALUES (NEW.order_id, NEW.session_id, NEW.seat_number, NEW.ticket_price);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_instead
INSTEAD OF INSERT ON simple_view
FOR EACH ROW
EXECUTE FUNCTION instead_insert();
INSERT INTO simple_view
(order_id, user_id, session_id, seat_number, ticket_price, status)
VALUES (20, 1, 2, 'B7', 3000, 'reserved');
SELECT * FROM simple_view

---------------------------------------------------------------------------------жуйелік триггер
CREATE OR REPLACE FUNCTION system_trigger_log()
RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE 'SYSTEM EVENT: Table order_items was modified';

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_system
AFTER INSERT OR UPDATE OR DELETE ON order_items
FOR EACH STATEMENT
EXECUTE FUNCTION system_trigger_log();

INSERT INTO order_items VALUES (1, 2, 'B40', 3000);
UPDATE order_items
SET ticket_price = 3500
WHERE seat_number = 'B1';
DELETE FROM order_items
WHERE seat_number = 'B2';


---------------------------------------------------------------------------------TRANSACTIONS(ACID)

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




--------------------------------------------------------------------------------test jurgizu
BEGIN;

INSERT INTO orders_new VALUES (801, 1, CURRENT_DATE, 'reserved');

ROLLBACK;

SELECT * FROM orders_new WHERE order_id = 801;
