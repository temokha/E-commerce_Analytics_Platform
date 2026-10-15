from airflow.sdk import dag, task, get_current_context

from store_ingestion import load_store_entity


@dag(
    dag_id="raw_store_ingestion",
    schedule=None,
    catchup=False,
    max_active_tasks=1,
    tags=["store", "raw"],
)
def raw_store_ingestion():

    @task
    def load_entity(entity: str):
        run_id = get_current_context()["run_id"]
        prefix = f"store/{entity}/{run_id}"
        load_store_entity(entity, prefix)

    entities = [
        "orders",
        "order_items",
        "products",
        "categories",
        "customers",
    ]

    for entity in entities:
        load_entity.override(task_id=f"load_{entity}")(entity)


raw_store_ingestion()