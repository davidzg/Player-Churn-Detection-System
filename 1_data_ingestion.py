import os
from google.cloud import bigquery


os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "../../f2p-game-balance-c2c1d685fd2e.json"
client = bigquery.Client()


project_id = "f2p-game-balance"
dataset_id = "game_data_analysis"
dataset_ref = f"{project_id}.{dataset_id}"


try:
    client.get_dataset(dataset_ref)
    print("Dataset already exists.")
except:
    dataset = bigquery.Dataset(dataset_ref)
    dataset.location = "US"
    client.create_dataset(dataset, timeout=30)
    print(f"Created dataset {dataset_id}")


files_to_upload = {
    "general.csv": "general",
    "tutorial.csv": "tutorial",
    "cards.csv": "cards",
    "campaigns.csv": "campaigns"
}

def upload_csv(file_path, table_name):
    table_ref = f"{dataset_ref}.{table_name}"
    
    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1, # Ignore header row
        autodetect=True,     # Let BQ guess the schema
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE, # Overwrite if exists
    )

    with open(file_path, "rb") as source_file:
        job = client.load_table_from_file(source_file, table_ref, job_config=job_config)

    job.result()  # Wait for the job to complete
    print(f"Loaded {file_path} into {table_ref}")


for file, table in files_to_upload.items():
    upload_csv(file, table)