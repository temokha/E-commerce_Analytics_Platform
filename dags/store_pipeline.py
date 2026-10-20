from airflow.sdk import dag, task, get_current_context

from store_ingestion import load_store_entity
from staging_load import load_entity_to_staging
from dwh_load import run_dwh_load, run_dwh_checks


ENTITIES = [
    "orders",
    "order_items",
    "products",
    "categories",
    "customers",
]


@dag(
    dag_id="store_pipeline",
    schedule=None,
    catchup=False,
    max_active_tasks=1,
    max_active_runs=1,
    tags=["store", "pipeline"],
)
def store_pipeline():

    @task
    def extract_entity(entity: str):
        run_id = get_current_context()["run_id"]
        prefix = f"store/{entity}/{run_id}"
        load_store_entity(entity, prefix)

    @task
    def stage_entity(entity: str):
        run_id = get_current_context()["run_id"]
        load_entity_to_staging(entity, run_id)

    @task
    def load_dwh():
        run_dwh_load()

    @task
    def check_dwh():
        run_dwh_checks()

    raw_tasks = [
        extract_entity.override(task_id=f"extract_{entity}")(entity)
        for entity in ENTITIES
    ]

    staging_tasks = [
        stage_entity.override(task_id=f"stage_{entity}")(entity)
        for entity in ENTITIES
    ]

    dwh_task = load_dwh()
    checks_task = check_dwh()

    # Staging начинается после успешной выгрузки всех пяти сущностей.
    for raw_task in raw_tasks:
        raw_task >> staging_tasks

    # DWH загружается после обновления всех пяти staging-таблиц.
    for staging_task in staging_tasks:
        staging_task >> dwh_task

    dwh_task >> checks_task


store_pipeline()