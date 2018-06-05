-- Run `make resetdb' to reset the db

 DROP FUNCTION IF EXISTS emp_exists(integer);
 DROP FUNCTION IF EXISTS auth_emp(integer, text);
 DROP FUNCTION IF EXISTS ancestor(integer, integer);
 DROP FUNCTION IF EXISTS create_root(integer, text, text, text);
 DROP FUNCTION IF EXISTS ancestors(integer);
 DROP FUNCTION IF EXISTS parent(integer);
 DROP FUNCTION IF EXISTS new_emp(integer, text, text, integer);
 DROP FUNCTION IF EXISTS child(integer);
 DROP FUNCTION IF EXISTS read_data(integer);
 DROP FUNCTION IF EXISTS update_emp(integer, text);
 DROP FUNCTION IF EXISTS remove_emp(integer);
 DROP FUNCTION IF EXISTS descendants(integer);


DROP TABLE IF EXISTS pathfromroot;
DROP TABLE IF EXISTS employee CASCADE;
DROP USER IF EXISTS app;