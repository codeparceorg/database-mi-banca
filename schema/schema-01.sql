-- ============================================================
-- Database Schema — Banking Application
-- PostgreSQL 17+
-- ============================================================


-- ============================================================
--  Auth
-- ============================================================

CREATE TABLE auth_token (
    id          UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    status      varchar(1)     NOT NULL DEFAULT 'A',
    email       VARCHAR(100)    NOT NULL UNIQUE,
    password    TEXT            NOT NULL UNIQUE,
    token       TEXT            NOT NULL UNIQUE,
    expires_at  TIMESTAMPTZ     NOT NULL,
    revoked     BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

