# Banking Application — Database

Base de datos PostgreSQL para la aplicación bancaria.

---

## Requisitos

- PostgreSQL 17+
- Cliente `psql`

---

## Crear la base de datos

```bash
# Conectarse al servidor PostgreSQL
psql -U postgres

# Crear la base de datos
CREATE DATABASE banking_app;

# Conectarse a la nueva base de datos
\c banking_app;
```

---

## Ejecutar el Schema

```bash
psql -U postgres -d banking_app -f database/schema.sql
```

Este comando crea:
- Los tipos ENUM personalizados
- Las 4 tablas del modelo (users, accounts, transactions, refresh_tokens)
- Los índices para optimizar consultas

---

## Ejecutar el Seed

```bash
psql -U postgres -d banking_app -f database/seed.sql
```

Este comando inserta datos de ejemplo:
- 2 usuarios (Juan Pérez y Ana López)
- 2 cuentas bancarias
- 12 transacciones para la cuenta de Juan (coincidentes con los datos mock del Frontend)
- 1 refresh token para Juan

---

## Verificar la instalación

```sql
-- Listar tablas
\dt

-- Ver estructura de una tabla
\d+ users

-- Ver datos insertados
SELECT * FROM users;
SELECT * FROM accounts;
SELECT * FROM transactions ORDER BY transaction_date DESC LIMIT 5;
```

---

## Consulta útil: Dashboard

```sql
-- Obtener saldo
SELECT balance FROM accounts WHERE account_number = '1000000001';

-- Obtener últimos movimientos
SELECT
    t.id,
    t.transaction_date::date AS fecha,
    t.description AS descripcion,
    CASE WHEN t.amount > 0 THEN 'Ingreso' ELSE 'Egreso' END AS tipo,
    t.amount AS monto,
    t.status AS estado
FROM transactions t
JOIN accounts a ON t.account_id = a.id
WHERE a.account_number = '1000000001'
ORDER BY t.transaction_date DESC
LIMIT 12;
```

---

## Estructura de archivos

```
database/
├── README.md             # Este archivo
├── schema.sql            # DDL: CREATE TABLE, INDEXES, ENUMS
├── seed.sql              # DML: INSERT con datos de ejemplo
├── tables.md             # Documentación de cada tabla
├── relationships.md      # Documentación de relaciones
├── constraints.md        # Lista de restricciones
├── indexes.md            # Documentación de índices
└── erd.md                # Descripción del diagrama ER
```

---

## Seguridad

- Las contraseñas se almacenan como hash (bcrypt), nunca en texto plano.
- Los tokens JWT se almacenan hasheados en `refresh_tokens.token`.
- Los tokens expirados o revocados deben limpiarse periódicamente.

---

## Notas

- Los UUIDs en seed.sql son fijos para entornos de desarrollo. En producción usar `gen_random_uuid()`.
- El balance de cuentas tiene restricción `CHECK (balance >= 0)` para evitar sobregiros.
- Las transacciones financieras no se eliminan físicamente (uso de `ON DELETE RESTRICT`).
