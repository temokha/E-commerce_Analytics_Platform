from airflow.sdk import dag, task

from dwh_load import run_dwh_load, run_dwh_checks


@dag(
    dag_id="staging_to_dwh",
    schedule=None,
    catchup=False,
    max_active_runs=1,
    tags=["store", "dwh"],
)
def staging_to_dwh():

    @task
    def load_dwh():
        run_dwh_load()

    @task
    def check_dwh():
        run_dwh_checks()

    load_dwh() >> check_dwh()


staging_to_dwh()