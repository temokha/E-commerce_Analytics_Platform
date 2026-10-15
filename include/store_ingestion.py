import json
import os

import boto3
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry


def load_store_entity(entity: str, prefix: str) -> None:
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
    source_url = f"https://api.sondahub.com/data/store/{entity}.json"
    object_key = f"{prefix}/{entity}.json"
    success_key = f"{prefix}/_SUCCESS"

    s3 = boto3.client(
        "s3",
        endpoint_url=os.environ["S3_ENDPOINT_URL"],
    )

    # Повторная попытка должна заново подтвердить успешную загрузку.
    s3.delete_object(Bucket=bucket, Key=success_key)

    with requests.Session() as session:
        retry_policy = Retry(
            total=3,
            backoff_factor=5,
            status_forcelist=[429, 500, 502, 503, 504],
            allowed_methods=["GET"],
            respect_retry_after_header=True,
            raise_on_status=False,
        )
        session.mount(
            "https://",
            HTTPAdapter(max_retries=retry_policy),
        )

        response = session.get(source_url, timeout=(10, 120))

        if not response.ok:
            print(
                f"{entity}: HTTP {response.status_code}; "
                f"Retry-After: {response.headers.get('Retry-After')}"
            )
        response.raise_for_status()

        payload = response.json()

        if isinstance(payload, list):
            records = payload
        elif isinstance(payload, dict) and isinstance(payload.get("data"), list):
            records = payload["data"]
        else:
            raise ValueError(f"{entity}: unexpected JSON structure")

        if not all(isinstance(record, dict) and "id" in record for record in records):
            raise ValueError(f"{entity}: records must be objects with an id")

        ids = [record["id"] for record in records]
        if len(ids) != len(set(ids)):
            raise ValueError(f"{entity}: duplicate ids found")

        # Сохраняем исходное содержимое файла без преобразований.
        content = response.content

    s3.put_object(
        Bucket=bucket,
        Key=object_key,
        Body=content,
        ContentType="application/json",
    )

    summary = {
        "entity": entity,
        "source_url": source_url,
        "object_key": object_key,
        "records": len(records),
        "bytes": len(content),
    }

    s3.put_object(
        Bucket=bucket,
        Key=success_key,
        Body=json.dumps(summary, ensure_ascii=False).encode("utf-8"),
        ContentType="application/json",
    )

    print(f"{entity}: saved {len(records)} records to {object_key}")