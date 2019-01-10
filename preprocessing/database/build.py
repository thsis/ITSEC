import os
import sys
import database
import logging
from web3.auto import w3
from web3.exceptions import UnhandledRequest
from tqdm import trange
from blockchain import blockexplorer, exceptions

# Read api-key
if os.path.exists("api_code.txt"):
    with open("api_code.txt") as f:
        api_code = f.read().strip()
else:
    api_code = None

# Get logger.
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
fh = logging.FileHandler("build.log")
format = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
formatter = logging.Formatter(format)
fh.setFormatter(formatter)
logger.addHandler(fh)

if __name__ == "__main__":
    # General Setup at first start.
    if not os.path.exists("progress.txt"):
        logger.info("Start ETL.")
        broken_file = open("broken.txt", "w")
        broken_file.close()
        progress_file = open("progress.txt", "w")
        progress_file.close()
        # First block in chain.
        start_block_nr = 2000000
    # Resume from broken pipe.
    else:
        if os.stat("progress.txt").st_size == 0:
            start_block_nr = 2000000
        else:
            with open("progress.txt", "r") as f:
                # The block to continue from, is the last line in the file.
                for line in f:
                    pass

            start_block_nr = int(line)
            logger.info("Resume ETL at {}".format(start_block_nr))

    # Get latest block and associated number.
    end_block = w3.eth.getBlock("latest")
    end_block_nr = end_block["number"]

    # Fix: sometimes the latest block is unconfirmed and it's number is 0
    if end_block_nr == 0:
        end_block_nr = start_block_nr + 1000000

    block_keys = ["hash", "gasUsed", "gasLimit", "number", "timestamp"]
    tx_keys = ["blockHash", "hash", "from", "to", "value", "gas", "gasPrice"]
    ip_keys = ["hash", "relayed_by"]

    for current_block_nr in trange(start_block_nr, end_block_nr+1):
        try:
            block = w3.eth.getBlock(current_block_nr)
            database.update(block, 'blocks', block_keys)
            database.update_list(block, 'transactions', tx_keys)
            for tx in database.tx_iterator(block):
                try:
                    transaction = blockexplorer.get_tx(tx, api_code=api_code)
                    database.update(transaction, 'ip_info', ip_keys)
                except exceptions.APIException:
                    continue
                except Exception as e:
                    logger.info(e)
                    continue
            # Save progress
            with open("progress.txt", "a") as f:
                f.write(str(current_block_nr) + "\n")
        except UnhandledRequest as error:
            logger.error(error)
            sys.exit(1)

        except (EOFError, KeyboardInterrupt):
            logger.info("Aborting ETL")
            sys.exit(0)
        except Exception as error:
            logger.error(error)
            with open("broken.txt", "a") as f:
                f.write(str(current_block_nr) + "\n")
            continue
