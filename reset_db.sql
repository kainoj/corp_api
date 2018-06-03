-- Run `make resetdb' to reset the db

DROP FUNCTION auth_emp(integer, text);
DROP FUNCTION ancestor(integer, integer);
DROP FUNCTION create_root(integer, text, text, text);
DROP FUNCTION ancestors(integer);
DROP FUNCTION parent(integer);
DROP FUNCTION new_emp(integer, text, text, integer);
DROP FUNCTION child(integer);
DROP FUNCTION read_data(integer);
DROP FUNCTION update_emp(integer, text);
DROP FUNCTION remove_emp(integer);
DROP FUNCTION descendants(integer);


DROP TABLE IF EXISTS pathfromroot;
DROP TABLE IF EXISTS employee CASCADE;
DROP USER IF EXISTS app;