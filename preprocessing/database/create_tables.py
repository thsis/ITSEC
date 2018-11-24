import os
import psycopg2
from config import config
from glob import glob


def create_tables(command):
    """Create tables for ethereum database."""
    conn = None
    try:
        params = config()
        conn = psycopg2.connect(**params)
        cur = conn.cursor()
        cur.execute(command)
        cur.close()
        # If you don't commit, no changes will be made.
        conn.commit()
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
    finally:
        if conn is not None:
            conn.close()


if __name__ == "__main__":
    queries_path = os.path.join("sql", "create", "*")
    queries = glob(queries_path)
    # HACK: table ip-info depends on transactoins, sort to fix order.
    queries.sort(reverse=True)
    for query in queries:
        with open(query) as q:
            command = q.read()
            create_tables(command)
