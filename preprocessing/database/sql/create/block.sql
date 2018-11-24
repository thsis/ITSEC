CREATE TABLE IF NOT EXISTS blocks (
  block_hash VARCHAR(255) PRIMARY KEY,
  gas_used INTEGER,
  gas_limit INTEGER,
  block_id INTEGER UNIQUE,
  inception_time INTEGER
)
