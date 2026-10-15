import json
import os
from contextlib import closing

import boto3
import psycopg2
from psycopg2 import sql
from psycopg2.extras import Json, execute_values


def load_entity_to_staging(entity: str, source_run_id: str) -> None:
    allowed_entities = {
        "orders",
        "order_items",
        "products",
        "categories",
        "customers",
    }

    if entity not in allowed_entities:
        raise ValueError(f"Unknown entity: {entity}")

    bucket = os.environ["S3_BUCKET"]
    prefix = f"store/{entity}/{source_run_id}"
    source_key = f"{prefix}/{entity}.json"

    s3 = boto3.client(
        "s3",
        endpoint_url=os.environ["S3_ENDPOINT_URL"],
    )

    # Проверяем завершение исходной выгрузки.
    with closing(
        s3.get_object(Bucket=bucket, Key=f"{prefix}/_SUCCESS")["Body"]
    ) as body:
        summary = json.loads(body.read())

    if summary["object_key"] != source_key:
        raise ValueError("Success marker refers to another file")

    # Читаем исходные данные.
    with closing(
        s3.get_object(Bucket=bucket, Key=source_key)["Body"]
    ) as body:
        payload = json.loads(body.read())

    records = payload if isinstance(payload, list) else payload["data"]

    if not records or len(records) != summary["records"]:
        raise ValueError("Empty file or record count mismatch")

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
                table = sql.Identifier("staging", entity)

                cursor.execute(
                    sql.SQL("DELETE FROM {}").format(table)
                )

                insert_query = sql.SQL(
                    "INSERT INTO {} (payload, source_key) VALUES %s"
                ).format(table)

                execute_values(
                    cursor,
                    insert_query.as_string(connection),
                    [(Json(record), source_key) for record in records],
                    page_size=1000,
                )

    print(f"{entity}: loaded {len(records)} records into staging")