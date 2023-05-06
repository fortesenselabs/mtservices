CREATE DATABASE IF NOT EXISTS wisefinance_db CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE wisefinance_db;
-- create table
CREATE TABLE IF NOT EXISTS users (
  id CHAR(36) NOT NULL PRIMARY KEY,
  email VARCHAR(100) NOT NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  hash_password VARCHAR(255) NULL,
  is_token BOOLEAN NOT NULL DEFAULT false,
  country VARCHAR(100) NOT NULL,
  phone_number CHAR(25) NOT NULL,
  role ENUM('USER', 'ADMIN') NOT NULL DEFAULT 'USER',
  is_active BOOLEAN NOT NULL DEFAULT false,
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  wallet_created BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  -- constraints
  CONSTRAINT users_un_email UNIQUE (email),
  CONSTRAINT users_un_phone_number UNIQUE (phone_number),
  CONSTRAINT users_check_role CHECK (role IN ('USER', 'ADMIN'))
);
CREATE TABLE IF NOT EXISTS wallets (
  id CHAR(40) NOT NULL PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  currency_code CHAR(5) NOT NULL,
  ledger_balance DECIMAL(10, 2) NOT NULL DEFAULT 0,
  available_balance DECIMAL(10, 2) NOT NULL DEFAULT 0,
  withdrawable_balance DECIMAL(10, 2) NOT NULL DEFAULT 0,
  account_number CHAR(25),
  tracking_reference VARCHAR(100),
  is_deactivated BOOLEAN NOT NULL DEFAULT false,
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  -- constraints
  CONSTRAINT wallets_fk_user_id FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT wallets_un_currency_code_user_id UNIQUE (currency_code, user_id),
  CONSTRAINT wallets_check_ledger_balance CHECK (ledger_balance >= 0),
  CONSTRAINT wallets_check_available_balance CHECK (available_balance >= 0),
  CONSTRAINT wallets_check_withdrawable_balance CHECK (withdrawable_balance >= 0)
);
-- Transactions
CREATE TABLE fiat_transactions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  wallet_id CHAR(36) NOT NULL,
  transaction_type ENUM('DEPOSIT', 'WITHDRAWAL') NOT NULL,
  currency_code CHAR(5) NOT NULL,
  amount_tendered DECIMAL(10, 2) NOT NULL DEFAULT 0,
  amount_received DECIMAL(10, 2) NOT NULL DEFAULT 0,
  fees DECIMAL(10, 2) NOT NULL DEFAULT 0,
  request_reference VARCHAR(50),
  transaction_reference VARCHAR(50),
  narration VARCHAR(50),
  status ENUM(
    'SUCCESSFUL',
    'PROCESSING',
    'PENDING',
    'CANCELLED',
    'FATAL_ERROR',
    'REQUEST_TIMEOUT',
    'FAILED'
  ) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  -- constraints
  CONSTRAINT fiat_transactions_fk_user_id FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fiat_transactions_fk_wallet_id FOREIGN KEY (wallet_id) REFERENCES wallets(id),
  CONSTRAINT fiat_transactions_check_amount_tendered CHECK (amount_tendered >= 0),
  CONSTRAINT fiat_transactions_check_amount_received CHECK (amount_received >= 0),
  CONSTRAINT fiat_transactions_check_fees CHECK (fees >= 0),
  CONSTRAINT fiat_transactions_check_transaction_type CHECK (transaction_type IN ('DEPOSIT', 'WITHDRAWAL'))
);
-- CREATE TABLE lightning_transactions (
--   id INT AUTO_INCREMENT PRIMARY KEY,
--   user_id CHAR(36) NOT NULL,
--   type ENUM('send', 'receive') NOT NULL,
--   currency_code CHAR(5) NOT NULL DEFAULT 'BTC',
--   payment_request VARCHAR(250) NOT NULL,
--   payment_hash VARCHAR(150) NULL,
--   reference VARCHAR(100) NULL,
--    -- routing fees (combine all the routing fees into one)
--   routing_fees DECIMAL(16, 8) NOT NULL DEFAULT 0,
--   status ENUM('PENDING', 'FAILED', 'SUCESSFUL') NOT NULL,
--   created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--   -- constraints
--   CONSTRAINT lightning_transactions_fk_user_id FOREIGN KEY (user_id) REFERENCES users(id),
--   CONSTRAINT lightning_transactions_check_routing_fees CHECK (routing_fees >= 0)
-- );
-- INSERT DEFAULT ADMIN USER
INSERT INTO users (
    id,
    email,
    first_name,
    last_name,
    hash_password,
    is_token,
    country,
    phone_number,
    role,
    is_active,
    is_deleted,
    wallet_created,
    created_at,
    updated_at
  )
VALUES (
    UUID(),
    'admin@example.com',
    'Admin',
    'User',
    '$2b$10$Gv2cJh5qGZU2k9FO.jPq/O1EvRhFa5/SRIQ1eVadRxxQA6RigR4ju',
    false,
    'USA',
    '+1234567890',
    'admin',
    true,
    false,
    false,
    NOW(),
    NOW()
  );
-- currency codes:
-- https://www.iso.org/iso-4217-currency-codes.html
-- https://github.com/datasets/currency-codes/blob/master/data/codes-all.csv
-- generate another one this time follow the json structure and the country should be Nigeria and isToken should be set to false and the phoneNumber should start from zero instead