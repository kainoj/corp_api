-- Run `make resetdb' to reset the db

DROP FUNCTION IF EXISTS create_root(int, text, text, text);
DROP FUNCTION IF EXISTS auth_emp(int, text);
-- DROP FUNCTION IF EXISTS new_emp(employee.id%TYPE, employee.dat%TYPE, employee.pswd%TYPE, text);

DROP USER IF EXISTS app;
DROP TABLE IF EXISTS pathfromroot;
DROP TABLE IF EXISTS employee CASCADE;