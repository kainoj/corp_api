import sys
import os
import json
import psycopg2
from argparse import ArgumentParser


class DbAdapter:

    FUNC_CALLS = ['open', 'root', 'ancestors', 'parent', 'new', 'remove']

    def __init__(self, init_db=False):
        self.conn = None
        self.init_db = init_db

    def init(self, schema='api_schema.sql'):
        """
        Initialize the database based uppon a given sql file. 
        Creates user `app` and all required tables, triggers, etc
        """
        self.conn.cursor().execute(open(schema, "r").read())        
        self.conn.commit()

    def open(self, data):
        """
        Open and connect to datebase.
        Sample input: 
        { "baza": "student", "login": "init", "password": "qwerty"}
        """
        host = 'localhost' if 'host' not in data else data['host']
        self.conn = psycopg2.connect(database=data['database'], 
                                     user=data['login'], 
                                     password=data['password'],
                                     host=host)
        if self.init_db:        
            self.init()       
        return None                 

    def root(self, user):
        root_id = user['emp']
        data = user['data']
        pswd = user['newpassword']
        secret = user['secret']
        self.conn.cursor().execute("SELECT create_root(%s, %s, %s, %s);", \
             (root_id, data, pswd, secret))
        self.conn.commit()

    def new(self, user):
        return ["todo new"]             
    
    def remove(self, user):
        return ["todo remove"]
    
    def ancestors(self, u):
        """
        ancestors <admin> <passwd> <emp>
        """
        cur = self.conn.cursor()
        cur.execute("SELECT ancestors(%s, %s, %s);", \
                    (u['emp'], u['admin'], u['passwd']))
        res = cur.fetchone()
        self.conn.commit()
        cur.close()
        return res[0]

    def parent(self, d):
        """
        parent <admin> <passwd> <emp>
        """
        cur = self.conn.cursor()
        cur.execute("SELECT parent(%s, %s, %s);", (d['emp'], d['admin'], d['passwd']))
        res = cur.fetchone()
        self.conn.commit()
        cur.close()
        if res[0] is None:
            return "NULL"
        return res[0]
        


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
            #try:
                data = getattr(db, func)(call[func])
                return status_ok(data)
            #except:
                break
    return status_error()


def status_error():
    """
    Returns a JSON objet representig an ERROR
    """
    return json.dumps({"status": "ERROR"})


def status_ok(data):
    if data is None:   
        return json.dumps({"status": "OK"})
    return json.dumps({"status": "OK", "data": data})


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
        print(handle_api_call(db, call))
        print()