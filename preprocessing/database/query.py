import os
import logging
from tqdm import trange
import database
import pandas as pd


# Get logger.
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
fh = logging.FileHandler("query.log")
format = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
formatter = logging.Formatter(format)
fh.setFormatter(formatter)
logger.addHandler(fh)

datafile = os.path.join("..", "..", "data", "ethereum-data.csv")
columns = ["block_hash", "block_gas", "gas_limit", "inception_time", "tx_hash",
           "sender", "receiver", "value", "gas_used", "gas_price"]

for block in trange(2000000, 2014806):
    try:
        blockinfo = database.query(block)
        df = pd.DataFrame(blockinfo, columns=columns)
        if os.path.exists(datafile):
            with open(datafile, "a") as f:
                df.to_csv(f, header=False, index=False)
        else:
            df.to_csv(datafile, index=False)
    except Exception as e:
        logger.error(e)
