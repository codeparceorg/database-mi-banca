# Constraints

---

## Primary Keys

Cada tabla tiene una llave primaria tipo UUID generada automáticamente.

| Tabla        | PK  | Generación          |
| ------------ | --- | ------------------- |
| users        | id  | `gen_random_uuid()` |
| accounts     | id  | `gen_random_uuid()` |
| transactions | id  | `gen_random_uuid()` |
| auth_tokens  | id  | `gen_random_uuid()` |

---

## Foreign Keys

| Tabla        | Columna        | Referencia   | ON DELETE |
| ------------ | -------------- | ------------ | --------- |
| accounts     | user_id        | users(id)    | RESTRICT  |
| transactions | account_id     | accounts(id) | RESTRICT  |
| users        | auth_tokens_id | users(id)    | RESTRICT  |

**Justificación de `RESTRICT` en accounts y transactions:**
- No se debe eliminar un usuario que tenga cuentas bancarias (protección financiera).
- No se debe eliminar una cuenta que tenga transacciones (requerido para auditoría).
- No se debe eliminar el usuarios, solo logicamente

---

## Unique Constraints

| Tabla       | Columna(s)     | Propósito                              |
| ----------- | -------------- | -------------------------------------- |
| users       | email          | Evitar cuentas duplicadas              |
| users       | client_number  | Identificador único de cliente         |
| accounts    | account_number | Número de cuenta único en el banco     |
| auth_tokens | token          | Evitar duplicación de tokens de sesión |
| auth_tokens | email          | Evitar cuentas duplicadas              |

---

## Check Constraints

| Tabla        | Constraint               | Condición      | Propósito                          |
| ------------ | ------------------------ | -------------- | ---------------------------------- |
| accounts     | chk_balance_non_negative | `balance >= 0` | Evita saldos negativos (sobregiro) |
| transactions | chk_amount_not_zero      | `amount != 0`  | Evita transacciones sin valor      |

---

## NOT NULL Constraints

| Tabla          | Campos obligatorios                                                                |
| -------------- | ---------------------------------------------------------------------------------- |
| users          | id, full_name, email, password_hash, client_number, status, created_at, updated_at |
| accounts       | id, user_id, account_number, account_type, currency, balance, status, created_at   |
| transactions   | id, account_id, transaction_type, amount, status, transaction_date, created_at     |
| refresh_tokens | id, user_id, token, expires_at, revoked, created_at                                |

---

## Default Values

| Tabla          | Columna          | Default       |
| -------------- | ---------------- | ------------- |
| users          | status           | `'active'`    |
| users          | created_at       | `NOW()`       |
| users          | updated_at       | `NOW()`       |
| accounts       | account_type     | `'checking'`  |
| accounts       | currency         | `'USD'`       |
| accounts       | balance          | `0`           |
| accounts       | status           | `'active'`    |
| accounts       | created_at       | `NOW()`       |
| transactions   | status           | `'completed'` |
| transactions   | transaction_date | `NOW()`       |
| transactions   | created_at       | `NOW()`       |
| refresh_tokens | revoked          | `FALSE`       |
| refresh_tokens | created_at       | `NOW()`       |

---

## ENUM Types

| Tipo               | Valores                              | Uso                          |
| ------------------ | ------------------------------------ | ---------------------------- |
| user_status        | active, inactive, suspended          | Estado del usuario           |
| account_type       | checking, savings                    | Tipo de cuenta bancaria      |
| account_status     | active, inactive, frozen, closed     | Estado de la cuenta          |
| transaction_type   | deposit, transfer, payment           | Clasificación de transacción |
| transaction_status | pending, completed, failed, reversed | Estado de la transacción     |
