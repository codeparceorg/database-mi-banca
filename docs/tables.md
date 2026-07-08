# Tables

---

## `users`

Almacena la información de los usuarios registrados en la aplicación.

| Columna         | Tipo                | Restricciones      | Descripción                                    |
|-----------------|---------------------|--------------------|------------------------------------------------|
| id              | UUID                | PK, DEFAULT gen_random_uuid() | Identificador único del usuario      |
| full_name       | VARCHAR(100)        | NOT NULL           | Nombre completo del usuario                   |
| email           | VARCHAR(255)        | NOT NULL, UNIQUE   | Correo electrónico (usado para login)          |
| password_hash   | TEXT                | NOT NULL           | Hash de la contraseña (bcrypt)                 |
| phone           | VARCHAR(20)         |                    | Número de teléfono (opcional)                  |
| address         | TEXT                |                    | Dirección del usuario                          |
| city            | VARCHAR(100)        |                    | Ciudad del usuario                             |
| avatar_url      | TEXT                |                    | URL de la foto de perfil                       |
| client_number   | VARCHAR(20)         | NOT NULL, UNIQUE   | Número único de cliente (formato CLT-XXXXX)    |
| status          | user_status         | NOT NULL, DEFAULT 'active' | Estado del usuario (active, inactive, suspended) |
| created_at      | TIMESTAMPTZ         | NOT NULL, DEFAULT NOW() | Fecha de creación del registro          |
| updated_at      | TIMESTAMPTZ         | NOT NULL, DEFAULT NOW() | Fecha de última actualización           |

**Mapa con API:** Se correlaciona con `GET /profile` y `PUT /profile`.

---

## `accounts`

Representa las cuentas bancarias de los usuarios.

| Columna        | Tipo              | Restricciones      | Descripción                                    |
|----------------|-------------------|--------------------|------------------------------------------------|
| id             | UUID              | PK, DEFAULT gen_random_uuid() | Identificador único de la cuenta       |
| user_id        | UUID              | NOT NULL, FK → users.id | Usuario propietario de la cuenta        |
| account_number | VARCHAR(20)       | NOT NULL, UNIQUE   | Número de cuenta visible para el usuario       |
| account_type   | account_type      | NOT NULL, DEFAULT 'checking' | Tipo de cuenta (checking, savings) |
| currency       | VARCHAR(3)        | NOT NULL, DEFAULT 'USD' | Código de moneda (ISO 4217)              |
| balance        | NUMERIC(15,2)     | NOT NULL, DEFAULT 0, CHECK ≥ 0 | Saldo disponible de la cuenta    |
| status         | account_status    | NOT NULL, DEFAULT 'active' | Estado de la cuenta (active, inactive, frozen, closed) |
| created_at     | TIMESTAMPTZ       | NOT NULL, DEFAULT NOW() | Fecha de creación de la cuenta          |

**Mapa con API:** Se correlaciona con `GET /dashboard` (campo `saldo`) y con `POST /transfer` (validación de saldo).

**Nota:** Una cuenta puede tener múltiples transacciones. Un usuario puede tener múltiples cuentas.

---

## `transactions`

Registra todas las transacciones que afectan el saldo de una cuenta.

| Columna             | Tipo              | Restricciones      | Descripción                                    |
|---------------------|-------------------|--------------------|------------------------------------------------|
| id                  | UUID              | PK, DEFAULT gen_random_uuid() | Identificador único de la transacción |
| account_id          | UUID              | NOT NULL, FK → accounts.id | Cuenta afectada por la transacción    |
| destination_account | VARCHAR(20)       |                    | Número de cuenta destino (solo para transferencias) |
| transaction_type    | transaction_type  | NOT NULL           | Tipo: deposit, transfer, payment               |
| amount              | NUMERIC(15,2)     | NOT NULL, CHECK ≠ 0 | Monto con signo (+ ingreso, - egreso)        |
| description         | TEXT               |                    | Descripción o motivo de la transacción        |
| status              | transaction_status | NOT NULL, DEFAULT 'completed' | Estado (pending, completed, failed, reversed) |
| transaction_date    | TIMESTAMPTZ       | NOT NULL, DEFAULT NOW() | Fecha en que ocurrió la transacción    |
| created_at          | TIMESTAMPTZ       | NOT NULL, DEFAULT NOW() | Fecha de creación del registro         |

**Convención de signos:**
- `amount > 0`: Ingreso / Crédito (depósitos, transferencias recibidas)
- `amount < 0`: Egreso / Débito (transferencias enviadas, pagos)

**Mapa con API:** Se correlaciona con `GET /dashboard` (campo `movimientos`) y con `POST /transfer` (registro de la transferencia).

**Consulta típica para Dashboard:**
```sql
SELECT
    t.id,
    t.transaction_date::date AS fecha,
    t.description AS descripcion,
    CASE WHEN t.amount > 0 THEN 'Ingreso' ELSE 'Egreso' END AS tipo,
    t.amount AS monto,
    t.status AS estado
FROM transactions t
WHERE t.account_id = ?
ORDER BY t.transaction_date DESC
LIMIT 12;
```

---

## `refresh_tokens`

Administra las sesiones de los usuarios mediante tokens de actualización JWT.

| Columna    | Tipo        | Restricciones      | Descripción                                   |
|------------|-------------|--------------------|-----------------------------------------------|
| id         | UUID        | PK, DEFAULT gen_random_uuid() | Identificador único del token       |
| user_id    | UUID        | NOT NULL, FK → users.id | Usuario al que pertenece el token    |
| token      | TEXT        | NOT NULL, UNIQUE   | Valor del refresh token                      |
| expires_at | TIMESTAMPTZ | NOT NULL           | Fecha de expiración del token                |
| revoked    | BOOLEAN     | NOT NULL, DEFAULT FALSE | Indica si el token fue revocado          |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Fecha de creación del token           |

**Mapa con API:** Se correlaciona con `POST /auth/login` (generación de tokens) y renovación de sesión.
