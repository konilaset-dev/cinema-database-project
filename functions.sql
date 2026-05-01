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
