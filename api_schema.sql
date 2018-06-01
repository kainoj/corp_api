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
CREATE OR REPLACE FUNCTION auth_emp(admin_id int, admin_pswd text) RETURNS boolean
AS $X$
    BEGIN
        IF EXISTS (
            SELECT e.* FROM employee e WHERE e.id = admin_id and e.pswd = admin_pswd
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
        INSERT INTO pathfromroot VALUES(id, array[]::integer[]);
    END;
$X$
LANGUAGE PLpgSQL;


CREATE OR REPLACE FUNCTION ancestors(emp_id int, admin_id int, pswd text) RETURNS int[]
AS $X$
    DECLARE
        is_authorised boolean;
    BEGIN
        SELECT auth_emp(admin_id, pswd) INTO is_authorised;
        -- If employee 'emp_id' exists and admin is authorized
        IF (emp_id IN (SELECT e.id FROM employee e)) AND (is_authorised) THEN
            RETURN (SELECT p.rootpath FROM pathfromroot p WHERE p.id = emp_id);
        END IF;
        RAISE EXCEPTION 'Employee does not exist or admin is not authorised';
    END;
$X$
LANGUAGE PLpgSQL;


CREATE OR REPLACE FUNCTION parent(emp_id int, admin_id int, admin_pswd text) RETURNS int
AS $X$
    DECLARE
        is_authorised boolean;
    BEGIN
        SELECT auth_emp(admin_id, admin_pswd) INTO is_authorised;
        -- If employee emp_id exists and admin is authorised
        IF (emp_id IN (SELECT e.id FROM employee e)) AND (is_authorised) THEN
            RETURN (SELECT e.parent FROM employee e WHERE e.id = emp_id);
        END IF;
        RAISE EXCEPTION 'Employee does not exist or admin is not authorised';
    END;
$X$
LANGUAGE PLpgSQL;

-- CREATE OR REPLACE FUNCTION new_emp(employee.id%TYPE, employee.dat%TYPE, employee.pswd%TYPE) RETURNS VOID
-- AS $X$
--     INSERT INTO employee VALUES($1, $2, $3);
--     -- to do 
-- $X$
-- LANGUAGE SQL;

