-- ============================================================
-- Database Schema — Banking Application
-- PostgreSQL 17+
-- ============================================================
-- ============================================================
-- 2. Accounts
-- ============================================================
CREATE TYPE account_type AS ENUM ('checking', 'savings');

CREATE SEQUENCE account_number_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE accounts (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID            NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    account_number  VARCHAR(20)     NOT NULL UNIQUE DEFAULT ('AC-' || LPAD(nextval('account_number_seq')::TEXT, 9, '0')),
    account_type    account_type    NOT NULL DEFAULT 'checking',
    currency        VARCHAR(3)      NOT NULL DEFAULT 'USD',
    balance         NUMERIC(15,2)   NOT NULL DEFAULT 0,
    status          VARCHAR(1)      NOT NULL DEFAULT 'A',
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_balance_non_negative CHECK (balance >= 0)
);

CREATE INDEX idx_accounts_user_id ON accounts (user_id);

-- ============================================================
-- Función del trigger
-- ============================================================

CREATE OR REPLACE FUNCTION create_default_account()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO accounts (
        user_id,
        account_number,
        account_type,
        currency,
        balance
    )
    VALUES (
        NEW.id,
        'AC-' || LPAD(nextval('account_number_seq')::TEXT, 10, '0'),
        'checking',
        'USD',
        0
    );

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_create_default_account
AFTER INSERT
ON users
FOR EACH ROW
EXECUTE FUNCTION create_default_account();
