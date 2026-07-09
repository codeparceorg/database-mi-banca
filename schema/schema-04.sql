-- ============================================================
-- Database Schema — Banking Application
-- PostgreSQL 17+
-- ============================================================
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
