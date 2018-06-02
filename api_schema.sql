-- Create API user if not exists
DROP USER IF EXISTS app;
CREATE USER app WITH password 'qwerty';

-- TODO
-- CREATE SEQUENCE seq_emp_id;

-- Create tables
CREATE TABLE IF NOT EXISTS employee(id int PRIMARY KEY,
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

-- TODO ------------------------------------------------------------------------------------DEBUG!!!
-- Check if 'sup' is superior of employee 'emp'
-- i.e. path from `root` to `emp` contains node `sup`
CREATE OR REPLACE FUNCTION is_superior(sup int, emp int) RETURNS boolean
AS $X$
    DECLARE
        emp_path int;
    BEGIN
        FOR emp_path IN (SELECT p.rootpath FROM pathfromroot p WHERE p.id = emp) LOOP
            IF emp_path = sup THEN
                RETURN True;
            END IF;
        END LOOP;
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


CREATE OR REPLACE FUNCTION ancestors(emp_id int) RETURNS int[]
AS $X$
    BEGIN
        RETURN (SELECT p.rootpath FROM pathfromroot p WHERE p.id = emp_id);
    END;
$X$
LANGUAGE PLpgSQL;


CREATE OR REPLACE FUNCTION parent(emp_id int) RETURNS int
AS $X$
    BEGIN
        RETURN (SELECT e.parent FROM employee e WHERE e.id = emp_id);
    END;
$X$
LANGUAGE PLpgSQL;

CREATE OR REPLACE FUNCTION new_emp(emp int, dat text, pswd text, parent int) RETURNS VOID
AS $X$
    INSERT INTO employee VALUES(emp, dat, pswd, parent);
    -- todo: update path
$X$
LANGUAGE SQL;

