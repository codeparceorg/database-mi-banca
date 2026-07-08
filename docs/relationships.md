# Relationships

---

## Diagrama de relaciones

```
┌──────────┐       ┌──────────────┐       ┌──────────────┐
│  users   │       │   accounts   │       │ transactions │
├──────────┤       ├──────────────┤       ├──────────────┤
│ id (PK)  │──1:N──│ user_id (FK) │──1:N──│ account_id   │
└──────────┘       │ id (PK)      │       │ (FK)         │
                   └──────────────┘       │ id (PK)      │
                                          └──────────────┘
┌──────────┐
│ refresh_ │
│ _tokens  │
├──────────┤
│ user_id  │
│ (FK)     │
└──────────┘
```

---

## Relaciones detalladas

### 1. `accounts.user_id` → `users.id`

| Tipo     | Muchos a uno (N:1)                              |
|----------|--------------------------------------------------|
| Tabla origen  | `accounts` (user_id)                        |
| Tabla destino | `users` (id)                               |
| Restricción   | `ON DELETE RESTRICT` — No permite eliminar un usuario que tenga cuentas |
| Justificación | Un usuario puede tener múltiples cuentas (checking, savings). Cada cuenta pertenece a exactamente un usuario. |

### 2. `transactions.account_id` → `accounts.id`

| Tipo     | Muchos a uno (N:1)                                |
|----------|--------------------------------------------------|
| Tabla origen  | `transactions` (account_id)                  |
| Tabla destino | `accounts` (id)                              |
| Restricción   | `ON DELETE RESTRICT` — No permite eliminar una cuenta que tenga transacciones |
| Justificación | Una cuenta tiene muchas transacciones a lo largo del tiempo. Cada transacción afecta a exactamente una cuenta desde la perspectiva del registro. |

### 3. `refresh_tokens.user_id` → `users.id`

| Tipo     | Muchos a uno (N:1)                                  |
|----------|----------------------------------------------------|
| Tabla origen  | `refresh_tokens` (user_id)                    |
| Tabla destino | `users` (id)                                  |
| Restricción   | `ON DELETE CASCADE` — Eliminar un usuario revoca automáticamente todos sus tokens |
| Justificación | Un usuario puede tener múltiples sesiones activas (varios dispositivos). Los tokens de sesión dependen totalmente del usuario. |

---

## Resumen de cardinalidades

| Desde         | Hacia          | Tipo      | Descripción                        |
|---------------|----------------|-----------|------------------------------------|
| users         | accounts       | 1 → N     | Un usuario puede tener varias cuentas |
| users         | refresh_tokens | 1 → N     | Un usuario puede tener varios tokens  |
| accounts      | transactions   | 1 → N     | Una cuenta puede tener muchas transacciones |

## Integridad referencial

- No existen registros huérfanos: todas las Foreign Keys están definidas.
- `ON DELETE RESTRICT` en cuentas y transacciones protege la integridad financiera.
- `ON DELETE CASCADE` en refresh_tokens permite limpieza segura al eliminar usuarios.
