clean:
	rm -rf __pycache__/

# Make sure that db name is relevant
resetdb:
	sudo psql -h localhost -d student -U init -W -f reset_db.sql
	