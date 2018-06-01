-- Create API user if not exists
DROP USER IF EXISTS app;
CREATE USER app WITH password 'qwerty';

-- TODO
-- CREATE SEQUENCE seq_emp_id;

-- Create tables
CREATE TABLE IF NOT EXISTS employee(id SERIAL PRIMARY KEY,
                                    dat TEXT,
                                    pswd TEXT NOT NULL,
                                    parent INT REFERENCES employee(id));

CREATE TABLE IF NOT EXISTS pathfromroot(id INT REFERENCES employee (id) NOT NULL,
                                        rootpath INT[]);




-- Returns True iif employee with given id exists and pswds match.
CREATE OR REPLACE FUNCTION auth_emp(id int, pswd text) RETURNS boolean
AS $X$
    BEGIN
        IF EXISTS (
            SELECT employee FROM employee e WHERE e.id = id and e.pswd = pswd
        ) THEN RETURN True;
        END IF;
        RETURN False;
    END;
$X$
LANGUAGE PLpgSQL;                                


-- Create root of the tree. Should be called only once.
CREATE OR REPLACE FUNCTION create_root(id int, dat text, new_pswd text, root_secret text) RETURNS VOID
AS $X$
    BEGIN
        IF (root_secret != 'qwerty') THEN
            RAISE EXCEPTION 'Cannot create root: wrong secret given';
        END IF;
        INSERT INTO employee VALUES(id, dat, new_pswd, NULL);
    END;
$X$
LANGUAGE PLpgSQL;


-- CREATE OR REPLACE FUNCTION new_emp(employee.id%TYPE, employee.dat%TYPE, employee.pswd%TYPE) RETURNS VOID
-- AS $X$
--     INSERT INTO employee VALUES($1, $2, $3);
--     -- to do 
-- $X$
-- LANGUAGE SQL;

