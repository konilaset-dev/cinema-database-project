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


-------INSTEAD OF TRIGGER
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

-----------------------------------------------------------------------жуйелік триггер
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
