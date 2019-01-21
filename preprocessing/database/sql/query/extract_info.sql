WITH blocktable AS (
  SELECT
    block_hash,
    gas_used AS block_gas,
    gas_limit,
    inception_time
  FROM blocks
  WHERE block_id = {}
),

transactiontable AS (
  SELECT
    transaction_hash,
    block_hash,
    sender,
    receiver,
    value,
    gas_used,
    gas_price
  FROM transactions
)

SELECT *
FROM blocktable bt
LEFT JOIN transactiontable tt USING(block_hash);
