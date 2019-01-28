import os
import psycopg2
import pandas as pd

from config import config


datafile = os.path.join("..", "..", "data", "ethereum-data-large.csv")
columns = ["block_hash", "block_gas", "gas_limit", "inception_time", "tx_hash",
           "sender", "receiver", "value", "gas_used", "gas_price"]

with open(os.path.join("sql", "query", "extract_batch.sql")) as q:
    sql = q.read()
conn = None
try:
    params = config()
    conn = psycopg2.connect(**params)
    cur = conn.cursor()
    cur.execute(sql)
    rows = cur.fetchall()
    cur.close()
except (Exception, psycopg2.DatabaseError) as error:
    print(error)
finally:
    if conn is not None:
        conn.close()


df = pd.DataFrame(rows, columns=columns)
df.to_csv(datafile, index=False)
