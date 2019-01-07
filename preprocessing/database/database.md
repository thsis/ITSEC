# Setup

Only for Linux

## Installation

1. Install `PostgreSQL`
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
```

2. Set the default password:
    1. Run the psql command from the postgres user account: `sudo -u postgres psql postgres`.
    2. Set the password: `\password postgres`.
    3. Enter a password.
    4. Close psql. `\q`.

3. Create the database: `CREATE DATABASE ethereum;`
4. Connect to database: `\c ethereum;`
4. Run `python3 create_tables.py`

## Documentation

### `blocks`

|column            | type     | description |
|:----------------:|:--------:|:-----------:|
| `hash`           | `string` | hash of block, unique identifier|
| `gas_used`       | `int`    | |
| `gas_limit`      | `int`    | |
| `number`         | `int`    | unique id of block|
| `inception_time` | `int`    | time of inception|

### `transactions`

|column              | type      | description |
|:- ----------------:|:---------:|:-----------:|
| `transaction_hash` | `string`  | hash of transation - not unique|
| `block_hash`       | `string`  ||
| `sender`           | `string`  ||
| `receiver`         | `string`  ||
| `value`            | `float`   ||
| `gas_used`         | `integer` ||
| `gas_price`        | `bigint`  ||
