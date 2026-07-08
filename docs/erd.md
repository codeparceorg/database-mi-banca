# Entity-Relationship Diagram

---

## Diagrama ER (texto)

```
┌─────────────────────────────────────────────────────┐
│                       USERS                          │
├─────────────────────────────────────────────────────┤
│  id              UUID            PK                  │
│  full_name       VARCHAR(100)    NOT NULL            │
│  email           VARCHAR(255)    NOT NULL, UNIQUE    │
│  password_hash   TEXT            NOT NULL            │
│  phone           VARCHAR(20)                         │
│  address         TEXT                                │
│  city            VARCHAR(100)                        │
│  avatar_url      TEXT                                │
│  client_number   VARCHAR(20)    NOT NULL, UNIQUE     │
│  status          user_status     DEFAULT 'active'    │
│  created_at      TIMESTAMPTZ     DEFAULT NOW()       │
│  updated_at      TIMESTAMPTZ     DEFAULT NOW()       │
└────────┬────────────────────────────────────────────┘
         │ 1
         │
         │ N (user_id)
         │
┌────────▼────────────────────────────────────────────┐
│                     ACCOUNTS                         │
├─────────────────────────────────────────────────────┤
│  id              UUID            PK                  │
│  user_id         UUID            FK → users.id      │
│  account_number  VARCHAR(20)     NOT NULL, UNIQUE    │
│  account_type    account_type    DEFAULT 'checking'  │
│  currency        VARCHAR(3)      DEFAULT 'USD'       │
│  balance         NUMERIC(15,2)   DEFAULT 0, CHECK≥0 │
│  status          account_status  DEFAULT 'active'    │
│  created_at      TIMESTAMPTZ     DEFAULT NOW()       │
└────────┬────────────────────────────────────────────┘
         │ 1
         │
         │ N (account_id)
         │
┌────────▼────────────────────────────────────────────┐
│                   TRANSACTIONS                       │
├─────────────────────────────────────────────────────┤
│  id                  UUID            PK              │
│  account_id          UUID            FK → accounts   │
│  destination_account VARCHAR(20)                     │
│  transaction_type    transaction_type NOT NULL        │
│  amount              NUMERIC(15,2)   NOT NULL, CHECK≠0│
│  description         TEXT                            │
│  status              transaction_status DEFAULT 'completed'│
│  transaction_date    TIMESTAMPTZ     DEFAULT NOW()    │
│  created_at          TIMESTAMPTZ     DEFAULT NOW()    │
└──────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│                   REFRESH_TOKENS                     │
├─────────────────────────────────────────────────────┤
│  id              UUID            PK                  │
│  user_id         UUID            FK → users.id      │
│  token           TEXT            NOT NULL, UNIQUE    │
│  expires_at      TIMESTAMPTZ     NOT NULL            │
│  revoked         BOOLEAN         DEFAULT FALSE       │
│  created_at      TIMESTAMPTZ     DEFAULT NOW()       │
└─────────────────────────────────────────────────────┘
         │
         │ N (user_id)
         │
         │ 1
┌────────┴────────────────────────────────────────────┐
│                       USERS                          │
└─────────────────────────────────────────────────────┘
```

---

## Convenciones de diseño

### Nombrado

- **Tablas:** plural en snake_case (`users`, `accounts`, `transactions`, `refresh_tokens`)
- **Columnas:** snake_case (`full_name`, `account_number`, `transaction_type`)
- **ENUMs:** snake_case (`user_status`, `account_type`, `transaction_status`)
- **Valores ENUM:** lowercase (`'active'`, `'checking'`, `'completed'`)

### Tipos de datos

- **UUID:** Todas las PK y FK usan UUID v4 para escalabilidad horizontal y seguridad (evita enumeración de IDs secuenciales)
- **NUMERIC(15,2):** Todos los valores monetarios usan precisión exacta (no `FLOAT`/`DOUBLE`)
- **TIMESTAMPTZ:** Todas las fechas incluyen zona horaria para consistencia entre regiones
- **VARCHAR vs TEXT:** `VARCHAR(N)` con límite fijo para campos cortos (nombres, números), `TEXT` para campos largos o sin límite predecible

### Normalización

El modelo cumple con Tercera Forma Normal (3FN):

1. **1FN:** Todos los atributos son atómicos. No hay grupos repetitivos.
2. **2FN:** Cada atributo no clave depende de la clave primaria completa. Tablas separadas para usuarios, cuentas, transacciones y tokens.
3. **3FN:** No hay dependencias transitivas. Por ejemplo, `client_number` depende directamente de `users.id`, no de otra tabla intermedia.

---

## Flujo de datos: Login → Dashboard

```
1. Login:  users.email → obtener password_hash y validar
2. Auth:   generar accessToken + refreshToken → insertar en refresh_tokens
3. Dashboard:  accounts.balance → saldo
               transactions WHERE account_id = ? ORDER BY transaction_date DESC → movimientos
4. Transfer:   accounts.balance → validar saldo
               INSERT INTO transactions → registrar débito
               UPDATE accounts.balance → restar saldo
               GET /profile → users (full_name, email, phone, address, city, client_number)
               PUT /profile → UPDATE users SET ... WHERE id = ?
```

---

## Evolución futura

### Funcionalidades previstas que el modelo puede soportar

| Funcionalidad       | Cambio requerido                                              |
|---------------------|---------------------------------------------------------------|
| Múltiples cuentas   | Ya soportado (accounts.user_id 1:N)                           |
| Tipos de cuenta     | Agregar valores al ENUM `account_type` (ej. 'credit')         |
| Pagos de servicios  | Nuevo valor en `transaction_type` o tabla `service_payments`  |
| Tarjetas            | Nueva tabla `cards` FK → accounts.id                          |
| Inversiones         | Nueva tabla `investments` FK → accounts.id                    |
| Créditos            | Nueva tabla `loans` FK → users.id                             |
| Auditoría           | Agregar tabla `audit_log` para historial de cambios           |
| Historial de login  | Agregar tabla `login_attempts`                                |
