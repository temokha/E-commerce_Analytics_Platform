import os
from contextlib import closing
from pathlib import Path

import psycopg2


def run_dwh_load() -> None:
    sql_path = Path("/opt/airflow/sql/09_load_dwh.sql")
    sql_text = sql_path.read_text(encoding="utf-8-sig")

    if not sql_text.strip():
        raise ValueError("DWH SQL file is empty")

    with closing(
        psycopg2.connect(
            host=os.environ["DWH_DB_HOST"],
            port=os.environ["DWH_DB_PORT"],
            dbname=os.environ["DWH_DB_NAME"],
            user=os.environ["DWH_DB_USER"],
            password=os.environ["DWH_DB_PASSWORD"],
        )
    ) as connection:
        with connection:
            with connection.cursor() as cursor:
                cursor.execute(sql_text)

    print("DWH load completed successfully")


def run_dwh_checks() -> None:
    sql_path = Path("/opt/airflow/sql/10_check_dwh.sql")
    sql_text = sql_path.read_text(encoding="utf-8-sig")

    if not sql_text.strip():
        raise ValueError("DWH checks SQL file is empty")

    with closing(
        psycopg2.connect(
            host=os.environ["DWH_DB_HOST"],
            port=os.environ["DWH_DB_PORT"],
            dbname=os.environ["DWH_DB_NAME"],
            user=os.environ["DWH_DB_USER"],
            password=os.environ["DWH_DB_PASSWORD"],
        )
    ) as connection:
        with connection:
            with connection.cursor() as cursor:
                cursor.execute(sql_text)
                results = cursor.fetchall()

                if len(results) != 6:
                    raise ValueError("Expected six DWH check results")

                failed_checks = []

                for check_name, error_count in results:
                    print(f"{check_name}: {error_count} errors")

                    if error_count is None or error_count != 0:
                        failed_checks.append((check_name, error_count))

                if failed_checks:
                    raise ValueError(
                        f"DWH quality checks failed: {failed_checks}"
                    )

    print("All DWH checks passed")