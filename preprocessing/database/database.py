import psycopg2
from config import config
from web3.auto import w3
from hexbytes import HexBytes
from blockchain import blockexplorer


def extract_info(dictlike, keys):
    """
    Extract values from a dictionary-style object.

    * Parameters:
        * `dictlike`: object that has all attributes in `keys`
        * `keys`: list of keys to loop over.

    * Returns:
        * `out`: tuple of values corresponding to each key in `keys`.
    """
    out = []

    for key in keys:
        val = getattr(dictlike, key, "NULL")
        if val is None:
            val = "NULL"
        if type(val) == HexBytes:
            out.append(val.hex())
        else:
            out.append(val)

    return tuple(out)


def update(dictlike, table, keys):
    """
    Update a database-table with the contents of one block.

    * Parameters:
        * `dictlike`: object that has a `__get__`-method implemented.
        * `table`: (`str`) name of table to update.
        * `keys`: list of keys to loop over.
    """

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
    """
    Batch update a database-table with the contents of one block.

    * Parameters:
        * `block`: object that has a `__get__`-method implemented.
        * `table`: (`str`) name of table to update.
        * `keys`: list of keys to loop over.
        * `block_key`: (`str`) key of `block` that contains an iterable.
    """
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


def tx_iterator(block):
    for transaction in block.transactions:
        yield transaction.hex()


if __name__ == "__main__":
    block = w3.eth.getBlock(6753133)
    block_keys = ["hash", "gasUsed", "gasLimit", "number", "timestamp"]
    tx_keys = ["blockHash", "hash", "from", "to", "value", "gas", "gasPrice"]
    ip_keys = ["hash", "relayed_by"]

    update(block, 'blocks', block_keys)
    update_list(block, 'transactions', tx_keys)
    for tx in tx_iterator(block):
        try:
            transaction = blockexplorer.get_tx(tx)
            update(transaction, 'ip_info', ip_keys)
        except Exception as e:
            print(e)
            continue
