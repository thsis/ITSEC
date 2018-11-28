import psycopg2
from config import config
from web3.auto import w3
from hexbytes import HexBytes


def extract_info(dictlike, keys):
    out = []

    for key in keys:
        val = dictlike.get(key, "NULL")
        if val is None:
            val = "NULL"
        if type(val) == HexBytes:
            out.append(val.hex())
        else:
            out.append(val)

    return tuple(out)


def update(dictlike, table, keys):
    """Update the block-table with the contents of one block."""

    row = extract_info(dictlike, keys)

    sql = "INSERT INTO {} VALUES {}".format(table, row)
    conn = None
    try:
        params = config()
        conn = psycopg2.connect(**params)
        cur = conn.cursor()
        cur.execute(sql)
        conn.commit()
        cur.close()
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
    finally:
        if conn is not None:
            conn.close()


def update_list(block, table, keys, block_key="transactions"):
    """Update table with the contents of one block."""
    conn = None
    try:
        params = config()
        conn = psycopg2.connect(**params)
        cur = conn.cursor()

        for transaction in block[block_key]:
            tx = w3.eth.getTransaction(transaction)

            info = extract_info(tx, keys)
            sql = "INSERT INTO {} VALUES {}".format(table, info)
            cur.execute(sql)
        conn.commit()
        cur.close()
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
    finally:
        if conn is not None:
            conn.close()


if __name__ == "__main__":
    block = w3.eth.getBlock(6753133)
    block_keys = ["hash", "gasUsed", "gasLimit", "number", "timestamp"]
    tx_keys = ["blockHash", "hash", "from", "to", "value", "gas", "gasPrice"]

    update(block, 'blocks', block_keys)
    update_list(block, 'transactions', tx_keys)
