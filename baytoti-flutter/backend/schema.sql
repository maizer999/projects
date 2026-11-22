-- Baytoti API — MySQL/MariaDB schema
-- Charset: utf8mb4 to handle Arabic correctly.

CREATE DATABASE IF NOT EXISTS baytoti
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE baytoti;

CREATE TABLE IF NOT EXISTS lists (
  id          VARCHAR(16)  NOT NULL,
  name        VARCHAR(100) NOT NULL,
  invite_code VARCHAR(10)  NOT NULL,
  owner_name  VARCHAR(50)  NULL,
  created_at  DATETIME     NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_lists_invite (invite_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS members (
  list_id   VARCHAR(16) NOT NULL,
  name      VARCHAR(50) NOT NULL,
  joined_at DATETIME    NOT NULL,
  PRIMARY KEY (list_id, name),
  CONSTRAINT fk_members_list FOREIGN KEY (list_id)
    REFERENCES lists(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS purchases (
  id             VARCHAR(20)                        NOT NULL,
  list_id        VARCHAR(16)                        NOT NULL,
  item_name      VARCHAR(200)                       NOT NULL,
  price          DECIMAL(10,2)                      NULL,
  category       ENUM('food','cleaning','other')    NOT NULL DEFAULT 'other',
  added_by_name  VARCHAR(50)                        NOT NULL,
  note           TEXT                               NULL,
  archived       TINYINT(1)                         NOT NULL DEFAULT 0,
  date           DATETIME                           NOT NULL,
  updated_at     DATETIME                           NOT NULL,
  PRIMARY KEY (id),
  KEY ix_purchases_list_date (list_id, archived, date),
  CONSTRAINT fk_purchases_list FOREIGN KEY (list_id)
    REFERENCES lists(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

CREATE TABLE IF NOT EXISTS product_stats (
  list_id    VARCHAR(16)  NOT NULL,
  normalized VARCHAR(200) NOT NULL,
  name       VARCHAR(200) NOT NULL,
  count      INT          NOT NULL DEFAULT 0,
  last_used  DATETIME     NOT NULL,
  PRIMARY KEY (list_id, normalized),
  KEY ix_stats_count (list_id, count),
  CONSTRAINT fk_stats_list FOREIGN KEY (list_id)
    REFERENCES lists(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
