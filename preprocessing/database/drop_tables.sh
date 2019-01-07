#!/bin/sh
echo 'Dropping the tables requires sudo rights.'
sudo -u postgres psql postgres <<EOF
\c ethereum;
DROP TABLE blocks;
DROP TABLE transactions;
DROP TABLE ip_info;
EOF
