from airflow.sdk import dag, task, get_current_context

from staging_load import load_entity_to_staging


@dag(
    dag_id="store_to_staging",
    schedule=None,
    catchup=False,
    max_active_tasks=1,
    max_active_runs=1,
    params={
        "source_run_id": "manual__2026-10-15T11:41:24.710240+00:00",
    },
    tags=["store", "staging"],
)
def store_to_staging():

    @task
    def load_entity(entity: str):
        context = get_current_context()
        source_run_id = context["params"]["source_run_id"]

        if not isinstance(source_run_id, str) or not source_run_id.strip():
            raise ValueError("source_run_id must be a non-empty string")

        load_entity_to_staging(entity, source_run_id)

    entities = [
        "orders",
        "order_items",
        "products",
        "categories",
        "customers",
    ]

    for entity in entities:
        load_entity.override(task_id=f"load_{entity}")(entity)


store_to_staging()