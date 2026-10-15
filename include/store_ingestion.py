import json
import os
import boto3
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry


def load_store_entity(entity: str, prefix: str) -> None:
    bucket = os.environ["S3_BUCKET"]
    s3 = boto3.client(
        "s3",
        endpoint_url=os.environ["S3_ENDPOINT_URL"],
    )

    # При повторном выполнении убираем прежнюю отметку об успехе.
    s3.delete_object(Bucket=bucket, Key=f"{prefix}/_SUCCESS")

    page = 1
    loaded_count = 0
    expected_total = None
    expected_pages = None

    with requests.Session() as session:
        retry_policy = Retry(
            total=3,
            backoff_factor=5,
            status_forcelist=[429, 500, 502, 503, 504],
            allowed_methods=["GET"],
            respect_retry_after_header=True,
        )

        session.mount(
            "https://",
            HTTPAdapter(max_retries=retry_policy),
        )
        while True:
            response = session.get(
                f"https://api.sondahub.com/v1/store/{entity}",
                params={"page": page, "limit": 100},
                timeout=30,
            )
            if response.status_code == 429:
                print(f"429 response URL: {response.url}")

                for header in [
                    "Retry-After",
                    "RateLimit",
                    "RateLimit-Policy",
                    "X-RateLimit-Limit",
                    "X-RateLimit-Remaining",
                    "X-RateLimit-Reset",
                    "Server",
                ]:
                    print(f"{header}: {response.headers.get(header)}")

                print(f"Response body: {response.text[:1000]}")
            response.raise_for_status()
            payload = response.json()

            meta = payload["meta"]
            records = payload["data"]

            if page == 1:
                expected_total = meta["total"]
                expected_pages = meta["pages"]

            if (
                meta["page"] != page
                or meta["total"] != expected_total
                or meta["pages"] != expected_pages
            ):
                raise ValueError("Pagination metadata changed during loading")

            object_key = f"{prefix}/page_{page}.json"

            s3.put_object(
                Bucket=bucket,
                Key=object_key,
                Body=json.dumps(payload, ensure_ascii=False).encode("utf-8"),
                ContentType="application/json",
            )

            loaded_count += len(records)
            print(f"{entity}: page {page}, saved {len(records)} records")

            if page >= expected_pages:
                break

            page += 1

    if loaded_count != expected_total:
        raise ValueError(
            f"Expected {expected_total} records, loaded {loaded_count}"
        )

    summary = {
        "pages": page,
        "records": loaded_count,
        "source_total": expected_total,
    }

    s3.put_object(
        Bucket=bucket,
        Key=f"{prefix}/_SUCCESS",
        Body=json.dumps(summary).encode("utf-8"),
        ContentType="application/json",
    )

    print(f"{entity}: loading complete, {loaded_count} records, {page} pages")