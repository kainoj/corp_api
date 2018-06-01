import sys
import os
import json
import psycopg2
from argparse import ArgumentParser


class DbAdapter:

    FUNC_CALLS = ['open', 'new', 'remove']

    def __init__(self, init_db=False):
        self.conn = None
        self.init_db = init_db

    def init(self, schema='api_schema.sql'):
        """
        Initialize the database based uppon a given sql file. 
        Creates user `app` and all required tables, triggers, etc
        """
        with self.conn.cursor() as cur:
            cur.execute(open(schema, "r").read())        

    def new(self, user):
        print("TODO: new")

    def open(self, data):
        """
        Open and connect to datebase.
        Sample input: 
        { "baza": "student", "login": "init", "password": "qwerty"}
        """
        
        host = 'localhost' if 'host' not in data else data['host']
        self.conn = psycopg2.connect(database=data['baza'], 
                                     user=data['login'], 
                                     password=data['password'],
                                     host=host)
        if self.init_db:            
            self.init()                                     
    
    def remove(self, user):
        print("TODO: remove")   


def parse_json(string):
    """
    Deserialise api call string to a JSON object.
    Returns None if deserialisation fails.
    """
    try:
        obj = json.loads(string)
    except:
        obj = None
    return obj


def handle_api_call(db, call):
    """
    Handle an api call. Returns a JSON which contains fucntion call result.
    If the call is invalid (ie non-existing function or None) then returns
    a JSON with ERROR status code.
    """
    
    for func in DbAdapter.FUNC_CALLS:
        if func in call:     
            return getattr(db, func)(call[func])
    return status_error()


def status_error():
    """
    Returns a JSON objet representig an ERROR
    """
    return json.dumps({"status": "ERROR"})


def status_ok(data):
    return json.dumps({"status": "OK TODO DATA"})


if __name__ == '__main__':
    
    parser = ArgumentParser(description='Corp management API. (c) pjo')
    parser.add_argument("-init", action='store_true', 
                        help='Create and initialize the corp database. '\
                        '`open()` call must be the first function call. '\
                        'Note: db user must already exist.')
    parser.add_argument("-file", metavar="file",
                        help='File from which api call will be read. ' \
                        'TODO: if not specified, use stdio.')
    args = parser.parse_args()

    db = DbAdapter(args.init)

    for call in [line.rstrip('\n') for line in open(args.file)]:
        print("-----------")
        print(call)
        call = parse_json(call)        
        handle_api_call(db, call)