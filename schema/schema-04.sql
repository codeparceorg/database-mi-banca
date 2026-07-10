-- ============================================================
-- Database Schema — Banking Application
-- PostgreSQL 17+
-- ============================================================
-- ============================================================
-- Transactions
-- ============================================================

CREATE TYPE transaction_status AS ENUM ('pending', 'completed', 'failed', 'reversed');
CREATE TYPE transaction_type AS ENUM ('deposit', 'transfer', 'payment');

CREATE TABLE transactions (
    id                  UUID                PRIMARY KEY DEFAULT gen_random_uuid(),
    account_number  VARCHAR(20)            NOT NULL  REFERENCES accounts(account_number) ON DELETE RESTRICT,
    destination_account VARCHAR(20),
    transaction_type    transaction_type    NOT NULL,
    amount              NUMERIC(15,2)       NOT NULL,
    description         TEXT,
    status              transaction_status  NOT NULL DEFAULT 'completed',
    transaction_date    TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    created_at          TIMESTAMPTZ         NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_amount_not_zero CHECK (amount != 0)
);

CREATE INDEX idx_transactions_account_number ON transactions (account_number);
CREATE INDEX idx_transactions_transaction_date ON transactions (transaction_date DESC);



-- ============================================================
-- Función del trigger
-- ============================================================

CREATE OR REPLACE FUNCTION process_transfer()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    source_balance NUMERIC(15,2);
    destination_exists BOOLEAN;
BEGIN

    -- Solo procesar transferencias pendientes
    IF NEW.transaction_type <> 'transfer'
       OR NEW.status <> 'pending' THEN

        RETURN NEW;

    END IF;


    /*
       Validar cuenta destino
    */
    SELECT EXISTS(
        SELECT 1
        FROM accounts
        WHERE account_number = NEW.destination_account
    )
    INTO destination_exists;


    IF NOT destination_exists THEN

        UPDATE transactions
        SET status = 'failed'
        WHERE id = NEW.id;

        RETURN NEW;

    END IF;



    /*
       Bloquear cuenta origen y validar saldo
    */
    SELECT balance
    INTO source_balance
    FROM accounts
    WHERE account_number = NEW.account_number
    FOR UPDATE;


    IF source_balance IS NULL
       OR source_balance < NEW.amount THEN


        UPDATE transactions
        SET status = 'failed'
        WHERE id = NEW.id;


        RETURN NEW;

    END IF;



    /*
       Descontar origen
    */
    UPDATE accounts
    SET balance = balance - NEW.amount
    WHERE account_number = NEW.account_number;



    /*
       Aumentar destino
    */
    UPDATE accounts
    SET balance = balance + NEW.amount
    WHERE account_number = NEW.destination_account;



    /*
       Crear movimiento destino
    */
    INSERT INTO transactions(
        account_number,
        destination_account,
        transaction_type,
        amount,
        description,
        status
    )
    VALUES(
        NEW.destination_account,
        NEW.account_number,
        'transfer',
        NEW.amount,
        'Transferencia recibida',
        'completed'
    );



    /*
       Completar transferencia origen
    */
    UPDATE transactions
    SET status = 'completed'
    WHERE id = NEW.id;


    RETURN NEW;


EXCEPTION
    WHEN OTHERS THEN

        UPDATE transactions
        SET status = 'failed'
        WHERE id = NEW.id;

        RETURN NEW;

END;
$$;

CREATE TRIGGER trg_process_transfer
AFTER INSERT
ON transactions
FOR EACH ROW
EXECUTE FUNCTION process_transfer();