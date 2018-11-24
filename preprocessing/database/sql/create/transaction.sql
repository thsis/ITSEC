CREATE TABLE  IF NOT EXISTS transactions (
  transaction_hash VARCHAR(255) NOT NULL,
  block_hash VARCHAR(255) NOT NULL,
  sender VARCHAR(255),
  receiver VARCHAR(255),
  value FLOAT,
  gas_used INTEGER,
  gas_price BIGINT
)
