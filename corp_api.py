import sys
import os
import json
import psycopg2
from argparse import ArgumentParser


class DbAdapter:

    FUNC_CALLS = ['open', 'root', 'ancestors', 'parent', 'child', 'new', 'remove']

    def __init__(self, init_db=False):
        self.conn = None
        self.init_db = init_db

    def init(self, schema='api_schema.sql'):
        """
        Initialize the database based uppon a given sql file. 
        Creates user `app` and all required tables, functions, etc
        """
        self.conn.cursor().execute(open(schema, "r").read())        
        self.conn.commit()

    def open(self, data):
        """
        Open and connect to datebase. Sample input: 
        { "database": "student", "login": "init", "password": "qwerty"}
        """
        host = 'localhost' if 'host' not in data else data['host']
        self.conn = psycopg2.connect(database=data['database'], 
                                     user=data['login'], 
                                     password=data['password'],
                                     host=host)
        if self.init_db:        
            self.init()       
        return None                 

    def root(self, d):
        """
        root <secret> <newpassword> <data> <emp> 
        """
        secret = d['secret']
        pswd, data, root_id =  d['newpassword'], d['data'], d['emp']
        self.conn.cursor().execute("SELECT create_root(%s, %s, %s, %s);", \
                                   (root_id, data, pswd, secret))
        self.conn.commit()

    def new(self, d):
        """
        new <admin> <passwd> <data> <newpasswd> <emp1> <emp>
        """
        admin, passwd, data, newpasswd, emp1, emp = \
         d['admin'], d['passwd'], d['data'], d['newpasswd'], d['emp1'], d['emp']

        self.authorise(level=2, admin=admin, pswd=passwd, sup=admin, emp=emp1)

        cur = self.conn.cursor()
        cur.execute("SELECT new_emp(%s, %s, %s, %s);", (emp, data, passwd, emp1))
        self.conn.commit()
        cur.close()
        return None           
    
    def remove(self, user):
        return ["todo remove"]
    
    def ancestors(self, u):
        """
        ancestors <admin> <passwd> <emp>
        """
        emp, admin, passwd = u['emp'], u['admin'], u['passwd'] 

        self.authorise(admin=admin, pswd=passwd)

        cur = self.conn.cursor()
        cur.execute("SELECT ancestors(%s);", (emp, ))
        res = cur.fetchone()
        self.conn.commit()
        cur.close()
        return res[0]

    def parent(self, d):
        """
        parent <admin> <passwd> <emp>
        """
        admin, passwd, emp = d['admin'], d['passwd'], d['emp']

        self.authorise(admin=admin, pswd=passwd)

        cur = self.conn.cursor()
        cur.execute("SELECT parent(%s);", (emp, ))
        res = cur.fetchone()
        self.conn.commit()
        cur.close()
        if res[0] is None:
            return "NULL"
        return res[0]

    def child(self, d):
        admin, passwd, emp = d['admin'], d['passwd'], d['emp']
        
        self.authorise(admin=admin, pswd=passwd)
        cur = self.conn.cursor()
        cur.execute("SELECT child(%s);", (emp, ))
        res = cur.fetchall()
        self.conn.commit()
        cur.close()
        return [r[0] for r in res]

    def authorise(self, level=0, admin=None, pswd=None, sup=None, emp=None):
        """
        Level 0 - check wheater admin's credentaials are valid.
        Level 1 - Level 0 and check if `sup` is `emp`'s superior.
        Level 2 - Level 1 OR check if `sup` is `emp` itself.
        
        Throws an exception if authorization fails.
        """
        if not self.is_authorised(admin, pswd):
            raise Exception("Invalid credentials")
        
        if level == 1 and not self.is_superior(sup, emp):
            raise Exception("No privileges")
        
        if level == 2 and not self.is_superior_or_emp(sup, emp):
            raise Exception("No privileges")


    def is_authorised(self, admin, pswd):
        """
        Check wheather admin's credentials are valid.
        """
        cur = self.conn.cursor()
        cur.execute("SELECT auth_emp(%s, %s);", (admin, pswd))
        res = cur.fetchone()[0]
        cur.close()
        return res

    def is_superior(self, sup, emp):
        """
        Check wheater `sup` is `emp`'s superior
        """
        cur = self.conn.cursor()
        cur.execute("SELECT is_superior(%s, %s);", (sup, emp))
        res = cur.fetchone()[0]
        cur.close()
        return res

    def is_superior_or_emp(self, sup, emp):
        return self.is_superior(sup, emp) or sup == emp
    
    def unauthorized(self):
        raise Exception("Unauthorised.")


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