# Travel Agency Database (MySQL)

Relational database for a travel agency, built during a database administration course and later reviewed for bugs and security issues.

## Files

| File | Description |
|---|---|
| `01_schema.sql` | Creates the database, 10 tables with foreign keys, and sample data |
| `02_queries.sql` | 20 queries: JOINs, aggregations, subqueries and date functions |
| `03_advanced.sql` | Variables, functions, stored procedures, transactions, trigger, view, users and indexes |

## How to run

Run the files in order on a local MySQL server:

```bash
mysql -u root -p < 01_schema.sql
mysql -u root -p agencia_viajes < 02_queries.sql
mysql -u root -p agencia_viajes < 03_advanced.sql
```

> ⚠️ `01_schema.sql` drops and recreates the database. Use it only in a local test environment.

Tested on MySQL 9.5.0.

## Security decisions

- **Password storage:** the `contrasena` column is sized for password hashes. A real application should store only a bcrypt or Argon2 hash, never the plain password. The sample data uses plain text only for demonstration.
- **Least privilege:** `admin_agencia` has full access to this database only; `consulta_reservas` can only read three tables.
- **No real credentials in code:** user passwords are placeholders (`CAMBIAR_ESTA_CLAVE`).
- **Audit trail:** a trigger logs every deleted reservation, using `CURRENT_USER()` to record the authenticated account.
- **Safe parameters:** stored procedures receive values as parameters instead of building SQL strings, which protects them from SQL injection.
- **Transactions:** deleting a reservation runs inside a transaction with rollback on error.

## Review notes

After reviewing my own code, I found and fixed:

- Wrong foreign keys: several places pointed to the wrong province.
- Double counting in query `k`: a JOIN duplicated rows, so the total spent was summed twice.
- A stored procedure that never deleted orphan travelers, because its cursor read rows that had already been deleted.
- A redundant index on a column that was already `UNIQUE`.

All data in this project is fictional.
