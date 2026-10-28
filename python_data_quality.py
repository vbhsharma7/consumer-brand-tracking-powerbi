"""
Run with: python python_data_quality.py
Requires: pandas (pip install pandas)
Outputs: fact_survey_response_clean.csv and qc_summary.txt
"""
from pathlib import Path
import pandas as pd

BASE = Path(__file__).resolve().parent
raw_path = BASE / "fact_survey_response_raw.csv"
df = pd.read_csv(raw_path)

lines = []
lines.append(f"Raw rows: {len(df)}")
lines.append(f"Duplicate ResponseID rows: {df['ResponseID'].duplicated().sum()}")

# Flag duplicates at the business grain, not just duplicate IDs.
grain = ["RespondentID", "QuestionID", "BrandID", "WaveID"]
duplicate_grain = df.duplicated(grain, keep="first")
lines.append(f"Duplicate business-grain rows flagged: {int(duplicate_grain.sum())}")

# Validate satisfaction score range. QuestionID 4 = Satisfaction.
invalid_satisfaction = (
    (df["QuestionID"] == 4)
    & df["NumericValue"].notna()
    & ~df["NumericValue"].between(1, 5)
)
lines.append(f"Invalid satisfaction values flagged: {int(invalid_satisfaction.sum())}")

# Basic status and response checks
invalid_status = ~df["ResponseStatus"].isin(["Valid", "NotAsked", "Flagged"])
lines.append(f"Unknown ResponseStatus values: {int(invalid_status.sum())}")

# Clean: keep first record per business grain and remove invalid satisfaction values.
clean = df.loc[~duplicate_grain & ~invalid_satisfaction & ~invalid_status].copy()
lines.append(f"Clean rows: {len(clean)}")
lines.append(f"Rows removed: {len(df) - len(clean)}")

clean.to_csv(BASE / "fact_survey_response_clean.csv", index=False)
(BASE / "qc_summary.txt").write_text("\\n".join(lines), encoding="utf-8")
print("\\n".join(lines))
print(f"\\nSaved: {BASE / 'fact_survey_response_clean.csv'}")
