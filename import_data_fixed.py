import os
import pandas as pd
import mysql.connector
from pathlib import Path

DATA_FOLDER = Path(__file__).resolve().parent

DB_NAME = "consumerbrandtracking"
FILE_TABLE_MAP = {
    "dim_respondent.csv": "dimrespondent",
    "dim_brand.csv": "dimbrand",
    "dim_wave.csv": "dimwave",
    "dim_question.csv": "dimquestion",
    "fact_survey_response_clean.csv": "factsurveyresponse",
}

print("Connecting to MySQL...")
conn = mysql.connector.connect(
        host="localhost",
        user="root",
        password=os.environ["MYSQL_PASSWORD"],
        database=DB_NAME,
    )
print("Connected successfully.")

cursor = conn.cursor()

try:
    for filename, table in FILE_TABLE_MAP.items():
        file_path = DATA_FOLDER / filename
        print(f"Loading {filename} into {table}...")

        if not file_path.exists():
            raise FileNotFoundError(f"Missing file: {file_path}")

        df = pd.read_csv(file_path)
        df = df.astype(object).where(pd.notna(df), None)

        columns = list(df.columns)
        col_sql = ", ".join(f"`{col}`" for col in columns)
        placeholders = ", ".join(["%s"] * len(columns))
        sql = f"INSERT INTO `{table}` ({col_sql}) VALUES ({placeholders})"
        rows = [tuple(r) for r in df.itertuples(index=False, name=None)]

        if rows:
            cursor.executemany(sql, rows)
            conn.commit()
            print(f"Imported {len(rows)} rows into {table}")
        else:
            print(f"No rows to import into {table}")

    print("\nAll CSV files imported successfully!")

except Exception as e:
    conn.rollback()
    print("\nImport stopped with error:")
    print(type(e).__name__, e)
    raise

finally:
    cursor.close()
    conn.close()
