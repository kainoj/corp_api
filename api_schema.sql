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
-- i.e. path from `root` to `emp` contains path from `root` to `sup`
CREATE OR REPLACE FUNCTION is_superior(sup int, emp int) RETURNS boolean
AS $X$
    DECLARE
        emp_path int[];
        sup_path int[];
    BEGIN
        SELECT p.rootpath INTO emp_path FROM pathfromroot p WHERE p.id = emp;
        SELECT p.rootpath INTO sup_path FROM pathfromroot p WHERE p.id = sup;
        RETURN emp_path @> sup_path;
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
    DECLARE
        parent_path int[];
        emp_path int[];
    BEGIN
        SELECT p.rootpath INTO parent_path FROM pathfromroot p WHERE p.id = parent;
        emp_path = parent_path || parent;
        INSERT INTO employee VALUES(emp, dat, pswd, parent);
        INSERT INTO pathfromroot VALUES(emp, emp_path);
    END;
$X$
LANGUAGE PLpgSQL;


CREATE OR REPLACE FUNCTION child(emp int) RETURNS SETOF int
AS $X$
    SELECT e.id FROM employee e WHERE e.parent = emp;
$X$
LANGUAGE SQL;


CREATE OR REPLACE FUNCTION read_data(emp int) RETURNS text
AS $X$
    SELECT e.dat FROM employee e WHERE e.id = emp;
$X$
LANGUAGE SQL;


CREATE OR REPLACE FUNCTION update_emp(emp int, emp_data text) RETURNS VOID
AS $X$
    UPDATE employee e SET dat = emp_data WHERE e.id = emp;
$X$
LANGUAGE SQL;