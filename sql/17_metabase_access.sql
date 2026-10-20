-- Создаём отдельного пользователя для Metabase.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_roles
        WHERE rolname = 'metabase_reader'
    ) THEN
        CREATE ROLE metabase_reader LOGIN;
    END IF;
END
$$;

-- Разрешаем подключение к базе.
GRANT CONNECT ON DATABASE ecommerce TO metabase_reader;

-- Разрешаем доступ к схеме и чтение существующих витрин.
GRANT USAGE ON SCHEMA dm TO metabase_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA dm TO metabase_reader;

-- Разрешаем чтение будущих витрин, созданных текущим пользователем.
ALTER DEFAULT PRIVILEGES IN SCHEMA dm
GRANT SELECT ON TABLES TO metabase_reader;

-- Выполнить отдельно, подставив свой пароль:
-- ALTER ROLE metabase_reader WITH PASSWORD 'replace_with_your_password';;