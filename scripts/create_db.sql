-- +migrate Up
-- Create DB
CREATE DATABASE IF NOT EXISTS wisefinance_db CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
-- USE wisefinance_db;
-- +migrate Down
-- DROP DATABASE IF EXISTS wisefinance_db;
-- 
-- DROP DATABASE IF EXISTS bitspend01_testdb;