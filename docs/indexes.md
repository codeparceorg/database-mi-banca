# Indexes

---

## Estrategia

Los índices están diseñados para optimizar las consultas más frecuentes del Frontend sin crear sobrecarga innecesaria en escritura.

Se prioriza:
- Búsqueda por email (login)
- Búsqueda por número de cuenta (transferencias)
- Historial de transacciones por cuenta (dashboard)
- Validación de tokens de sesión

---

## Lista de índices

### `users`

| Índice                  | Columna(s)    | Tipo   | Propósito                                                    |
|-------------------------|---------------|--------|--------------------------------------------------------------|
| idx_users_email         | email         | B-tree | Acelerar búsqueda de usuario por email en login (`WHERE email = ?`) |
| idx_users_client_number | client_number | B-tree | Acelerar búsqueda por número de cliente en perfil            |

**Justificación:** El login es la operación más frecuente. `email` tiene UNIQUE, pero el índice adicional permite búsquedas rápidas incluso antes de la validación de unicidad.

---

### `accounts`

| Índice                     | Columna(s)      | Tipo   | Propósito                                                    |
|----------------------------|-----------------|--------|--------------------------------------------------------------|
| idx_accounts_user_id       | user_id         | B-tree | Obtener todas las cuentas de un usuario (`WHERE user_id = ?`) |
| idx_accounts_account_number| account_number  | B-tree | Búsqueda de cuenta por número en transferencias (`WHERE account_number = ?`) |

**Justificación:** `account_number` tiene UNIQUE pero el índice facilita JOIN y búsqueda en transferencias. `user_id` es clave foránea y se usa en JOIN frecuente con users.

---

### `transactions`

| Índice                           | Columna(s)           | Tipo   | Propósito                                                    |
|----------------------------------|----------------------|--------|--------------------------------------------------------------|
| idx_transactions_account_id      | account_id           | B-tree | Obtener todas las transacciones de una cuenta (`WHERE account_id = ?`) |
| idx_transactions_transaction_date| transaction_date DESC| B-tree | Ordenar movimientos por fecha (más recientes primero) en Dashboard |

**Justificación:** La consulta principal del Dashboard es `SELECT ... FROM transactions WHERE account_id = ? ORDER BY transaction_date DESC LIMIT 12`. El índice compuesto implícito por `account_id + transaction_date DESC` cubre esta consulta eficientemente. El índice en `account_id` solo es suficiente porque PostgreSQL puede escanear por account_id y luego ordenar por fecha; pero si el volumen de datos crece, se podría añadir un índice compuesto `(account_id, transaction_date DESC)`.

---

### `refresh_tokens`

| Índice                         | Columna(s) | Tipo   | Propósito                                                    |
|--------------------------------|------------|--------|--------------------------------------------------------------|
| idx_refresh_tokens_user_id     | user_id    | B-tree | Obtener todos los tokens de un usuario (revocación, limpieza) |
| idx_refresh_tokens_token       | token      | B-tree | Búsqueda de token específico para validación (`WHERE token = ?`) |

**Justificación:** `token` tiene UNIQUE pero el índice B-tree permite búsqueda directa. `user_id` es clave foránea usada en limpieza de sesiones.

---

## Índices no creados (intencionalmente)

| Posible índice              | Razón para no crearlo                                    |
|-----------------------------|----------------------------------------------------------|
| transactions(description)   | Las búsquedas por descripción no son frecuentes          |
| users(phone)                | El teléfono no se usa como criterio de búsqueda          |
| transactions(status)        | Baja cardinalidad (pocos valores), no justifica índice   |
| accounts(currency)          | Baja cardinalidad, todos los registros serían USD        |

## Performance esperada

| Consulta                                    | Índice utilizado                          |
|---------------------------------------------|-------------------------------------------|
| Login por email                             | idx_users_email                           |
| Obtener perfil de usuario                   | idx_users_client_number                   |
| Listar cuentas de un usuario                | idx_accounts_user_id                      |
| Buscar cuenta por número                    | idx_accounts_account_number               |
| Obtener últimos movimientos del Dashboard   | idx_transactions_account_id + idx_transactions_transaction_date |
| Validar refresh token                       | idx_refresh_tokens_token                  |
| Revocar tokens de un usuario                | idx_refresh_tokens_user_id                |
