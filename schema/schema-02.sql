-- ============================================================
-- Database Schema — Banking Application
-- PostgreSQL 17+
-- ============================================================
-- ============================================================
--  Users
-- ============================================================
CREATE SEQUENCE client_number_seq
START WITH 1
INCREMENT BY 1;

CREATE TABLE public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL,
    address VARCHAR(200) NOT NULL,
    city VARCHAR(100) NOT NULL,
    avatar_url VARCHAR(200) NOT NULL,

    client_number VARCHAR(20) NOT NULL UNIQUE
        DEFAULT ('CT-' || LPAD(nextval('client_number_seq')::TEXT, 9, '0')),

    status VARCHAR(1) NOT NULL DEFAULT 'A',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    auth_token_id UUID NOT NULL REFERENCES auth_tokens(id) ON DELETE CASCADE
);

CREATE INDEX idx_users_client_number
ON users(client_number);