SELECT
  b.block_hash,
  b.block_gas,
  b.gas_limit,
  b.inception_time,
  t.transaction_hash,
  t.sender,
  t.receiver,
  t.value,
  t.gas_used,
  t.gas_price
FROM (
  SELECT
    block_hash,
    gas_used AS block_gas,
    gas_limit,
    inception_time
  FROM blocks) b
  LEFT JOIN (
  SELECT
    transaction_hash,
    block_hash,
    sender,
    receiver,
    value,
    gas_used,
    gas_price
  FROM transactions) t
  ON t.block_hash = b.block_hash
LIMIT 10
