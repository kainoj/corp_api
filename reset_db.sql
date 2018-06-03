-- Run `make resetdb' to reset the db

DROP FUNCTION IF EXISTS create_root(int, text, text, text);
DROP FUNCTION IF EXISTS auth_emp(int, text);
DROP FUNCTION IF EXISTS ancestors(int);
DROP FUNCTION IF EXISTS is_superior(int, int);
DROP FUNCTION IF EXISTS parent(int);
DROP FUNCTION IF EXISTS child(int);
-- DROP FUNCTION IF EXISTS new_emp(employee.id%TYPE, employee.dat%TYPE, employee.pswd%TYPE, text);

DROP TABLE IF EXISTS pathfromroot;
DROP TABLE IF EXISTS employee CASCADE;
DROP USER IF EXISTS app;