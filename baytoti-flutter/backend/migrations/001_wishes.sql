-- Migration 001 — wishes (النواقص) synced across list members.
-- Run once on the deployed DB:
--   sudo mariadb baytoti < /tmp/001_wishes.sql

USE baytoti;

CREATE TABLE IF NOT EXISTS wishes (
  id            VARCHAR(20)  NOT NULL,
  list_id       VARCHAR(16)  NOT NULL,
  item_name     VARCHAR(200) NOT NULL,
  added_by_name VARCHAR(50)  NOT NULL,
  created_at    DATETIME     NOT NULL,
  PRIMARY KEY (id),
  KEY ix_wishes_list_date (list_id, created_at),
  CONSTRAINT fk_wishes_list FOREIGN KEY (list_id)
    REFERENCES lists(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
