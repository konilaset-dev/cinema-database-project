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
