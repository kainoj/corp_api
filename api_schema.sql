-- Create tables
CREATE TABLE IF NOT EXISTS employee(id int PRIMARY KEY,
                                    dat TEXT,
                                    pswd TEXT NOT NULL,
                                    parent INT REFERENCES employee(id) ON DELETE CASCADE);

CREATE TABLE IF NOT EXISTS pathfromroot(id INT REFERENCES employee(id) ON DELETE CASCADE NOT NULL,
                                        rootpath INT[]);


-- Create API user if not exists and grant priviliges
DROP USER IF EXISTS app;
CREATE USER app WITH ENCRYPTED PASSWORD 'qwerty';
GRANT ALL PRIVILEGES ON employee, pathfromroot TO app;                                     

CREATE EXTENSION IF NOT EXISTS pgcrypto;


-- Returns True iif employee with given id exists and pswds match.
CREATE OR REPLACE FUNCTION auth_emp(admin_id int, admin_pswd text) RETURNS boolean
AS $X$
    BEGIN
        IF EXISTS (
            SELECT e.* FROM employee e WHERE e.id = admin_id and e.pswd = crypt(admin_pswd, e.pswd)
        ) THEN RETURN True;
        END IF;
        RETURN False;
    END;
$X$
LANGUAGE PLpgSQL STABLE;                                


-- Check if 'sup' is ancestor (superior) of employee 'emp'
-- i.e. path from `root` to `emp` contains path from `root` to `sup`
CREATE OR REPLACE FUNCTION ancestor(sup int, emp int) RETURNS boolean
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
LANGUAGE PLpgSQL STABLE;


-- Create root of the tree. Should be called only once.
CREATE OR REPLACE FUNCTION create_root(id int, dat text, new_pswd text, root_secret text) RETURNS VOID
AS $X$
    BEGIN
        IF (crypt(root_secret, 'this one is secret') != 'thzvQYNpeKHKI') THEN
            RAISE EXCEPTION 'Cannot create root: wrong secret given';
        END IF;
        INSERT INTO employee VALUES(id, dat, crypt(new_pswd, gen_salt('bf')), NULL);
        INSERT INTO pathfromroot VALUES(id, array[]::integer[]);
    END;
$X$
LANGUAGE PLpgSQL VOLATILE;


CREATE OR REPLACE FUNCTION ancestors(emp_id int) RETURNS int[]
AS $X$
    BEGIN
        RETURN (SELECT p.rootpath FROM pathfromroot p WHERE p.id = emp_id);
    END;
$X$
LANGUAGE PLpgSQL STABLE;


CREATE OR REPLACE FUNCTION parent(emp_id int) RETURNS int
AS $X$
    BEGIN
        RETURN (SELECT e.parent FROM employee e WHERE e.id = emp_id);
    END;
$X$
LANGUAGE PLpgSQL STABLE;


CREATE OR REPLACE FUNCTION new_emp(emp int, dat text, pswd text, parent int) RETURNS VOID
AS $X$
    DECLARE
        parent_path int[];
        emp_path int[];
    BEGIN
        SELECT p.rootpath INTO parent_path FROM pathfromroot p WHERE p.id = parent;
        emp_path = parent_path || parent;
        INSERT INTO employee VALUES(emp, dat, crypt(pswd, gen_salt('bf')), parent);
        INSERT INTO pathfromroot VALUES(emp, emp_path);
    END;
$X$
LANGUAGE PLpgSQL VOLATILE;


CREATE OR REPLACE FUNCTION child(emp int) RETURNS SETOF int
AS $X$
    SELECT e.id FROM employee e WHERE e.parent = emp;
$X$
LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION read_data(emp int) RETURNS text
AS $X$
    SELECT e.dat FROM employee e WHERE e.id = emp;
$X$
LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION update_emp(emp int, emp_data text) RETURNS VOID
AS $X$
    UPDATE employee e SET dat = emp_data WHERE e.id = emp;
$X$
LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION remove_emp(emp int) RETURNS VOID
AS $X$
    DELETE FROM pathfromroot WHERE pathfromroot.id = emp;
    DELETE FROM employee WHERE employee.id = emp;
$X$
LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION descendants(emp int) RETURNS SETOF int
AS $X$
    BEGIN
        RETURN QUERY (WITH RECURSIVE children(id) AS (
            SELECT e.id FROM employee e WHERE e.parent = emp
            UNION ALL
                SELECT e2.id FROM children ch JOIN employee e2 ON (ch.id = e2.parent)
        )
        SELECT * FROM children);
    END;
$X$
LANGUAGE PLpgSQL STABLE;